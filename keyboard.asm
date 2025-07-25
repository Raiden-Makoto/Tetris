    .data
ADDR_KBRD:
    .word 0xffff0000
msg_key_pressed:       .asciiz "A key was pressed\n"

    .text
    .globl main

main:
    la $s6, ADDR_KBRD       # Load address of keyboard control
    lw $s6, 0($s6)          # Get actual memory address
    li $s5, 0               # Initialize counter
    
game_loop:
    lw $t9, 0($s6)          # poll keyboard control
    andi $t9, $t9, 1        # check ready bit
    beqz $t9, sleep         # not ready

    j process_key           # key ready

sleep:
    li $a0, 100
    jal nap_time            # sleep for 100ms 
    addiu $s5, $s5, 100
    blt $s5, 1000, game_loop  # continue loop if under 1000ms

    li $s5, 0               # reset counter after 1 second
    j game_loop

process_key:
    li $v0, 4
    la $a0, msg_key_pressed
    syscall
    lw $a0, 4($s6)          # load key code
    beq $a0, 0x61, a_pressed   # 'a' pressed
    beq $a0, 0x64, d_pressed   # 'd' pressed
    beq $a0, 0x73, s_pressed   # 's' pressed
    beq $a0, 0x77, w_pressed   # 'w' pressed
    beq $a0, 0x71, done        # 'q' quit
    
    # Reset keyboard status for next keypress
    sw $zero, 0($s6)
    j game_loop

a_pressed:
    # Handle 'a' key
    j key_processed

d_pressed:
    # Handle 'd' key
    j key_processed

s_pressed:
    # Handle 's' key
    j key_processed

w_pressed:
    # Handle 'w' key
    j key_processed

key_processed:
    sw $zero, 0($s6)        # reset keyboard status
    j game_loop

done:
    li $v0, 10              # exit program
    syscall

nap_time:
	li $v0, 32
	syscall
	jr $ra