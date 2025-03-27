
.eqv WIDTH 2048                # FrameBuffer Width
.eqv FB_LENGTH 1048576          # FrameBuffer Length
.eqv SPRITE1A_WIDTH 288        # Sprite Width
.eqv SPRITE1A_LENGTH 15552     # Sprite Length
.eqv SPEED 4

# Data Segment
.data
FB:         .space FB_LENGTH           # Framebuffer
SPRITE1A:   .space SPRITE1A_LENGTH     # Sprite 1A buffer
file1A:     .asciiz "sapo.rgba"      # Sprite 1A file name

# Text Segment
.text
.globl main
main:
    # Initialize framebuffer
    li $s5, 0                # i = 0
    la $t0, FB               # $t0 = framebuffer base address
    li $a2, FB_LENGTH        # Framebuffer length
    li $a3, WIDTH            # Framebuffer width

    # Open Sprite File (file1A)
    li $v0, 13               # syscall: open file
    la $a0, file1A           # File name
    li $a1, 0                # Flags: read-only
    li $a2, 0                # Mode: ignore
    syscall
    move $s0, $v0            # Store file descriptor in $s0

    # Read Sprite Data into SPRITE1A buffer
    li $v0, 14               # syscall: read file
    move $a0, $s0            # File descriptor
    la $a1, SPRITE1A         # Buffer address
    li $a2, SPRITE1A_LENGTH  # Number of bytes to read
    syscall

    # Convert Sprite Data to Little-Endian
    jal littleendian

    # Paint Sprite on Framebuffer
    la $a0, FB               # Framebuffer base address
    la $a1, SPRITE1A         # Sprite buffer address
    li $a2, SPRITE1A_LENGTH  # Sprite length
    li $a3, SPRITE1A_WIDTH   # Sprite width
    jal Pintar

    # Exit program
    li $v0, 10               # syscall: exit
    syscall

# Procedure: Paint Sprite on Framebuffer
Pintar:
    li $t5, 0                # i = 0
    add $t0, $a0, 0          # $t0 = framebuffer pointer
    add $t1, $a1, 0          # $t1 = sprite buffer pointer
loop:
    bge $t5, $a2, done       # Exit loop if i >= sprite length
    li $t4, 0                # j = 0
line:
    bge $t4, $a3, next_row   # Exit line if j >= sprite width
    lw $t6, ($t1)            # Load pixel from sprite buffer
    sw $t6, ($t0)            # Store pixel in framebuffer
    addiu $t0, $t0, 4        # Advance framebuffer pointer
    addiu $t1, $t1, 4        # Advance sprite buffer pointer
    addiu $t5, $t5, 4        # Increment i
    addiu $t4, $t4, 4        # Increment j
    j line
next_row:
    li $t2, WIDTH            # Framebuffer width
    sub $t2, $t2, $a3        # Calculate row offset
    sll $t2, $t2, 2          # Convert to bytes
    add $t0, $t0, $t2        # Advance framebuffer pointer to next row
    j loop
done:
    jr $ra                   # Return

# Procedure: Convert Sprite Data to Little-Endian
littleendian:
    li $s5, 0                # i = 0
    move $t0, $a1            # $t0 = sprite buffer pointer
loopLE:
    bge $s5, $a2, doneLE     # Exit loop if i >= sprite length
    lw $s6, ($t0)            # Load pixel
    andi $t1, $s6, 0xFF      # Extract blue channel
    sll $t1, $t1, 16         # Shift blue to correct position
    srl $t2, $s6, 16         # Extract red channel
    andi $t2, $t2, 0xFF      # Mask red channel
    andi $t3, $s6, 0xFF00    # Extract green channel
    or $s6, $t1, $t2         # Combine blue and red
    or $s6, $s6, $t3         # Add green channel
    sw $s6, ($t0)            # Store converted pixel
    addiu $t0, $t0, 4        # Advance sprite buffer pointer
    addiu $s5, $s5, 4        # Increment i
    j loopLE
doneLE:
    jr $ra                   # Return