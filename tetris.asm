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

# Tetris Pieces
all_pieces:
I: .half 0x000F, 0x0000, 0x0000, 0x0000   # I piece: bottom 4 bits set in first row
O: .half 0x0006, 0x0006, 0x0000, 0x0000   # O piece: bits 1 and 2 set in first two rows
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

##############################################################################
# Code
##############################################################################
		.text
	.globl main

	# Run the Tetris game.
main:
	la $t0, ADDR_DSPL # Connect to display
	lw $s7, 0($t0)   # Load display base pointer into $s7
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
   	mul  $t4, $t1, $t3   # spaces to skip = index * 8
   	add  $s0, $t2, $t4   # s0 = address of selected piece
   	
   	#li   $t1, 0           # index 0 for I piece
    	#la   $t2, all_pieces  # base address of pieces
    	#li   $t3, 8           # size of each piece block in bytes (4 halfwords * 2 bytes)
    	#mul  $t4, $t1, $t3    # offset = index * size
    	#add  $s0, $t2, $t4    # $s0 = address of I piece
    	
    	# Get a random color
    	li   $v0, 42
    	li   $a1, 777
    	syscall
    	remu $t5, $a0, 7  # remainder mod 3 is color
    	la   $t6, RED     # get address of color table
    	sll  $t7, $t5, 2
    	add  $t6, $t6, $t7
    	lw   $s1, 0($t6)   # $s1 = color
	
    	# Spawn @(x,y) = (6,0) centered in top row
    	li   $a2, 6
    	li   $a3, 2
    
    	# Start drawing the piece (4x4 grid)
	li $t0, 0                  # row index (0 to 3)

draw_pc_main:
    beq $t0, 4, game_loop  # done with all rows

    lhu $t1, 0($s0)        # load halfword for current row (piece data)
    li  $t4, 0             # column index (0 to 3)

draw_pc_inner:
    beq $t4, 4, next_row

    # Compute bitmask: bit = 1 << (3 - col)
    li   $t5, 3
    sub  $t5, $t5, $t4
    li   $t6, 1
    sllv $t6, $t6, $t5

    # Check if bit is set
    and  $t7, $t1, $t6
    beqz $t7, do_nothing

    # Calculate x = spawn_x + col
    add  $t8, $a2, $t4      # t8 = x

    # Calculate y = spawn_y + row
    add  $t9, $a3, $t0      # t9 = y

    # Compute address: (y * 16 + x) * 4 + screen_base
    mul  $t3, $t9, 16       # y * 16
    add  $t3, $t3, $t8      # + x
    sll  $t3, $t3, 2        # *4 bytes per pixel
    add  $t6, $s7, $t3      # screen base + offset
    sw   $s1, 0($t6)        # draw color

do_nothing:
    addi $t4, $t4, 1        # next column
    j draw_pc_inner

next_row:
    addi $s0, $s0, 2        # next halfword (row)
    addi $t0, $t0, 1        # next row
    j draw_pc_main



game_loop:
	# 1a. Check if key has been pressed
    	# 1b. Check which key has been pressed
    	# 2a. Check for collisions
	# 2b. Update locations (paddle, ball)
	# 3. Draw the screen
	# 4. Sleep
	
	b done

    #5. Go back to 1
    #b game_loop
    
done: # debugging only
	li $v0, 10
	syscall
