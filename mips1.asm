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

# Macro para cargar una imagen en memoria desde un archivo
.macro cargar_imagen(%direccion_nombre_archivo, %direccion_carga)
    # Abrir el archivo
    li $v0, 13
    la $a0, %direccion_nombre_archivo
    li $a1, 0
    li $a2, 0
    syscall
    
    # Leer contenido del archivo y escribir en memoria
    move $a0, $v0
    la $a1, %direccion_carga
    li $a2, 4
    leer_bucle:
        li $v0, 14
        syscall
        
        # Ajustar el orden de bytes (endian)
        lw $t8, ($a1)
        andi $t9, $t8, 0x0000FF00
        andi $t0, $t8, 0x000000FF
        sll $t0, $t0, 16
        add $t9, $t9, $t0
        andi $t0, $t8, 0x00FF0000
        srl $t0, $t0, 16
        add $t9, $t9, $t0
        sw $t9, ($a1)
        
        add $a1, $a1, 4
        bnez $v0, leer_bucle
    
    # Cerrar el archivo
    move $a0, $v0
    li $v0, 16
    syscall
.end_macro

# Macro para calcular las coordenadas reales en el framebuffer
.macro calcular_posicion_real(%x, %y)
    # Procesar coordenada X
    add $s2, $zero, %x
    div $t8, $s2, FB_WIDTH
    mul $t8, $t8, FB_WIDTH
    ble $s2, FB_WIDTH, x_negativa_o_dentro
    sub $s2, $s2, $t8
    b x_final
    x_negativa_o_dentro:
    bgez $s2, x_final
    sub $s2, $s2, $t8
    beqz $s2, x_final
    add $s2, $s2, FB_WIDTH
    x_final:
    
    # Procesar coordenada Y
    add $s3, $zero, %y
    div $t8, $s3, FB_HEIGHT
    mul $t8, $t8, FB_HEIGHT
    ble $s3, FB_HEIGHT, y_negativa_o_dentro
    sub $s3, $s3, $t8
    b y_final
    y_negativa_o_dentro:
    bgez $s3, y_final
    sub $s3, $s3, $t8
    beqz $s3, y_final
    add $s3, $s3, FB_HEIGHT
    y_final:
.end_macro

# Macro para obtener la dirección de memoria de unas coordenadas
.macro obtener_direccion(%x, %y)
    add $t8, $zero, %y
    mul $t8, $t8, FB_WIDTH
    add $t8, $t8, %x
    mul $t8, $t8, 4
    add $s4, $t8, FB_ADDRESS
.end_macro

# Macro para dibujar una imagen en el framebuffer
.macro dibujar_imagen(%datos_img, %ancho_img, %alto_img, %x, %y)
    la $s5, %datos_img
    add $s6, $zero, %ancho_img
    add $t9, $zero, %alto_img
    add $t0, $zero, %x
    add $t1, $zero, %y
    add $t2, $zero, $s6
    add $t3, $zero, $t0
    
    bucle_filas:
        bucle_columnas:
            lw $t4, ($s5)
            calcular_posicion_real($t0, $t1)
            obtener_direccion($s2, $s3)
            sw $t4, ($s4)
            add $s5, $s5, 4
            add $t0, $t0, 1
            add $t2, $t2, -1
            bnez $t2, bucle_columnas
        
        add $t2, $zero, $s6
        add $t1, $t1, 1
        add $t0, $zero, $t3
        add $t9, $t9, -1
        bnez $t9, bucle_filas
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
	cargar_imagen(background_path, background)
	cargar_imagen(boat_path, boat)
	cargar_imagen(fish1_path, fish1)
	cargar_imagen(fish1_skeleton_path, fish1_skeleton)
	cargar_imagen(fish1_background_path, fish1_background)
	cargar_imagen(fish2_right_path, fish2_right)
	cargar_imagen(fish2_left_path, fish2_left)
	cargar_imagen(fish2_skeleton_left_path, fish2_skeleton_left)
	cargar_imagen(fish2_background_path, fish2_background)
	cargar_imagen(fish3_right_path, fish3_right)
	cargar_imagen(fish3_left_path, fish3_left)
	cargar_imagen(mine1_path, mine1)
	cargar_imagen(mine2_path, mine2)
	cargar_imagen(mine_blow_path, mine_blow)
	cargar_imagen(lose_screen_path, lose_screen)
	cargar_imagen(crab_path, crab)
	cargar_imagen(crab1_path, crab1)
	cargar_imagen(crab_dollar_path, crab_dollar)
	cargar_imagen(win_screen_path, win_screen)
	# draw in screen
	dibujar_imagen(background, FB_WIDTH, FB_HEIGHT, 0, 0)
	dibujar_imagen(boat, BOAT_WIDTH, BOAT_HEIGHT, 0, BOAT_Y)
	dibujar_imagen(mine1, FISH1_WIDTH, FISH1_HEIGHT, X_MINE1_START, Y_MINE1_START)
	dibujar_imagen(mine2, FISH1_WIDTH, FISH1_HEIGHT, X_MINE2_END, Y_MINE2_START)
			
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
			dibujar_imagen(fish1, FISH1_WIDTH, FISH1_HEIGHT, $t0, $t1)
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
			dibujar_imagen(fish2_right, FISH1_WIDTH, FISH1_HEIGHT, $t0, $t1)
			b fish2_done
			fish2_go_left: # draw the fish going left
			ble $t0, X_FISH2_START, fish2_go_right
			sw $zero, fish2_going_right
			sub $t0, $t0, FISH2_SPEED
			sw $t0, x_fish2
			dibujar_imagen(fish2_left, FISH1_WIDTH, FISH1_HEIGHT, $t0, $t1)
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
			dibujar_imagen(fish3_right, FISH1_WIDTH, FISH1_HEIGHT, $t0, $t1)
			b fish3_done
			fish3_go_left: # draw the fish going left
			ble $t0, X_FISH3_START, fish3_go_right
			sw $zero, fish3_going_right
			sub $t0, $t0, FISH3_SPEED
			sw $t0, x_fish3
			dibujar_imagen(fish3_left, FISH1_WIDTH, FISH1_HEIGHT, $t0, $t1)
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
			dibujar_imagen(mine1, FISH1_WIDTH, FISH1_HEIGHT, $t0, $t1)
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
			dibujar_imagen(mine2, FISH1_WIDTH, FISH1_HEIGHT, $t0, $t1)
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
			dibujar_imagen(crab, FISH1_WIDTH, FISH1_HEIGHT, $t0, $t1)
			add $t2, $zero, 1
			sw $t2, crab_alternate
			b crab_alternate_end
			draw_crab1:
			dibujar_imagen(crab1, FISH1_WIDTH, FISH1_HEIGHT, $t0, $t1)
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
			calcular_posicion_real($t0, $t1)
			obtener_direccion($s2, $s3)
			lw $t0, ($s4)
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
				calcular_posicion_real($t0, $t1)
				obtener_direccion($s2, $s3)
				li $t2, 0xFFFFFFFF
				sw $t2, ($s4)
				lw $t0, x_start_fishing_rod
				lw $t1, y_end_fishing_rod
				add $t0, $t0, 1
				calcular_posicion_real($t0, $t1)
				obtener_direccion($s2, $s3)
				li $t2, 0xFFFFFFFF
				sw $t2, ($s4)
				lw $t1, y_end_fishing_rod
				add $t1, $t1, 1
				sw $t1, y_end_fishing_rod
				b second_loop																																																			
			
			fish1_hit:
				# draw skeleton fish
				lw $t0, x_fish1
				lw $t1, y_fish1
				dibujar_imagen(fish1_skeleton, FISH1_WIDTH, FISH1_HEIGHT, $t0, $t1)
				# draw background
				lw $t0, x_fish1
				lw $t1, y_fish1
				dibujar_imagen(fish1_background, FISH1_WIDTH, FISH1_HEIGHT, $t0, $t1)
				sw $zero, fish1_exists				
				b retract_fishing_rod
			
			fish2_hit:
				# draw skeleton fish
				lw $t0, x_fish2
				lw $t1, y_fish2
				lw $t2, fish2_going_right
				# draw skeleton right
				beqz $t2, draw_fish2_skeleton_left
				dibujar_imagen(fish2_skeleton_right, FISH1_WIDTH, FISH1_HEIGHT, $t0, $t1)
				b draw_fish2_background
				# draw skeleton left
				draw_fish2_skeleton_left:
				dibujar_imagen(fish2_skeleton_left, FISH1_WIDTH, FISH1_HEIGHT, $t0, $t1)				
				# draw background
				draw_fish2_background:
				sw $zero, fish2_exists
				lw $t0, x_fish2
				lw $t1, y_fish2
				dibujar_imagen(fish2_background, FISH1_WIDTH, FISH1_HEIGHT, $t0, $t1)
				b retract_fishing_rod
				
			fish3_hit:
				# draw skeleton fish
				lw $t0, x_fish3
				lw $t1, y_fish3
				lw $t2, fish3_going_right
				# draw skeleton right
				beqz $t2, draw_fish3_skeleton_left
				dibujar_imagen(fish2_skeleton_right, FISH1_WIDTH, FISH1_HEIGHT, $t0, $t1)
				b draw_fish3_background
				# draw skeleton left
				draw_fish3_skeleton_left:
				dibujar_imagen(fish2_skeleton_left, FISH1_WIDTH, FISH1_HEIGHT, $t0, $t1)				
				# draw background
				draw_fish3_background:
				sw $zero, fish3_exists
				lw $t0, x_fish3
				lw $t1, y_fish3
				dibujar_imagen(fish2_background, FISH1_WIDTH, FISH1_HEIGHT, $t0, $t1)
				b retract_fishing_rod
			
			mine1_hit:
				# draw mine explosion
				lw $t0, x_mine1
				lw $t1, y_mine1
				dibujar_imagen(mine_blow, FISH1_WIDTH, FISH1_HEIGHT, $t0, $t1)
				# draw lose screen
				dibujar_imagen(lose_screen, WL_SCREEN_WIDTH, WL_SCREEN_HEIGHT, WL_SCREEN_X, WL_SCREEN_Y)
				# end program		
				b exit
				
			mine2_hit:
				# draw mine explosion
				lw $t0, x_mine2
				lw $t1, y_mine2
				dibujar_imagen(mine_blow, FISH1_WIDTH, FISH1_HEIGHT, $t0, $t1)
				# draw lose screen
				dibujar_imagen(lose_screen, WL_SCREEN_WIDTH, WL_SCREEN_HEIGHT, WL_SCREEN_X, WL_SCREEN_Y)
				# end program		
				b exit
				
			crab_hit:
				# draw crab dollar (sponge me boy)
				lw $t0, x_crab
				lw $t1, y_crab
				dibujar_imagen(crab_dollar, FISH1_WIDTH, FISH1_HEIGHT, $t0, $t1)
				# draw win screen
				dibujar_imagen(win_screen, WL_SCREEN_WIDTH, WL_SCREEN_HEIGHT, WL_SCREEN_X, WL_SCREEN_Y)
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
					calcular_posicion_real($t0, $t1)
					obtener_direccion($s2, $s3)
					lw $t2, ($s4) # restitute this pixel color
					add $s4, $s4, 4
					sw $t2, ($s4)
					add $s4, $s4, 4
					sw $t2, ($s4)
					lw $t1, y_end_fishing_rod
					sub $t1, $t1, 1
					sw $t1, y_end_fishing_rod						
					b third_loop
			
			# draw the boat (if it moves)
			boat_draw:			
			lw $t0, 0xFFFF0004
			beqz $t0, boat_end
			lw $t0, x_boat
			dibujar_imagen(boat, BOAT_WIDTH, BOAT_HEIGHT, $t0, BOAT_Y)
			
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