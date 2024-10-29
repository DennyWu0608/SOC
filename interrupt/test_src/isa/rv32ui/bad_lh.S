 .text
 .global _start;
 _start:
 li s10, 0;
 li s11, 0;
 auipc	ra,0x2;
 addi	ra,ra,-56; # 2000 <begin_signature>
 lh	t5,4(ra);
 lui	t4,0x1;
 addi	t4,t4,-16; # ff0 <loop_pass+0xd5c>
 li	gp,4;
 bne	t5,t4,274;