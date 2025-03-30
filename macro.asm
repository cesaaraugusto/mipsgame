# Constants
	#Framebuffer
    .eqv ANCHO_FB 512
    .eqv ALTURA_FB 256
    .eqv DIRECCION_DISPLAY 0x10010000

	#Fondo
    .eqv espacio_fondo_ancho 512
    .eqv espacio_fondo_altura 256
    .eqv espacio_fondo_longitud 524288

	#Sapo
    .eqv espacio_sapo_ancho 72
    .eqv espacio_sapo_altura 62
    .eqv espacio_sapo_longitud 17856
    
	#Mosca
    .eqv espacio_mosca_ancho 32
    .eqv espacio_mosca_altura 32
    .eqv espacio_mosca_longitud 4096

	#Efecto
    .eqv espacio_efecto_ancho 35
    .eqv espacio_efecto_altura 35
    .eqv espacio_efecto_longitud 4900

	#Final
    .eqv espacio_final_ancho 256
    .eqv espacio_final_altura 128
    .eqv espacio_final_longitud 131072

    #Constantes Movimiento
    .eqv j_sapo_minimo 0 
    .eqv j_sapo_maximo 220
    .eqv i_sapo_posicion 0
    .eqv j_sapo_posicion_inicial 101 
    .eqv sapo_velocidad 4 
    .eqv j_mosca2_minimo 0
    .eqv j_mosca2_maximo 256
    .eqv j_mosca4_minimo 256
    .eqv j_mosca4_maximo 0
    .eqv j_mosca5_minimo 150
    .eqv j_mosca5_maximo 0
    .eqv i_mosca1_posicion 200
    .eqv i_mosca2_posicion 263
    .eqv i_mosca3_posicion 325
    .eqv i_mosca4_posicion 388
    .eqv i_mosca5_posicion 450
    .eqv j_mosca1_posicion_inicial 112
    .eqv j_mosca2_posicion_inicial 0
    .eqv j_mosca3_posicion_inicial 112
    .eqv j_mosca4_posicion_inicial 224
    .eqv j_mosca5_posicion_inicial 112
    .eqv mosca1_velocidad 3
    .eqv mosca2_velocidad 2
    .eqv mosca3_velocidad 4
    .eqv mosca4_velocidad 2
    .eqv mosca5_velocidad 5
    .eqv mosca2_espera 5
    .eqv mosca4_espera 10

.macro cargar(%file_name, %buffer)
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

    # Cerrar archivo
    li $v0, 16
    syscall
.end_macro

.macro pintar(%img, %width, %height, %pos_x, %pos_y)
    # fill the registers
	la $s3, %img							# image bytes address
	add $s4, $zero, %width		# image width (pixels)
	add $t2, $zero, %height		# image height (pixels)
	add $t3, $zero, %pos_x						# image load pos x (pixels)
	add $t4, $zero, %pos_y						# image load pos y (pixels)
	add $t6, $zero, $s4 					# counter for row's elements
	add $t7, $zero, $t3 					# saving x coordinate
	# loop over rows
	loop1:
		
		# loop over the elements of a row
		loop2:
			# get the pixel data
			lw $t5, ($s3)
			# get address to write pixel data
			ubicar($t3, $t4)
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

.macro ubicar(%x, %y)
    # Cargar las coordenadas iniciales en $s0 y $s1
    add   $s0, $zero, %x
    add   $s1, $zero, %y

    # Calcular x = (%x mod FB_WIDTH) de forma positiva
    li    $t0, ANCHO_FB      # Cargar el ancho del FB en $t0
    div   $s0, $t0           # Divide $s0 entre FB_WIDTH
    mfhi  $s0                # $s0 ← residuo
    bltz  $s0, adjust_x      # Si el residuo es negativo, ajústalo
    j     compute_y
adjust_x:
    add   $s0, $s0, $t0      # $s0 = $s0 + FB_WIDTH

compute_y:
    # Calcular y = (%y mod FB_HEIGHT) de forma positiva
    li    $t0, ALTURA_FB     # Cargar la altura del FB en $t0
    div   $s1, $t0           # Divide $s1 entre FB_HEIGHT
    mfhi  $s1                # $s1 ← residuo
    bltz  $s1, adjust_y
    j     done_coords
adjust_y:
    add   $s1, $s1, $t0
done_coords:
.end_macro

.data
#Imagenes
file_fondo: .asciiz "fondo.rgba"
.align 2
espacio_fondo: .space espacio_fondo_longitud
file_sapo: .asciiz "sapo.rgba"
.align 2
espacio_sapo: .space espacio_sapo_longitud
file_sapo_lengua: .asciiz "sapolengua.rgba"
.align 2
espacio_sapo_lengua: .space espacio_sapo_longitud
file_mosca_arriba: .asciiz "moscacloseup.rgba"
.align 2
espacio_mosca_arriba: .space espacio_mosca_longitud
file_mosca_arriba_vuela: .asciiz "moscaopenup.rgba"
.align 2
espacio_mosca_arriba_vuela: .space espacio_mosca_longitud
file_mosca_abajo: .asciiz "moscaclosedown.rgba"
.align 2
espacio_mosca_abajo: .space espacio_mosca_longitud
file_mosca_abajo_vuela: .asciiz "moscaopendown.rgba"
.align 2
espacio_mosca_abajo_vuela: .space espacio_mosca_longitud
file_mosca_mala_arriba: .asciiz "moscamalacloseup.rgba"
.align 2
espacio_mosca_mala_arriba: .space espacio_mosca_longitud
file_mosca_mala_arriba_vuela: .asciiz "moscamalaopenup.rgba"
.align 2
espacio_mosca_mala_arriba_vuela: .space espacio_mosca_longitud
file_mosca_mala_abajo: .asciiz "moscamalaclosedown.rgba"
.align 2
espacio_mosca_mala_abajo: .space espacio_mosca_longitud
file_mosca_mala_abajo_vuela: .asciiz "moscamalaopendown.rgba"
.align 2
espacio_mosca_mala_abajo_vuela: .space espacio_mosca_longitud
file_efecto_malo: .asciiz "calabera.rgba"
.align 2
espacio_efecto_malo: .space espacio_efecto_longitud
file_efecto_bueno: .asciiz "brillo.rgba"
.align 2
espacio_efecto_bueno: .space espacio_efecto_longitud
file_final_bueno: .asciiz "win.rgba"
.align 2
espacio_final_bueno: .space espacio_final_longitud
file_final_malo: .asciiz "lose.rgba"
.align 2
espacio_final_malo: .space espacio_final_longitud
file_fondo_objeto: .asciiz "fondoobjeto.rgba"
.align 2
espacio_fondo_objeto: .space espacio_efecto_longitud

# Movimiento
j_sapo: .word j_sapo_posicion_inicial
i_sapo: .word i_sapo_posicion
j_mosca1: .word j_mosca1_posicion_inicial
i_mosca1: .word i_mosca1_posicion
j_mosca2: .word j_mosca2_posicion_inicial
i_mosca2: .word i_mosca2_posicion
j_mosca3: .word j_mosca3_posicion_inicial
i_mosca3: .word i_mosca3_posicion
j_mosca4: .word j_mosca4_posicion_inicial
i_mosca4: .word i_mosca4_posicion
j_mosca5: .word j_mosca5_posicion_inicial
i_mosca5: .word i_mosca5_posicion
mine1_going_right: .word 1
mine2_going_right: .word 1
mine1_frame_wait_counter: .word 0
mine2_frame_wait_counter: .word 0
mosca1_exists: .word 1
mosca3_exists: .word 1
mosca4_exists: .word 1
mosca_alternate: .word 1
tecla_lengua: .word 0
score: .word 0
j_lengua: .word 0
i_lengua_inicial: .word 0
i_lengua_final: .word 0

.text
    # Carga imagenes
    cargar(file_fondo, espacio_fondo)
    cargar(file_sapo, espacio_sapo)
    cargar(file_sapo_lengua, espacio_sapo_lengua)
    cargar(file_mosca_arriba, espacio_mosca_arriba)
    cargar(file_mosca_arriba_vuela, espacio_mosca_arriba_vuela)
    cargar(file_mosca_abajo, espacio_mosca_abajo)
    cargar(file_mosca_abajo_vuela, espacio_mosca_abajo_vuela)
    cargar(file_mosca_mala_arriba, espacio_mosca_mala_arriba)
    cargar(file_mosca_mala_arriba_vuela, espacio_mosca_mala_arriba_vuela)
    cargar(file_mosca_mala_abajo, espacio_mosca_mala_abajo)
    cargar(file_mosca_mala_abajo_vuela, espacio_mosca_mala_abajo_vuela)
    cargar(file_efecto_malo, espacio_efecto_malo)
    cargar(file_efecto_bueno, espacio_efecto_bueno)
    cargar(file_final_malo, espacio_final_malo)
    cargar(file_final_bueno, espacio_final_bueno)

    # Llamar a macros con valores inmediatos
    pintar(espacio_fondo, espacio_fondo_ancho, espacio_fondo_altura, 0, 0)
    pintar(espacio_sapo_lengua, espacio_sapo_ancho, espacio_sapo_altura, 0, 101)
    pintar(espacio_mosca_abajo, espacio_mosca_ancho, espacio_mosca_altura, 200, 112)
    pintar(espacio_mosca_mala_abajo, espacio_mosca_ancho, espacio_mosca_altura, 263, 0)
    pintar(espacio_mosca_arriba, espacio_mosca_ancho, espacio_mosca_altura, 325, 112)
    pintar(espacio_mosca_mala_arriba, espacio_mosca_ancho, espacio_mosca_altura, 388, 224)
    pintar(espacio_mosca_abajo, espacio_mosca_ancho, espacio_mosca_altura, 450, 112)

   main:
    lw   $t0, 0xFFFF0004         # Carga en $t0 la tecla presionada desde la dirección 0xFFFF0004
    beq  $t0, 0x65, salida         # Si $t0 es igual a 0x65, salta a "salida" para terminar el programa
    li   $t1, sapo_velocidad      # Carga en $t1 la velocidad definida para el sapo (sapo_velocidad)
    lw   $t2, j_sapo              # Carga en $t2 la posición actual del sapo (variable j_sapo)
    beq  $t0, 0x77, sapo_sube      # Si la tecla es 0x77, salta a "sapo_sube" (movimiento hacia la izquierda)
    beq  $t0, 0x73, sapo_baja      # Si la tecla es 0x73, salta a "sapo_baja" (movimiento hacia la derecha)
    beq  $t0, 0x64, lengua         # Si la tecla es 0x64, salta a "lengua" para activar la lengua
    sw   $zero, 0xFFFF0004         # Limpia la dirección 0xFFFF0004 (resetea el valor de la tecla)
    b    bucle             # Salta al “bucle” para las actualizaciones y dibujo

sapo_sube:
    sub  $t2, $t2, sapo_velocidad  # Resta la velocidad a la posición actual para mover el sapo a la izquierda
    sw   $t2, j_sapo              # Actualiza la posición del sapo en la variable j_sapo
    b    bucle             # Salta a “bucle”

sapo_baja:
    add  $t2, $t2, sapo_velocidad  # Suma la velocidad a la posición actual para mover el sapo a la derecha
    sw   $t2, j_sapo              # Actualiza la posición en j_sapo
    b    bucle             # Salta a “bucle”

lengua:
    sw   $t0, tecla_lengua        # Guarda en tecla_lengua el código de la tecla presionada (activa la lengua)
    add  $t2, $t2, 27             # Ajusta la posición de la lengua sumando 27 a la posición actual del sapo
    sw   $t2, j_lengua            # Guarda la posición resultante en j_lengua (coordenada X de la lengua)
    li   $t2, i_sapo_posicion     # Carga en $t2 el valor base de la posición del sapo (i_sapo_posicion)
    add  $t2, $t2, espacio_sapo_ancho  # Suma a ese valor el ancho del sapo (espacio_sapo_ancho)
    sw   $t2, i_lengua_inicial    # Define i_lengua_inicial con el valor calculado (límite izquierdo de la línea)
    sw   $t2, i_lengua_final      # Inicializa i_lengua_final con el mismo valor (extremo derecho inicial de la lengua)

bucle:
    # (Comienzo de la actualización general y dibujo de objetos)

    lw   $t0, tecla_lengua        # Carga el valor de tecla_lengua para verificar si la lengua está activa
    bne  $t0, 0x64, pintar_sapo    # Si tecla_lengua no es 0x64, salta a pintar_sapo (dibuja el sapo)
    lw   $t0, i_lengua_inicial    # Carga la coordenada X de inicio de la lengua (i_lengua_inicial)
    lw   $t1, j_lengua            # Carga la coordenada Y de la lengua (j_lengua)
    ubicar($t0, $t1)              # Convierte las coordenadas lógicas (i_lengua_inicial, j_lengua) a reales, dejando $s0 y $s1
    add  $t0, $zero, $s1          # Copia el valor real de la coordenada Y (de $s1) a $t0
    mul  $t0, $t0, ANCHO_FB       # Calcula el offset vertical: y_real * ANCHO_FB
    add  $t0, $t0, $s0           # Suma la coordenada x real para obtener el índice lineal
    mul  $t0, $t0, 4             # Convierte el índice lineal a byte-offset (4 bytes/píxel)
    add  $s0, $t0, DIRECCION_DISPLAY  # Suma la dirección base del framebuffer y obtiene la dirección real del píxel
    lw   $t0, ($s0)             # Carga el color del píxel ubicado en la dirección calculada
    beq  $t0, 0x001B9919, limpiar_lengua  # Si el color es 0x001B9919, salta a limpiar_lengua

lengua_sin_darle_al_blaco:
    lw   $t0, 0xFFFF0004         # Vuelve a cargar el valor de la tecla desde la dirección de entrada
    beq  $t0, 0x61, limpiar_lengua # Si la tecla es 0x61, salta a limpiar_lengua (desactiva la lengua)
    lw   $t3, i_lengua_final      # Carga la posición X actual del extremo de la lengua (i_lengua_final)
    li   $t8, 489                # Carga el valor 489, que es el límite derecho de la lengua
    bge  $t3, $t8, limpiar_lengua  # Si i_lengua_final >= 489, salta a limpiar_lengua (no se dibuja más)
    lw   $t0, i_lengua_final      # Carga nuevamente i_lengua_final para usar en el dibujo
    lw   $t1, j_lengua            # Carga la coordenada Y donde se dibuja la lengua
    ubicar($t0, $t1)              # Convierte (i_lengua_final, j_lengua) a coordenadas reales ($s0 y $s1)
    add  $t0, $zero, $s1          # Copia el valor de y real (de $s1) a $t0
    mul  $t0, $t0, ANCHO_FB       # Calcula el offset vertical real multiplicando y_real por el ancho del framebuffer
    add  $t0, $t0, $s0           # Suma la coordenada x real para formar el índice lineal
    mul  $t0, $t0, 4             # Multiplica el índice por 4 para obtener la posición en bytes
    add  $s0, $t0, DIRECCION_DISPLAY  # Añade la dirección base del framebuffer para obtener la dirección final
    li   $t2, 0x5059D3           # Carga el color de dibujo 0x5059D3 en $t2
    sw   $t2, ($s0)             # Escribe el color en el píxel (dibuja la primera fila de la lengua)
    lw   $t0, i_lengua_final      # Vuelve a cargar i_lengua_final para dibujar la segunda fila
    lw   $t1, j_lengua            # Carga la coordenada Y base de la lengua
    add  $t1, $t1, 1             # Incrementa la coordenada Y en 1 para la fila inferior
    ubicar($t0, $t1)              # Convierte (i_lengua_final, j_lengua+1) a coordenadas reales ($s0, $s1)
    add  $t0, $zero, $s1          # Copia la coordenada y real en $t0
    mul  $t0, $t0, ANCHO_FB       # Calcula el offset vertical utilizando y_real y ANCHO_FB
    add  $t0, $t0, $s0           # Suma la coordenada x real para formar el índice lineal
    mul  $t0, $t0, 4             # Convierte el índice a bytes (4 bytes/píxel)
    add  $s0, $t0, DIRECCION_DISPLAY  # Suma la dirección base del framebuffer para obtener la dirección final del píxel
    li   $t2, 0x5059D3           # Vuelve a cargar el color 0x5059D3 en $t2
    sw   $t2, ($s0)             # Escribe el color en la segunda fila (dibuja el pixel con grosor)
    lw   $t1, i_lengua_final      # Carga el valor actual de i_lengua_final
    li   $t8, 489               # Carga el valor 489 (límite derecho de la lengua)
    blt  $t1, $t8, increment_line  # Si i_lengua_final es menor que 489, salta a increment_line
    j    bucle             # De lo contrario, salta a bucle sin incrementar

increment_line:
    addi $t1, $t1, 1             # Incrementa i_lengua_final en 1 (extiende la lengua horizontalmente)
    sw   $t1, i_lengua_final      # Guarda el nuevo valor de i_lengua_final en memoria
    b    bucle             # Salta a bucle

limpiar_lengua:
    sw   $zero, tecla_lengua     # Resetea la variable tecla_lengua a 0
    sw   $zero, 0xFFFF0004       # Limpia el registro de entrada (establece 0 en 0xFFFF0004)

horizontal_retract_loop:
    lw   $t0, i_lengua_inicial   # Carga la posición mínima de la lengua (i_lengua_inicial)
    lw   $t1, 72                # Carga el valor 72 (generalmente la posición X del sapo)
    beq  $t0, $t1, pintar_sapo   # Si i_lengua_inicial es igual a 72, la retracción termina y se salta a pintar_sapo
    lw   $t2, j_lengua           # Carga la coordenada Y de la lengua
    ubicar($t0, $t2)             # Convierte (i_lengua_inicial, j_lengua) a coordenadas reales ($s0, $s1)
    add  $t3, $zero, $s1         # Copia la coordenada y real en $t3
    mul  $t3, $t3, ANCHO_FB      # Calcula el offset vertical: y_real * ANCHO_FB
    add  $t3, $t3, $s0          # Suma la coordenada x real para formar el índice lineal
    mul  $t3, $t3, 4            # Convierte el índice a byte-offset (4 bytes/píxel)
    add  $s0, $t3, DIRECCION_DISPLAY  # Calcula la dirección final del píxel en el framebuffer
    li   $t4, 0x1B9919          # Carga el color 0x1B9919 (color usado para borrar la lengua)
    sw   $t4, ($s0)            # Escribe el color en el pixel (borra ese píxel)
    sub  $t0, $t0, 1            # Decrementa en 1 la posición X (retracción hacia el sapo)
    sw   $t0, i_lengua_final   # Actualiza la variable i_lengua_final con el nuevo valor
    b    horizontal_retract_loop  # Repite la retracción horizontal

pintar_sapo:
    lw   $t0, 0xFFFF0004       # Carga la tecla presionada desde 0xFFFF0004
    beqz $t0, final_sapo        # Si no se presionó ninguna tecla, salta a final_sapo
    lw   $t0, j_sapo           # Carga la posición Y actual del sapo (j_sapo)
    pintar(espacio_sapo_lengua, espacio_sapo_ancho, espacio_sapo_altura, i_sapo_posicion, $t0)  # Llama a la función pintar para dibujar el sapo

final_sapo:
    lw   $t0, tecla_lengua     # Carga el estado de la lengua desde tecla_lengua
    bne  $t0, 0x64, bucle_fin  # Si la lengua no sigue activa (tecla distinta de 0x64), salta a bucle_fin
    b    bucle          # Si la lengua sigue activa, regresa a bucle

bucle_fin:
    b    main                # Salta a la rutina principal para el siguiente frame

salida:
    li   $v0, 10             # Carga el código 10 del syscall (exit)
    syscall                  # Llama al syscall para salir del programa
