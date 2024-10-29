#include <stdio.h>
#include <string>
#include <assert.h>
#include "Vtest_top.h"
#include "Vtest_top__Syms.h"
#include "verilated_vcd_c.h"

#define MAX_SIM_CYCLE 20
#define HALT_ADDR   0x1F0000
vluint64_t main_time = 0; 

using namespace std;
void sim_mem_load_bin(Vtest_top_dpram__R200000_RB15* ram, string filename);
int sim_mem_read(Vtest_top_dpram__R200000_RB15* ram,uint32_t addr, size_t length);
int sim_regs_read(Vtest_top_regfile* regs,uint32_t addr);


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

    int isa_test = 0;
    if (argc == 3) {
        isa_test = stoi(string(argv[2]));
    }
    
    VerilatedVcdC* tfp = new VerilatedVcdC(); 

    Vtest_top *top = new Vtest_top("top");
    if (isa_test==2) {
        top->trace(tfp, 0);
        tfp->open("wave.vcd"); 
    }

    sim_mem_load_bin(top->test_top->dpram0, string(argv[1]));
    top->reset_in = 1;
    for (int i = 0 ; i < 5 ; i ++){
        top->clk_in = 0;
        top->eval ();
        if (isa_test==2) {
           main_time += 1;
           tfp->dump(main_time);
        }
        top->clk_in = 1;
        top->eval ();
        if (isa_test==2) {
           main_time += 1;
           tfp->dump(main_time);
        }
    }
    top->reset_in = 0;   

    while(!Verilated::gotFinish()) {
        top->clk_in=0;
        top->eval();
        if (isa_test==2) {
           main_time += 1;
           tfp->dump(main_time);
        }
         top->clk_in=1;
        top->eval();
        if (isa_test==2) {
           main_time += 1;
           tfp->dump(main_time);
        }
        if (top->halt_out)
            break;
    }
    
    //int x26, x27;
    //for isa-test
    if (isa_test==1) {
        int x26 = sim_regs_read(top->test_top->core_top0->regfile0, 26);
        int x27 = sim_regs_read(top->test_top->core_top0->regfile0, 27);
        int gp = sim_regs_read(top->test_top->core_top0->regfile0, 3);
        if (x26==0 || x27==0) { 
            printf("FAIL %d\n", gp);
        } else
            printf("PASS\n");
    }
    top->final();
    //tfp->close();
    delete top;
    return 0;
}


