# fib.asm
# register usage: $t3 = n, $t4 = f1, $t5 = f2

FIB:
    addi $t3, $zero, 10 # Initialise n = 10
    addi $t4, $zero, 1 # Initialise f1 = 1
    addi $t5, $zero, -1 # Initialise f2 = -1
    
LOOP:
    beq $t3, $zero, END # If n = 0 then go to END, exit loop
    add $t4, $t4, $t5 # f1 = f1 + f2
    sub $t5, $t4, $t5 # f2 = f1 - f2
    addi $t3, $t3, -1 # n = n - 1
    j LOOP # Jump to top of loop

END:
    add $t4, $t4, $t5
    sb $t4, 0($sp) # store result