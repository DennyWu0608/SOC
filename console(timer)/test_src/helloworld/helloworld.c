
#include "util.h"
#include "soc_reg.h"
#include "kprintf.h"

int main(int argc, char **argv) 
{
  kprintf("%d s\n", give_time());
  int c=18;
  char *s = "Hello";
  int count = 10;
  c = 0x31;
  kprintf("%d s\n", give_time());
  kprintf("DCLab 系統晶片 %s %c, %d, %x, %p\n",s,c,c,c,s);
  while (count > 0)
  {
    kprintf("%d s\n", give_time());
    count --;
  }
  sim_halt();
  //printf("DCLab 系統晶片");
  return 0;
}


