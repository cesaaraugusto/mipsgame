	# Constants
		#FrameBuffer
		.eqv ANCHO_FB 512			
		.eqv ALTURA_FB 256
		.eqv LONGITUD_FB 524288
		.eqv DIRECCION_DISPLAY 0x10010000

		#Fondo
		.eqv espacio_fondo_ancho 512		
		.eqv espacio_fondo_altura 256
		.eqv espacio_fondo_longitud 524288	

		#Sapo		
		.eqv espacio_sapo_ancho 72		
		.eqv espacio_sapo_altura 54
		.eqv espacio_sapo_longitud 15552	

		#Mosca Buena 1
		#.eqv espacio_mosca_buena1_ancho 52		# Sprte Witdth 52*4
		#.eqv espacio_sapo_altura 40
		#.eqv espacio_mosca_buena1_longitud 8320	# Sprite longitud 52*40*4

		#Mosca Buena 2
		#.eqv espacio_mosca_buena1_ancho 52		# Sprte Witdth 52*4
		#.eqv espacio_sapo_altura 40
		#.eqv espacio_mosca_buena1_longitud 8320	# Sprite longitud 52*40*4

		#Mosca Buena 3
		#.eqv espacio_mosca_buena1_ancho 52		# Sprte Witdth 52*4
		#.eqv espacio_sapo_altura 40
		#.eqv espacio_mosca_buena1_longitud 8320	# Sprite longitud 52*40*4

		#Mosca Mala 1
		#.eqv espacio_mosca_buena1_ancho 52		# Sprte Witdth 52*4
		#.eqv espacio_sapo_altura 40
		#.eqv espacio_mosca_buena1_longitud 8320	# Sprite longitud 52*40*4

		#Mosca Mala 2
		#.eqv espacio_mosca_buena1_ancho 52		# Sprte Witdth 52*4
		#.eqv espacio_sapo_altura 40
		#.eqv espacio_mosca_buena1_longitud 8320	# Sprite longitud 52*40*4
		
.macro load_image(%file_name_address, %load_address)
	# open the file
	li $v0, 13						      # load v0 with integer for syscall
	la $a0, %file_name_address  # file name address
	li $a1, 0										# $a1 = flags, 0 is read only
	li $a2, 0 			 						# $a2 = mode, 0 is ignore
	syscall 										# Open File, $v0 stores file descriptor (fd)
	
	# write byte contents from file to address
	move $a0, $v0								# move the file descriptor to a0
	la $a1, %load_address       # load the address to dump data in a1
	li $a2, 4										# number of characters to read each time
	# start dumping the bytes
	loop1:
		li $v0, 14 								# re-write this register to keep reading from file
		syscall
		
		# treat the endian order bs (images are in BE already)
		# ok so, if I read 4 bytes they get read as 
		# little endian so it is flipped (ABGR)
		# but the format used is not actually RGBA
		# but rather ARGB for some dumb reason
		# I will just ignore the A value as it is
		# irrelevant for the bitmap screen
		lw $t0, ($a1)
		andi $t1, $t0, 0x0000FF00
		andi $t2, $t0, 0x000000FF
		sll $t2, $t2, 16
		add $t1, $t1, $t2
		andi $t2, $t0, 0x00FF0000
		srl $t2, $t2, 16
		add $t1, $t1, $t2
		sw $t1, ($a1)		
		
		add $a1, $a1, 4 					# new position to dump the incomming bytes
		bnez $v0, loop1     			# continue reading until 0 chars read 
	
	# close the file
	move $a0, $v0
	li $v0, 16
	syscall
.end_macro

# function to draw an image in the framebuffer at the specified position (x, y)
# uses registers s3, s4, t2, t3, t4, t5, t6 and t7
.macro draw_image(%img_data, %img_width, %img_height, %x, %y)
	# fill the registers
	la $s3, %img_data							# image bytes address
	add $s4, $zero, %img_width		# image width (pixels)
	add $t2, $zero, %img_height		# image height (pixels)
	add $t3, $zero, %x						# image load pos x (pixels)
	add $t4, $zero, %y						# image load pos y (pixels)
	add $t6, $zero, $s4 					# counter for row's elements
	add $t7, $zero, $t3 					# saving x coordinate
	# loop over rows
	loop1:
		
		# loop over the elements of a row
		loop2:
			# get the pixel data
			lw $t5, ($s3)
			# get address to write pixel data
			# place the values in the registers
			add $s0, $zero, $t3
			add $s1, $zero, $t4 
						# treat x
			div $t0, $s0, ANCHO_FB # get x's multiplier
			mul $t0, $t0, ANCHO_FB
			ble $s0, ANCHO_FB, x_is_neg_or_less_than_fb_width
			sub $s0, $s0, $t0
			b x_is_done 		
			x_is_neg_or_less_than_fb_width:
			bgez $s0, x_is_done
	 		sub $s0, $s0, $t0
	 		beqz $s0, x_is_done 
			add $s0, $s0, ANCHO_FB
			x_is_done:
						# treat y
			div $t0, $s1, ALTURA_FB # get y's multiplier
			mul $t0, $t0, ALTURA_FB
			ble $s1, ALTURA_FB, y_is_neg_or_less_than_fb_height
			sub $s1, $s1, $t0
			b y_is_done 		
			y_is_neg_or_less_than_fb_height:
			bgez $s1, y_is_done
			sub $s1, $s1, $t0
			beqz $s1, y_is_done
			add $s1, $s1, ALTURA_FB
			y_is_done:
			# results are done
		
			add $t0, $zero, $s1
			mul $t0, $t0, ANCHO_FB
			add $t0, $t0, $s0
			mul $t0, $t0, 4
			add $s0, $t0, DIRECCION_DISPLAY
			# write the pixel data
			sw $t5, ($s0)
			# update the variables for the next loop
			add $s3, $s3, 4			# advance 4 bytes in img data address
			add $t3, $t3, 1			# advance 1 in x
			add $t6, $t6, -1  	# one element less in the row
			bnez $t6, loop2
		
		add $t6, $zero, $s4 	# reset counter for row's elements	
		add $t4, $t4, 1 			# advance one in y
		add $t3, $zero, $t7		# reset x
		add $t2, $t2, -1			# next row
		bnez $t2, loop1
.end_macro
				
	# Data Segment
		.data
# Estatico
FB: 		.space LONGITUD_FB		
file_fondo: 	.asciiz "fondo.rgba" 		# File name
		.word 0
espacio_fondo:	.space espacio_fondo_longitud
file_sapo: 	.asciiz "sapo.rgba" 		# File name
		.word 0
espacio_sapo:	.space espacio_sapo_longitud
#file_mosca_buena1: 	.asciiz "moscacloseup.rgba" 		# File name
#		.word 0
#espacio_mosca_buena1:	.space espacio_mosca_buena1_longitud

	# Text Segment
		.text
		.globl main
main:
	load_image(file_fondo, espacio_fondo)
	load_image(file_sapo, espacio_sapo)
	draw_image(espacio_fondo, espacio_fondo_ancho, espacio_fondo_altura, 0, 0)
	draw_image(espacio_sapo, espacio_sapo_ancho, espacio_sapo_altura, 0, 100)
	
