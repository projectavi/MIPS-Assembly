.data
displayAddress: .word 0x10008000

.text
lw $t0, displayAddress # Load the address for the display into t0
li $t1, 0xff0000 	# $t1 stores the red colour code
li $t2, 0x00ff00 	# $t2 stores the green colour code
li $t3, 0xff0000 	# $t3 stores the blue colour code

main:
    jal layout_grid
    
    # Memory wipe? Memory wipe
    
    jal setup_border_and_paddle_and_ball
    
    # Memory wipe
    
    
    
    j exit
    
exit:
li $v0, 10 # terminate the program gracefully
syscall

setup_border_and_paddle_and_ball:
    add $v0, $ra, $zero
    
    li $a3, 0xffffff
    li $a2, 96
    li $a1, 1
    addi $a0, $zero, 0x10008000 
    
    jal draw_rect
    
    li $a3, 0xffffff
    li $a2, 1
    li $a1, 8
    addi $a0, $zero, 128
    addi $t0, $zero, 44
    mult $a0, $a0, $t0
    addi $a0, $a0, 0x10008000 
    addi $a0, $a0, 48
    
    jal draw_rect
    
    li $a3, 0xffffff
    li $a2, 1
    li $a1, 1
    addi $a0, $zero, 128
    addi $t0, $zero, 42
    mult $a0, $a0, $t0
    addi $a0, $a0, 0x10008000 
    addi $a0, $a0, 64
    
    jal draw_rect
    
    li $a3, 0xffffff
    li $a2, 96
    li $a1, 1
    addi $a0, $zero, 0x10008000 
    addi $a0, $a0, 124
    
    jal draw_rect
    
    li $a3, 0xffffff
    li $a2, 1
    li $a1, 64
    addi $a0, $zero, 0x10008000 
    
    jal draw_rect
    
    jr $v0

layout_grid:
    # Loop 6 times horizontally and 8 times vertically producing coordinates to start a rectangle
    addi $a1, $zero, 4 # Width
    addi $a2, $zero 1 # Height
    addi $a3, $t3, 0 # Colour
    
    addi $a0, $t0, 392 # Location
    
    addi $t7, $zero, 5 # Number per row
    addi $t8, $zero, 8 # Number of rows
    add $t5, $ra, $zero
    jal outer_grid_loop
    
inner_grid_loop:
    beq $t7, $zero, end_inner_grid_loop
    addi $a3, $a3, 32
    add $t6, $ra, $zero
    jal draw_rect
    add $ra, $t6, $zero
    addi $a0, $a0, 24
    addi $t7, $t7, -1
    j inner_grid_loop
    
end_inner_grid_loop:
    addi $a0, $a0, 136
    addi $t8, $t8, -1
    j outer_grid_loop

outer_grid_loop:
    # Adds an additional 136 to $a0 every fifth rectangle
    beq $t8, $zero, end_outer_grid_loop
    addi $t7, $zero, 5 # Number per row
    add $v0, $ra, $zero
    addi $v1, $v1, 2048
    mult $a3, $t8, $v1
    jal inner_grid_loop
    add $ra, $v0, $zero
    j outer_grid_loop
    
end_outer_grid_loop:
    jr $t5
    
# The rectangle drawing function
# Takes in the following:
# - $a0 : Starting location for drawing the rectangle
# - $a1 : The width of the rectangle
# - $a2 : The height of the rectangle
# - #a3 : The colour of the rectangle
draw_rect:
add $t0, $zero, $a0		# Put drawing location into $t0
add $t1, $zero, $a2		# Put the height into $t1
add $t2, $zero, $a1		# Put the width into $t2
add $t3, $zero, $a3		# Put the colour into $t3
j outer_rect_loop

outer_rect_loop:
beq $t1, $zero, end_outer_rect_loop

inner_rect_loop:
beq $t2, $zero, end_inner_rect_loop
sw $t3, 0($t0)
addi $t0, $t0, 4
addi $t2, $t2, -1
j inner_rect_loop

end_inner_rect_loop:
addi $t1, $t1, -1
add $t2, $a1, $zero
addi $t0, $t0, 128
sll $t4, $t2, 2
sub $t0, $t0, $t4
j outer_rect_loop

end_outer_rect_loop:
jr $ra