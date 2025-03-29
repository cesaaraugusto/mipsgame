# Constants
    .eqv ANCHO_FB 512
    .eqv ALTURA_FB 256
    .eqv DIRECCION_DISPLAY 0x10010000

    .eqv espacio_fondo_ancho 512
    .eqv espacio_fondo_altura 256
    .eqv espacio_fondo_longitud 524288

    .eqv espacio_sapo_ancho 72
    .eqv espacio_sapo_altura 54
    .eqv espacio_sapo_longitud 15552

.macro load_image(%file_name, %buffer)
    # Abrir archivo
    li $v0, 13
    la $a0, %file_name
    li $a1, 0
    syscall

    # Leer datos
    move $a0, $v0
    li $v0, 14
    la $a1, %buffer
    li $a2, espacio_fondo_longitud
    syscall

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
		bnez $v0, loop1 

    # Cerrar archivo
    li $v0, 16
    syscall
.end_macro

.macro draw_image(%img, %width, %height, %pos_x, %pos_y)
    la $t0, %img                # Direcci�n de la imagen
    li $t1, 0                   # Contador Y
    li $s0, %width              # Ancho en registro
    li $s1, %height             # Altura en registro
    li $s2, ANCHO_FB            # Constantes en registros
    li $s3, ALTURA_FB
    li $t7, %pos_x              # Cargar posici�n X como inmediato
    li $t8, %pos_y              # Cargar posici�n Y como inmediato

    loop_y:
        li $t2, 0               # Contador X
        
        loop_x:
            # Calcular offset de la imagen
            mul $t3, $t1, $s0
            add $t3, $t3, $t2
            sll $t3, $t3, 2
            add $t3, $t0, $t3

            # Calcular coordenadas finales
            add $t4, $t7, $t2   # X = pos_x + contador_x
            add $t5, $t8, $t1   # Y = pos_y + contador_y

            # Ajustar coordenadas X (m�dulo 512)
            div $t4, $s2
            mfhi $t4            # X mod ANCHO_FB
            
            # Ajustar coordenadas Y (m�dulo 256)
            div $t5, $s3
            mfhi $t5            # Y mod ALTURA_FB

            # Calcular direcci�n en framebuffer
            mul $t6, $t5, $s2
            add $t6, $t6, $t4
            sll $t6, $t6, 2
            lui $t9, 0x1001
            add $t6, $t6, $t9

            # Escribir p�xel
            lw $t9, ($t3)
            sw $t9, ($t6)

            addi $t2, $t2, 1
            blt $t2, $s0, loop_x

        addi $t1, $t1, 1
        blt $t1, $s1, loop_y
.end_macro

.data
file_fondo: .asciiz "fondo.rgba"
.align 2
espacio_fondo: .space espacio_fondo_longitud
file_sapo: .asciiz "sapo.rgba"
.align 2
espacio_sapo: .space espacio_sapo_longitud

.text
main:
    load_image(file_fondo, espacio_fondo)
    load_image(file_sapo, espacio_sapo)

    # Llamar a macros con valores inmediatos
    draw_image(espacio_fondo, espacio_fondo_ancho, espacio_fondo_altura, 0, 0)
    draw_image(espacio_sapo, espacio_sapo_ancho, espacio_sapo_altura, 0, 100)

    li $v0, 10
    syscall