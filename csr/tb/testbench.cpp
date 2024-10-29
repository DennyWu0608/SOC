#include <stdio.h>
#include <string>
#include <assert.h>
#include "Vtest_top.h"
#include "Vtest_top__Syms.h"
#include "verilated_vcd_c.h"

#define MAX_SIM_CYCLE 20 // change the wave time
vluint64_t main_time = 0; 

using namespace std;
void sim_mem_load_bin(Vtest_top_dpram__R200000_RB15* ram, string filename);
uint32_t sim_regs_read(Vtest_top_regfile* regs,uint32_t addr);

double sc_time_stamp()
 {
     return (main_time);
 }

int main(int argc,char **argv)
{
    Verilated::commandArgs(argc,argv);
    Verilated::traceEverOn(true); 

    if (argc < 2) {
        printf("Please provide riscv test elf file\n");
        return -1;
    }

    VerilatedVcdC* tfp = new VerilatedVcdC(); 

    Vtest_top *top = new Vtest_top("top");
    top->trace(tfp, 0);
    tfp->open("wave.vcd"); 

    sim_mem_load_bin(top->test_top->dpram0, string(argv[1]));

    top->reset_in = 1;
    for (int i = 0 ; i < 5 ; i ++){
        top->clk_in = 0;
        top->eval ();
        main_time += 5;
        tfp->dump(main_time);
        top->clk_in = 1;
        top->eval ();
        main_time += 5;
        tfp->dump(main_time);
    }
    top->reset_in = 0;    
    
    for( int i=0; i<MAX_SIM_CYCLE;i++) {
        top->clk_in=0;
        top->eval();
        main_time +=5;
        tfp->dump(main_time);
        top->clk_in=1;
        top->eval();
        main_time +=5;
        tfp->dump(main_time);
    }
     top->final();
     tfp->close();
     delete top;
     return 0;
}