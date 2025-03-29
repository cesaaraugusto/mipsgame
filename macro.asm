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

.data
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
