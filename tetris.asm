#####################################################################
# CSCB58 Summer 2025 Assembly Final Project - UTSC
# Name, Student Number, UTorID, official email
# Bitmap Display Configuration:
# - Unit width in pixels: 8 (update this as needed) 
# - Unit height in pixels: 8 (update this as needed)
# - Display width in pixels: 128 (update this as needed)
# - Display height in pixels: 256 (update this as needed)
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestones have been reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 1/2/3/4/5 (choose the one the applies)
# - Milestone 1 reached: 7/21
# - Milestone 2 reached: ??
#
# Which approved features have been implemented?
# (See the assignment handout for the list of features)
# Easy Features:
# 1. (fill in the feature, if any)
# 2. (fill in the feature, if any)
# ... (add more if necessary)
# Hard Features:
# 1. (fill in the feature, if any)
# 2. (fill in the feature, if any)
# ... (add more if necessary)
# How to play:
# (Include any instructions)
# Link to video demonstration for final submission:
# - (insert YouTube / MyMedia / other URL here). Make sure we can view it!
#
# Are you OK with us sharing the video with people outside course staff?
# - yes / no
#
# Any additional information that the TA needs to know:
# - (write here, if any)
#
#####################################################################

##############################################################################

.data
comma:   .asciiz ", "
newline: .asciiz "\n"
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL: .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD: .word 0xffff0000
# Color white for the walls
WALL_CLR: .word 0xffffffff


# Tetris Pieces
all_pieces:
I: .half 0x000F, 0x0000, 0x0000, 0x0000   # I piece
O: .half 0x0006, 0x0006, 0x0000, 0x0000   # O piece
T: .half 0x0004, 0x000E, 0x0000, 0x0000   # T piece
S: .half 0x0006, 0x000C, 0x0000, 0x0000   # S piece
Z: .half 0x000C, 0x0006, 0x0000, 0x0000   # Z piece
J: .half 0x0008, 0x000E, 0x0000, 0x0000   # J piece
L: .half 0x0002, 0x000E, 0x0000, 0x0000   # L piece
# I hate litle endian

# Colors
RED:   .word 0x00FF0000
GREEN: .word 0x0000FF00
DARK_BLUE:  .word 0x000000FF
LITE_BLUE: .word 0x00ADD8E6
PURPLE: .word 0x00800080
ORANGE: .word 0x00FFA500
YELLOW: .word 0x00FFFF00

##############################################################################
# Mutable Data
##############################################################################
# S7 is the DISPLAY
# S6 is the keyboard

# fk it we hardcode the checkerboard
.data

##############################################################################
# Code
##############################################################################
.text
.globl main

		# Run the Tetris game.
main:
    la   $t0, ADDR_DSPL      # Load address of ADDR_DSPL
    lw   $s7, 0($t0)         # Load 0x10008000 into $s7
    
    # Draw checkerboard
    jal  draw_checkerboard
    
    # Continue with game
    jal build_a_wall
    
    j game_loop
    
    #li $v0, 10
    #syscall

draw_checkerboard:
    # Using $s7 as base pointer
    li   $t0, 0              # y counter (0-31)
    
y_loop:
    li   $t1, 0              # x counter (0-15)
    
x_loop:
    # Calculate checkerboard pattern (x + y) % 2
    add  $t2, $t1, $t0
    andi $t2, $t2, 1
    
    # Calculate address: $s7 + (y*64 + x*4)
    sll  $t3, $t0, 6         # y * 64 (16 units/row * 4 bytes/unit)
    sll  $t4, $t1, 2         # x * 4
    add  $t5, $t3, $t4       # offset
    add  $t6, $s7, $t5       # Final address ($s7 + offset)
    
    # Set colors
    beqz $t2, dark_unit
    li   $t7, 0x00333333     # Light gray
    j    store_color
    
dark_unit:
    li   $t7, 0x00222222     # Dark gray
    
store_color:
    sw   $t7, 0($t6)         # Store color to display memory
    
    # Increment x
    addi $t1, $t1, 1
    blt  $t1, 16, x_loop     # 16 units across (128/8)
    
    # Increment y
    addi $t0, $t0, 1
    blt  $t0, 32, y_loop     # 32 units down (256/8)
    
    jr   $ra                 # Return to caller

build_a_wall:
    lw   $t1, WALL_CLR

    li   $t2, 0 # y = 0
    li   $t3, 0  # x = 0 
draw_left_wall:
    mul  $t4, $t2, 16
    add  $t4, $t4, $t3
    sll  $t4, $t4, 2
    add  $t5, $s7, $t4
    sw   $t1, 0($t5)
    addi $t2, $t2, 1
    li   $t6, 32
    blt  $t2, $t6, draw_left_wall

    li   $t2, 0
    li   $t3, 15
draw_right_wall:
    mul  $t4, $t2, 16
    add  $t4, $t4, $t3
    sll  $t4, $t4, 2
    add  $t5, $s7, $t4
    sw   $t1, 0($t5)
    addi $t2, $t2, 1
    li   $t6, 32
    blt  $t2, $t6, draw_right_wall

    li   $t2, 31
    li   $t3, 0
draw_bottom_wall:
    mul  $t4, $t2, 16
    add  $t4, $t4, $t3
    sll  $t4, $t4, 2
    add  $t5, $s7, $t4
    sw   $t1, 0($t5)
    addi $t3, $t3, 1
    li   $t6, 16
    blt  $t3, $t6, draw_bottom_wall

    li   $v0, 42
    li   $a1, 700
    syscall
    remu $t1, $a0, 7
    la   $t2, all_pieces
    li   $t3, 8
    mul  $t4, $t1, $t3
    add  $s0, $t2, $t4

    li   $v0, 42
    li   $a1, 777
    syscall
    remu $t5, $a0, 7
    la   $t6, RED
    sll  $t7, $t5, 2
    add  $t6, $t6, $t7
    lw   $s1, 0($t6)

    li   $a2, 6
    li   $a3, 0

    jal  draw_pc_main
    jr   $ra

draw_pc_main:
    move $t2, $s0
    li   $t0, 0

draw_pc_row:
    beq $t0, 4, done_drawing
    lhu  $t1, 0($t2)
    li   $t4, 0

draw_pc_inner:
    beq $t4, 4, next_row

    li   $t5, 3
    sub  $t5, $t5, $t4
    li   $t6, 1
    sllv $t6, $t6, $t5
    and  $t7, $t1, $t6
    beqz $t7, do_nothing

    add  $t8, $a2, $t4
    add  $t9, $a3, $t0

    mul  $t3, $t9, 16
    add  $t3, $t3, $t8
    sll  $t3, $t3, 2
    add  $t6, $s7, $t3
    sw   $s1, 0($t6)

do_nothing:
    addi $t4, $t4, 1
    j draw_pc_inner

next_row:
    addi $t2, $t2, 2
    addi $t0, $t0, 1
    j draw_pc_row

done_drawing:
    jr $ra

# Now we need to get the keyboard inputs setup

game_loop:
    	# 2a. Check for collisions
	# 2b. Update locations (paddle, ball)
	# 3. Draw the screen
	
	b done

	li $a0 2
	jal nap_time # zzzzzz
	
	# Load the keyboard
	la $t0, ADDR_KBRD
	lw $s6, 0($t0) # use s6 for keyboard
	lw $t9, 0($s6)   # load first wrod from keybrd
	beq $t9, 1, crash_out
	# b game_loop
    
crash_out:
	lw $a0, 4($s6)
	beq $a0, 0x61, a_was_pressed
	beq $a0, 0x64, d_was_pressed
	# w key rotates clockwise 90
	# s key rotates clockwise -90
	beq $a0, 0x71, done # quit the game
	# gravity to move the piece down automatically
	# other keyboard commands ...
	j game_loop

a_was_pressed:
	# code logic here
	jal erase_piece
	sub $a2, $a2, 1 # decrease x by 1 to move left
	jal check_hitting_wall # check if we can move the piece left
	# if check_hitting_wall is 1, add back 1 to x
	jal draw_pc_main # draw the piece one spot left
	# 
	
d_was_pressed:
	# code logic here
	jal erase_piece
	add $a2, $a2, 1
	jal check_hitting_wall
	# if check_hitting_wall returns 1, sub back 1 from x
	jal draw_pc_main # redraw the piece
   
# This function erases a piece and
# reverts back the checkerboard pattern that was originally there
erase_piece:
	# $s0 = pointer to piece
	# $a2 = x, $a3 = y

	li $t3, 0            # row index
	move $t2, $s0        # piece pointer

erase_row:
	beq $t3, 4, brd_clr
	lhu $t4, 0($t2)      # current row halfwrod
	li $t5, 0            # column index

erase_col:
	beq $t5, 4, next_row_erase

	# Check if bit (3 - col) is set
	li $t6, 3
	sub $t6, $t6, $t5
	li $t7, 1
	sllv $t7, $t7, $t6
	and $t8, $t4, $t7
	beqz $t8, nothing_to_erase

	# Compute (x + col, y + row)
	add $t9, $a2, $t5    # x = x + col
	add $t6, $a3, $t3    # y = y + row

	# Checkerboard color based on (x + y) % 2
	add $t0, $t9, $t6    # x + y
	andi $t0, $t0, 1     # keep LSB
	beqz $t0, light_pattern

	# DARK_GRAY
	la $t1, 0x0
	j draw_pixel_2

light_pattern:
	la $t1, 0xf

draw_pixel_2:
	lw $t1, 0($t1)

	# Compute address = (y * 16 + x) * 4 + $s7
	mul $t7, $t6, 16
	add $t7, $t7, $t9
	sll $t7, $t7, 2
	add $t7, $t7, $s7
	sw $t1, 0($t7)

nothing_to_erase:
	addi $t5, $t5, 1
	j erase_col

next_row_erase:
	addi $t2, $t2, 2
	addi $t3, $t3, 1
	j erase_row

brd_clr:
	jr $ra

	
check_hitting_wall:
	# s0 contains the index of the piece we want to wall test
	lhu $t1, 0($s0)
	li $t2, 0


nap_time:
	li $v0, 32
	syscall
	jr $ra
    
done: # debugging only
	li $v0, 10
	syscall
