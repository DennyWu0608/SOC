.text			# Define beginning of text section
.global	_start		# Define entry _start

_start:
    li x1, 1
	li x2, 5
	li x3, 10
	csrrw x2, mscratch, x2
	csrrci x1, mscratch, 7
	csrrci x6, mscratch, 10
	.end			# End of file