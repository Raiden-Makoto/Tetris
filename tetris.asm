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
# - Milestone current: 3
# - Milestone 1: Drew the three walls and a checkboard grid, spawns initial tetromino
# - Milestone 2: Movement (left, right, rotation and drop) added
# - Milestone 3: All collision detection added, and row clearing added
# - Milestone 4: 2 Easy, 1 Hard, need 1 more Easy
#
# Which approved features have been implemented?
# WE ARE GOING TO DO 4 EASY 2 HARD
# Easy Features: (4 easy)
# 1. Add sound effects for game intro, game over, hard drop and clearing row
# 2. Added game over screen, restart option, and play again option
# 3. Gravity (TODO)
# 4. Make sure that each tetromino type is a different colour (TODO/IP)
# Hard Features: (2 hard)
# 1. Implement full set of tetrominoes
# 2. Wall kick feature
# 
# How to play:
# A: move left
# D: move right
# W: rotate right
# S: move piece down manually
# space bar: drop piece
# Q: quit game
# R: restart (in the middle of the game)
# R: play again (available for 5 seconds after the game ends)
#
# Link to video demonstration for final submission:
# - (insert YouTube / MyMedia / other URL here). Make sure we can view it!
#
# Are you OK with us sharing the video with people outside course staff?
# - no
#
# Any additional information that the TA needs to know:
# - What's your tetris high score?
#
#####################################################################
# TODOS:
# 1: HF: map each piece to its corresponding color from original tetris
# 2: EF: add gravity
# 3: EF: increase gravity speed
# 
##############################################################################

.data
comma:   .asciiz ", "
newline: .asciiz "\n"

# debug for keyboard
msg_game_starting:	.asciiz "Game Starting\n"
msg_game_over: .asciiz "Ur kinda bad at ts game\n"
msg_gravity: .asciiz "Moving piece down\n"
msg_spawn_failed: .asciiz "Failed to spawn piece. Ending game\n"
msg_rows_full: .asciiz "Full row found at y="

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

# Colors
#RED:   .word 0x00FF0000
#GREEN: .word 0x0000FF00
#DARK_BLUE:  .word 0x000000FF
#LITE_BLUE: .word 0x00ADD8E6
#PURPLE: .word 0x00800080
#ORANGE: .word 0x00FFA500
#YELLOW: .word 0x00FFFF00

# Piece states for rotation
current_piece: .space 8
rotated_piece: .space 8
grid_below: .space 8 # contains the 4x4 grid one unit under the piece
grid_left: .space 8 # containes the 4x4 grid one unit to the left
grid_right: .space 8 # contains the 4x4 grid one unit to the right
# used for collision checks and reset after

# game over bozo
g_piece: .half 0x000F, 0x0008, 0x0008, 0x0009, 0x0009, 0x000F
a_piece: .half 0x0006, 0x0009, 0x0009, 0x000F, 0x0009, 0x0009  
m_piece: .half 0x0009, 0x000F, 0x0009, 0x0009, 0x0009, 0x0009
e_piece: .half 0x000F, 0x0008, 0x000F, 0x0008, 0x0008, 0x000F
o_piece: .half 0x000F, 0x0009, 0x0009, 0x0009, 0x0009, 0x000F
v_piece: .half 0x0009, 0x0009, 0x0009, 0x0009, 0x0006, 0x0006
r_piece: .half 0x000E, 0x0009, 0x000E, 0x000C, 0x000A, 0x0009

# Random ahh notes for goofy ahh sounds
.eqv F6 89
.eqv Eflat6 87
.eqv Csharp6 85
.eqv Bflat5 82
.eqv Gsharp5 80
.eqv G5 79
.eqv Fsharp5 78
.eqv F5 77
.eqv Eflat5 75
.eqv D5 74
.eqv Dflat5 73
.eqv C5 72
.eqv B4 71
.eqv Bflat4 70
.eqv Aflat4 68
.eqv G4 67
.eqv Fsharp4 66
.eqv F4 65
.eqv Eflat4 63
.eqv D4 62
.eqv Fsharp3 54

##############################################################################
# Mutable Data
##############################################################################
# S7 is the DISPLAY
# S6 is the keyboard
# S5 is the gravity counter
# S4 stores the grid to the left OR right
# S3 stores the grid below
# S2 will store the rotated piece
# S1 stores the piece color
# S0 is the pointer to the piece
##############################################################################
# Code
##############################################################################
.text
.globl main

# Run the very crappy Tetris game.
main:
    # initialize display, keyboard
    la   $t0, ADDR_DSPL
    lw   $s7, 0($t0)
    la   $s6, ADDR_KBRD
    lw   $s6, 0($s6)
    la   $s3, grid_below
    # draw background and walls
    jal  draw_checkerboard
    jal  build_a_wall
    # “Game Starting” message
    li   $v0, 4
    la   $a0, msg_game_starting
    syscall
    jal  play_starting_sound # start up music (def not cr intro)
    li   $a2, 6
    li   $a3, 0 # reset these for piece spawn
    jal  random_bs_go
    jal  draw_pc_main
    j    game_loop

draw_checkerboard: # draws alternating darka dn light gray squares
    li   $t0, 0  # y from 0 to 31
    
y_loop:
    li   $t1, 0  # x from 0 to 15
    
x_loop:
    # Calculate checkerboard pattern (x + y) % 2
    add  $t2, $t1, $t0
    andi $t2, $t2, 1   
    # Calculate address: $s7 + (y*64 + x*4)
    sll  $t3, $t0, 6  # y * 64 (16 units/row * 4 bytes/unit)
    sll  $t4, $t1, 2 # x * 4
    add  $t5, $t3, $t4   # offset
    add  $t6, $s7, $t5  # Final address ($s7 + offset)
    # Set colors
    beqz $t2, dark_unit
    li   $t7, 0x00333333 # Light gray
    j    store_color
    
dark_unit:
    li   $t7, 0x00222222 # Dark gray
    
store_color:
    sw   $t7, 0($t6) # Store color to display memory
    addi $t1, $t1, 1
    blt  $t1, 16, x_loop # 16 units wide (128/8)
    addi $t0, $t0, 1
    blt  $t0, 32, y_loop  # 32 units tall (256/8)  
    jr   $ra   

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
	jr   $ra 
	
# loads a random piece and color and stores the piece in current_piece
random_bs_go:
	# — clear current_piece to all zeros
    la   $t0, current_piece
    sw   $zero, 0($t0)    # bytes 0–3 → 0
    sw   $zero, 4($t0)    # bytes 4–7 → 0
    li   $v0, 42
    li   $a1, 700
    syscall
    remu $t1, $a0, 7
    la   $t2, all_pieces
    li   $t3, 8
    mul  $t4, $t1, $t3
    add  $s0, $t2, $t4     # $s0 = pointer to random piece
    li   $v0, 42
    li   $a1, 777
    syscall
    remu $t5, $a0, 7   # $t5 = 0…6
    beqz  $t5, pick_red
    li    $t6, 1
    beq   $t5, $t6, pick_green
    li    $t6, 2
    beq   $t5, $t6, pick_blue
    li    $t6, 3
    beq   $t5, $t6, pick_lite_blue
    li    $t6, 4
    beq   $t5, $t6, pick_purple
    li    $t6, 5
    beq   $t5, $t6, pick_orange
    j pick_yellow

pick_red:
    li   $s1, 0x00FF0000   # RED
    j    pick_done

pick_green:
    li   $s1, 0x0000FF00   # GREEN
    j    pick_done

pick_blue:
    li   $s1, 0x000000FF   # DARK_BLUE
    j    pick_done

pick_lite_blue:
    li   $s1, 0x00ADD8E6   # LITE_BLUE
    j    pick_done

pick_purple:
    li   $s1, 0x00800080   # PURPLE
    j    pick_done

pick_orange:
    li   $s1, 0x00FFA500   # ORANGE
    j    pick_done

pick_yellow:
    li   $s1, 0x00FFFF00   # YELLOW

pick_done:
    la   $t0, current_piece
    li   $t1, 0

copy_piece_loop:
    beq  $t1, 8, done_copying  # 4 halfwords = 8 bytes
    lhu  $t2, 0($s0)
    sh   $t2, 0($t0)
    addi $s0, $s0, 2
    addi $t0, $t0, 2
    addi $t1, $t1, 2
    j    copy_piece_loop

done_copying:
	la   $s0, current_piece # oops
    li   $a2, 6
    li   $a3, 0
    jr   $ra

draw_pc_main:
    move $t2, $s0
    li   $t0, 0

draw_pc_row:
    beq  $t0, 4, done_drawing
    lhu  $t1, 0($t2)
    li   $t4, 0

draw_pc_inner:
    beq  $t4, 4, next_row
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
    j    draw_pc_inner

next_row:
    addi $t2, $t2, 2
    addi $t0, $t0, 1
    j    draw_pc_row

done_drawing:
    jr $ra

game_loop:
    lw   $t9, 0($s6)   # keyboard
    andi $t9, $t9, 1  # check if theres something thjere
    beqz $t9, sleep  # not ready, keep waiting
    j    process_key   # key ready

sleep: # cs students don't do this
    li   $a0, 50
    jal  nap_time    # zzzzzzzzzz *snores*
    addi $s5, $s5, 50
    blt  $s5, 1900, game_loop  # skip gravity if wait time under 1900ms  (100ms for gravity)
    # user has not pressed anything for 2 seconds
    #jal gravity # gravity the piece down
    # continue the game loop
    j    game_loop

process_key:
    lw   $a0, 4($s6)  # load key code
    beq  $a0, 0x20, hard_drop # spacebar pressed
    beq  $a0, 0x61, a_was_pressed   # 'a' pressed
    beq  $a0, 0x64, d_was_pressed   # 'd' pressed
    beq  $a0, 0x72, r_was_pressed   # 'r' pressed
    beq  $a0, 0x73, s_was_pressed   # 's' pressed
    beq  $a0, 0x77, w_was_pressed   # 'w' pressed
    beq  $a0, 0x71, done    # 'q' quit
    # Reset keyboard status for next keypress
    sw   $zero, 0($s6)
    j    game_loop
    
a_was_pressed:
    jal  erase_pc_main # erase the piece so we don't self collide
    jal  check_left_collision # check if we can move left part 2
    bnez $v1, you_cant_move_left # if yes, do nothing and go back to game
    #jal erase_pc_main # erase the piece
    addi $a2, $a2, -1
    jal  clear_grid_left # clear the grid
    jal  draw_pc_main # redraws the piece 1 left
    addi $s5, $s5, 100 # add gravity delay
    j    after_keyboard_handled # continue after key press

you_cant_move_left:
	jal  clear_grid_left
	jal  draw_pc_main # redraw the piece 
	j    after_keyboard_handled # do nothing and continue game

check_left_collision:
    addi $sp, $sp, -8  # make space for two words
    sw   $ra, 4($sp)   # save return address
    li   $v1, 0    # assume no collision
    jal  get_grid_left 
    # load piece rows
    lhu  $t0, 0($s0)
    lhu  $t1, 2($s0)
    lhu  $t2, 4($s0)
    lhu  $t3, 6($s0)
    # load grid_left mask
    la   $t8, grid_left
    lhu  $t4, 0($t8)
    lhu  $t5, 2($t8)
    lhu  $t6, 4($t8)
    lhu  $t7, 6($t8)

    # AND/OR overlap test
    and  $t9, $t0, $t4
    and  $t8, $t1, $t5
    or   $t9, $t9, $t8
    and  $t8, $t2, $t6
    or   $t9, $t9, $t8
    and  $t8, $t3, $t7
    or   $t9, $t9, $t8
    bnez $t9, clc_blocked
    # restore $ra & $sp, then return to caler
    lw   $ra, 4($sp)
    addi $sp, $sp, 8
    jr   $ra

clc_blocked:
    li   $v1, 1
    lw   $ra, 4($sp)
    addi $sp, $sp, 8
    jr   $ra

get_grid_left:
    la    $t0, grid_left
    li    $t1, 0 

gl_row_loop:
    beq   $t1, 4, gl_done 
    li    $t2, 0 
    li    $t3, 0 

gl_col_loop:
    beq   $t3, 4, gl_store 
    addi  $t4, $a2, -1    
    add   $t4, $t4, $t3  
    add   $t5, $a3, $t1
    # if X < 0 or X >= 16 set as occupied so we don't fall off the map
    bltz  $t4, gl_setbit
    li    $t6, 16
    bge   $t4, $t6, gl_setbit
    # load pixel at (X,Y)
    mul   $t7, $t5, 16    
    add   $t7, $t7, $t4    
    sll   $t7, $t7, 2  
    add   $t7, $s7, $t7   
    lw    $t8, 0($t7)
    # skip if empty/checkerboard
    li    $t6, 0x00222222
    beq   $t8, $t6, gl_nextcol
    li    $t6, 0x00333333
    beq   $t8, $t6, gl_nextcol

gl_setbit:
    li    $t6, 3
    sub   $t6, $t6, $t3
    li    $t7, 1
    sllv  $t7, $t7, $t6
    or    $t2, $t2, $t7

gl_nextcol:
    addi  $t3, $t3, 1
    j gl_col_loop

gl_store:
    sh    $t2, 0($t0)   # store mask
    addi  $t0, $t0, 2    # advance pointer
    addi  $t1, $t1, 1   # next row
    j gl_row_loop

gl_done:
    jr    $ra

clear_grid_left:
    la   $t0, grid_left   # pointer to grid_left
    sh   $zero, 0($t0)  # clear row 0
    sh   $zero, 2($t0)  # clear row 1
    sh   $zero, 4($t0)  # clear row 2
    sh   $zero, 6($t0)  # clear row 3
    jr   $ra

d_was_pressed:
    jal  erase_pc_main # erase the piece so we don't self collide
    jal  check_right_collision # check if we can move left part 2
    bnez $v1, you_cant_move_right # if yes, do nothing and go back to game
    #jal erase_pc_main # erase the piece
    addi $a2, $a2, 1
    jal  clear_grid_right # clear the grid
    jal  draw_pc_main # redraws the piece 1 unit left
     addi $s5, $s5, 100 # add gravity delay
    j    after_keyboard_handled # continue after key press

you_cant_move_right:
	jal  clear_grid_right
	jal  draw_pc_main # redraw the piece 
	j    after_keyboard_handled # do nothing and continue game

clear_grid_right:
    la   $t0, grid_right   # pointer to grid_right buffer
    sh   $zero, 0($t0)  # clear row 0
    sh   $zero, 2($t0)  # clear row 1
    sh   $zero, 4($t0)  # clear row 2
    sh   $zero, 6($t0)  # clear row 3
    jr   $ra

get_grid_right:
    la    $t0, grid_right  # points to grid_right
    li    $t1, 0    # row index i = 0

gr_row_loop:
    beq   $t1, 4, gr_done   
    li    $t2, 0   
    li    $t3, 0  

gr_col_loop:
    beq   $t3, 4, gr_store
    addi  $t4, $a2, 1   
    add   $t4, $t4, $t3  
    add   $t5, $a3, $t1
    bltz  $t4, gr_setbit
    li    $t6, 16
    bge   $t4, $t6, gr_setbit
    mul   $t7, $t5, 16    
    add   $t7, $t7, $t4   
    sll   $t7, $t7, 2 
    add   $t7, $s7, $t7
    lw    $t8, 0($t7)
    # skip if checkerboard/empty
    li    $t6, 0x00222222
    beq   $t8, $t6, gr_nextcol
    li    $t6, 0x00333333
    beq   $t8, $t6, gr_nextcol

gr_setbit:
    li    $t6, 3
    sub   $t6, $t6, $t3 
    li    $t7, 1
    sllv  $t7, $t7, $t6
    or    $t2, $t2, $t7

gr_nextcol:
    addi  $t3, $t3, 1
    j gr_col_loop

gr_store:
    sh    $t2, 0($t0)  
    addi  $t0, $t0, 2 
    addi  $t1, $t1, 1
    j gr_row_loop

gr_done:
    jr    $ra

check_right_collision:
    addi $sp, $sp, -8 
    sw   $ra, 4($sp)  
    li   $v1, 0
    jal  clear_grid_right
    jal  get_grid_right 
    lhu  $t0, 0($s0)
    lhu  $t1, 2($s0)
    lhu  $t2, 4($s0)
    lhu  $t3, 6($s0)
    la   $t7, grid_right
    lhu  $t4, 0($t7)
    lhu  $t5, 2($t7)
    lhu  $t6, 4($t7)
    lhu  $t7, 6($t7)
    and  $t9, $t0, $t4
    and  $t8, $t1, $t5
    or   $t9, $t9, $t8
    and  $t8, $t2, $t6
    or   $t9, $t9, $t8
    and  $t8, $t3, $t7
    or   $t9, $t9, $t8
    bnez $t9, crc_blocked
    lw   $ra, 4($sp)
    addi $sp, $sp, 8
    jr   $ra

crc_blocked:
    li   $v1, 1
    lw   $ra, 4($sp)
    addi $sp, $sp, 8
    jr   $ra
   
# This function erases a piece and
# reverts back the checkerboard pattern that was originally there
# This function works as intended
erase_pc_main:
	# $s0 = pointer to piece
	# $a2 = x, $a3 = y
	li   $t0, 0    # row index
	move $t2, $s0    # piece pointer
	
erase_row:
	beq  $t0, 4, get_eliminated_nub
	lhu  $t1, 0($t2)  
    li   $t4, 0 
    
erase_col:
	beq $t4, 4, next_erase_row
    li   $t5, 3
    sub  $t5, $t5, $t4
    li   $t6, 1
    sllv $t6, $t6, $t5
    and  $t7, $t1, $t6
    beqz $t7, skip_erase_block 
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
    sll  $t5, $t9, 6  
    sll  $t6, $t8, 2  
    add  $t3, $t5, $t6   
    add  $t3, $s7, $t3   
    sw   $t7, 0($t3) 

skip_erase_block:
	addi $t4, $t4, 1
    j erase_col

next_erase_row:
    addi $t2, $t2, 2 
    addi $t0, $t0, 1
    j erase_row
    
 get_eliminated_nub:
 	jr $ra
	
check_hitting_wall:
    # s0 contains the index of the piece we want to wall test
    # $a2 is the x coord (0 = left wall, 16 = right wall)
    # $a3 is the y coord (31 = bottom wall)
    # Returns: $v1 = 1 if collision, 0 otherwise
    li   $v1, 0   # Assume no collision
    move $t2, $s0     # $t2 points to piece base
    li   $t0, 0   # row index

check_wall_row:
    beq  $t0, 4, trump_is_happy # no piece illegally crossed the wall
    lhu  $t1, 0($t2)  # get 16-bit row data
    li   $t4, 0   # column index

check_wall_inner_loop:
    beq $t4, 4, next_wall_row
    # test bit: leftmost is bit 3
    li   $t5, 3
    sub  $t5, $t5, $t4    # $t5 = 3 - column
    li   $t6, 1
    sllv $t6, $t6, $t5    # create bitmask
    and  $t7, $t1, $t6
    beqz $t7, wall_skip_block   # skip if bit is 0
    
    # compute screen coordinates
    add  $t8, $a2, $t4    # x = a2 + col
    add  $t9, $a3, $t0    # y = a3 + row

    # check x boundaries (0 or 16)
    beqz $t8, wall_collision    # x = 0 (left wall)
    li   $t3, 16
    beq  $t8, $t3, wall_collision # x = 16 (right wall)
    
    # check y boundary (31)
    li   $t3, 31
    beq  $t9, $t3, wall_collision # y = 31 (bottom wall)
    
wall_skip_block:
    addi $t4, $t4, 1  # next column
    j    check_wall_inner_loop

next_wall_row:
    addi $t2, $t2, 2  # next 2-byte row
    addi $t0, $t0, 1  # next row
    j    check_wall_row

wall_collision:
    li   $v1, 1
    jr   $ra

trump_is_happy:
    li   $v1, 0  # ensure no collision
    jr   $ra

# This function rotates a piece 90 degrees clockwise
w_was_pressed:
    # rotate the piece here
    jal check_if_opc
	bnez $v0, after_keyboard_handled
    # if its not the o piece
    # srs wall-kicks may be needed before we can draw
    # the piece or reject the rotation
    la $s2, rotated_piece
    jal rotate_piece_cw
    # remove the old piece from the board before moving new piece in
	jal erase_pc_main 
    # Copy rotated_piece to current_piece, assuming rotation is valid
	lhu $t0, 0($s2)
	lhu $t1, 2($s2)
	lhu $t2, 4($s2)
	lhu $t3, 6($s2)
	sh $t0, 0($s0)
	sh $t1, 2($s0)
	sh $t2, 4($s0)
	sh $t3, 6($s0)
	# clear the rotated_piece for next rotation
	sh $zero, 0($s2)
	sh $zero, 2($s2)
	sh $zero, 4($s2)
	sh $zero, 6($s2)
	jal draw_pc_main # draw the rotated piece
	#no need to change $a2 or $a3

	j after_keyboard_handled # keep goin

rotate_piece_cw:
	# $s0 points to current piece (in current_piece .space 8)
    # $s2 points to rotated data (in rotated_piece .space 8)
    # $t0-$t7 as temp registers
    # The bit at (i,j) goes to (3-j, i)
    # Load all 4 rows at once cus I'm lazy and we're hardcoding
    lhu $t0, 0($s0)   # Row 0
    lhu $t1, 2($s0)   # Row 1 
    lhu $t2, 4($s0)   # Row 2
    lhu $t3, 6($s0)   # Row 3
    # Manually rotate the columns because I'm sick and tired of this bullshit
    # Rotated Row 0 = Original Column 3 (bits from bottom to top)
    andi $t4, $t0, 0x0008   # Row 0, bit 3 (value 8)
    srl $t4, $t4, 3     # Move to bit 0
    andi $t5, $t1, 0x0008   # Row 1, bit 3
    srl $t5, $t5, 2     # Move to bit 1
    andi $t6, $t2, 0x0008   # Row 2, bit 3  
    srl $t6, $t6, 1     # Move to bit 2
    andi $t7, $t3, 0x0008   # Row 3, bit 3
    or $t4, $t4, $t5    # Combine bits
    or $t4, $t4, $t6
    or $t4, $t4, $t7
    sh $t4, 0($s2)  # Store rotated row 0
    # Rotated Row 1 = Original Column 2 (bits from bottom to top)
    andi $t4, $t0, 0x0004  # Row 0, bit 2 (value 4)
    srl $t4, $t4, 2     # Move to bit 0
    andi $t5, $t1, 0x0004   # Row 1, bit 2
    srl $t5, $t5, 1     # Move to bit 1
    andi $t6, $t2, 0x0004   # Row 2, bit 2
    andi $t7, $t3, 0x0004   # Row 3, bit 2
    sll $t7, $t7, 1     # Move to bit 3
    or $t4, $t4, $t5
    or $t4, $t4, $t6
    or $t4, $t4, $t7
    sh $t4, 2($s2)  # Store rotated row 1
    # Rotated Row 2 = Original Column 1 (bits from bottom to top)
    andi $t4, $t0, 0x0002  # Row 0, bit 1 (value 2)
    srl $t4, $t4, 1     # Move to bit 0
    andi $t5, $t1, 0x0002   # Row 1, bit 1
    andi $t6, $t2, 0x0002   # Row 2, bit 1
    sll $t6, $t6, 1     # Move to bit 2
    andi $t7, $t3, 0x0002   # Row 3, bit 1
    sll $t7, $t7, 2     # Move to bit 3
    or $t4, $t4, $t5
    or $t4, $t4, $t6
    or $t4, $t4, $t7
    sh $t4, 4($s2) # Store rotated row 2
    # Rotated Row 3 = Original Column 0 (bits from bottom to top)
    andi $t4, $t0, 0x0001  # Row 0, bit 0 (value 1)
    andi $t5, $t1, 0x0001   # Row 1, bit 0
    sll $t5, $t5, 1     # Move to bit 1
    andi $t6, $t2, 0x0001   # Row 2, bit 0
    sll $t6, $t6, 2     # Move to bit 2
    andi $t7, $t3, 0x0001   # Row 3, bit 0
    sll $t7, $t7, 3     # Move to bit 3
    or $t4, $t4, $t5
    or $t4, $t4, $t6
    or $t4, $t4, $t7
    sh $t4, 6($s2) # Store rotated row 3
    jr $ra     

s_was_pressed:              # moves the piece down by one row manually
    jal erase_pc_main       # erase current piece so it can be redrawn
    jal get_grid_below      
    jal check_downward_collision # see if its blocked underneath, stored in $v1
    jal clear_grid_below    # clear out the buffer for next keypress
    bnez $v1, lock_and_spawn   # if collision, generate new piece
    addi $a3, $a3, 1        # no collision then move piece down one row
    jal draw_pc_main
    j after_keyboard_handled
    
lock_and_spawn:
    jal hd_collision  
    j after_keyboard_handled

# Input:  $s0 points to current piece (4 half-words)
# Output: $v0 = 1 if O piece, else 0
# easier to check for o piece and skip rotation than to rotate it
check_if_opc:
    lhu $t0, 0($s0) # Row 0
    lhu $t1, 2($s0)  # Row 1
    lhu $t2, 4($s0) # Row 2
    lhu $t3, 6($s0)  # Row 3
    li  $t4, 0x0006    # Expected value for row 0 and 1
    li  $t5, 0x0000  # Expected value for row 2 and 3
    # expected value =  b52 refernece!?!?!?
    xor $t6, $t0, $t4 # $t6 = 0 if match
    xor $t7, $t1, $t4
    or  $t6, $t6, $t7
    xor $t7, $t2, $t5
    or  $t6, $t6, $t7
    xor $t7, $t3, $t5
    or  $t6, $t6, $t7 # $t6 = 0 only if all rows match
    li  $v0, 0    # Default: not O-piece
    beqz $t6, is_opiece
    jr   $ra

is_opiece:
    li $v0, 1
    jr $ra

# i got tired of trying to align everything to look neat
# why tf doesnt mars have keyboard shortcuts bruh
# ts pmo sm icl
r_was_pressed:
	# Reset every single variable
    li $s5, 0   
    li $a2, 6   
    li $a3, 0 
    la $t0, current_piece
    sw $zero, 0($t0)
    sw $zero, 4($t0)
    la $t0, rotated_piece
    sw $zero, 0($t0)
    sw $zero, 4($t0)
    # Clear screen (very important)
    jal draw_checkerboard
    jal build_a_wall
    jal clear_grid_left
    jal clear_grid_right
    jal clear_grid_below
    jal windows_startup # this sound to signal game reset
    # Generate a new piece
    jal random_bs_go
    jal draw_pc_main
    # Reset keyboard state and restart game
    j   after_keyboard_handled

# this function simulates my grades
# (i.e it drops pieces to the ground)
hard_drop:
    jal erase_pc_main  # remove piece from screen
    j hd_loop

hd_loop:
	li  $v1, 0
    jal get_grid_below  # fill grid_below with cells below the piece
    jal check_downward_collision
    jal clear_grid_below    # reset buffer for next iteration
    bnez $v1, hd_collision  # if collision detected, stop
    # No collision so move piece down by one
    addi $a3, $a3, 1
    j    hd_loop   # keep dropping

hd_collision:
    #addi $a3, $a3, -1   # comment this out because:
    # when we check for collisions, we check if we can move the piece down one row
    # if we can't, we need to lock the piece where it is currently
    # subtracting 1 from y will make it go up a row, which is bad
    jal draw_pc_main    # draw permanently at final position
    li  $a0, 200 # wait before clearing rows
    jal nap_time
    # row clearing crap
    jal mac_startup_sound # play this every time a piece hard drops
    addi $s5, $s5, 800 # duration of waiting + sfx to gravity counter + 50ms delay
    jal clear_completed_lines
    # spawn the next piece
    li $a0, 200
    jal nap_time
    # get a new random piece and reset x,y
    jal check_top2rows_empty
    bnez $v1, piece_died # end the game, we can't spawn
    # otherwise we can spawn the piece
    li $a2, 6
    li $a3, 0
    jal random_bs_go
    jal draw_pc_main
    j after_keyboard_handled
    
clear_completed_lines:
    addi  $sp, $sp, -4
    sw    $ra, 0($sp)

cc_loop:
    jal   count_full_rows # $v1 contains y of a full row, or –1 if none
    bltz  $v1, cc_done   # if $v1 < 0, no more full rows (off the map 
    jal   zap_line
    li $a0, 444 # sleep for a few ms to prevent sfx from clashing
    jal nap_time
	jal mario_lvlup
	addi $s5, $s5, 200
    j   cc_loop  # repeat until no full rows or off the map

cc_done:
    lw $ra, 0($sp)
    addi  $sp, $sp, 4
    jr    $ra

# check_top_two_rows_empty
# Sets v1=1 and returns if any pixel in y=0 or y=1 is not checkerboard;
# else v1=0.
check_top2rows_empty:
    li   $v1, 0   # assume clear
    li   $t0, 6  # col = 6, we start spawning here

scan_cols:
    bge  $t0, 10, top2rows_clear # done after col 10 since 4x4 grid
    sll  $t1, $t0, 2  
    add  $t2, $s7, $t1 
    lw   $t3, 0($t2)
    li   $t4, 0x00222222
    beq  $t3, $t4, chk_row1
    li   $t4, 0x00333333
    beq  $t3, $t4, chk_row1
    li   $v1, 1
    jr   $ra

chk_row1:
    addi $t1, $t1, 64  
    add  $t2, $s7, $t1
    lw   $t3, 0($t2)
    li   $t4, 0x00222222
    beq  $t3, $t4, next_col
    li   $t4, 0x00333333
    beq  $t3, $t4, next_col
    li   $v1, 1
    jr   $ra

next_col:
    addi $t0, $t0, 1
    j    scan_cols

top2rows_clear:
    jr   $ra

check_downward_collision:
	li $v1, 0
	
	lhu $t0, 0($s0) # piece row 0
	lhu $t1, 2($s0)  # piece row 1
	lhu $t2, 4($s0)    # piece row 2
	lhu $t3, 6($s0)   # piece row
	lhu $t4, 0($s3)    # grid_below row 0
	lhu $t5, 2($s3)    # grid_below row 1
	lhu $t6, 4($s3)    # grid_below row 2
	lhu $t7, 6($s3)    # grid_below row 3
	and $t8, $t0, $t4   # check row 0
	and $t9, $t1, $t5  # check row 1
	or  $t8, $t8, $t9
	and $t9, $t2, $t6   # check row 2
	or  $t8, $t8, $t9
	and $t9, $t3, $t7  # check row 3
	or  $t8, $t8, $t9
	beqz $t8, nothing_below
	li $v1, 1    # big boom boom here
	jr $ra

nothing_below:
	li $v1, 0
	jr $ra

# being unaligned is kinda ugly
# tf am i lookin at	
get_grid_below:
    move $t0, $s3   
    li   $t1, 0  

gb_row_loop:
    beq  $t1, 4, gb_done
    addi $t5, $a3, 1
    add  $t5, $t5, $t1  
    li   $t6, 31
    bge  $t5, $t6, gb_full_row
    li   $t3, 0   
    li   $t2, 0 

gb_col_loop:
    beq  $t2, 4, gb_store_row
    add  $t4, $a2, $t2
    mul  $t7, $t5, 16
    add  $t7, $t7, $t4
    sll  $t7, $t7, 2
    add  $t8, $s7, $t7
    lw   $t9, 0($t8)
    # if non‑checkerboard
    li   $t6, 0x00222222
    beq  $t9, $t6, gb_next_col
    li   $t6, 0x00333333
    beq  $t9, $t6, gb_next_col
    beqz $t9, gb_next_col
    li   $t6, 3
    sub  $t6, $t6, $t2
    li   $t7, 1
    sllv $t7, $t7, $t6
    or   $t3, $t3, $t7

gb_next_col:
    addi $t2, $t2, 1
    j    gb_col_loop

gb_full_row:
    li   $t3, 0x000F 

gb_store_row:
    sh   $t3, 0($t0)
    addi $t0, $t0, 2
    addi $t1, $t1, 1
    j    gb_row_loop

gb_done:
    jr   $ra
    
clear_grid_below:
    la   $t0, grid_below
    sh   $zero, 0($t0)
    sh   $zero, 2($t0)
    sh   $zero, 4($t0)
    sh   $zero, 6($t0)
    jr $ra

zap_line:
    addi  $sp, $sp, -4   
    sw    $ra, 0($sp)
    move  $t9, $v1    
    li    $t0, 1 
    
clear_row_loop:
    bgt   $t0, 14, everyday_im_shufflin
    add   $t1, $t9, $t0
    andi  $t1, $t1, 1
    beqz  $t1, clear_dark
    li    $t3, 0x00333333 
    j clear_store
    
clear_dark:
    li    $t3, 0x00222222
    
clear_store:
    sll   $t2, $t9, 4  
    add   $t2, $t2, $t0   
    sll   $t2, $t2, 2 
    add   $t2, $s7, $t2
    sw    $t3, 0($t2)
    addi  $t0, $t0, 1
    j clear_row_loop

everyday_im_shufflin:
    addi  $t9, $t9, -1 
    
onehopthistime:
    bltz  $t9, fill_top_rows 
    li    $t0, 1 
    
takeitbacknowyo:
    bgt   $t0, 14, dec_shift_row
    sll   $t2, $t9, 4
    add   $t2, $t2, $t0
    sll   $t2, $t2, 2
    add   $t2, $s7, $t2
    lw    $t3, 0($t2)
    li    $t4, 0x00222222
    beq   $t3, $t4, set_light
    li    $t4, 0x00333333
    beq   $t3, $t4, set_dark
    j write_pixel
    
set_light:
    li    $t3, 0x00333333
    j write_pixel
    
set_dark:
    li    $t3, 0x00222222
    
write_pixel:
    addi  $t5, $t9, 1
    sll   $t6, $t5, 4
    add   $t6, $t6, $t0
    sll   $t6, $t6, 2
    add   $t6, $s7, $t6
    sw    $t3, 0($t6)
    addi  $t0, $t0, 1
    j takeitbacknowyo
    
dec_shift_row:
    addi  $t9, $t9, -1
    j onehopthistime

fill_top_rows:
    li    $t0, 1
    
fill_top_loop:
    bgt   $t0, 14, done_shift
    andi  $t1, $t0, 1  
    beqz  $t1, fill_dark
    li    $t3, 0x00333333
    j fill_store
    
fill_dark:
    li    $t3, 0x00222222

# i love when i need to make 1265367123 functions     
# to do the same thing
# because 1 var changed and
# the loops are different
# assembly sucks python goated
fill_store:
    sll   $t2, $t0, 2
    add   $t2, $s7, $t2
    sw    $t3, 0($t2)
    addi  $t0, $t0, 1
    j fill_top_loop

done_shift:
    lw    $ra, 0($sp)
    addi  $sp, $sp, 4
    jr    $ra

count_full_rows:
    li   $v1, -1  # default: no full row found
    li   $t9, 30  # start at bottom playable row y=30

scan_next_row:
    bltz $t9, cfr_done  
    li   $t0, 1   
    li   $t8, 0 

cfr_scan_cols:
    bgt  $t0, 14, check_full 
    sll  $t2, $t9, 4 
    add  $t2, $t2, $t0   
    sll  $t2, $t2, 2  
    add  $t2, $s7, $t2  
    lw   $t3, 0($t2) 
    li   $t4, 0x00222222
    beq  $t3, $t4, cfr_next_col
    li   $t4, 0x00333333
    beq  $t3, $t4, cfr_next_col
    addi $t8, $t8, 1 

cfr_next_col:
    addi $t0, $t0, 1 
    j    cfr_scan_cols

check_full:
    li   $t4, 14
    bne  $t8, $t4, hogrider
    move $v1, $t9
    j cfr_done

hogrider:
    addi $t9, $t9, -1
    j    scan_next_row

cfr_done:
	li $v0, 4
	la $a0, msg_rows_full
	syscall
	li $v0, 1
	move $a0, $v1
	syscall
	li $v0, 4
	la $a0, newline
	syscall
    jr   $ra

# FINAL FUNCTIONS: MUST GO AT BOTTOM!
after_keyboard_handled:
	sw $zero, 0($s6) # reset the keyboard and go back to main loop
	# check the gravity timer, and apply if needed
	#blt $s5, 
	# this ensures the user can get their commands in before gravity applies
    j game_loop

nap_time:
	li $v0, 32
	syscall
	jr $ra
  
done:
	# draw the game over screen
	li $v0, 4
	la $a0, msg_game_over
	syscall
	# clear the annoying corner
	li $t0, 0x00000000 # black pixel

    # Row 0 (y = 0)
    sb $t0, 0($s7)
    sb $t0, 1($s7)
    sb $t0, 2($s7)
    sb $t0, 3($s7)
    sb $t0, 4($s7)
    sb $t0, 5($s7)
    sb $t0, 6($s7)
    sb $t0, 7($s7)

    # Row 1 (y = 1): offset = 128
    sb $t0, 128($s7)
    sb $t0, 129($s7)
    sb $t0, 130($s7)
    sb $t0, 131($s7)
    sb $t0, 132($s7)
    sb $t0, 133($s7)
    sb $t0, 134($s7)
    sb $t0, 135($s7)

    # Row 2 (y = 2): offset = 256
    sb $t0, 256($s7)
    sb $t0, 257($s7)
    sb $t0, 258($s7)
    sb $t0, 259($s7)
    sb $t0, 260($s7)
    sb $t0, 261($s7)
    sb $t0, 262($s7)
    sb $t0, 263($s7)

    # Row 3 (y = 3): offset = 384
    sb $t0, 384($s7)
    sb $t0, 385($s7)
    sb $t0, 386($s7)
    sb $t0, 387($s7)
    sb $t0, 388($s7)
    sb $t0, 389($s7)
    sb $t0, 390($s7)
    sb $t0, 391($s7)

    # Row 4 (y = 4): offset = 512
    sb $t0, 512($s7)
    sb $t0, 513($s7)
    sb $t0, 514($s7)
    sb $t0, 515($s7)
    sb $t0, 516($s7)
    sb $t0, 517($s7)
    sb $t0, 518($s7)
    sb $t0, 519($s7)

    # Row 5 (y = 5): offset = 640
    sb $t0, 640($s7)
    sb $t0, 641($s7)
    sb $t0, 642($s7)
    sb $t0, 643($s7)
    sb $t0, 644($s7)
    sb $t0, 645($s7)
    sb $t0, 646($s7)
    sb $t0, 647($s7)

    # Row 6 (y = 6): offset = 768
    sb $t0, 768($s7)
    sb $t0, 769($s7)
    sb $t0, 770($s7)
    sb $t0, 771($s7)
    sb $t0, 772($s7)
    sb $t0, 773($s7)
    sb $t0, 774($s7)
    sb $t0, 775($s7)

    # Row 7 (y = 7): offset = 896
    sb $t0, 896($s7)
    sb $t0, 897($s7)
    sb $t0, 898($s7)
    sb $t0, 899($s7)
    sb $t0, 900($s7)
    sb $t0, 901($s7)
    sb $t0, 902($s7)
    sb $t0, 903($s7)
	
	# everything else
	li $a2, 0
	li $a3, 0
	la   $t0, all_pieces    # base address of pieces
	addiu $s0, $t0, 8  # offset to O piece
	li   $s1, 0x00000000   # black color
	li   $t2, 0    # y position in units

clear_loop:
    # Exit if y > 31
    li   $t0, 32
    bge  $a3, $t0, game_over_yay
    # Draw black O piece at (x = $a2, y = $a3)
    la   $a0, O     # O piece address
    jal  draw_pc_main
    li   $t1, 16
    blt  $a2, $t1, continue_row
    li    $a2, 0
    addiu $a3, $a3, 2
    j clear_loop

continue_row:
    addiu $a2, $a2, 2 
    j clear_loop

gmovr_draw_pc_main:
    move $t2, $s0    # $t2 = address of piece data (g_piece)
    li   $t0, 0  # $t0 = row counter (0 to 5)

gmovr_draw_pc_row:
    beq $t0, 6, gmovr_done_drawing  # Changed from 4 to 6 for height
    lhu  $t1, 0($t2) # load row data (4 columns in bits 3-0)
    li   $t4, 0  # $t4 = column counter (0 to 3)

gmovr_draw_pc_inner:
    beq $t4, 4, gmovr_next_row  # Process 4 columns
    # Check each of 4 bits (columns)
    li   $t5, 3  # Changed from 5 to 3 (4 columns)
    sub  $t5, $t5, $t4   # $t5 = 3 - current column
    li   $t6, 1
    sllv $t6, $t6, $t5   # create mask for current bit
    and  $t7, $t1, $t6   # check if bit is set
    beqz $t7, gmovr_do_nothing
    # Calculate screen position (unchanged)
    add  $t8, $a2, $t4   # x position
    add  $t9, $a3, $t0   # y position
    mul  $t3, $t9, 16    # Assuming 16-unit screen width
    add  $t3, $t3, $t8
    sll  $t3, $t3, 2 # bytes per pixel
    add  $t6, $s7, $t3   # framebuffer address
    sw   $s1, 0($t6) # store color

gmovr_do_nothing:
    addi $t4, $t4, 1
    j gmovr_draw_pc_inner

gmovr_next_row:
    addi $t2, $t2, 2 # next halfword row
    addi $t0, $t0, 1 # increment row counter
    j gmovr_draw_pc_row

gmovr_done_drawing:
    jr $ra

game_over_yay:
	# Print game over message
    li $v0, 4
    la $a0, msg_game_over
    syscall
	# Draw GAME OVER using block letters
    li $a2, 0   # initial x position
    li $a3, 8   # initial y position
    # Draw letter G
    li $s1, 0x00FF0000 # red color
    la $s0, g_piece # load G piece data
    jal gmovr_draw_pc_main
    # Draw letter A
    li $s1, 0x00FFA500 # orange color
    addi $a2, $a2, 4
    la $s0, a_piece
    jal gmovr_draw_pc_main
    # Draw letter M
    li $s1, 0x00FFFF00 # yellow color
    addi $a2, $a2, 4
    la $s0, m_piece
    jal gmovr_draw_pc_main
    # Draw letter E
    li $s1, 0x0000FF00 # green
    addi $a2, $a2, 4
    la $s0, e_piece
    jal gmovr_draw_pc_main
    
    # next line
    addi $a3, $a3, 7
    # Draw letter O
    li $s1, 0x00ADD8E6 # light BLUE
    addi $a2, $a2, 4
    la $s0, o_piece
    jal gmovr_draw_pc_main
    # Draw letter V
    li $s1, 0x000000FF # blue
    addi $a2, $a2, 4
    la $s0, v_piece
    jal gmovr_draw_pc_main
    # Draw letter E
    li $s1, 0x00800080 # pyrple  
    addi $a2, $a2, 4
    la $s0, e_piece
    jal gmovr_draw_pc_main
    # Draw letter R
    li $s1, 0x00FF0000
    addi $a2, $a2, 4
    la $s0, r_piece
    jal gmovr_draw_pc_main
    # play davids washing machine song
    jal washing_machine
    j play_again_check
   
	
# check if r is pressed in the next 5 seconds
# if yes, jump to r_was_pressed (resets game)
# if not, quit program
play_again_check:
    li   $t0, 0

wait_for_r_loop:
    li   $t1, 5000 
    bge  $t0, $t1, quit_game
    lw   $t2, 0($s6)
    andi $t2, $t2, 1
    beqz $t2, sleep_and_check_next
    lw   $t3, 4($s6)
    li   $t4, 0x72   # 'r'
    beq  $t3, $t4, r_was_pressed
    sw   $zero, 0($s6) 

sleep_and_check_next:
    li   $a0, 100
    jal  nap_time    # sleep 100 ms
    addi $t0, $t0, 100   # add 100 ms to elapsed
    j    wait_for_r_loop

quit_game:
    li $v0, 10 # exit program
    syscall	    
 
piece_died:
	li $v0, 4
	la $a0, msg_spawn_failed
	syscall
	li $a0, 144
	jal nap_time
	j done
	
# SONUND EFFECTS/MUSIC
play_starting_sound:
	# plays CR intro chord
	li $v0, 33
	li $a2, 0
	li $a3, 100 # max volume
	li $a0 Dflat5
	li $a1 96
	syscall
	li $a0 Fsharp5
	syscall
	li $a0 Gsharp5
	syscall
	li $a0 Csharp6
	syscall
	li $a0 F6
	syscall
	jr $ra

mac_startup_sound:
	# a piece hard dropped
	li $v0, 31
	li $a2, 0 # piano is goated
	li $a3, 100 # full volume
	li $a1 349 # duration
	li $a0 Fsharp3
	syscall
	li $a0 Fsharp4
	syscall
	li $a0 Bflat4
	syscall
	li $a0 Dflat5
	syscall
	jr $ra
	
# windows startup sound
windows_startup:
	li $v0, 33
	li $a2, 0 # piano is goated
	li $a3, 100 # max volume
	li $a0, Gsharp5
	li $a1, 312
	syscall
	li $a0, Eflat5
	syscall
	li $a0, Aflat4
	syscall
	li $a0, Bflat4
	li $a1, 625
	syscall
	jr $ra
	
mario_lvlup:
	# play this sound for every row cleared
	# G maj arpeg then Aflat then Bflat
	li $v0, 33
	li $a2, 0 # piano is W
	li $a3, 100 # max volume
	li $a1, 40 # rapid arpeggios
	li $a0, G4
	syscall
	li $a0, B4
	syscall
	li $a0, D5
	syscall
	li $a0, G5
	syscall
	li $a0, Aflat4
	syscall
	li $a0, C5
	syscall
	li $a0, Eflat5
	syscall
	li $a0, Gsharp5
	syscall
	li $a0, Bflat4
	syscall 
	li $a0, D5
	syscall
	li $a0, F5
	syscall
	li $a0, Bflat5
	syscall
	jr $ra # remember to reset a2 and a3
					
washing_machine:
	# ending theme
	# plays main melody from die forelle (the trout)
	li $v0, 33
	li $a2, 0 # for piano, this sounds the best
	li $a3, 100 # full volume
	li $a0, Eflat4
	li $a1, 312 # duration in ms
	syscall 
	li $a0, Aflat4
	syscall
	syscall
	li $a0 C5
	syscall
	syscall
	li $a0 Aflat4
	li $a1 625 # quarter note
	syscall
	li $a0, Eflat4
	li $a1, 312 # eight note
	syscall
	syscall
	li $a1, 469 # dotted 8th
	syscall
	li $a1 156
	syscall
	li $a0 Bflat4
	syscall
	li $a0 Aflat4
	syscall
	li $a0 G4
	syscall
	li $a0 F4
	syscall
	li $a0 Eflat4
	li $a1 937
	syscall
	# second part of melody
	li $a0, Eflat4
	li $a1, 312 # duration in ms
	syscall 
	li $a0, Aflat4
	syscall
	syscall
	li $a0 C5
	syscall
	syscall
	li $a0 Aflat4
	li $a1 625 # quarter note
	syscall
	li $a0 Eflat4
	li $a1 312
	syscall
	li $a0 Aflat4
	syscall
	li $a0 G4
	syscall
	li $a0 F4
	li $a1 156 # sixteenth note
	syscall
	li $a0 G4
	syscall
	li $a0 Aflat4
	li $a1 312
	syscall
	li $a0 D4
	syscall
	li $a0 Eflat4
	li $a1 937
	syscall
	# third part of melody
	li $a0 Eflat4
	li $a1 312
	syscall
	li $a0 G4
	syscall
	syscall
	li $a0 Aflat4
	li $a1 156
	syscall
	li $a0 G4
	syscall
	li $a0 F4
	syscall
	li $a0 G4
	syscall
	li $a0 Aflat4
	li $a1 625
	syscall
	li $a0 Eflat4
	li $a1 312 
	syscall
	li $a0 Aflat4
	syscall
	li $a0 G4
	syscall
	syscall
	li $a1 156
	syscall
	li $a0 Dflat5
	syscall
	li $a0 Bflat4
	syscall
	li $a0 G4
	syscall
	li $a0 Aflat4
	li $a1 937
	syscall 
	# fifth part of melody
	li $a1 312
	syscall
	li $a0 F4
	syscall
	syscall
	syscall
	li $a0 Aflat4
	syscall
	li $a1 625
	syscall
	li $a0 Eflat4
	li $a1 312
	syscall
	syscall
	li $a1 469
	syscall
	li $a1 156
	syscall
	li $a1 312
	li $a0 Bflat4
	syscall
	li $a0 G4
	syscall
	li $a0 Aflat4
	li $a1 937
	syscall
	li $a1 312
	syscall
	li $a1 156
	syscall
	li $a0 G4
	syscall
	li $a1 312
	li $a0 F4
	syscall
	li $a1 156
	syscall
	li $a0 Aflat4
	syscall
	li $a0 G4
	syscall
	li $a0 Bflat4
	syscall
	li $a0 Aflat4
	li $a1 625
	syscall
	li $a0 Eflat4
	li $a1 312
	syscall
	syscall
	li $a1 469
	syscall
	li $a1 156
	syscall
	li $a1 312
	li $a0 Bflat4
	syscall
	li $a0 G4
	syscall
	li $a0 Aflat4
	li $a1 1250
	syscall
	jr $ra
