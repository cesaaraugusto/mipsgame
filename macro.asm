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
    .eqv espacio_mosca_ancho 35
    .eqv espacio_mosca_altura 35
    .eqv espacio_mosca_longitud 4900

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
    .eqv j_mosca3_minimo 10
    .eqv j_mosca3_maximo 250
    .eqv i_mosca1_posicion 200
    .eqv i_mosca2_posicion 325
    .eqv i_mosca3_posicion 450
    .eqv i_mosca4_posicion 263
    .eqv i_mosca5_posicion 388
    .eqv j_mosca1_posicion_inicial 112
    .eqv j_mosca2_posicion_inicial 112
    .eqv j_mosca3_posicion_inicial 112
    .eqv j_mosca4_posicion_inicial 224
    .eqv mosca1_velocidad 3
    .eqv mosca2_velocidad 4
    .eqv mosca3_velocidad 5
    .eqv mosca4_velocidad 2

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
    mfhi  $s0                # $s0 鈫? residuo
    bltz  $s0, adjust_x      # Si el residuo es negativo, aj煤stalo
    j     compute_y
adjust_x:
    add   $s0, $s0, $t0      # $s0 = $s0 + FB_WIDTH

compute_y:
    # Calcular y = (%y mod FB_HEIGHT) de forma positiva
    li    $t0, ALTURA_FB     # Cargar la altura del FB en $t0
    div   $s1, $t0           # Divide $s1 entre FB_HEIGHT
    mfhi  $s1                # $s1 鈫? residuo
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

msg_color: .asciiz "Color actual del pixel: "

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
j_mosca5: .word j_mosca4_posicion_inicial
i_mosca5: .word i_mosca5_posicion
mosca_mala_vuelo_arriba: .word 1
mosca_vuelo_arriba: .word 1
mosca_vuelo_pausa_contador: .word 0
mosca1_exists: .word 1
mosca2_exists: .word 1
mosca3_exists: .word 1
mosca1_vuelo: .word 1
mosca2_vuelo: .word 1
mosca3_vuelo: .word 1
mosca4_vuelo: .word 1
mosca5_vuelo: .word 1
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
    pintar(espacio_sapo, espacio_sapo_ancho, espacio_sapo_altura, 0, 101)
    pintar(espacio_mosca_abajo, espacio_mosca_ancho, espacio_mosca_altura, 200, 112)
    pintar(espacio_mosca_arriba, espacio_mosca_ancho, espacio_mosca_altura, 325, 112)
    pintar(espacio_mosca_abajo, espacio_mosca_ancho, espacio_mosca_altura, 450, 112)

   main:
    lw   $t0, 0xFFFF0004         # Carga en $t0 la tecla presionada desde la direcci贸n 0xFFFF0004
    beq  $t0, 0x65, salida         # Si $t0 es igual a 0x65, salta a "salida" para terminar el programa
    li   $t1, sapo_velocidad      # Carga en $t1 la velocidad definida para el sapo (sapo_velocidad)
    lw   $t2, j_sapo              # Carga en $t2 la posici贸n actual del sapo (variable j_sapo)
    beq  $t0, 0x77, sapo_sube      # Si la tecla es 0x77, salta a "sapo_sube" (movimiento hacia la izquierda)
    beq  $t0, 0x73, sapo_baja      # Si la tecla es 0x73, salta a "sapo_baja" (movimiento hacia la derecha)
    beq  $t0, 0x64, lengua         # Si la tecla es 0x64, salta a "lengua" para activar la lengua
    sw   $zero, 0xFFFF0004         # Limpia la direcci贸n 0xFFFF0004 (resetea el valor de la tecla)
    b    bucle             # Salta al 鈥渂ucle鈥? para las actualizaciones y dibujo

sapo_sube:
    sub  $t2, $t2, sapo_velocidad  # Resta la velocidad a la posici贸n actual para mover el sapo a la izquierda
    sw   $t2, j_sapo              # Actualiza la posici贸n del sapo en la variable j_sapo
    b    bucle             # Salta a 鈥渂ucle鈥?

sapo_baja:
    add  $t2, $t2, sapo_velocidad  # Suma la velocidad a la posici贸n actual para mover el sapo a la derecha
    sw   $t2, j_sapo              # Actualiza la posici贸n en j_sapo
    b    bucle             # Salta a 鈥渂ucle鈥?

lengua:
    sw   $t0, tecla_lengua        # Guarda en tecla_lengua el c贸digo de la tecla presionada (activa la lengua)
    add  $t2, $t2, 29             # Ajusta la posici贸n de la lengua sumando 27 a la posici贸n actual del sapo
    sw   $t2, j_lengua            # Guarda la posici贸n resultante en j_lengua (coordenada X de la lengua)
    li   $t2, i_sapo_posicion     # Carga en $t2 el valor base de la posici贸n del sapo (i_sapo_posicion)
    add  $t2, $t2, espacio_sapo_ancho  # Suma a ese valor el ancho del sapo (espacio_sapo_ancho)
    sw   $t2, i_lengua_inicial    # Define i_lengua_inicial con el valor calculado (l铆mite izquierdo de la l铆nea)
    sw   $t2, i_lengua_final      # Inicializa i_lengua_final con el mismo valor (extremo derecho inicial de la lengua)
    b    pintar_sapo_lengua

bucle:
 # --- Manejo de Mosca 1 ---
#    lw   $t0, i_mosca1
#    lw   $t1, j_mosca1
#    lw   $t2, mosca1_vuelo
#    beq  $t2, 1, abrir_alas
#    pintar(espacio_mosca_abajo, espacio_mosca_ancho, espacio_mosca_altura, $t0, $t1)
#    li   $t2, 1
#    sw   $t2, mosca1_vuelo
#    b    final_vuelo
#abrir_alas:
#    pintar(espacio_mosca_abajo_vuela, espacio_mosca_ancho, espacio_mosca_altura, $t0, $t1)
#    sw   $zero, mosca1_vuelo
#final_vuelo:
#    lw   $t0, j_mosca1
#    add  $t0, $t0, mosca1_velocidad
#    sw   $t0, j_mosca1
#mosca1_lista:

 # --- Manejo de Mosca 2 ---
    lw   $t0, i_mosca2
    lw   $t1, j_mosca2
    lw   $t2, mosca2_vuelo
    beq  $t2, 1, abrir_alas2
    pintar(espacio_mosca_arriba, espacio_mosca_ancho, espacio_mosca_altura, $t0, $t1)
    li   $t2, 1
    sw   $t2, mosca2_vuelo
    b    final_vuelo2
abrir_alas2:
    pintar(espacio_mosca_arriba_vuela, espacio_mosca_ancho, espacio_mosca_altura, $t0, $t1)
    sw   $zero, mosca2_vuelo
final_vuelo2:
    lw   $t0, j_mosca2
    sub  $t0, $t0, mosca2_velocidad
    sw   $t0, j_mosca2
mosca2_lista:

 # --- Manejo de Mosca 3 ---
    lw   $t0, i_mosca3
    lw   $t1, j_mosca3
    lw   $t2, mosca3_vuelo
    beq  $t2, 1, abrir_alas3
    pintar(espacio_mosca_abajo, espacio_mosca_ancho, espacio_mosca_altura, $t0, $t1)
    li   $t2, 1
    sw   $t2, mosca3_vuelo
    b    final3_vuelo
abrir_alas3:
    pintar(espacio_mosca_abajo_vuela, espacio_mosca_ancho, espacio_mosca_altura, $t0, $t1)
    sw   $zero, mosca3_vuelo
final3_vuelo:
    lw   $t0, j_mosca3
    add  $t0, $t0, mosca3_velocidad
    sw   $t0, j_mosca3
mosca3_lista:

 # --- Manejo de Mosca 4 ---
    lw   $t0, i_mosca4
    lw   $t1, j_mosca4
    lw   $t2, mosca4_vuelo
    beq  $t2, 1, abrir_alas4
    pintar(espacio_mosca_mala_abajo, espacio_mosca_ancho, espacio_mosca_altura, $t0, $t1)
    li   $t2, 1
    sw   $t2, mosca4_vuelo
    b    final4_vuelo
abrir_alas4:
    pintar(espacio_mosca_mala_abajo_vuela, espacio_mosca_ancho, espacio_mosca_altura, $t0, $t1)
    sw   $zero, mosca4_vuelo
final4_vuelo:
    lw   $t0, j_mosca4
    add  $t0, $t0, mosca4_velocidad
    sw   $t0, j_mosca4
mosca4_lista:

 # --- Manejo de Mosca 4 ---
    lw   $t0, i_mosca5
    lw   $t1, j_mosca5
    lw   $t2, mosca5_vuelo
    beq  $t2, 1, abrir_alas5
    pintar(espacio_mosca_mala_arriba, espacio_mosca_ancho, espacio_mosca_altura, $t0, $t1)
    li   $t2, 1
    sw   $t2, mosca5_vuelo
    b    final5_vuelo
abrir_alas5:
    pintar(espacio_mosca_mala_arriba_vuela, espacio_mosca_ancho, espacio_mosca_altura, $t0, $t1)
    sw   $zero, mosca5_vuelo
final5_vuelo:
    lw   $t0, j_mosca5
    sub  $t0, $t0, mosca4_velocidad
    sw   $t0, j_mosca5
mosca5_lista:

    lw   $t0, tecla_lengua        # Carga el valor de tecla_lengua para verificar si la lengua est谩 activa
    bne  $t0, 0x64, pintar_sapo    # Si tecla_lengua no es 0x64, salta a pintar_sapo (dibuja el sapo)
    lw   $t0, i_lengua_inicial    # Carga la coordenada X de inicio de la lengua (i_lengua_inicial)
    lw   $t1, j_lengua            # Carga la coordenada Y de la lengua (j_lengua)
    ubicar($t0, $t1)              # Convierte las coordenadas l贸gicas (i_lengua_inicial, j_lengua) a reales, dejando $s0 y $s1
    add  $t0, $zero, $s1          # Copia el valor real de la coordenada Y (de $s1) a $t0
    mul  $t0, $t0, ANCHO_FB       # Calcula el offset vertical: y_real * ANCHO_FB
    add  $t0, $t0, $s0           # Suma la coordenada x real para obtener el 铆ndice lineal
    mul  $t0, $t0, 4             # Convierte el 铆ndice lineal a byte-offset (4 bytes/p铆xel)
    add  $s0, $t0, DIRECCION_DISPLAY  # Suma la direcci贸n base del framebuffer y obtiene la direcci贸n real del p铆xel
    lw   $t0, ($s0)             # Carga el color del p铆xel ubicado en la direcci贸n calculada

lengua_sin_darle_al_blanco:
    lw   $t0, 0xFFFF0004           # Recarga el valor de la tecla desde la direcci髇 de entrada
    beq  $t0, 0x61, limpiar_lengua  # Si la tecla es 0x61, salta a limpiar_lengua (desactiva la lengua)
    
    lw   $t3, i_lengua_final       # Carga la posici髇 X actual del extremo de la lengua (i_lengua_final)
    li   $t8, 489                  # L韒ite derecho de la lengua
    bge  $t3, $t8, limpiar_lengua  # Si i_lengua_final >= 489, salta a limpiar_lengua (no se dibuja m醩)
    
    lw   $t0, i_lengua_final       # Vuelve a cargar i_lengua_final para usar en el dibujo
    lw   $t1, j_lengua             # Carga la coordenada Y donde se dibuja la lengua
    ubicar($t0, $t1)               # Convierte (i_lengua_final, j_lengua) en coordenadas reales ($s0, $s1)
    
    # Calcula la direcci髇 del p韝el en el framebuffer:
    add  $t0, $zero, $s1           # Copia la coordenada Y real ($s1) a $t0
    mul  $t0, $t0, ANCHO_FB        # y_real * ANCHO_FB (offset vertical)
    add  $t0, $t0, $s0             # Suma la coordenada X real para formar el 韓dice lineal
    mul  $t0, $t0, 4               # Multiplica por 4 para obtener la posici髇 en bytes
    add  $s0, $t0, DIRECCION_DISPLAY # Suma la base del framebuffer para obtener la direcci髇 final

    # Comprobaci髇 del color actual del p韝el:
    lw   $t4, ($s0)               # Carga el color actual del p韝el en $t4
    li   $t5, -16711420            # Carga el color prohibido (#141510) en $t5
    beq  $t4, $t5, limpiar_lengua   # Si el p韝el ya es de color #141510, salta a limpiar_lengua

    # --- Bloque agregado para imprimir el color actual ---
    la   $a0, msg_color           # Carga la direcci髇 del mensaje "Color actual del pixel: "
    li   $v0, 4                   # C骴igo de servicio para imprimir cadena
    syscall

    move $a0, $t4                # Mueve el contenido de $t4 (color actual) a $a0
    li   $v0, 1                   # C骴igo de servicio para imprimir entero
    syscall
    # -------------------------------------------------------

    li   $t2, 0x5059D3            # Carga el color de dibujo 0x5059D3 en $t2
    sw   $t2, ($s0)               # Escribe el color en el p韝el (dibuja la primera fila de la lengua)

    lw   $t1, i_lengua_final      # Recarga el valor actual de i_lengua_final
    li   $t8, 489                 # Carga nuevamente el l韒ite derecho (489)
    blt  $t1, $t8, increment_line # Si i_lengua_final es menor que 489, salta a increment_line
    j    bucle                   # De lo contrario, salta a bucle sin incrementar

increment_line:
    addi $t1, $t1, 1              # Incrementa i_lengua_final en 1 (extiende la lengua horizontalmente)
    sw   $t1, i_lengua_final      # Guarda el nuevo valor de i_lengua_final en memoria
    j    bucle                   # Salta a bucle


limpiar_lengua:
    sw   $zero, tecla_lengua           # Resetea la bandera de activaci贸n de la lengua
    sw   $zero, 0xFFFF0004             # Limpia el puerto de entrada (regresa la tecla a 0)

clear_loop:
    lw   $t0, i_lengua_final           # Carga la coordenada X actual del extremo de la lengua
    lw   $t1, i_lengua_inicial         # Carga el l铆mite izquierdo de la lengua
    blt  $t0, $t1, clear_done          # Si i_lengua_final es menor que i_lengua_inicial, finaliza la limpieza
    lw   $t2, j_lengua                 # Carga la coordenada Y donde se dibuja la lengua
    ubicar($t0, $t2)                   # Convierte (i_lengua_final, j_lengua) a coordenadas reales (resultado en $s0 y $s1)
    move $t3, $s1                     # Copia la coordenada Y real desde $s1 a $t3
    mul  $t3, $t3, ANCHO_FB           # Multiplica y_real por el ancho del framebuffer (calcula offset vertical en p铆xeles)
    add  $t3, $t3, $s0                # Suma la coordenada X real ($s0) para formar el 铆ndice lineal del p铆xel
    li   $t4, 4                      # Carga el valor 4, que representa 4 bytes por p铆xel
    mul  $t3, $t3, $t4               # Convierte el 铆ndice lineal a un offset en bytes
    add  $t3, $t3, DIRECCION_DISPLAY  # A帽ade la direcci贸n base del framebuffer para obtener la direcci贸n f铆sica del p铆xel
    li   $t5, 0x84945C             # Carga el color de fondo (0x00000000) para borrar el p铆xel
    sw   $t5, ($t3)                 # Escribe el color de fondo en el p铆xel de la primera fila

    lw   $t6, i_lengua_final         # Carga el valor actual de i_lengua_final
    addi $t6, $t6, -1               # Decrementa i_lengua_final en 1 (retracci贸n de la lengua)
    sw   $t6, i_lengua_final         # Actualiza la variable i_lengua_final en memoria

    j    clear_loop                 # Repite el ciclo para borrar el siguiente p铆xel de la lengua

clear_done:
    j    bucle                     # Una vez que se hayan borrado todos los p铆xeles necesarios, salta al ciclo principal (bucle)


pintar_sapo:
    lw   $t0, 0xFFFF0004                     # Carga la tecla presionada desde 0xFFFF0004
    beqz $t0, final_sapo                     # Si no se presion贸 ninguna tecla, salta a final_sapo
    lw   $t0, j_sapo                         # Carga la posici贸n Y actual del sapo (j_sapo)
    pintar(espacio_sapo, espacio_sapo_ancho, espacio_sapo_altura, i_sapo_posicion, $t0)
    j    final_sapo                         # Salta a final_sapo despu茅s de pintar

pintar_sapo_lengua:
    lw   $t0, 0xFFFF0004                     # Carga la tecla presionada desde 0xFFFF0004
    beqz $t0, final_sapo                     # Si no se presion贸 ninguna tecla, salta a final_sapo
    lw   $t0, j_sapo                         # Carga la posici贸n Y actual del sapo (j_sapo)
    pintar(espacio_sapo_lengua, espacio_sapo_ancho, espacio_sapo_altura, i_sapo_posicion, $t0)
    j    final_sapo                         # Salta a final_sapo despu茅s de pintar
    
final_sapo:
    lw   $t0, tecla_lengua                  # Revisa el estado actual de la lengua
    bne  $t0, 0x64, bucle_fin               # Si la lengua no sigue activa, salta a bucle_fin
    b    bucle                             # Si la lengua sigue activa, vuelve a bucle

bucle_fin:
    b    main                # Salta a la rutina principal para el siguiente frame

salida:
    li   $v0, 10             # Carga el c贸digo 10 del syscall (exit)
    syscall                  # Llama al syscall para salir del programa
