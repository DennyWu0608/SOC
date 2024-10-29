TOP = test_top
GTKWAVE = gtkwave

V_SRC = ./rtl/soc/test_top.v
V_SRC += ./rtl/core/core_top.v
V_SRC += $(wildcard ./rtl/core/if/*.v)
V_SRC += $(wildcard ./rtl/core/id/*.v)
V_SRC += $(wildcard ./rtl/core/exe/*.v)
V_SRC += $(wildcard ./rtl/core/mem/*.v)
V_SRC += $(wildcard ./rtl/core/wb/*.v)
V_SRC += $(wildcard ./rtl/core/ctrl/*.v)
V_SRC += $(wildcard ./rtl/device/*.v)

TESTBENCH_SRC = $(wildcard ./tb/*.cpp)
VTOP = ./rtl/soc/${TOP}.v
INC = -Irtl/core/include
PROG = test
PROG_S = $(wildcard ./test_src/*.S)
PROG_TWO = os

.DEFAULT_GOAL := all
all: vhdl

obj_dir/V${TOP}.mk: ${V_SRC} ${TESTBENCH_SRC} 
	verilator -Wall --cc --exe --build ${TESTBENCH_SRC} ${INC} ${V_SRC}  --trace
	
obj_dir/V${TOP}.exe : obj_dir/V${TOP}.mk
	$(MAKE) -C obj_dir -f V$(TOP).mk

test_src/${PROG}.bin: ${PROG_S}
	$(MAKE) -C test_src

.PHONY : vhdl
vhdl: obj_dir/V${TOP}.mk

.PHONY : run
run: test_src/${PROG}.bin obj_dir/V${TOP}
	obj_dir/V${TOP} test_src/${PROG}.bin


.PHONY : wave
wave: 
	${GTKWAVE} wave.vcd

.PHONY: c_test
c_test: obj_dir/V${TOP}.exe 
	${MAKE} -C test_src/c_test
	obj_dir/V${TOP} test_src/c_test/${PROG}.bin

.PHONY: csr_test
csr_test: obj_dir/V${TOP}
	${MAKE} -C test_src/csr_test
	obj_dir/V${TOP} test_src/csr_test/${PROG}.bin

.PHONY: isa_test
isa_test: obj_dir/V${TOP}.exe 
	${MAKE} -C test_src/isa
	python3 test_all_isa.py

.PHONY : test_isa
test_isa: 
	${MAKE} -C test_src/isa 

.PHONY : timer
timer: 
	obj_dir/V${TOP} test_src/07-hwtimer/${PROG_TWO}.bin

.PHONY : timer2
timer2: 
	obj_dir/V${TOP} test_src/07-hwtimer/${PROG_TWO}.bin 2

.PHONY : multitask
multitask: 
	obj_dir/V${TOP} test_src/04-multitask/${PROG_TWO}.bin

.PHONY : preemptive
preemptive: 
	obj_dir/V${TOP} test_src/08-preemptive/${PROG_TWO}.bin

.PHONY : syscall
syscall: 
	obj_dir/V${TOP} test_src/11-syscall/${PROG_TWO}.bin

.PHONY : clean
clean:
# ${MAKE} -C test/c_test clean
	rm -rf obj_dir wave.vcd
	rm -rf test_src/*.elf test_src/*.bin

