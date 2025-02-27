.data
    infix: .space 256
    postfix: .space 256
    stack: .space 256
    prompt: .asciiz "\nEnter Expression: " 
    newLine: .asciiz "\n"
    inputError: .asciiz "Input error!!!\n"
    prompt_postfix: .asciiz "Postfix is: "
    prompt_result: .asciiz "Result is: "
    prompt_infix: .asciiz "Infix is: "   
    endMsg: .asciiz "Do you want to continue? Press any key to continue or 'q' to quit: "
    byeMsg: .asciiz "\nGoodbye!!!\n"
     
.text
.globl main
main:
begin:
    # Get infix expression from user
    li $v0, 4
    la $a0, prompt
    syscall 

    li $v0, 8
    la $a0, infix
    li $a1, 256
    syscall 

    li $s2, '+'
    li $s3, '-'
    li $s4, '*'
    li $s5, '/'
    li $t2, 32 # ' '
    li $t3, 10 # '\n'
    li $t8, 48 # '0'
    li $t9, 57 # '9'
validate_input:
    # Validate input
    la $s1, infix
    li $s6, 0 # counter

validate_loop:
    lb $t1, 0($s1) # Get character
    beqz $t1, convert_to_postfix # End of input string

    # Check if character is valid
    blt $t1, $t8, check_operator
    bgt $t1, $t9, check_operator
    j next_char

check_operator:
    beq $t1, $s2, next_char
    beq $t1, $s3, next_char
    beq $t1, $s4, next_char
    beq $t1, $s5, next_char
    beq $t1, $t2, next_char
    beq $t1, $t3, next_char

    # If character is not valid, print error and prompt for input again
    la $a0, inputError
    li $v0, 4
    syscall
    j begin

next_char:
    addi $s1, $s1, 1 # Move to next character
    j validate_loop

convert_to_postfix:
    # Reset postfix array
    la $t5, postfix # Load address of postfix array
    li $t6, 0 # Counter for resetting
    
reset_postfix_loop:
    sb $zero, 0($t5) # Set current byte in postfix array to zero
    addi $t5, $t5, 1 # Move to next byte
    addi $t6, $t6, 1 # Increment counter
    blt $t6, 256, reset_postfix_loop # Loop until all bytes are reset
    # Initialize counters
    li $s6, -1 # infix counter
    li $s7, -1 # stack counter
    li $t7, -1 # postfix counter

while:
    la $s1, infix  # buffer = $s1
    la $t5, postfix # postfix = $t5
    la $t6, stack # stack = $t6

    addi $s6, $s6, 1  # counter++
    
    # get buffer[counter]
    add $s1, $s1, $s6
    lb $t1, 0($s1) # t1 = value of buffer[counter]

    beq $t1, $s2, operator # '+'
    beq $t1, $s3, operator # '-'
    beq $t1, $s4, operator # '*'
    beq $t1, $s5, operator # '/'
    beq $t1, 10, n_operator # '\n'
    beq $t1, 32, n_operator # ' '
    beq $t1, $zero, endWhile
    # push number to postfix
    addi $t7, $t7, 1
    add $t5, $t5, $t7
    sb $t1, 0($t5)

    lb $a0, 1($s1)
    jal number
    beq $v0, 1, n_operator

add_space:
    add $t1, $zero, 32
    sb $t1, 1($t5)
    addi $t7, $t7, 1

    j n_operator

operator:
    # add to stack
    beq $s7, -1, pushToStack
    add $t6, $t6, $s7
    lb $t2, 0($t6) # t2 = value of stack[counter]
    # check t1 precedence
    beq $t1, $s2, t3_1
    beq $t1, $s3, t3_1
    li $t3, 2
    j check_t2

t3_1:
    li $t3, 1

check_t2:
    beq $t2, $s2, t4_1
    beq $t2, $s3, t4_1
    li $t4, 2
    j compare_precedence

t4_1:
    li $t4, 1

compare_precedence:
    beq $t3, $t4, equal_precedence
    slt $s1, $t3, $t4
    beqz $s1, t3_large_t4

# t3 < t4
# pop t2 from stack and t2 ==> postfix
# get new top stack do again
    sb $zero, 0($t6)
    addi $s7, $s7, -1  # scounter++
    addi $t6, $t6, -1
    la $t5, postfix # postfix = $t5
    addi $t7, $t7, 1
    add $t5, $t5, $t7
    sb $t2, 0($t5)

    j operator

t3_large_t4:
    # push t1 to stack
    j pushToStack

equal_precedence:
    # pop t2 from stack and t2 ==> postfix
    # push to stack
    sb $zero, 0($t6)
    addi $s7, $s7, -1  # scounter++
    addi $t6, $t6, -1
    la $t5, postfix # postfix = $t5
    addi $t7, $t7, 1 # pcounter++
    add $t5, $t5, $t7
    sb $t2, 0($t5)

    j pushToStack

pushToStack:
    la $t6, stack # stack = $t6
    addi $s7, $s7, 1  # scounter++
    add $t6, $t6, $s7
    sb $t1, 0($t6)

n_operator:    
    j while

endWhile:
    addi $s1, $zero, 32
    add $t7, $t7, 1
    add $t5, $t5, $t7 
    la $t6, stack
    add $t6, $t6, $s7

popallstack:
    lb $t2, 0($t6) # t2 = value of stack[counter]
    beq $t2, 0, endPostfix
    sb $zero, 0($t6)
    addi $s7, $s7, -2 
    add $t6, $t6, $s7
    sb $t2, 0($t5)
    add $t5, $t5, 1

    j popallstack

endPostfix:
    # Print postfix
    la $a0, prompt_postfix
    li $v0, 4
    syscall

    la $a0, postfix
    li $v0, 4
    syscall

    la $a0, newLine
    li $v0, 4
    syscall

    # Calculate result
    li $s3, 0 # counter
    la $s2, stack # stack = $s2

while_ps:
    la $s1, postfix # postfix = $s1
    add $s1, $s1, $s3
    lb $t1, 0($s1)

    # if null
    beqz $t1, end_while_ps
    add $a0, $zero, $t1
    jal number
    beqz $v0, is_operator
    jal add_number_to_stack

    j continue

is_operator:
    jal pop
    add $a1, $zero, $v0 # b
    jal pop
    add $a0, $zero, $v0 # a
    add $a2, $zero, $t1 # op
    jal calculate

continue:
    add $s3, $s3, 1 # counter++
    j while_ps

# Calculate
calculate:
    sw $ra, 0($sp)
    li $v0, 0
    beq $a2, '*', cal_case_mul
    nop
    beq $a2, '/', cal_case_div
    nop
    beq $a2, '+', cal_case_plus
    nop
    beq $a2, '-', cal_case_sub

cal_case_mul:
    mul $v0, $a0, $a1
    j cal_push

cal_case_div:
    div $a0, $a1
    mflo $v0
    j cal_push

cal_case_plus:
    add $v0, $a0, $a1
    j cal_push

cal_case_sub:
    sub $v0, $a0, $a1
    j cal_push

cal_push:
    add $a0, $v0, $zero
    jal push
    nop
    lw $ra, 0($sp) 
    jr $ra

# Add number to stack
add_number_to_stack:
    # save $ra
    sw $ra, 0($sp)
    li $v0, 0

    while_num:
        beq $t1, '0', case_0
        beq $t1, '1', case_1
        beq $t1, '2', case_2
        beq $t1, '3', case_3
        beq $t1, '4', case_4
        beq $t1, '5', case_5
        beq $t1, '6', case_6
        beq $t1, '7', case_7
        beq $t1, '8', case_8
        beq $t1, '9', case_9

        case_0:
            j end_num
        case_1:
            addi $v0, $v0, 1    
            j end_num
        case_2:
            addi $v0, $v0, 2
            j end_num
        case_3:
            addi $v0, $v0, 3
            j end_num
        case_4:
            addi $v0, $v0, 4
            j end_num
        case_5:
            addi $v0, $v0, 5
            j end_num
        case_6:
            addi $v0, $v0, 6
            j end_num
        case_7:
            addi $v0, $v0, 7
            j end_num
        case_8:
            addi $v0, $v0, 8
            j end_num
        case_9:
            addi $v0, $v0, 9
            j end_num

        end_num:
            add $s3, $s3, 1 # counter++
            la $s1, postfix # postfix = $s1
            add $s1, $s1, $s3
            lb $t1, 0($s1)

            beq $t1, $zero, end_while_num
            beq $t1, ' ', end_while_num

            mul $v0, $v0, 10
            j while_num

end_while_num:
    add $a0, $zero, $v0
    jal push
    lw $ra, 0($sp) 
    jr $ra

number:
    slt $v0, $a0, $t8
    bnez $v0, number_false
    slt $v0, $t9, $a0
    bnez $v0, number_false
    li $v0, 1
    jr $ra

number_false:
    li $v0, 0
    jr $ra

# Pop from stack
pop:
    lw $v0, -4($s2)
    sw $zero, -4($s2)
    add $s2, $s2, -4
    jr $ra
    
# Push to stack
push:
    sw $a0, 0($s2)
    add $s2, $s2, 4
    jr $ra

end_while_ps:
    # Print result
    la $a0, prompt_result
    li $v0, 4
    syscall

    jal pop
    add $a0, $zero, $v0 
    li $v0, 1
    syscall

    la $a0, newLine
    li $v0, 4
    syscall

ask_continue:
    # Prompt to continue or exit
    la $a0, endMsg
    li $v0, 4
    syscall
    
    # Read a character
    li $v0, 12
    syscall
    li $t1, 'q'
    beq $v0, $t1, end
    j begin

end:
    la $a0, byeMsg
    li $v0, 4
    syscall
    li $v0, 10
    syscall
