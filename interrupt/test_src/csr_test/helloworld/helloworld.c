
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

  unsigned int x = 0x12345679;
  unsigned int y = 0;
  kprintf("mepc=%032B\n",x);
  w_mepc(x);
  y = r_mhartid();
  kprintf("mepc=%032B\n",y);

  sim_halt();
  return 0;
}

