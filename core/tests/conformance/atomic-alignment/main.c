#include "atomic.h"
#include <stdint.h>
#include <signal.h>
#include <sys/wait.h>
#include <unistd.h>
#include <stdio.h>
int main(void) {
  _Alignas(16) unsigned char data[32] = {0};
  int status; pid_t child;
  (void)load8((uintptr_t)data);
  (void)load8((uintptr_t)(data + 1));
  (void)store8((uintptr_t)data);
  (void)store8((uintptr_t)(data + 1));
  (void)exchange8((uintptr_t)data);
  (void)exchange8((uintptr_t)(data + 1));
  (void)fetchAdd8((uintptr_t)data);
  (void)fetchAdd8((uintptr_t)(data + 1));
  (void)fetchSub8((uintptr_t)data);
  (void)fetchSub8((uintptr_t)(data + 1));
  (void)fetchAnd8((uintptr_t)data);
  (void)fetchAnd8((uintptr_t)(data + 1));
  (void)fetchOr8((uintptr_t)data);
  (void)fetchOr8((uintptr_t)(data + 1));
  (void)fetchXor8((uintptr_t)data);
  (void)fetchXor8((uintptr_t)(data + 1));
  (void)load16((uintptr_t)data);
  for (int offset = 1; offset < 2; ++offset) {
    child = fork(); if (child < 0) return 2;
    if (child == 0) { (void)load16((uintptr_t)(data + offset)); _exit(0); }
    if (waitpid(child, &status, 0) != child) return 3;
    if (!WIFSIGNALED(status) || (WTERMSIG(status) != SIGILL && WTERMSIG(status) != SIGTRAP)) {
      fprintf(stderr, "load16 offset %d did not deliberately trap (status %d)\n", offset, status); return 1;
    }
  }
  (void)store16((uintptr_t)data);
  for (int offset = 1; offset < 2; ++offset) {
    child = fork(); if (child < 0) return 2;
    if (child == 0) { (void)store16((uintptr_t)(data + offset)); _exit(0); }
    if (waitpid(child, &status, 0) != child) return 3;
    if (!WIFSIGNALED(status) || (WTERMSIG(status) != SIGILL && WTERMSIG(status) != SIGTRAP)) {
      fprintf(stderr, "store16 offset %d did not deliberately trap (status %d)\n", offset, status); return 1;
    }
  }
  (void)exchange16((uintptr_t)data);
  for (int offset = 1; offset < 2; ++offset) {
    child = fork(); if (child < 0) return 2;
    if (child == 0) { (void)exchange16((uintptr_t)(data + offset)); _exit(0); }
    if (waitpid(child, &status, 0) != child) return 3;
    if (!WIFSIGNALED(status) || (WTERMSIG(status) != SIGILL && WTERMSIG(status) != SIGTRAP)) {
      fprintf(stderr, "exchange16 offset %d did not deliberately trap (status %d)\n", offset, status); return 1;
    }
  }
  (void)fetchAdd16((uintptr_t)data);
  for (int offset = 1; offset < 2; ++offset) {
    child = fork(); if (child < 0) return 2;
    if (child == 0) { (void)fetchAdd16((uintptr_t)(data + offset)); _exit(0); }
    if (waitpid(child, &status, 0) != child) return 3;
    if (!WIFSIGNALED(status) || (WTERMSIG(status) != SIGILL && WTERMSIG(status) != SIGTRAP)) {
      fprintf(stderr, "fetchAdd16 offset %d did not deliberately trap (status %d)\n", offset, status); return 1;
    }
  }
  (void)fetchSub16((uintptr_t)data);
  for (int offset = 1; offset < 2; ++offset) {
    child = fork(); if (child < 0) return 2;
    if (child == 0) { (void)fetchSub16((uintptr_t)(data + offset)); _exit(0); }
    if (waitpid(child, &status, 0) != child) return 3;
    if (!WIFSIGNALED(status) || (WTERMSIG(status) != SIGILL && WTERMSIG(status) != SIGTRAP)) {
      fprintf(stderr, "fetchSub16 offset %d did not deliberately trap (status %d)\n", offset, status); return 1;
    }
  }
  (void)fetchAnd16((uintptr_t)data);
  for (int offset = 1; offset < 2; ++offset) {
    child = fork(); if (child < 0) return 2;
    if (child == 0) { (void)fetchAnd16((uintptr_t)(data + offset)); _exit(0); }
    if (waitpid(child, &status, 0) != child) return 3;
    if (!WIFSIGNALED(status) || (WTERMSIG(status) != SIGILL && WTERMSIG(status) != SIGTRAP)) {
      fprintf(stderr, "fetchAnd16 offset %d did not deliberately trap (status %d)\n", offset, status); return 1;
    }
  }
  (void)fetchOr16((uintptr_t)data);
  for (int offset = 1; offset < 2; ++offset) {
    child = fork(); if (child < 0) return 2;
    if (child == 0) { (void)fetchOr16((uintptr_t)(data + offset)); _exit(0); }
    if (waitpid(child, &status, 0) != child) return 3;
    if (!WIFSIGNALED(status) || (WTERMSIG(status) != SIGILL && WTERMSIG(status) != SIGTRAP)) {
      fprintf(stderr, "fetchOr16 offset %d did not deliberately trap (status %d)\n", offset, status); return 1;
    }
  }
  (void)fetchXor16((uintptr_t)data);
  for (int offset = 1; offset < 2; ++offset) {
    child = fork(); if (child < 0) return 2;
    if (child == 0) { (void)fetchXor16((uintptr_t)(data + offset)); _exit(0); }
    if (waitpid(child, &status, 0) != child) return 3;
    if (!WIFSIGNALED(status) || (WTERMSIG(status) != SIGILL && WTERMSIG(status) != SIGTRAP)) {
      fprintf(stderr, "fetchXor16 offset %d did not deliberately trap (status %d)\n", offset, status); return 1;
    }
  }
  (void)load32((uintptr_t)data);
  for (int offset = 1; offset < 4; ++offset) {
    child = fork(); if (child < 0) return 2;
    if (child == 0) { (void)load32((uintptr_t)(data + offset)); _exit(0); }
    if (waitpid(child, &status, 0) != child) return 3;
    if (!WIFSIGNALED(status) || (WTERMSIG(status) != SIGILL && WTERMSIG(status) != SIGTRAP)) {
      fprintf(stderr, "load32 offset %d did not deliberately trap (status %d)\n", offset, status); return 1;
    }
  }
  (void)store32((uintptr_t)data);
  for (int offset = 1; offset < 4; ++offset) {
    child = fork(); if (child < 0) return 2;
    if (child == 0) { (void)store32((uintptr_t)(data + offset)); _exit(0); }
    if (waitpid(child, &status, 0) != child) return 3;
    if (!WIFSIGNALED(status) || (WTERMSIG(status) != SIGILL && WTERMSIG(status) != SIGTRAP)) {
      fprintf(stderr, "store32 offset %d did not deliberately trap (status %d)\n", offset, status); return 1;
    }
  }
  (void)exchange32((uintptr_t)data);
  for (int offset = 1; offset < 4; ++offset) {
    child = fork(); if (child < 0) return 2;
    if (child == 0) { (void)exchange32((uintptr_t)(data + offset)); _exit(0); }
    if (waitpid(child, &status, 0) != child) return 3;
    if (!WIFSIGNALED(status) || (WTERMSIG(status) != SIGILL && WTERMSIG(status) != SIGTRAP)) {
      fprintf(stderr, "exchange32 offset %d did not deliberately trap (status %d)\n", offset, status); return 1;
    }
  }
  (void)fetchAdd32((uintptr_t)data);
  for (int offset = 1; offset < 4; ++offset) {
    child = fork(); if (child < 0) return 2;
    if (child == 0) { (void)fetchAdd32((uintptr_t)(data + offset)); _exit(0); }
    if (waitpid(child, &status, 0) != child) return 3;
    if (!WIFSIGNALED(status) || (WTERMSIG(status) != SIGILL && WTERMSIG(status) != SIGTRAP)) {
      fprintf(stderr, "fetchAdd32 offset %d did not deliberately trap (status %d)\n", offset, status); return 1;
    }
  }
  (void)fetchSub32((uintptr_t)data);
  for (int offset = 1; offset < 4; ++offset) {
    child = fork(); if (child < 0) return 2;
    if (child == 0) { (void)fetchSub32((uintptr_t)(data + offset)); _exit(0); }
    if (waitpid(child, &status, 0) != child) return 3;
    if (!WIFSIGNALED(status) || (WTERMSIG(status) != SIGILL && WTERMSIG(status) != SIGTRAP)) {
      fprintf(stderr, "fetchSub32 offset %d did not deliberately trap (status %d)\n", offset, status); return 1;
    }
  }
  (void)fetchAnd32((uintptr_t)data);
  for (int offset = 1; offset < 4; ++offset) {
    child = fork(); if (child < 0) return 2;
    if (child == 0) { (void)fetchAnd32((uintptr_t)(data + offset)); _exit(0); }
    if (waitpid(child, &status, 0) != child) return 3;
    if (!WIFSIGNALED(status) || (WTERMSIG(status) != SIGILL && WTERMSIG(status) != SIGTRAP)) {
      fprintf(stderr, "fetchAnd32 offset %d did not deliberately trap (status %d)\n", offset, status); return 1;
    }
  }
  (void)fetchOr32((uintptr_t)data);
  for (int offset = 1; offset < 4; ++offset) {
    child = fork(); if (child < 0) return 2;
    if (child == 0) { (void)fetchOr32((uintptr_t)(data + offset)); _exit(0); }
    if (waitpid(child, &status, 0) != child) return 3;
    if (!WIFSIGNALED(status) || (WTERMSIG(status) != SIGILL && WTERMSIG(status) != SIGTRAP)) {
      fprintf(stderr, "fetchOr32 offset %d did not deliberately trap (status %d)\n", offset, status); return 1;
    }
  }
  (void)fetchXor32((uintptr_t)data);
  for (int offset = 1; offset < 4; ++offset) {
    child = fork(); if (child < 0) return 2;
    if (child == 0) { (void)fetchXor32((uintptr_t)(data + offset)); _exit(0); }
    if (waitpid(child, &status, 0) != child) return 3;
    if (!WIFSIGNALED(status) || (WTERMSIG(status) != SIGILL && WTERMSIG(status) != SIGTRAP)) {
      fprintf(stderr, "fetchXor32 offset %d did not deliberately trap (status %d)\n", offset, status); return 1;
    }
  }
  (void)load64((uintptr_t)data);
  for (int offset = 1; offset < 8; ++offset) {
    child = fork(); if (child < 0) return 2;
    if (child == 0) { (void)load64((uintptr_t)(data + offset)); _exit(0); }
    if (waitpid(child, &status, 0) != child) return 3;
    if (!WIFSIGNALED(status) || (WTERMSIG(status) != SIGILL && WTERMSIG(status) != SIGTRAP)) {
      fprintf(stderr, "load64 offset %d did not deliberately trap (status %d)\n", offset, status); return 1;
    }
  }
  (void)store64((uintptr_t)data);
  for (int offset = 1; offset < 8; ++offset) {
    child = fork(); if (child < 0) return 2;
    if (child == 0) { (void)store64((uintptr_t)(data + offset)); _exit(0); }
    if (waitpid(child, &status, 0) != child) return 3;
    if (!WIFSIGNALED(status) || (WTERMSIG(status) != SIGILL && WTERMSIG(status) != SIGTRAP)) {
      fprintf(stderr, "store64 offset %d did not deliberately trap (status %d)\n", offset, status); return 1;
    }
  }
  (void)exchange64((uintptr_t)data);
  for (int offset = 1; offset < 8; ++offset) {
    child = fork(); if (child < 0) return 2;
    if (child == 0) { (void)exchange64((uintptr_t)(data + offset)); _exit(0); }
    if (waitpid(child, &status, 0) != child) return 3;
    if (!WIFSIGNALED(status) || (WTERMSIG(status) != SIGILL && WTERMSIG(status) != SIGTRAP)) {
      fprintf(stderr, "exchange64 offset %d did not deliberately trap (status %d)\n", offset, status); return 1;
    }
  }
  (void)fetchAdd64((uintptr_t)data);
  for (int offset = 1; offset < 8; ++offset) {
    child = fork(); if (child < 0) return 2;
    if (child == 0) { (void)fetchAdd64((uintptr_t)(data + offset)); _exit(0); }
    if (waitpid(child, &status, 0) != child) return 3;
    if (!WIFSIGNALED(status) || (WTERMSIG(status) != SIGILL && WTERMSIG(status) != SIGTRAP)) {
      fprintf(stderr, "fetchAdd64 offset %d did not deliberately trap (status %d)\n", offset, status); return 1;
    }
  }
  (void)fetchSub64((uintptr_t)data);
  for (int offset = 1; offset < 8; ++offset) {
    child = fork(); if (child < 0) return 2;
    if (child == 0) { (void)fetchSub64((uintptr_t)(data + offset)); _exit(0); }
    if (waitpid(child, &status, 0) != child) return 3;
    if (!WIFSIGNALED(status) || (WTERMSIG(status) != SIGILL && WTERMSIG(status) != SIGTRAP)) {
      fprintf(stderr, "fetchSub64 offset %d did not deliberately trap (status %d)\n", offset, status); return 1;
    }
  }
  (void)fetchAnd64((uintptr_t)data);
  for (int offset = 1; offset < 8; ++offset) {
    child = fork(); if (child < 0) return 2;
    if (child == 0) { (void)fetchAnd64((uintptr_t)(data + offset)); _exit(0); }
    if (waitpid(child, &status, 0) != child) return 3;
    if (!WIFSIGNALED(status) || (WTERMSIG(status) != SIGILL && WTERMSIG(status) != SIGTRAP)) {
      fprintf(stderr, "fetchAnd64 offset %d did not deliberately trap (status %d)\n", offset, status); return 1;
    }
  }
  (void)fetchOr64((uintptr_t)data);
  for (int offset = 1; offset < 8; ++offset) {
    child = fork(); if (child < 0) return 2;
    if (child == 0) { (void)fetchOr64((uintptr_t)(data + offset)); _exit(0); }
    if (waitpid(child, &status, 0) != child) return 3;
    if (!WIFSIGNALED(status) || (WTERMSIG(status) != SIGILL && WTERMSIG(status) != SIGTRAP)) {
      fprintf(stderr, "fetchOr64 offset %d did not deliberately trap (status %d)\n", offset, status); return 1;
    }
  }
  (void)fetchXor64((uintptr_t)data);
  for (int offset = 1; offset < 8; ++offset) {
    child = fork(); if (child < 0) return 2;
    if (child == 0) { (void)fetchXor64((uintptr_t)(data + offset)); _exit(0); }
    if (waitpid(child, &status, 0) != child) return 3;
    if (!WIFSIGNALED(status) || (WTERMSIG(status) != SIGILL && WTERMSIG(status) != SIGTRAP)) {
      fprintf(stderr, "fetchXor64 offset %d did not deliberately trap (status %d)\n", offset, status); return 1;
    }
  }
  puts("ATOMIC ALIGNMENT: aligned operations succeed; all under-aligned operations deliberately trap");
  return 0;
}
