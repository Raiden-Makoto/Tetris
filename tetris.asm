#####################################################################
# CSCB58 Summer 2025 Assembly Final Project - UTSC
# Name, Student Number, UTorID, official email
# Bitmap Display Configuration:
# - Unit width in pixels: 8 (update this as needed) 
# - Unit height in pixels: 8 (update this as needed)
# - Display width in pixels: 64 (update this as needed)
# - Display height in pixels: 128 (update this as needed)
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
	lw $t0, 0($t0)
	lw $t1, WALL_CLR
	# Start by drawing the walls
	# Our display is 64 wide by 128 height and each unit is 8 by 8
	# There are 8 columns and 16 rows
	
	li $t2, 0 # y = 0
	li $t3, 0  # x = 0 
draw_left_wall:
	mul $t4, $t2, 8 # skip this number of units to get to next row start
	add $t4, $t4, $t3 # redundant statement for x=0 but is here for clarity
	sll $t4, $t4, 2   # next word (= 2^2 bytes)
	add $t5, $t0, $t4 # actual address in display
	sw $t1, 0($t5) # draw the cell
	addi $t2, $t2, 1 # y += 1
	li $t6, 16 # we have 16 rows
	blt $t2 $t6, draw_left_wall # loop until wall is finished
	
	li $t2, 0 # y = 0
	li $t3 7 # same as above but now x = 7
draw_right_wall:
	mul $t4, $t2, 8 # skip this number of units to get to next row start
	add $t4, $t4, $t3 # redundant statement for x=0 but is here for clarity
	sll $t4, $t4, 2   # next word (= 2^2 bytes)
	add $t5, $t0, $t4 # actual address in display
	sw $t1, 0($t5) # draw the cell
	addi $t2, $t2, 1 # y += 1
	li $t6, 16 # we have 16 rows
	blt $t2 $t6, draw_right_wall # loop until wall is finished
	
	li $t2, 15 # y = 15
	li $t3, 0 # x = 0
draw_bottom_wall:
	mul $t4, $t2, 8 
	add  $t4, $t4, $t3     
	sll  $t4, $t4, 2 
    	add  $t5, $t0, $t4 
    	sw   $t1, 0($t5)
    	addi $t3, $t3, 1
    	li   $t6, 8 # we only have 8 columns this time
    	blt  $t3, $t6, draw_bottom_wall
    	
    	b done
	
    

game_loop:
	# 1a. Check if key has been pressed
    	# 1b. Check which key has been pressed
    	# 2a. Check for collisions
	# 2b. Update locations (paddle, ball)
	# 3. Draw the screen
	# 4. Sleep

    #5. Go back to 1
    b game_loop
    
done: # debugging only
	li $v0, 10
	syscall
