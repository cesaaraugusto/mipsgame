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

    # Cerrar archivo
    li $v0, 16
    syscall
.end_macro

.macro draw_image(%img, %width, %height, %pos_x, %pos_y)
    la $t0, %img                # Dirección de la imagen
    li $t1, 0                   # Contador Y
    li $s0, %width              # Ancho en registro
    li $s1, %height             # Altura en registro
    li $s2, ANCHO_FB            # Constantes en registros
    li $s3, ALTURA_FB
    li $t7, %pos_x              # Cargar posición X como inmediato
    li $t8, %pos_y              # Cargar posición Y como inmediato

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

            # Ajustar coordenadas X (módulo 512)
            div $t4, $s2
            mfhi $t4            # X mod ANCHO_FB
            
            # Ajustar coordenadas Y (módulo 256)
            div $t5, $s3
            mfhi $t5            # Y mod ALTURA_FB

            # Calcular dirección en framebuffer
            mul $t6, $t5, $s2
            add $t6, $t6, $t4
            sll $t6, $t6, 2
            lui $t9, 0x1001
            add $t6, $t6, $t9

            # Escribir píxel
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