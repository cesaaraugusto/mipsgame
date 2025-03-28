	# Constants
		.eqv WIDTH 256			# FrameBuffer Width
		.eqv FB_LENGTH 262144 		# 256*256*4

.macro mostrar_imagen(%nombre_archivo,%espacio_reservado,%framebuffer)
	# Open File
		li $v0, 13 			# $v0 specifies the syscall type, where 13=open file
		la $a0, %nombre_archivo 			# $a2 = address of the name of file to read
		add $a1, $0, $0 		# $a1=flags, 0 is O_RDONLY
		add $a2, $0, $0 		# $a2=mode, 0 is ignore
		syscall 			# Open File, $v0 stores file descriptor (fd)
		move $s0, $v0 			# store fd in $s0

	# Read FB_LENGTH bytes from file, storing in framebuffer
		li $v0, 14 			# $v0 specifies the syscall type, where 14=read from file
		move $a0, $s0 			# $a0=file_descriptor
		la $a1, %framebuffer 			# $a1=address of input buffer (frame buffer)
		li $a2, %espacio_reservado 		# $a2=maximum numbers of characters to read
		syscall 			# Read From File, $v0 contains number of characters read or 0 if EOF

	# Workaround Bitmap Display Bug
		li $s5, 0 			# i=0
		move $t0, $a1 			# $t0 is FB base address
        loop: 		bge $s5, $a2, done 		# while i<FB_LENGHT
        	lw $s6, ($t0) 			# load ith pixel in $s6
        	sw $s6, ($t0) 			# store ith pixel
        	addiu $t0, $t0, 4 		# step address fw
        	addiu $s5, $s5, 4 		# i++
        	j loop
        done:
        # Close File
        	li $v0, 16 			# $v0 specifies the syscall type, where 16=close file
        	move $a0, $s0 			# $a0=file_descriptor
        	syscall
.end_macro

	# Data Segment
.data
    FB: 		.space FB_LENGTH 		# Reserve FB_LENGTH Sapce in Data Segment in FB label
    file: 		.asciiz "Lenna.rgba" 		# File name
	    	.word 0

	# Text Segment
.text
		.globl main
main:
    mostrar_imagen(file, FB_LENGHT, FB)
	# Exit Gracefully
		li $v0, 10 			# $v0 specifies the syscall type, where 10=exit
		syscall 			# Exit
