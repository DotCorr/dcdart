#include "cas.h"
#include <stdint.h>
#ifdef _WIN32
#include <windows.h>
#define THREAD_RESULT DWORD WINAPI
#define THREAD_RETURN return 0
#else
#include <pthread.h>
#define THREAD_RESULT void *
#define THREAD_RETURN return 0
#endif
static uint64_t counter;
static THREAD_RESULT worker(void *ignored) {
  (void)ignored;
  for (int i=0;i<10000;++i) increment(&counter);
  THREAD_RETURN;
}
int main(int argc, char **argv) {
  if (argc>1) {
    uint64_t storage[2] = {0,0};
    void *bad = (unsigned char *)storage + 1;
    if (argv[1][0]=='2') return cas16(bad,0,1);
    if (argv[1][0]=='4') return cas32(bad,0,1);
    return (int)cas64(bad,0,1);
  }
  if(booleanLoop(0)!=0 || booleanLoop(17)!=17) return 5;
#define CHECK(W) uint##W##_t x##W=7; if(cas##W(&x##W,7,19)!=7 || x##W!=19 || cas##W(&x##W,7,23)!=19 || x##W!=19) return 1;
  CHECK(8) CHECK(16) CHECK(32) CHECK(64)
#define SIGNED(W) int##W##_t y##W=-7; if(casSigned##W(&y##W,-7,-19)!=-7 || y##W!=-19 || casSigned##W(&y##W,-7,23)!=-19 || y##W!=-19) return 6;
  SIGNED(8) SIGNED(16) SIGNED(32) SIGNED(64)
#ifdef _WIN32
  HANDLE threads[4];
  for(int i=0;i<4;++i) { threads[i]=CreateThread(0,0,worker,0,0,0); if(!threads[i]) return 2; }
  WaitForMultipleObjects(4,threads,TRUE,INFINITE);
  for(int i=0;i<4;++i) CloseHandle(threads[i]);
#else
  pthread_t threads[4];
  for(int i=0;i<4;++i) if(pthread_create(&threads[i],0,worker,0)) return 2;
  for(int i=0;i<4;++i) if(pthread_join(threads[i],0)) return 3;
#endif
  return counter==40000 ? 0 : 4;
}
