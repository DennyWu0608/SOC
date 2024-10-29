	.text			# Define beginning of text section
	.global	_start		# Define entry _start

_start:
	li x3, 0x1a
	li x4, 0x1b
	la x5, _array
	sh x3, 0(x5)		# char x4 = *x5
	sh x4, 4(x5)		# char x4 = *(x5+4)
	lh x8, 0(x5)
	lh x9, 4(x5)
	lh x10, 0(x5)

_array:	
	.byte 0x10
	.byte 0x20
	.byte 0x30
	.byte 0x40
	.byte 0x50
	.byte 0x60
	.byte 0x70
	.byte 0x80


	.end			# End of file
