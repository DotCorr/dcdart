#include "flow.h"
int main(void) {
  uint32_t data[]={3,5,7,11};
  if(walk(data,4)!=26 || walk(data,0)!=0) return 1;
  if(choose(data,data+1,0)!=data || choose(data,data+1,1)!=data+1) return 2;
  if(alternate(10)!=70 || alternate(0)!=0) return 3;
  return 0;
}
