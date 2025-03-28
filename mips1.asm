.eqv FB_ADDRESS 0x10010000
.eqv FB_WIDTH 256
.eqv FB_HEIGHT 512
.eqv FB_BYTE_WIDTH 1024
.eqv FB_BYTE_LENGTH 524288 	# (256 * 4) * 512

.eqv BOAT_SPEED 4
.eqv BOAT_WIDTH 78
.eqv BOAT_HEIGHT 60
.eqv BOAT_BYTE_WIDTH 312
.eqv BOAT_BYTE_LENGTH 18720 # (78 * 4) * 60
.eqv BOAT_Y 80

.eqv FISH1_WIDTH 32
.eqv FISH1_HEIGHT 32
.eqv FISH1_BYTE_WIDTH 128
.eqv FISH1_BYTE_LENGTH 4096
.eqv FISH1_SPEED 3
.eqv FISH2_SPEED 4
.eqv X_FISH2_START 0
.eqv Y_FISH2_START 210
.eqv X_FISH2_END 110
.eqv FISH3_SPEED 5
.eqv X_FISH3_START 96
.eqv Y_FISH3_START 325
.eqv X_FISH3_END 210
.eqv MINE1_SPEED 1
.eqv MINE1_FRAMES_WAIT 5
.eqv MINE2_SPEED 4
.eqv MINE2_FRAMES_WAIT 13
.eqv X_MINE1_START 5
.eqv Y_MINE1_START 330
.eqv X_MINE1_END 65
.eqv X_MINE2_START 140
.eqv Y_MINE2_START 275
.eqv X_MINE2_END 220
.eqv X_CRAB_START 128
.eqv Y_CRAB_START 468
.eqv CRAB_SPEED 3

.eqv WL_SCREEN_WIDTH 200
.eqv WL_SCREEN_HEIGHT 100
.eqv WL_SCREEN_BYTE_LENGTH 80000
.eqv WL_SCREEN_X 28
.eqv WL_SCREEN_Y 206

# loads file data into memory at a given address
# endian is considered, uses t0, t1 and t2
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

# gets the real coords of a given (x, y) inside the framebuffer
# basically it behaves as a screenwrap
# uses register t0
# returns the result into s0 (x) and s1 (y) 
.macro get_coords_real_pos(%x, %y)
		# place the values in the registers
		add $s0, $zero, %x
		add $s1, $zero, %y 
		
		# treat x
		div $t0, $s0, FB_WIDTH # get x's multiplier
		mul $t0, $t0, FB_WIDTH
		ble $s0, FB_WIDTH, x_is_neg_or_less_than_fb_width
		sub $s0, $s0, $t0
		b x_is_done 		
		x_is_neg_or_less_than_fb_width:
		bgez $s0, x_is_done
	 	sub $s0, $s0, $t0
	 	beqz $s0, x_is_done 
		add $s0, $s0, FB_WIDTH
		x_is_done:
		
		# treat y
		div $t0, $s1, FB_HEIGHT # get y's multiplier
		mul $t0, $t0, FB_HEIGHT
		ble $s1, FB_HEIGHT, y_is_neg_or_less_than_fb_height
		sub $s1, $s1, $t0
		b y_is_done 		
		y_is_neg_or_less_than_fb_height:
		bgez $s1, y_is_done
		sub $s1, $s1, $t0
		beqz $s1, y_is_done
		add $s1, $s1, FB_HEIGHT
		y_is_done:
		
		# results are done
.end_macro

# returns the address of the coords in pixels given
# assumes the coords are inside the framebuffer already (get_coords_real_pos)
# the address to return is stored in s0
# uses t0
.macro get_coords_address(%x, %y)
	add $t0, $zero, %y
	mul $t0, $t0, FB_WIDTH
	add $t0, $t0, %x
	mul $t0, $t0, 4
	add $s0, $t0, FB_ADDRESS
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
			get_coords_real_pos($t3, $t4)
			get_coords_address($s0, $s1)
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

.data
	fb: .space FB_BYTE_LENGTH
	background: .space FB_BYTE_LENGTH
	boat: .space BOAT_BYTE_LENGTH
	fish1: .space FISH1_BYTE_LENGTH
	fish1_skeleton: .space FISH1_BYTE_LENGTH
	fish1_background: .space FISH1_BYTE_LENGTH
	fish2_right: .space FISH1_BYTE_LENGTH
	fish2_left: .space FISH1_BYTE_LENGTH
	fish2_skeleton_right: .space FISH1_BYTE_LENGTH
	fish2_skeleton_left: .space FISH1_BYTE_LENGTH
	fish2_background: .space FISH1_BYTE_LENGTH
	fish3_right: .space FISH1_BYTE_LENGTH
	fish3_left: .space FISH1_BYTE_LENGTH
	mine1: .space FISH1_BYTE_LENGTH
	mine2: .space FISH1_BYTE_LENGTH
	mine_blow: .space FISH1_BYTE_LENGTH 
	crab: .space FISH1_BYTE_LENGTH
	crab1: .space FISH1_BYTE_LENGTH
	crab_dollar: .space FISH1_BYTE_LENGTH 
	lose_screen: .space WL_SCREEN_BYTE_LENGTH
	win_screen: .space WL_SCREEN_BYTE_LENGTH
	background_path: .asciiz "background.rgba"
	boat_path: .asciiz "boat.rgba"
	fish1_path: .asciiz "fish1.rgba"
	fish1_skeleton_path: .asciiz "fish1_skeleton.rgba"
	fish1_background_path: .asciiz "fish1_background.rgba"
	fish2_right_path: .asciiz "fish2_right.rgba"
	fish2_left_path: .asciiz "fish2_left.rgba"
	fish2_skeleton_right_path: .asciiz "fish2_skeleton_right.rgba"
	fish2_skeleton_left_path: .asciiz "fish2_skeleton_left.rgba"
	fish2_background_path: .asciiz "fish2_background.rgba"
	fish3_right_path: .asciiz "fish3_right.rgba"
	fish3_left_path: .asciiz "fish3_left.rgba"
	mine1_path: .asciiz "mine1.rgba"
	mine2_path: .asciiz "mine2.rgba"
	mine_blow_path: .asciiz "mine_blow.rgba"
	lose_screen_path: .asciiz "lose_screen.rgba"
	crab_path: .asciiz "crab.rgba"
	crab1_path: .asciiz "crab1.rgba"
	crab_dollar_path: .asciiz "crab_dollar.rgba"
	win_screen_path: .asciiz "win_screen.rgba"
	x_boat: .word 0
	y_boat: .word 0
	x_fish1: .word -64
	y_fish1: .word 180
	fish1_exists: .word 1
	x_fish2: .word 5
	y_fish2: .word 280
	fish2_exists: .word 1
	fish2_going_right: .word 1
	x_fish3: .word X_FISH3_START
	y_fish3: .word Y_FISH3_START
	fish3_exists: .word 1
	fish3_going_right: .word 1
	x_mine1: .word X_MINE1_START
	y_mine1: .word Y_MINE1_START
	mine1_frame_wait_counter: .word 0
	mine1_going_right: .word 1
	x_mine2: .word X_MINE2_END
	y_mine2: .word Y_MINE2_START
	mine2_frame_wait_counter: .word 0
	mine2_going_right: .word 1
	x_crab: .word X_CRAB_START
	y_crab: .word Y_CRAB_START
	crab_alternate: .word 1
	space_key: .word 0
	score: .word 0
	x_start_fishing_rod: .word 0
	y_start_fishing_rod: .word 0
	y_end_fishing_rod: .word 0
	
.text
	# load the image's data into memory
	# load memory
	load_image(background_path, background)
	load_image(boat_path, boat)
	load_image(fish1_path, fish1)
	load_image(fish1_skeleton_path, fish1_skeleton)
	load_image(fish1_background_path, fish1_background)
	load_image(fish2_right_path, fish2_right)
	load_image(fish2_left_path, fish2_left)
	load_image(fish2_skeleton_left_path, fish2_skeleton_left)
	load_image(fish2_background_path, fish2_background)
	load_image(fish3_right_path, fish3_right)
	load_image(fish3_left_path, fish3_left)
	load_image(mine1_path, mine1)
	load_image(mine2_path, mine2)
	load_image(mine_blow_path, mine_blow)
	load_image(lose_screen_path, lose_screen)
	load_image(crab_path, crab)
	load_image(crab1_path, crab1)
	load_image(crab_dollar_path, crab_dollar)
	load_image(win_screen_path, win_screen)
	# draw in screen
	draw_image(background, FB_WIDTH, FB_HEIGHT, 0, 0)
	draw_image(boat, BOAT_WIDTH, BOAT_HEIGHT, 0, BOAT_Y)
	draw_image(mine1, FISH1_WIDTH, FISH1_HEIGHT, X_MINE1_START, Y_MINE1_START)
	draw_image(mine2, FISH1_WIDTH, FISH1_HEIGHT, X_MINE2_END, Y_MINE2_START)
			
	# infinite loop in which the game develops
	main_loop:
		
		#####################
		# boat action related
				
		# get the key that is being hit
		lw $t0, 0xFFFF0004		# where key presses are stored
		beq $t0, 0x71, exit 	# q key to exit
		
		# handle the boat right/left movement
		li $t1, BOAT_SPEED
		lw $t2, x_boat
		beq $t0, 0x61, boat_left					# a means left
		beq $t0, 0x64, boat_right					# d means right
		beq $t0, 0x20, boat_fishing_rod		# space means drop fishing rod
		sw $zero, 0xFFFF0004
		b second_loop											# nothing means the boat stays static
		boat_left: # left
		sub $t2, $t2, BOAT_SPEED
		sw $t2, x_boat
		b second_loop
		boat_right: # right
		add $t2, $t2, BOAT_SPEED
		sw $t2, x_boat
		b second_loop
		boat_fishing_rod: # drop fishing rod
		sw $t0, space_key
		# update fishing rod's starting position
		add $t2, $t2, 41
		sw $t2, x_start_fishing_rod
		li $t2, BOAT_Y
		add $t2, $t2, BOAT_HEIGHT
		sub $t2, $t2, 10
		sw $t2, y_start_fishing_rod
		sw $t2, y_end_fishing_rod
						
		# loop that gets activated when the boat launches its fishing rod
		second_loop:
			
			######################
			# draw all the objects
			
			# handle fish 1
			lw $t0, fish1_exists
			beqz $t0, fish1_done 
			lw $t0, x_fish1
			lw $t1, y_fish1
			draw_image(fish1, FISH1_WIDTH, FISH1_HEIGHT, $t0, $t1)
			lw $t0, x_fish1
			lw $t1, y_fish1
			add $t0, $t0, FISH1_SPEED
			sw $t0, x_fish1
			sw $t1, y_fish1
			fish1_done:
			
			# handle fish 2
			lw $t0, fish2_exists
			beqz $t0, fish2_done 
			lw $t0, x_fish2
			lw $t1, y_fish2
			# check if it is at x's defined limit
			lw $t2, fish2_going_right
			beqz $t2, fish2_go_left
			fish2_go_right: # draw the fish going right
			bge $t0, X_FISH2_END, fish2_go_left
			li $t2, 1
			sw $t2, fish2_going_right	
			add $t0, $t0, FISH2_SPEED
			sw $t0, x_fish2
			draw_image(fish2_right, FISH1_WIDTH, FISH1_HEIGHT, $t0, $t1)
			b fish2_done
			fish2_go_left: # draw the fish going left
			ble $t0, X_FISH2_START, fish2_go_right
			sw $zero, fish2_going_right
			sub $t0, $t0, FISH2_SPEED
			sw $t0, x_fish2
			draw_image(fish2_left, FISH1_WIDTH, FISH1_HEIGHT, $t0, $t1)
			fish2_done:
			
			# handle fish 3
			lw $t0, fish3_exists
			beqz $t0, fish3_done 
			lw $t0, x_fish3
			lw $t1, y_fish3
			# check if it is at x's defined limit
			lw $t2, fish3_going_right
			beqz $t2, fish3_go_left
			fish3_go_right: # draw the fish going right
			bge $t0, X_FISH3_END, fish3_go_left
			li $t2, 1
			sw $t2, fish3_going_right	
			add $t0, $t0, FISH3_SPEED
			sw $t0, x_fish3
			draw_image(fish3_right, FISH1_WIDTH, FISH1_HEIGHT, $t0, $t1)
			b fish3_done
			fish3_go_left: # draw the fish going left
			ble $t0, X_FISH3_START, fish3_go_right
			sw $zero, fish3_going_right
			sub $t0, $t0, FISH3_SPEED
			sw $t0, x_fish3
			draw_image(fish3_left, FISH1_WIDTH, FISH1_HEIGHT, $t0, $t1)
			fish3_done:
		
			# handle mine 1
			lw $t0, mine1_frame_wait_counter
			bne $t0, MINE1_FRAMES_WAIT, mine1_update_counter			
			# check if the mine is going left or right and update the direction
			lw $t0, x_mine1
			ble $t0, X_MINE1_START, update_mine1_going_right
			bge $t0, X_MINE1_END, update_mine1_going_left
			b update_mine1_going_done
			update_mine1_going_right:
			li $t0, 1
			sw $t0, mine1_going_right
			b update_mine1_going_done
			update_mine1_going_left:
			sw $zero, mine1_going_right
			b update_mine1_going_done
			update_mine1_going_done:			
			# after that, update the next x position of the mine
			lw $t0, mine1_going_right
			lw $t1, x_mine1
			beqz $t0, mine1_sub_x
			mine1_add_x:
			add $t1, $t1, MINE1_SPEED
			b mine1_add_sub_end
			mine1_sub_x:
			sub $t1, $t1, MINE1_SPEED
			mine1_add_sub_end:
			sw $t1, x_mine1			
			# draw the mine
			draw_mine1:	
			lw $t0, x_mine1
			lw $t1, y_mine1
			draw_image(mine1, FISH1_WIDTH, FISH1_HEIGHT, $t0, $t1)
			sw $zero, mine1_frame_wait_counter
			b mine1_done			
			# update mine counter
			mine1_update_counter:
			lw $t0, mine1_frame_wait_counter
			add $t0, $t0, 1
			sw $t0, mine1_frame_wait_counter
			mine1_done:
		
			# handle mine 2
			lw $t0, mine2_frame_wait_counter
			bne $t0, MINE2_FRAMES_WAIT, mine2_update_counter			
			# check if the mine is going left or right and update the direction
			lw $t0, x_mine2
			ble $t0, X_MINE2_START, update_mine2_going_right
			bge $t0, X_MINE2_END, update_mine2_going_left
			b update_mine2_going_done
			update_mine2_going_right:
			li $t0, 1
			sw $t0, mine2_going_right
			b update_mine2_going_done
			update_mine2_going_left:
			sw $zero, mine2_going_right
			b update_mine2_going_done
			update_mine2_going_done:			
			# after that, update the next x position of the mine
			lw $t0, mine2_going_right
			lw $t1, x_mine2
			beqz $t0, mine2_sub_x
			mine2_add_x:
			add $t1, $t1, MINE2_SPEED
			b mine2_add_sub_end
			mine2_sub_x:
			sub $t1, $t1, MINE2_SPEED
			mine2_add_sub_end:
			sw $t1, x_mine2			
			# draw the mine
			draw_mine2:	
			lw $t0, x_mine2
			lw $t1, y_mine2
			draw_image(mine2, FISH1_WIDTH, FISH1_HEIGHT, $t0, $t1)
			sw $zero, mine2_frame_wait_counter
			b mine2_done			
			# update mine1 counter
			mine2_update_counter:
			lw $t0, mine2_frame_wait_counter
			add $t0, $t0, 1
			sw $t0, mine2_frame_wait_counter
			mine2_done:
		
			# handle crab 
			lw $t0, x_crab
			lw $t1, y_crab
			lw $t2, crab_alternate
			beq $t2, 1, draw_crab1 
			draw_image(crab, FISH1_WIDTH, FISH1_HEIGHT, $t0, $t1)
			add $t2, $zero, 1
			sw $t2, crab_alternate
			b crab_alternate_end
			draw_crab1:
			draw_image(crab1, FISH1_WIDTH, FISH1_HEIGHT, $t0, $t1)
			sw $zero, crab_alternate
			b crab_alternate_end
			crab_alternate_end:
			lw $t0, x_crab
			sub $t0, $t0, CRAB_SPEED
			sw $t0, x_crab
			crab_done:
			
			#############
			# handle boat
			
			# handle the fishing rod if space_key is 0x20
			lw $t0, space_key
			bne $t0, 0x20, boat_draw
			
			# check if something hits (color, mine or fish)
			
			# check what the fishing rod hits
			lw $t0, x_start_fishing_rod
			lw $t1, y_end_fishing_rod
			get_coords_real_pos($t0, $t1)
			get_coords_address($s0, $s1)
			lw $t0, ($s0)
			beq $t0, 0x00B2BD48, retract_fishing_rod 	# sand
			beq $t0, 0x00FF6B00, fish1_hit 						# fish 1
			beq $t0, 0x00C300FF, fish2_hit 						# fish 2
			beq $t0, 0x0037FF00, fish3_hit 						# fish 3
			beq $t0, 0x00101010, mine1_hit 					  # mine 1
			beq $t0, 0x00232323, mine2_hit 					  # mine 2
			beq $t0, 0x00FF0000, crab_hit 					  # crab
						
			# win/lose screens
			
			no_fishing_rod_hit: # keep drawing the fishing rod
				# unless key e is entered
				lw $t0, 0xFFFF0004
				beq $t0, 0x65, retract_fishing_rod
				lw $t0, x_start_fishing_rod
				lw $t1, y_end_fishing_rod
				get_coords_real_pos($t0, $t1)
				get_coords_address($s0, $s1)
				li $t2, 0xFFFFFFFF
				sw $t2, ($s0)
				lw $t0, x_start_fishing_rod
				lw $t1, y_end_fishing_rod
				add $t0, $t0, 1
				get_coords_real_pos($t0, $t1)
				get_coords_address($s0, $s1)
				li $t2, 0xFFFFFFFF
				sw $t2, ($s0)
				lw $t1, y_end_fishing_rod
				add $t1, $t1, 1
				sw $t1, y_end_fishing_rod
				b second_loop																																																			
			
			fish1_hit:
				# draw skeleton fish
				lw $t0, x_fish1
				lw $t1, y_fish1
				draw_image(fish1_skeleton, FISH1_WIDTH, FISH1_HEIGHT, $t0, $t1)
				# draw background
				lw $t0, x_fish1
				lw $t1, y_fish1
				draw_image(fish1_background, FISH1_WIDTH, FISH1_HEIGHT, $t0, $t1)
				sw $zero, fish1_exists				
				b retract_fishing_rod
			
			fish2_hit:
				# draw skeleton fish
				lw $t0, x_fish2
				lw $t1, y_fish2
				lw $t2, fish2_going_right
				# draw skeleton right
				beqz $t2, draw_fish2_skeleton_left
				draw_image(fish2_skeleton_right, FISH1_WIDTH, FISH1_HEIGHT, $t0, $t1)
				b draw_fish2_background
				# draw skeleton left
				draw_fish2_skeleton_left:
				draw_image(fish2_skeleton_left, FISH1_WIDTH, FISH1_HEIGHT, $t0, $t1)				
				# draw background
				draw_fish2_background:
				sw $zero, fish2_exists
				lw $t0, x_fish2
				lw $t1, y_fish2
				draw_image(fish2_background, FISH1_WIDTH, FISH1_HEIGHT, $t0, $t1)
				b retract_fishing_rod
				
			fish3_hit:
				# draw skeleton fish
				lw $t0, x_fish3
				lw $t1, y_fish3
				lw $t2, fish3_going_right
				# draw skeleton right
				beqz $t2, draw_fish3_skeleton_left
				draw_image(fish2_skeleton_right, FISH1_WIDTH, FISH1_HEIGHT, $t0, $t1)
				b draw_fish3_background
				# draw skeleton left
				draw_fish3_skeleton_left:
				draw_image(fish2_skeleton_left, FISH1_WIDTH, FISH1_HEIGHT, $t0, $t1)				
				# draw background
				draw_fish3_background:
				sw $zero, fish3_exists
				lw $t0, x_fish3
				lw $t1, y_fish3
				draw_image(fish2_background, FISH1_WIDTH, FISH1_HEIGHT, $t0, $t1)
				b retract_fishing_rod
			
			mine1_hit:
				# draw mine explosion
				lw $t0, x_mine1
				lw $t1, y_mine1
				draw_image(mine_blow, FISH1_WIDTH, FISH1_HEIGHT, $t0, $t1)
				# draw lose screen
				draw_image(lose_screen, WL_SCREEN_WIDTH, WL_SCREEN_HEIGHT, WL_SCREEN_X, WL_SCREEN_Y)
				# end program		
				b exit
				
			mine2_hit:
				# draw mine explosion
				lw $t0, x_mine2
				lw $t1, y_mine2
				draw_image(mine_blow, FISH1_WIDTH, FISH1_HEIGHT, $t0, $t1)
				# draw lose screen
				draw_image(lose_screen, WL_SCREEN_WIDTH, WL_SCREEN_HEIGHT, WL_SCREEN_X, WL_SCREEN_Y)
				# end program		
				b exit
				
			crab_hit:
				# draw crab dollar (sponge me boy)
				lw $t0, x_crab
				lw $t1, y_crab
				draw_image(crab_dollar, FISH1_WIDTH, FISH1_HEIGHT, $t0, $t1)
				# draw win screen
				draw_image(win_screen, WL_SCREEN_WIDTH, WL_SCREEN_HEIGHT, WL_SCREEN_X, WL_SCREEN_Y)
				# end program		
				b exit
			
			retract_fishing_rod:
				# reset these variables
				sw $zero, space_key
				sw $zero, 0xFFFF0004		
				third_loop:
					lw $t0, y_start_fishing_rod
					lw $t1, y_end_fishing_rod
					beq $t0, $t1, boat_draw
					lw $t0, x_start_fishing_rod
					sub $t0, $t0, 1
					lw $t1, y_end_fishing_rod
					get_coords_real_pos($t0, $t1)
					get_coords_address($s0, $s1)
					lw $t2, ($s0) # restitute this pixel color
					add $s0, $s0, 4
					sw $t2, ($s0)
					add $s0, $s0, 4
					sw $t2, ($s0)
					lw $t1, y_end_fishing_rod
					sub $t1, $t1, 1
					sw $t1, y_end_fishing_rod						
					b third_loop
			
			# draw the boat (if it moves)
			boat_draw:			
			lw $t0, 0xFFFF0004
			beqz $t0, boat_end
			lw $t0, x_boat
			draw_image(boat, BOAT_WIDTH, BOAT_HEIGHT, $t0, BOAT_Y)
			
			boat_end:
			
			# next frame in second loop
			lw $t0, space_key
			bne $t0, 0x20, second_loop_end 
			b second_loop
		
		# get out of the second loop
		second_loop_end:
		# next frame in main loop
		b main_loop

# get out of the main loop
exit:

# draw win/lose screen
