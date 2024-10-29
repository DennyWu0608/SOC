
#include "util.h"
#include "soc_reg.h"
#include "kprintf.h"

int gcd(int a, int b)
{
  if (b==0) return a;
  return gcd(b, a%b);
}

int main(int argc, char **argv) 
{
  int s[10]={0};
  int x=100, y=24;

  for (int i=0;i<10;i++)
    s[i]='0'+i;
  
  for (int j=0;j<10;j++)
    kprintf("string = %c, %03x\n", s[j],s[j]);
 

  kprintf("recursive test gcd(%d,%d)=%d", x, y, gcd(x,y));
  sim_halt();
  return 0;
}

