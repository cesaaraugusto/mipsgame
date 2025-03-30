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
    .eqv espacio_sapo_altura 54
    .eqv espacio_sapo_longitud 15552
    
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
    .eqv j_mosca1_minimo 150
    .eqv j_mosca1_maximo 0
    .eqv j_mosca2_minimo 0
    .eqv j_mosca2_maximo 256
    .eqv j_mosca3_minimo 256
    .eqv j_mosca3_maximo 50
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
fish1_exists: .word 1
fish2_exists: .word 1
fish3_exists: .word 1
crab_alternate: .word 1
space_key: .word 0
score: .word 0
x_start_fishing_rod: .word 0
y_start_fishing_rod: .word 0
y_end_fishing_rod: .word 0
.text
main:
    # Carga imagenes
    cargar(file_fondo, espacio_fondo)
    cargar(file_sapo, espacio_sapo)
    cargar(file_sapo, espacio_sapo_lengua)
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
    pintar(espacio_mosca_arriba, espacio_mosca_ancho, espacio_mosca_altura, 200, 112)
    pintar(espacio_mosca_mala_abajo, espacio_mosca_ancho, espacio_mosca_altura, 263, 0)
    pintar(espacio_mosca_abajo, espacio_mosca_ancho, espacio_mosca_altura, 325, 112)
    pintar(espacio_mosca_mala_arriba, espacio_mosca_ancho, espacio_mosca_altura, 388, 224)
    pintar(espacio_mosca_arriba, espacio_mosca_ancho, espacio_mosca_altura, 450, 112)
    
    li $v0, 10
    syscall
