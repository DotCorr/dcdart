#include "atomic.h"
#include <stdint.h>
#include <signal.h>
#include <sys/wait.h>
#include <unistd.h>
#include <stdio.h>

#define ADAPTER(name) static uint64_t call_##name(uint64_t address) { return name(address); }
#define WIDTH(bits) \
  ADAPTER(load##bits) ADAPTER(store##bits) ADAPTER(exchange##bits) \
  ADAPTER(fetchAdd##bits) ADAPTER(fetchSub##bits) ADAPTER(fetchAnd##bits) \
  ADAPTER(fetchOr##bits) ADAPTER(fetchXor##bits)
WIDTH(8) WIDTH(16) WIDTH(32) WIDTH(64)
#undef WIDTH
#define ENTRY(name, bits) {call_##name##bits, bits / 8, #name #bits}
#define WIDTH(bits) \
  ENTRY(load, bits), ENTRY(store, bits), ENTRY(exchange, bits), \
  ENTRY(fetchAdd, bits), ENTRY(fetchSub, bits), ENTRY(fetchAnd, bits), \
  ENTRY(fetchOr, bits), ENTRY(fetchXor, bits)

int main(void) {
  const struct { uint64_t (*call)(uint64_t); int bytes; const char *name; } tests[] = {
    WIDTH(8), WIDTH(16), WIDTH(32), WIDTH(64)
  };
  _Alignas(16) unsigned char data[32] = {0};
  for (unsigned i = 0; i < sizeof(tests) / sizeof(tests[0]); ++i) {
    (void)tests[i].call((uintptr_t)data);
    if (tests[i].bytes == 1) (void)tests[i].call((uintptr_t)(data + 1));
    for (int offset = 1; offset < tests[i].bytes; ++offset) {
      pid_t child = fork();
      if (child < 0) return 2;
      if (child == 0) {
        (void)tests[i].call((uintptr_t)(data + offset));
        _exit(0);
      }
      int status;
      if (waitpid(child, &status, 0) != child) return 3;
      // A hardware SIGBUS/SIGSEGV is not the language's deliberate trap.
      if (!WIFSIGNALED(status) || (WTERMSIG(status) != SIGILL && WTERMSIG(status) != SIGTRAP)) {
        fprintf(stderr, "%s offset %d did not deliberately trap (status %d)\n",
                tests[i].name, offset, status);
        return 1;
      }
    }
  }
  puts("ATOMIC ALIGNMENT: aligned operations succeed; all under-aligned operations deliberately trap");
  return 0;
}
