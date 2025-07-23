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
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL: .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD: .word 0xffff0000
# Color white for the walls
WALL_CLR: .word 0xffffffff
NO_PIECE: .word 0x00000000 # empty color/black
# Checkerboard Colors
DARK_GRAY:   .word 0xFF555555
LIGHT_GRAY:  .word 0xFFAAAAAA

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


##############################################################################
# Code
##############################################################################
.text
.globl main

	# Run the Tetris game.
main:
	la $t0, ADDR_DSPL # Connect to display
	lw $s7, 0($t0)   # Load display base pointer into $s7
	
draw_checkerboard:
	li $t0 0
	
outer_row:
	li $t1 0
	
inner_col:
	add $t2, $t1, $t0
	andi $t2, $t2, 1
	beqz $t2, dark_square
	la $t3, LIGHT_GRAY
	j draw_unit
	
dark_square:
	la $t3, DARK_GRAY
	
draw_unit:
	lw $t4, 0($t3)
	li $t5, 0              # dy: pixel row inside unit
	
draw_block_row:
	li $t6, 0              # dx: pixel col inside unit
	
draw_block_col:
    # Compute absolute pixel x,y
    mul $t7, $t0, 8        # y = row * 8
    add $t7, $t7, $t5
    mul $t8, $t7, 128      # y * width (128)
    
    mul $t9, $t1, 8        # x = col * 8
    add $t9, $t9, $t6
    add $t8, $t8, $t9      # (y * width) + x
    sll $t8, $t8, 2        # *4 for byte address

    add $t8, $s7, $t8
    sw $t4, 0($t8)

    addi $t6, $t6, 1
    li $t2, 8
    blt $t6, $t2, draw_block_col

    addi $t5, $t5, 1
    li $t2, 8
    blt $t5, $t2, draw_block_row

    addi $t1, $t1, 1
    li $t2, 16
    blt $t1, $t2, inner_col

    addi $t0, $t0, 1
    li $t2, 16
    blt $t0, $t2, outer_row
    
    	# Now draw the walls 
	
	lw $t1, WALL_CLR
	# Start by drawing the walls
	# Our display is 64 wide by 128 height and each unit is 8 by 8
	# There are 8 columns and 16 rows
	
	li $t2, 0 # y = 0
	li $t3, 0  # x = 0 
draw_left_wall:
	mul $t4, $t2, 16 # skip this number of units to get to next row start
	add $t4, $t4, $t3 # redundant statement for x=0 but is here for clarity
	sll $t4, $t4, 2   # next word (= 2^2 bytes)
	add $t5, $s7, $t4 # actual address in display (using $s7 now)
	sw $t1, 0($t5) # draw the cell
	addi $t2, $t2, 1 # y += 1
	li $t6, 32 # we have 32 rows
	blt $t2 $t6, draw_left_wall # loop until wall is finished
	
	li $t2, 0 # y = 0
	li $t3, 15 # same as above but now x = 15
draw_right_wall:
	mul $t4, $t2, 16 # skip this number of units to get to next row start
	add $t4, $t4, $t3 # redundant statement for x=0 but is here for clarity
	sll $t4, $t4, 2   # next word (= 2^2 bytes)
	add $t5, $s7, $t4 # actual address in display (using $s7 now)
	sw $t1, 0($t5) # draw the cell
	addi $t2, $t2, 1 # y += 1
	li $t6, 32 # we have 32 rows
	blt $t2 $t6, draw_right_wall # loop until wall is finished
	
	li $t2, 31 # y = 31
	li $t3, 0 # x = 0
draw_bottom_wall:
	mul $t4, $t2, 16 
	add  $t4, $t4, $t3     
	sll  $t4, $t4, 2 
    	add  $t5, $s7, $t4 
    	sw   $t1, 0($t5)
    	addi $t3, $t3, 1
    	li   $t6, 16 # we only have 16 columns this time
    	blt  $t3, $t6, draw_bottom_wall
    	
    	# Get a random piece to start with
    	li   $v0, 42 # random integer
    	li   $a1, 700
   	syscall
    	remu $t1, $a0, 7 # remainder mod 7 determines the piece
    	la   $t2, all_pieces # get address of array
    	li   $t3, 8
   	mul  $t4, $t1, $t3   # skip index * 8 spaces
   	add  $s0, $t2, $t4   # s0 = addr of selected piece
   
    	# Get a random color
    	li   $v0, 42
    	li   $a1, 777
    	syscall
    	remu $t5, $a0, 7  # remainder mod 7 is color
    	la   $t6, RED     # get address of color table
    	sll  $t7, $t5, 2
    	add  $t6, $t6, $t7
    	lw   $s1, 0($t6)   # $s1 = color
	
    	# Spawn @(x,y) = (6,0) centered in top row
    	li   $a2, 6
    	li   $a3, 0
    
    	# Start drawing the piece (4x4 grid)
	jal draw_pc_main
	b game_loop # done setupm start the game

# draw_pc_main
# This function draws the piece located at ($a2, $a3) using the shape pointed to by $s0
# and color $s1. The shape is a 4x4 grid of 4 halfwords.
draw_pc_main:
    move $t2, $s0      # temp pointer to shape data
    li   $t0, 0        # row index (0 to 3)

draw_pc_row:
    beq $t0, 4, done_drawing  # done with all rows
    lhu $t1, 0($t2)           # current row halfword
    li  $t4, 0                # column index (0 to 3)

draw_pc_inner:
    beq $t4, 4, next_row

    # Compute bitmask: 1 << (3 - col)
    li   $t5, 3
    sub  $t5, $t5, $t4
    li   $t6, 1
    sllv $t6, $t6, $t5
    and  $t7, $t1, $t6        # Check if bit is set
    beqz $t7, do_nothing      # if not set, skip drawing

    add  $t8, $a2, $t4        # t8 = x
    add  $t9, $a3, $t0        # t9 = y

    # Address: (y * 16 + x) * 4 + screen_base
    mul  $t3, $t9, 16         # y * 16
    add  $t3, $t3, $t8        # + x
    sll  $t3, $t3, 2          # *4 bytes per pixel
    add  $t6, $s7, $t3        # screen base + offset
    sw   $s1, 0($t6)          # draw color

do_nothing:
    addi $t4, $t4, 1          # next column
    j draw_pc_inner

next_row:
    addi $t2, $t2, 2          # next halfword (row)
    addi $t0, $t0, 1          # next row
    j draw_pc_row

done_drawing:
    jr $ra

# Now we need to get the keyboard inputs setup

game_loop:
    	# 2a. Check for collisions
	# 2b. Update locations (paddle, ball)
	# 3. Draw the screen

	li $a0 2
	jal nap_time # zzzzzz
	
	# Load the keyboard
	la $t0, ADDR_KBRD
	lw $s6, 0($t0) # use s6 for keyboard
	lw $t9, 0($s6)   # load first wrod from keybrd
	beq $t9, 1, crash_out
	# b game_loop

    #5. Go back to 1
    #b game_loop
    
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
	beqz $t0, use_light

	# DARK_GRAY
	la $t1, DARK_GRAY
	j draw_pixel

use_light:
	la $t1, LIGHT_GRAY

draw_pixel:
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
