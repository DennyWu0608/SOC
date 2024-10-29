# 0 "sh.S"
# 0 "<built-in>"
# 0 "<command-line>"
# 1 "sh.S"
# See LICENSE for license details.

#*****************************************************************************
# sh.S
#-----------------------------------------------------------------------------

# Test sh instruction.


# 1 "../riscv_test.h" 1
# 11 "sh.S" 2
# 1 "../test_macros.h" 1
# 10 "../test_macros.h"
#-----------------------------------------------------------------------
# Helper macros
#-----------------------------------------------------------------------
# 105 "../test_macros.h"
# We use a macro hack to simpify code generation for various numbers
# of bubble cycles.
# 121 "../test_macros.h"
#-----------------------------------------------------------------------
# RV64UI MACROS
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Tests for instructions with immediate operand
#-----------------------------------------------------------------------
# 177 "../test_macros.h"
#-----------------------------------------------------------------------
# Tests for an instruction with register operands
#-----------------------------------------------------------------------
# 205 "../test_macros.h"
#-----------------------------------------------------------------------
# Tests for an instruction with register-register operands
#-----------------------------------------------------------------------
# 299 "../test_macros.h"
#-----------------------------------------------------------------------
# Test memory instructions
#-----------------------------------------------------------------------
# 425 "../test_macros.h"
#-----------------------------------------------------------------------
# Test jump instructions
#-----------------------------------------------------------------------
# 454 "../test_macros.h"
#-----------------------------------------------------------------------
# RV64UF MACROS
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Tests floating-point instructions
#-----------------------------------------------------------------------
# 859 "../test_macros.h"
#-----------------------------------------------------------------------
# Pass and fail code (assumes test num is in gp)
#-----------------------------------------------------------------------
# 871 "../test_macros.h"
#-----------------------------------------------------------------------
# Test data section
#-----------------------------------------------------------------------
# 12 "sh.S" 2

.macro init; .endm
.section .text.init; .align 6; .globl _start; _start: li x26, 0x00; li x27, 0x00;

  #-------------------------------------------------------------
  # Basic tests
  #-------------------------------------------------------------

  test_2: la x1, tdat; li x2, 0x00000000000000aa; sh x2, 0(x1); lh x30, 0(x1);; li x29, ((0x00000000000000aa) & ((1 << (64 - 1) << 1) - 1)); li gp, 2; bne x30, x29, fail;;
  test_3: la x1, tdat; li x2, 0xffffffffffffaa00; sh x2, 2(x1); lh x30, 2(x1);; li x29, ((0xffffffffffffaa00) & ((1 << (64 - 1) << 1) - 1)); li gp, 3; bne x30, x29, fail;;
  test_4: la x1, tdat; li x2, 0xffffffffbeef0aa0; sh x2, 4(x1); lw x30, 4(x1);; li x29, ((0xffffffffbeef0aa0) & ((1 << (64 - 1) << 1) - 1)); li gp, 4; bne x30, x29, fail;;
  test_5: la x1, tdat; li x2, 0xffffffffffffa00a; sh x2, 6(x1); lh x30, 6(x1);; li x29, ((0xffffffffffffa00a) & ((1 << (64 - 1) << 1) - 1)); li gp, 5; bne x30, x29, fail;;

  # Test with negative offset

  test_6: la x1, tdat8; li x2, 0x00000000000000aa; sh x2, -6(x1); lh x30, -6(x1);; li x29, ((0x00000000000000aa) & ((1 << (64 - 1) << 1) - 1)); li gp, 6; bne x30, x29, fail;;
  test_7: la x1, tdat8; li x2, 0xffffffffffffaa00; sh x2, -4(x1); lh x30, -4(x1);; li x29, ((0xffffffffffffaa00) & ((1 << (64 - 1) << 1) - 1)); li gp, 7; bne x30, x29, fail;;
  test_8: la x1, tdat8; li x2, 0x0000000000000aa0; sh x2, -2(x1); lh x30, -2(x1);; li x29, ((0x0000000000000aa0) & ((1 << (64 - 1) << 1) - 1)); li gp, 8; bne x30, x29, fail;;
  test_9: la x1, tdat8; li x2, 0xffffffffffffa00a; sh x2, 0(x1); lh x30, 0(x1);; li x29, ((0xffffffffffffa00a) & ((1 << (64 - 1) << 1) - 1)); li gp, 9; bne x30, x29, fail;;

  # Test with a negative base

  test_10: la x1, tdat9; li x2, 0x12345678; addi x4, x1, -32; sh x2, 32(x4); lh x5, 0(x1);; li x29, ((0x5678) & ((1 << (64 - 1) << 1) - 1)); li gp, 10; bne x5, x29, fail;







  # Test with unaligned base

  test_11: la x1, tdat9; li x2, 0x00003098; addi x1, x1, -5; sh x2, 7(x1); la x4, tdat10; lh x5, 0(x4);; li x29, ((0x3098) & ((1 << (64 - 1) << 1) - 1)); li gp, 11; bne x5, x29, fail;
# 53 "sh.S"
  #-------------------------------------------------------------
  # Bypassing tests
  #-------------------------------------------------------------

  test_12: li gp, 12; li x4, 0; 1: li x1, 0xffffffffffffccdd; la x2, tdat; sh x1, 0(x2); lh x30, 0(x2); li x29, 0xffffffffffffccdd; bne x30, x29, fail; addi x4, x4, 1; li x5, 2; bne x4, x5, 1b;
  test_13: li gp, 13; li x4, 0; 1: li x1, 0xffffffffffffbccd; la x2, tdat; nop; sh x1, 2(x2); lh x30, 2(x2); li x29, 0xffffffffffffbccd; bne x30, x29, fail; addi x4, x4, 1; li x5, 2; bne x4, x5, 1b;
  test_14: li gp, 14; li x4, 0; 1: li x1, 0xffffffffffffbbcc; la x2, tdat; nop; nop; sh x1, 4(x2); lh x30, 4(x2); li x29, 0xffffffffffffbbcc; bne x30, x29, fail; addi x4, x4, 1; li x5, 2; bne x4, x5, 1b;
  test_15: li gp, 15; li x4, 0; 1: li x1, 0xffffffffffffabbc; nop; la x2, tdat; sh x1, 6(x2); lh x30, 6(x2); li x29, 0xffffffffffffabbc; bne x30, x29, fail; addi x4, x4, 1; li x5, 2; bne x4, x5, 1b;
  test_16: li gp, 16; li x4, 0; 1: li x1, 0xffffffffffffaabb; nop; la x2, tdat; nop; sh x1, 8(x2); lh x30, 8(x2); li x29, 0xffffffffffffaabb; bne x30, x29, fail; addi x4, x4, 1; li x5, 2; bne x4, x5, 1b;
  test_17: li gp, 17; li x4, 0; 1: li x1, 0xffffffffffffdaab; nop; nop; la x2, tdat; sh x1, 10(x2); lh x30, 10(x2); li x29, 0xffffffffffffdaab; bne x30, x29, fail; addi x4, x4, 1; li x5, 2; bne x4, x5, 1b;

  test_18: li gp, 18; li x4, 0; 1: la x2, tdat; li x1, 0x2233; sh x1, 0(x2); lh x30, 0(x2); li x29, 0x2233; bne x30, x29, fail; addi x4, x4, 1; li x5, 2; bne x4, x5, 1b;
  test_19: li gp, 19; li x4, 0; 1: la x2, tdat; li x1, 0x1223; nop; sh x1, 2(x2); lh x30, 2(x2); li x29, 0x1223; bne x30, x29, fail; addi x4, x4, 1; li x5, 2; bne x4, x5, 1b;
  test_20: li gp, 20; li x4, 0; 1: la x2, tdat; li x1, 0x1122; nop; nop; sh x1, 4(x2); lh x30, 4(x2); li x29, 0x1122; bne x30, x29, fail; addi x4, x4, 1; li x5, 2; bne x4, x5, 1b;
  test_21: li gp, 21; li x4, 0; 1: la x2, tdat; nop; li x1, 0x0112; sh x1, 6(x2); lh x30, 6(x2); li x29, 0x0112; bne x30, x29, fail; addi x4, x4, 1; li x5, 2; bne x4, x5, 1b;
  test_22: li gp, 22; li x4, 0; 1: la x2, tdat; nop; li x1, 0x0011; nop; sh x1, 8(x2); lh x30, 8(x2); li x29, 0x0011; bne x30, x29, fail; addi x4, x4, 1; li x5, 2; bne x4, x5, 1b;
  test_23: li gp, 23; li x4, 0; 1: la x2, tdat; nop; nop; li x1, 0x3001; sh x1, 10(x2); lh x30, 10(x2); li x29, 0x3001; bne x30, x29, fail; addi x4, x4, 1; li x5, 2; bne x4, x5, 1b;

  li a0, 0xbeef
  la a1, tdat
  sh a0, 6(a1)

  bne x0, gp, pass; fail: li x26, 0x01; li x27, 0x00; loop_fail: lui a5, 0x1f0; li a6, 1; sw a6, 0(a5); j loop_fail;; pass: li x26, 0x01; li x27, 0x01; loop_pass: lui a5, 0x1f0; li a6, 1; sw a6, 0(a5); j loop_pass;



  .data
 .pushsection .tohost,"aw",@progbits; .align 6; .global tohost; tohost: .dword 0; .align 6; .global fromhost; fromhost: .dword 0; .popsection; .align 4; .global begin_signature; begin_signature:

 

tdat:
tdat1: .half 0xbeef
tdat2: .half 0xbeef
tdat3: .half 0xbeef
tdat4: .half 0xbeef
tdat5: .half 0xbeef
tdat6: .half 0xbeef
tdat7: .half 0xbeef
tdat8: .half 0xbeef
tdat9: .half 0xbeef
tdat10: .half 0xbeef

.align 4; .global end_signature; end_signature:
