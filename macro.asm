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
    
    #Fondo objeto
    .eqv espacio_fondo_objeto_ancho 40
    .eqv espacio_fondo_objeto_altura 40
    .eqv espacio_fondo_objeto_longitud 6400

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
    # Cargar la dirección base de la imagen en $s3
    la $s3, %img							# Dirección de los bytes de la imagen
    # Configurar el ancho y alto de la imagen
    add $s4, $zero, %width		# Ancho de la imagen (en píxeles)
    add $t2, $zero, %height		# Alto de la imagen (en píxeles)
    # Configurar la posición inicial donde se dibujará la imagen
    add $t3, $zero, %pos_x						# Posición X donde se cargará la imagen
    add $t4, $zero, %pos_y						# Posición Y donde se cargará la imagen
    # Configurar contadores para recorrer filas y columnas
    add $t6, $zero, $s4 					# Contador para los elementos de una fila
    add $t7, $zero, $t3 					# Guardar la coordenada X inicial

    # Bucle para recorrer las filas de la imagen
    loop1:
        # Bucle para recorrer los elementos de una fila
        loop2:
            # Obtener el dato del píxel actual
            lw $t5, ($s3)					# Cargar el dato del píxel desde la imagen
            # Calcular la dirección donde se escribirá el píxel
            ubicar($t3, $t4)				# Convertir coordenadas lógicas a reales
            add $t0, $zero, $s1			# Copiar la coordenada Y real
            mul $t0, $t0, ANCHO_FB			# Calcular el offset vertical (y_real * ancho del framebuffer)
            add $t0, $t0, $s0				# Sumar la coordenada X real
            mul $t0, $t0, 4				# Convertir el índice lineal a bytes (4 bytes por píxel)
            add $s0, $t0, DIRECCION_DISPLAY	# Sumar la dirección base del framebuffer
            # Escribir el dato del píxel en la dirección calculada
            sw $t5, ($s0)					# Escribir el píxel en el framebuffer
            # Actualizar las variables para el siguiente píxel
            add $s3, $s3, 4				# Avanzar 4 bytes en la dirección de la imagen
            add $t3, $t3, 1				# Avanzar 1 en la coordenada X
            add $t6, $t6, -1  			# Reducir el contador de elementos de la fila
            bnez $t6, loop2				# Repetir hasta que se procesen todos los elementos de la fila
        
        # Preparar para la siguiente fila
        add $t6, $zero, $s4 			# Reiniciar el contador de elementos de la fila
        add $t4, $t4, 1 				# Avanzar una fila en la coordenada Y
        add $t3, $zero, $t7			# Reiniciar la coordenada X al inicio de la fila
        add $t2, $t2, -1				# Reducir el contador de filas restantes
        bnez $t2, loop1				# Repetir hasta que se procesen todas las filas
.end_macro

.macro ubicar(%x, %y)
    # Cargar las coordenadas iniciales en $s0 y $s1
    add   $s0, $zero, %x          # Cargar la coordenada X en $s0
    add   $s1, $zero, %y          # Cargar la coordenada Y en $s1

    # Calcular x = (%x mod ANCHO_FB) de forma positiva
    li    $t0, ANCHO_FB           # Cargar el ancho del framebuffer en $t0
    div   $s0, $t0                # Dividir $s0 entre ANCHO_FB
    mfhi  $s0                     # Obtener el residuo de la división (mod)
    bltz  $s0, adjust_x           # Si el residuo es negativo, ajustarlo
    j     compute_y               # Saltar al cálculo de Y
adjust_x:
    add   $s0, $s0, $t0           # Ajustar $s0 sumando ANCHO_FB

compute_y:
    # Calcular y = (%y mod ALTURA_FB) de forma positiva
    li    $t0, ALTURA_FB          # Cargar la altura del framebuffer en $t0
    div   $s1, $t0                # Dividir $s1 entre ALTURA_FB
    mfhi  $s1                     # Obtener el residuo de la división (mod)
    bltz  $s1, adjust_y           # Si el residuo es negativo, ajustarlo
    j     done_coords             # Saltar al final del cálculo
adjust_y:
    add   $s1, $s1, $t0           # Ajustar $s1 sumando ALTURA_FB
done_coords:
    # Final del cálculo de coordenadas
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
file_mosca1: .asciiz "moscaclosedown.rgba"
.align 2
espacio_mosca1: .space espacio_mosca_longitud
file_mosca1_vuela: .asciiz "moscaopendown.rgba"
.align 2
espacio_mosca1_vuela: .space espacio_mosca_longitud
file_mosca2: .asciiz "mosca2closeup.rgba"
.align 2
espacio_mosca2: .space espacio_mosca_longitud
file_mosca2_vuela: .asciiz "mosca2openup.rgba"
.align 2
espacio_mosca2_vuela: .space espacio_mosca_longitud
file_mosca3: .asciiz "mosca3closedown.rgba"
.align 2
espacio_mosca3: .space espacio_mosca_longitud
file_mosca3_vuela: .asciiz "mosca3opendown.rgba"
.align 2
espacio_mosca3_vuela: .space espacio_mosca_longitud
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
file_efecto_bueno: .asciiz "brillo.rgba"
.align 2
espacio_efecto_bueno: .space espacio_efecto_longitud
file_final_bueno: .asciiz "win.rgba"
.align 2
espacio_final_bueno: .space espacio_final_longitud
file_final_malo: .asciiz "lose.rgba"
.align 2
espacio_final_malo: .space espacio_final_longitud
file_fondo_objeto: .asciiz "fondoobjetos.rgba"
.align 2
espacio_fondo_objeto: .space espacio_fondo_objeto_longitud

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
mosca1_existe: .word 1
mosca2_existe: .word 1
mosca3_existe: .word 1
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
    cargar(file_mosca2, espacio_mosca2)
    cargar(file_mosca2_vuela, espacio_mosca2_vuela)
    cargar(file_mosca1, espacio_mosca1)
    cargar(file_mosca1_vuela, espacio_mosca1_vuela)
    cargar(file_mosca3, espacio_mosca3)
    cargar(file_mosca3_vuela, espacio_mosca3_vuela)
    cargar(file_mosca_mala_arriba, espacio_mosca_mala_arriba)
    cargar(file_mosca_mala_arriba_vuela, espacio_mosca_mala_arriba_vuela)
    cargar(file_mosca_mala_abajo, espacio_mosca_mala_abajo)
    cargar(file_mosca_mala_abajo_vuela, espacio_mosca_mala_abajo_vuela)
    cargar(file_efecto_bueno, espacio_efecto_bueno)
    cargar(file_final_malo, espacio_final_malo)
    cargar(file_final_bueno, espacio_final_bueno)
    cargar(file_fondo_objeto, espacio_fondo_objeto)

    # Llamar a macros con valores inmediatos
    pintar(espacio_fondo, espacio_fondo_ancho, espacio_fondo_altura, 0, 0)
    pintar(espacio_sapo, espacio_sapo_ancho, espacio_sapo_altura, 0, 101)
    pintar(espacio_mosca1, espacio_mosca_ancho, espacio_mosca_altura, 200, 112)
    pintar(espacio_mosca2, espacio_mosca_ancho, espacio_mosca_altura, 325, 112)
    pintar(espacio_mosca3, espacio_mosca_ancho, espacio_mosca_altura, 450, 112)
    pintar(espacio_mosca_mala_abajo, espacio_mosca_ancho, espacio_mosca_altura, 263, 224)
    pintar(espacio_mosca_mala_arriba, espacio_mosca_ancho, espacio_mosca_altura, 388, 224)

main:
    lw   $t0, 0xFFFF0004         # Leer la tecla presionada desde la dirección 0xFFFF0004
    beq  $t0, 0x65, salida       # Si la tecla es 'e' (0x65), salir del programa
    li   $t1, sapo_velocidad     # Cargar la velocidad del sapo en $t1
    lw   $t2, j_sapo             # Cargar la posición actual del sapo en $t2
    beq  $t0, 0x77, sapo_sube    # Si la tecla es 'w' (0x77), mover el sapo hacia arriba
    beq  $t0, 0x73, sapo_baja    # Si la tecla es 's' (0x73), mover el sapo hacia abajo
    beq  $t0, 0x64, lengua       # Si la tecla es 'd' (0x64), activar la lengua
    sw   $zero, 0xFFFF0004       # Limpiar la dirección 0xFFFF0004 (resetear la tecla)
    b    bucle                   # Saltar al bucle principal

sapo_sube:
    sub  $t2, $t2, sapo_velocidad  # Restar la velocidad a la posición actual del sapo
    sw   $t2, j_sapo               # Actualizar la posición del sapo
    b    bucle                     # Volver al bucle principal

sapo_baja:
    add  $t2, $t2, sapo_velocidad  # Sumar la velocidad a la posición actual del sapo
    sw   $t2, j_sapo               # Actualizar la posición del sapo
    b    bucle                     # Volver al bucle principal

lengua:
    sw   $t0, tecla_lengua         # Guardar el código de la tecla presionada
    add  $t2, $t2, 29              # Ajustar la posición de la lengua en relación al sapo
    sw   $t2, j_lengua             # Guardar la posición Y de la lengua
    li   $t2, i_sapo_posicion      # Cargar la posición base del sapo en $t2
    add  $t2, $t2, espacio_sapo_ancho  # Ajustar la posición en X de la lengua
    sw   $t2, i_lengua_inicial     # Guardar el límite izquierdo de la lengua
    sw   $t2, i_lengua_final       # Inicializar el extremo derecho de la lengua
    b    pintar_sapo_lengua        # Saltar a la rutina para pintar el sapo con lengua

bucle:
    lw   $t3, mosca1_existe        # Verificar si la mosca 1 existe
    li   $t4, 1                    # Cargar el valor 1 (mosca existe)
    beq  $t3, $t4, vuelo_mosca1    # Si la mosca existe, manejar su vuelo
    j    mosca1_lista              # Si no, saltar al siguiente bloque

vuelo_mosca1:
    lw   $t0, i_mosca1             # Cargar la posición X de la mosca 1
    lw   $t1, j_mosca1             # Cargar la posición Y de la mosca 1
    lw   $t2, mosca1_vuelo         # Verificar si la mosca está volando
    beq  $t2, 1, abrir_alas        # Si está volando, abrir las alas
    pintar(espacio_mosca1, espacio_mosca_ancho, espacio_mosca_altura, $t0, $t1)  # Pintar la mosca
    li   $t2, 1                    # Cambiar el estado de vuelo
    sw   $t2, mosca1_vuelo         # Guardar el nuevo estado
    b    final_vuelo               # Saltar al final del vuelo

abrir_alas:
    pintar(espacio_mosca1_vuela, espacio_mosca_ancho, espacio_mosca_altura, $t0, $t1)  # Pintar la mosca con alas abiertas
    sw   $zero, mosca1_vuelo       # Cambiar el estado de vuelo a 0

final_vuelo:
    lw   $t0, j_mosca1             # Cargar la posición Y de la mosca 1
    add  $t0, $t0, mosca1_velocidad  # Incrementar la posición X según la velocidad
    sw   $t0, j_mosca1             # Guardar la nueva posición
mosca1_lista:

    lw   $t3, mosca2_existe         # Verificar si la mosca 2 existe
    li   $t4, 1                     # Cargar el valor 1 (mosca existe)
    beq  $t3, $t4, vuelo_mosca2     # Si existe, manejar su vuelo
    j    mosca2_lista               # Si no, saltar al siguiente bloque

vuelo_mosca2:
    lw   $t0, i_mosca2             # Cargar la posición X de la mosca 2
    lw   $t1, j_mosca2             # Cargar la posición Y de la mosca 2
    lw   $t2, mosca2_vuelo         # Verificar si la mosca está volando
    beq  $t2, 1, abrir_alas2       # Si está volando, abrir las alas
    pintar(espacio_mosca2, espacio_mosca_ancho, espacio_mosca_altura, $t0, $t1)  # Pintar la mosca
    li   $t2, 1                    # Cambiar el estado de vuelo
    sw   $t2, mosca2_vuelo         # Guardar el nuevo estado
    b    final_vuelo2              # Saltar al final del vuelo

abrir_alas2:
    pintar(espacio_mosca2_vuela, espacio_mosca_ancho, espacio_mosca_altura, $t0, $t1)  # Pintar la mosca con alas abiertas
    sw   $zero, mosca2_vuelo       # Cambiar el estado de vuelo a 0

final_vuelo2:
    lw   $t0, j_mosca2             # Cargar la posición Y de la mosca 2
    sub  $t0, $t0, mosca2_velocidad  # Decrementar la posición X según la velocidad
    sw   $t0, j_mosca2             # Guardar la nueva posición
mosca2_lista:

    lw   $t3, mosca3_existe         # Verificar si la mosca 3 existe
    li   $t4, 1                     # Cargar el valor 1 (mosca existe)
    beq  $t3, $t4, vuelo_mosca3     # Si existe, manejar su vuelo
    j    mosca3_lista               # Si no, saltar al siguiente bloque

vuelo_mosca3:
    lw   $t0, i_mosca3             # Cargar la posición X de la mosca 3
    lw   $t1, j_mosca3             # Cargar la posición Y de la mosca 3
    lw   $t2, mosca3_vuelo         # Verificar si la mosca está volando
    beq  $t2, 1, abrir_alas3       # Si está volando, abrir las alas
    pintar(espacio_mosca3, espacio_mosca_ancho, espacio_mosca_altura, $t0, $t1)  # Pintar la mosca
    li   $t2, 1                    # Cambiar el estado de vuelo
    sw   $t2, mosca3_vuelo         # Guardar el nuevo estado
    b    final3_vuelo              # Saltar al final del vuelo

abrir_alas3:
    pintar(espacio_mosca3_vuela, espacio_mosca_ancho, espacio_mosca_altura, $t0, $t1)  # Pintar la mosca con alas abiertas
    sw   $zero, mosca3_vuelo       # Cambiar el estado de vuelo a 0

final3_vuelo:
    lw   $t0, j_mosca3             # Cargar la posición Y de la mosca 3
    add  $t0, $t0, mosca3_velocidad  # Incrementar la posición X según la velocidad
    sw   $t0, j_mosca3             # Guardar la nueva posición
mosca3_lista:

 # --- Manejo de Mosca 4 ---
    lw   $t0, i_mosca4             # Cargar la posición X de la mosca 4
    lw   $t1, j_mosca4             # Cargar la posición Y de la mosca 4
    lw   $t2, mosca4_vuelo         # Verificar si la mosca 4 está volando
    beq  $t2, 1, abrir_alas4       # Si está volando, abrir las alas
    pintar(espacio_mosca_mala_abajo, espacio_mosca_ancho, espacio_mosca_altura, $t0, $t1)  # Pintar la mosca 4 cerrada
    li   $t2, 1                    # Cambiar el estado de vuelo a 1 (volando)
    sw   $t2, mosca4_vuelo         # Guardar el nuevo estado de vuelo
    b    final4_vuelo              # Saltar al final del vuelo

abrir_alas4:
    pintar(espacio_mosca_mala_abajo_vuela, espacio_mosca_ancho, espacio_mosca_altura, $t0, $t1)  # Pintar la mosca 4 con alas abiertas
    sw   $zero, mosca4_vuelo       # Cambiar el estado de vuelo a 0 (no volando)

final4_vuelo:
    lw   $t0, j_mosca4             # Cargar la posición Y de la mosca 4
    add  $t0, $t0, mosca4_velocidad  # Incrementar la posición Y según la velocidad de la mosca 4
    sw   $t0, j_mosca4             # Guardar la nueva posición Y de la mosca 4
mosca4_lista:                      # Etiqueta para continuar con la siguiente mosca

# --- Manejo de Mosca 5 ---
    lw   $t0, i_mosca5             # Cargar la posición X de la mosca 5
    lw   $t1, j_mosca5             # Cargar la posición Y de la mosca 5
    lw   $t2, mosca5_vuelo         # Verificar si la mosca 5 está volando
    beq  $t2, 1, abrir_alas5       # Si está volando, abrir las alas
    pintar(espacio_mosca_mala_arriba, espacio_mosca_ancho, espacio_mosca_altura, $t0, $t1)  # Pintar la mosca 5 cerrada
    li   $t2, 1                    # Cambiar el estado de vuelo a 1 (volando)
    sw   $t2, mosca5_vuelo         # Guardar el nuevo estado de vuelo
    b    final5_vuelo              # Saltar al final del vuelo

abrir_alas5:
    pintar(espacio_mosca_mala_arriba_vuela, espacio_mosca_ancho, espacio_mosca_altura, $t0, $t1)  # Pintar la mosca 5 con alas abiertas
    sw   $zero, mosca5_vuelo       # Cambiar el estado de vuelo a 0 (no volando)

final5_vuelo:
    lw   $t0, j_mosca5             # Cargar la posición Y de la mosca 5
    sub  $t0, $t0, mosca4_velocidad  # Decrementar la posición Y según la velocidad de la mosca 5
    sw   $t0, j_mosca5             # Guardar la nueva posición Y de la mosca 5
mosca5_lista:                      # Etiqueta para continuar con la siguiente lógica

    lw   $t0, tecla_lengua        # Cargar el valor de tecla_lengua para verificar si la lengua está activa
    bne  $t0, 0x64, pintar_sapo   # Si tecla_lengua no es 0x64, salta a pintar_sapo (dibuja el sapo)

    # Obtener las coordenadas iniciales de la lengua
    lw   $t0, i_lengua_inicial    # Cargar la coordenada X de inicio de la lengua (i_lengua_inicial)
    lw   $t1, j_lengua            # Cargar la coordenada Y de la lengua (j_lengua)

    # Convertir las coordenadas lógicas a coordenadas reales
    ubicar($t0, $t1)              # Convierte las coordenadas lógicas (i_lengua_inicial, j_lengua) a reales
    add  $t0, $zero, $s1          # Copiar la coordenada Y real (de $s1) a $t0
    mul  $t0, $t0, ANCHO_FB       # Calcular el offset vertical: y_real * ANCHO_FB
    add  $t0, $t0, $s0            # Sumar la coordenada X real para obtener el índice lineal
    mul  $t0, $t0, 4              # Convertir el índice lineal a byte-offset (4 bytes por píxel)
    add  $s0, $t0, DIRECCION_DISPLAY  # Sumar la dirección base del framebuffer para obtener la dirección real del píxel

    # Leer el color del píxel en la dirección calculada
    lw   $t0, ($s0)               # Cargar el color del píxel ubicado en la dirección calculada

lengua_sin_darle_al_blanco:
    # Verificar si se presionó la tecla para desactivar la lengua
    lw   $t0, 0xFFFF0004           # Leer el valor de la tecla desde la dirección de entrada
    beq  $t0, 0x61, limpiar_lengua  # Si la tecla es 'a' (0x61), salta a limpiar_lengua

    # Verificar si la lengua alcanzó su límite derecho
    lw   $t3, i_lengua_final       # Cargar la posición X actual del extremo de la lengua
    li   $t8, 489                  # Límite derecho de la lengua
    bge  $t3, $t8, limpiar_lengua  # Si i_lengua_final >= 489, salta a limpiar_lengua

    # Preparar para dibujar la lengua
    lw   $t0, i_lengua_final       # Cargar la posición X actual de la lengua
    lw   $t1, j_lengua             # Cargar la posición Y de la lengua
    ubicar($t0, $t1)               # Convertir las coordenadas lógicas a reales

    # Calcular la dirección del píxel en el framebuffer
    add  $t0, $zero, $s1           # Copiar la coordenada Y real ($s1) a $t0
    mul  $t0, $t0, ANCHO_FB        # Calcular el offset vertical: y_real * ANCHO_FB
    add  $t0, $t0, $s0             # Sumar la coordenada X real para obtener el índice lineal
    mul  $t0, $t0, 4               # Convertir el índice lineal a bytes (4 bytes por píxel)
    add  $s0, $t0, DIRECCION_DISPLAY # Sumar la dirección base del framebuffer

    # Verificar el color del píxel actual
    lw   $t4, ($s0)               # Cargar el color del píxel actual
    li   $t5, -16711420            # Color de la mosca 1
    beq  $t4, $t5, mosca1_comida   # Si coincide, salta a la rutina de mosca1_comida
    li   $t5, -14540254            # Color de la mosca 2
    beq  $t4, $t5, mosca2_comida   # Si coincide, salta a la rutina de mosca2_comida
    li   $t5, -11382190            # Color de la mosca 3
    beq  $t4, $t5, mosca3_comida   # Si coincide, salta a la rutina de mosca3_comida
    li   $t5, -15990786            # Color de una mosca mala
    beq  $t4, $t5, perder          # Si coincide, salta a la rutina de perder

    # Dibujar la lengua
    li   $t2, 0x5059D3            # Color de la lengua
    sw   $t2, ($s0)               # Escribir el color en el framebuffer

    # Incrementar la posición de la lengua
    lw   $t1, i_lengua_final      # Cargar la posición actual de i_lengua_final
    li   $t8, 489                 # Límite derecho de la lengua
    blt  $t1, $t8, increment_line # Si i_lengua_final < 489, salta a increment_line
    j    bucle                   # Si no, regresa al bucle principal

increment_line:
    addi $t1, $t1, 1              # Incrementar la posición final de la lengua (i_lengua_final) en 1
    sw   $t1, i_lengua_final      # Guardar el nuevo valor de i_lengua_final
    j    bucle                   # Regresar al bucle principal

mosca1_comida:
    sw   $zero, mosca1_existe        # Marcar que la mosca 1 ya no existe
    lw   $t0, i_mosca1               # Cargar la posición X de la mosca 1
    lw   $t1, j_mosca1               # Cargar la posición Y de la mosca 1
    pintar(espacio_efecto_bueno, espacio_efecto_ancho, espacio_efecto_altura, $t0, $t1)  # Pintar el efecto de captura
    lw   $t0, i_mosca1               # Cargar la posición X de la mosca 1
    lw   $t1, j_mosca1               # Cargar la posición Y de la mosca 1
    pintar(espacio_fondo_objeto, espacio_fondo_objeto_ancho, espacio_fondo_objeto_altura, $t0, $t1)  # Restaurar el fondo
    lw   $t6, score                 # Cargar el puntaje actual
    addi $t6, $t6, 1                # Incrementar el puntaje en 1
    sw   $t6, score                 # Guardar el nuevo puntaje
    li   $t7, 3                     # Cargar el puntaje necesario para ganar
    beq  $t6, $t7, ganar            # Si el puntaje es igual a 3, saltar a la rutina de victoria
    j    limpiar_lengua             # Si no, continuar con la limpieza de la lengua

mosca2_comida:
    sw   $zero, mosca2_existe        # Marcar que la mosca 2 ya no existe
    lw   $t0, i_mosca2               # Cargar la posición X de la mosca 2
    lw   $t1, j_mosca2               # Cargar la posición Y de la mosca 2
    pintar(espacio_efecto_bueno, espacio_efecto_ancho, espacio_efecto_altura, $t0, $t1)  # Pintar el efecto de captura
    lw   $t0, i_mosca2               # Cargar la posición X de la mosca 2
    lw   $t1, j_mosca2               # Cargar la posición Y de la mosca 2
    pintar(espacio_fondo_objeto, espacio_mosca_ancho, espacio_mosca_altura, $t0, $t1)  # Restaurar el fondo
    lw   $t6, score                 # Cargar el puntaje actual
    addi $t6, $t6, 1                # Incrementar el puntaje en 1
    sw   $t6, score                 # Guardar el nuevo puntaje
    li   $t7, 3                     # Cargar el puntaje necesario para ganar
    beq  $t6, $t7, ganar            # Si el puntaje es igual a 3, saltar a la rutina de victoria
    j    limpiar_lengua             # Si no, continuar con la limpieza de la lengua

mosca3_comida:
    lw   $t0, i_mosca3               # Cargar la posición X de la mosca 3
    lw   $t1, j_mosca3               # Cargar la posición Y de la mosca 3
    pintar(espacio_efecto_bueno, espacio_efecto_ancho, espacio_efecto_altura, $t0, $t1)  # Pintar el efecto de captura
    lw   $t0, i_mosca3               # Cargar la posición X de la mosca 3
    lw   $t1, j_mosca3               # Cargar la posición Y de la mosca 3
    pintar(espacio_fondo_objeto, espacio_mosca_ancho, espacio_mosca_altura, $t0, $t1)  # Restaurar el fondo
    lw   $t6, score                 # Cargar el puntaje actual
    addi $t6, $t6, 1                # Incrementar el puntaje en 1
    sw   $t6, score                 # Guardar el nuevo puntaje
    li   $t7, 3                     # Cargar el puntaje necesario para ganar
    beq  $t6, $t7, ganar            # Si el puntaje es igual a 3, saltar a la rutina de victoria
    j    limpiar_lengua             # Si no, continuar con la limpieza de la lengua

limpiar_lengua:
    sw   $zero, tecla_lengua        # Reiniciar la bandera de activación de la lengua
    sw   $zero, 0xFFFF0004          # Limpiar el puerto de entrada (tecla presionada)

clear_loop:
    lw   $t0, i_lengua_final        # Cargar la posición X actual del extremo de la lengua
    lw   $t1, i_lengua_inicial      # Cargar la posición X inicial de la lengua
    blt  $t0, $t1, clear_done       # Si i_lengua_final < i_lengua_inicial, terminar la limpieza
    lw   $t2, j_lengua              # Cargar la posición Y de la lengua
    ubicar($t0, $t2)                # Convertir las coordenadas lógicas a reales
    move $t3, $s1                   # Copiar la coordenada Y real
    mul  $t3, $t3, ANCHO_FB         # Calcular el offset vertical (y_real * ancho del framebuffer)
    add  $t3, $t3, $s0              # Sumar la coordenada X real
    mul  $t3, $t3, 4                # Convertir el índice lineal a bytes (4 bytes por píxel)
    add  $t3, $t3, DIRECCION_DISPLAY # Sumar la dirección base del framebuffer
    li   $t4, 0x84945C              # Cargar el color de fondo
    sw   $t4, ($t3)                 # Escribir el color de fondo en el framebuffer

    lw   $t6, i_lengua_final        # Cargar el valor actual de i_lengua_final
    addi $t6, $t6, -1               # Decrementar i_lengua_final en 1
    sw   $t6, i_lengua_final        # Guardar el nuevo valor de i_lengua_final
    j    clear_loop                 # Repetir el ciclo para borrar el siguiente píxel

clear_done:
    j    bucle                      # Regresar al bucle principal

pintar_sapo:
    lw   $t0, 0xFFFF0004                     # Leer la tecla presionada desde la dirección 0xFFFF0004
    beqz $t0, final_sapo                     # Si no se presionó ninguna tecla, saltar a final_sapo
    lw   $t0, j_sapo                         # Cargar la posición Y actual del sapo (j_sapo)
    pintar(espacio_sapo, espacio_sapo_ancho, espacio_sapo_altura, i_sapo_posicion, $t0)  # Pintar el sapo
    j    final_sapo                          # Saltar a final_sapo después de pintar

pintar_sapo_lengua:
    lw   $t0, 0xFFFF0004                     # Leer la tecla presionada desde la dirección 0xFFFF0004
    beqz $t0, final_sapo                     # Si no se presionó ninguna tecla, saltar a final_sapo
    lw   $t0, j_sapo                         # Cargar la posición Y actual del sapo (j_sapo)
    pintar(espacio_sapo_lengua, espacio_sapo_ancho, espacio_sapo_altura, i_sapo_posicion, $t0)  # Pintar el sapo con lengua
    j    final_sapo                          # Saltar a final_sapo después de pintar

final_sapo:
    lw   $t0, tecla_lengua                   # Revisar el estado actual de la lengua
    bne  $t0, 0x64, bucle_fin                # Si la lengua no está activa, saltar a bucle_fin
    b    bucle                               # Si la lengua sigue activa, volver al bucle principal

ganar:
    pintar(espacio_final_bueno, espacio_final_ancho, espacio_final_altura, 128, 64)  # Pintar la pantalla de victoria
    j    salida                              # Saltar a salida después de imprimir la pantalla

perder:
    pintar(espacio_final_malo, espacio_final_ancho, espacio_final_altura, 128, 64)  # Pintar la pantalla de derrota
    j    salida                              # Saltar a salida después de imprimir la pantalla

bucle_fin:
    b    main                                # Volver a la rutina principal para el siguiente frame

salida:
    li   $v0, 10                             # Cargar el código 10 del syscall (exit)
    syscall                                  # Llamar al syscall para salir del programa