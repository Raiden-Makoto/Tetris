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

# debug for keyboard
msg_key_pressed:       .asciiz "A key was pressed\n"
msg_erasing_piece:   .asciiz "Erasing piece\n"
msg_drawing_piece:   .asciiz "Drawing new piece\n"
msg_game_starting:	.asciiz "Game Starting\n"
msg_do_something: .asciiz "press a fucking key\n"

##############################################################################
# Immutable Data
########################iiz ######################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL: .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD: .word 0xffff0000 # this will contain a 1 if a key is pressed
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
    la $s6, ADDR_KBRD        # Load keyboard address once into $s6
    li $s5, 0                # timer counter in ms (using $s5), we apply gravity every second
    li $t1, 20               # loop delay in ms (20 ms) while polling for input
    # Draw checkerboard
    jal  draw_checkerboard  
    # Draw the three wals
    jal build_a_wall
    # Continue with the game
    li   $v0, 4
    la   $a0, msg_game_starting
    syscall
    # load random color and piece and draw it
    jal random_bs_go
    jal draw_pc_main
    # loop until the player loses
    j game_loop

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
	jr $ra #should go here
	
random_bs_go:
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

game_loop:
	li $s5, 0 #initialize counter
    
    
# hurry up and press a key bruh
no_key_pressed:
	lw $t9, 0($s6)           # poll keyboard every 10ms
    beq $t9, 1, crash_out    # someone pressed a key
    # Wait 10 ms
    li $a0, 100
    jal nap_time
    addiu $s5, $s5, 100       # $s5 += 100 ms
    
    li $v0, 4
    la $a0, msg_do_something
    syscall

    # Check if 1 second has passed
    blt $s5, 1000, no_key_pressed

    # 5. Time to apply gravity
    #jal gravity              # nonexistent gravity function here
    li $s5, 0                # reset timer counter
	j game_loop # are you going to press a key ffs

crash_out:
	li   $v0, 4
    la   $a0, msg_key_pressed
    syscall
    lw $a0, 4($s6)           # load key code
    beq $a0, 0x61, a_was_pressed   # 'a' move left
    beq $a0, 0x64, d_was_pressed   # 'd' move right
    beq $a0, 0x73, s_was_pressed   # 's' rotate ccw
    beq $a0, 0x77, w_was_pressed   # 'w' rotate cw
    beq $a0, 0x71, done            # 'q' quit
	
	# Reset keyboard status so next keypress can be detected
    sw $zero, 0($s6)
    j game_loop

a_was_pressed:
    # DEBUG: A was pressed
    li   $v0, 4
    la   $a0, msg_key_pressed
    syscall

    addi $a2, $a2, -1            # decrease x by 1 to move left, y is the same
    jal  check_hitting_wall      # check if we cant move the piece left
    addi $a2, $a2, 1
    bnez $v1, you_cant_move_left # if yes, do nothing and go back to game

    # DEBUG: Erasing piece
    li   $v0, 4
    la   $a0, msg_erasing_piece
    syscall

    jal  erase_pc_main

    addi $a2, $a2, -1

    # DEBUG: Drawing new piece
    li   $v0, 4
    la   $a0, msg_drawing_piece
    syscall

    jal  draw_pc_main

    j done                 # for debug only
    j after_keyboard_handled


you_cant_move_left:
	# donithing
	j after_keyboard_handled # continue the game

d_was_pressed:
    addi $a2, $a2, 1           # Try to move right (increase x)
    jal check_hitting_wall     # Check for wall collision
    addi $a2, $a2, -1		 # revert for erase
    bnez $v1, you_cant_move_right  # If collision, revert and skip drawing
    jal erase_pc_main # remove the old piece
	addi $a2, $a2, 1 #move right
    jal draw_pc_main           # If no collision, draw piece in new position
    j after_keyboard_handled   # Continue game

you_cant_move_right:
    # do nothing
    j after_keyboard_handled   # Continue game
   
# This function erases a piece and
# reverts back the checkerboard pattern that was originally there
erase_pc_main:
	# $s0 = pointer to piece
	# $a2 = x, $a3 = y
	li $t0, 0            # row index
	move $t2, $s0        # piece pointer
	
erase_row:
	beq $t0, 4, get_eliminated_nub
	lhu  $t1, 0($t2)      # Load 16-bit row
    li   $t4, 0           # column index (0 to 3)
    
erase_col:
	beq $t4, 4, next_erase_row
	# Check if the bit is set at (3 - col)
    li   $t5, 3
    sub  $t5, $t5, $t4
    li   $t6, 1
    sllv $t6, $t6, $t5
    and  $t7, $t1, $t6
    beqz $t7, skip_erase_block  # If 0, no need to erase
		
	# Calculate (x, y) on screen grid
    add  $t8, $a2, $t4    # x = $a2 + col
    add  $t9, $a3, $t0    # y = $a3 + row

    # (x + y) % 2 to determine color
    add  $t3, $t8, $t9
    andi $t3, $t3, 1
    beqz $t3, use_dark
    li   $t7, 0x00333333  # Light gray
    j    erase_store
    
use_dark:
	li $t7, 0x00222222
	
erase_store:
    # Compute display address = $s7 + (y * 64 + x * 4)
    sll  $t5, $t9, 6      # y * 64
    sll  $t6, $t8, 2      # x * 4
    add  $t3, $t5, $t6    # offset = y*64 + x*4
    add  $t3, $s7, $t3    # $t3 = final address
    sw   $t7, 0($t3)      # store color

skip_erase_block:
	addi $t4, $t4, 1
    j erase_col

next_erase_row:
    addi $t2, $t2, 2      # Next row (2 bytes)
    addi $t0, $t0, 1
    j erase_row
    
 get_eliminated_nub:
 	jr $ra
	
check_hitting_wall:
	# s0 contains the index of the piece we want to wall test
	# $a2 is the x coord
	# $a3 is the y coord
	# x cannot be 0 or 15 and
	# y cannot be 31
	li   $v1, 0           # Assume no collision
    move $t2, $s0         # $t2 points to piece base
    li   $t0, 0           # row index

check_wall_row:
    beq $t0, 4, trump_is_happy # no piece illegally crossed the wall
    lhu  $t1, 0($t2)      # get 16-bit row data
    li   $t4, 0           # column index

check_wall_inner_loop:
	beq $t4, 4, next_wall_row
	# test bit: leftmost is bit 3
    li   $t5, 3
    sub  $t5, $t5, $t4
    li   $t6, 1
    sllv $t6, $t6, $t5
    and  $t7, $t1, $t6
    beqz $t7, wall_skip_block   # skip if bit is 0 (not part of a block)
	
	# compute screen x = a2 + col, y = a3 + row
    add  $t8, $a2, $t4
    add  $t9, $a3, $t0

    # check if x == 31
    li   $t3, 31
    beq  $t8, $t3, wall_collision

    # check if y == 0 or y == 15
    li   $t3, 0
    beq  $t9, $t3, wall_collision
    li   $t3, 15
    beq  $t9, $t3, wall_collision
    
wall_skip_block:
    addi $t4, $t4, 1
    j check_wall_inner_loop

next_wall_row:
    addi $t2, $t2, 2      # next 2-byte row
    addi $t0, $t0, 1
    j check_wall_row

wall_collision:
    li   $v1, 1           # set collision
    jr   $ra

trump_is_happy:
    jr $ra

# This function rotates a piece 90 degrees clockwise
w_was_pressed:
	jal nap_time
	j after_keyboard_handled

# Tis function ratates a piece 90 degrees ccw
s_was_pressed:
	jal nap_time
	j after_keyboard_handled

after_keyboard_handled:
    b done
    # check for piece-piece collision
	# then gravity
	# check if any lines complete (hardest part)



nap_time:
	li $v0, 32
	syscall
	jr $ra
    
done: # debugging only
	li $v0, 10
	syscall
