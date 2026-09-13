#include "text.h"
#include <string.h>
static uint8_t data[] = {65,0,255,42};
Str foreignText(void) { return (Str){data,4}; }
uint64_t consume(Str text) { return text.length == 6 && memcmp(text.bytes,"DCDart",6)==0 ? 77 : 0; }
static Str reverse_slice(Str text) { return (Str){text.bytes+1,text.length-1}; }
int main(void) {
  Str a = greeting();
  if (a.length!=6 || memcmp(a.bytes,"h\xc3\xa9llo",6)) return 1;
  Str b = identity((Str){data,4});
  if (b.bytes!=data || b.length!=4 || length(b)!=4) return 2;
  if (checksum(b)!=362 || fromC()!=362 || toC()!=77) return 3;
  Str c = throughCallback(reverse_slice,b);
  if (c.bytes!=data+1 || c.length!=3 || checksum(c)!=297) return 4;
  if (checksum((Str){0,0})!=0) return 5;
  return 0;
}
