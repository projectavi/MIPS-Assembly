.data
displayAddress: .word 0x10008000
ADDR_KBRD: .word 0xffff0000
PADDLE_LOC_LEFT: .word 48
PADDLE_LOC_RIGHT: .word 56
BALL_LOC: .word 0
BALL_ANGLE: .word -124 # - 124 is right 45, - 132 is left 45

.text
.globl main
lw $t0, displayAddress # Load the address for the display into t0
li $t1, 0xff0000 	# $t1 stores the red colour code
li $t2, 0x00ff00 	# $t2 stores the green colour code
li $t3, 0xff0000 	# $t3 stores the blue colour code

main:
    jal layout_grid
    
    # Memory wipe? Memory wipe
    
    jal setup_border_and_paddle_and_ball
    
    # Memory wipe
    
    jal game_loop
    
    j exit
    
game_loop:
    lw $t0, ADDR_KBRD
    lw $t8, 0($t0)
    beq $t8, 1, handle_keyboard_input
    j game_loop
    
moving_game_loop:
    lw $t0, ADDR_KBRD
    lw $t8, 0($t0)
    beq $t8, 1, handle_keyboard_input
    jal move_ball
    
    j moving_game_loop

move_ball:
    lw $t3, BALL_LOC # Get the current location of the ball
    lw $a1, BALL_ANGLE # Get the angle of movement of the ball
    
    # Paint it black
    addi $t1, $zero, 0x000000
    sw $t1, 0($t3)
    
    # Check around the ball instead of the new location
    # Check up
    addi $t3, $t3, -128
    lw $a2, 0($t3)
    bne $a2, 0x000000, bounce_down_control
    
    # Check down
    addi $t3, $t3, 256
    lw $a2, 0($t3)
    bne $a2, 0x000000, bounce_up_control
    
    # Check left
    addi $t3, $t3, -132
    lw $a2, 0($t3)
    bne $a2, 0x000000, bounce_right_control
    
    # Check right
    addi $t3, $t3, 8
    lw $a2, 0($t3)
    bne $a2, 0x000000, bounce_left_control
    
    lw $t3, BALL_LOC # Get the current location of the ball
    
    # Move the location in the specified direction
    add $t3, $t3, $a1
    
    # Paint it white
    addi $t1, $zero, 0xffffff
    sw $t1, 0($t3)
    
    # Store the new location in the variable
    sw $t3, BALL_LOC
    
    # Sleep
    addi $v0, $zero, 32
    addi $a0, $zero, 44
    syscall
    
    jr $ra

bounce_down_control:
    lw $a1, BALL_ANGLE # Get the angle of movement of the ball
    addi $t9, $a2, 0
    lw $t3, BALL_LOC # Get the current location of the ball
    # Check if corner
    addi $t3, $t3, -4
    lw $a2, 0($t3)
    bne $a2, 0x000000, bounce_downright
    
    addi $t3, $t3, 8
    lw $a2, 0($t3)
    bne $a2, 0x000000, bounce_downleft
    lw $t3, BALL_LOC # Get the current location of the ball
    
    addi $a2, $t9, 0

    beq $a2, 0xfffffc, bounce_roof
    
    # Delete brick: check horizontally for all connected coloured pixels and colour them black, the location is $t4
    add $t4, $t3, -128
    add $t5, $t4, $zero
    j delete_brick_loop_left
    
bounce_up_control:
    lw $a1, BALL_ANGLE # Get the angle of movement of the ball
    addi $t9, $a2, 0
    lw $t3, BALL_LOC # Get the current location of the ball
    
    addi $a2, $t9, 0
    beq $a2, 0xffffff, bounce_paddle
    
    # Delete brick: check horizontally for all connected coloured pixels and colour them black, the location is $t4
    add $t4, $t3, 128
    add $t5, $t4, $zero
    j delete_brick_loop_left
    
bounce_left_control:
    lw $a1, BALL_ANGLE # Get the angle of movement of the ball
    addi $t9, $a2, 0
    lw $t3, BALL_LOC # Get the current location of the ball
    # Check if corner
    addi $t3, $t3, -128
    lw $a2, 0($t3)
    bne $a2, 0x000000, bounce_downright
    lw $t3, BALL_LOC # Get the current location of the ball
    
    addi $a2, $t9, 0
    beq $a2, 0xfffffd, bounce_right
    
    # Delete brick: check horizontally for all connected coloured pixels and colour them black, the location is $t4
    add $t4, $t3, 4
    add $t5, $t4, $zero
    j delete_brick_loop_left
    
bounce_right_control:
    lw $a1, BALL_ANGLE # Get the angle of movement of the ball
    addi $t9, $a2, 0
    lw $t3, BALL_LOC # Get the current location of the ball
    # Check if corner
    addi $t3, $t3, 4
    lw $a2, 0($t3)
    bne $a2, 0x000000, bounce_downleft
    lw $t3, BALL_LOC # Get the current location of the ball
    
    addi $a2, $t9, 0
    beq $a2, 0xfffffe, bounce_left
    
    # Delete brick: check horizontally for all connected coloured pixels and colour them black, the location is $t4
    add $t4, $t3, -4
    add $t5, $t4, $zero
    j delete_brick_loop_left
    
delete_brick_bounce:
    # If ball was moving up then bounce down, if ball was moving down then bounce up
    
    bgez $a1 bounce_paddle
    blez $a1 bounce_roof
    
delete_brick_loop_right:
    # Reset $t5
    addi $t5, $t4, 4
    j delete_brick_actual_loop_part_right
    
delete_brick_actual_loop_part_right:
    # Get the value of the colour at $t5
    lw $t6, 0($t5)
    
    # If the colour is black then handle bouncing
    beq $t6, 0x000000, delete_brick_bounce
    
    # Store painting colour in $t7
    addi $t7, $zero, 0x000000
    
    # Paint it black
    sw $t7, 0($t5)
    
    # Move $t5 left
    addi $t5, $t5, 4
    
    j delete_brick_actual_loop_part_right
    
delete_brick_loop_left:
    # Temporarily use $t5 to store which pixel you are deleting
    
    # Get the value of the colour at $t5
    lw $t6, 0($t5)
    
    # If the colour is black then loop right
    beq $t6, 0x000000, delete_brick_loop_right
    
    # Store painting colour in $t7
    addi $t7, $zero, 0x000000
    
    # Paint it black
    sw $t7, 0($t5)
    
    # Move $t5 left
    addi $t5, $t5, -4
    
    j delete_brick_loop_left
    
bounce_paddle:
    # Bounce when the ball hits the paddle from above
    beq $a1, 132, bounce_upright
    beq $a1, 124, bounce_upleft
    
bounce_left:
    # Bounce when the ball hits the left wall
    beq $a1, -132, bounce_upright
    beq $a1, 124, bounce_downright
    
bounce_right:
    # Bounce when the ball hits the right wall
    beq $a1, 132, bounce_downleft
    beq $a1, -124, bounce_upleft
    
bounce_roof:
    # Bounce when the ball hits the ceiling
    beq $a1, -124, bounce_downright
    beq $a1, -132, bounce_downleft

bounce_upleft:
    addi $a1, $zero, -132
    
    add $t3, $t3, $a1
    
    j bounce_end

bounce_upright:
    addi $a1, $zero, -124
    
    add $t3, $t3, $a1
    
    j bounce_end
    
bounce_downleft:
    addi $a1, $zero, 124
    
    add $t3, $t3, $a1
    
    j bounce_end

bounce_downright:
    addi $a1, $zero, 132
    
    add $t3, $t3, $a1
    
    j bounce_end

bounce_end:
    # Paint it white
    addi $t1, $zero, 0xffffff
    sw $t1, 0($t3)
    
    # Store the new location in the variable
    sw $t3, BALL_LOC
    sw $a1, BALL_ANGLE
    
    jr $ra

handle_keyboard_input:
    lw $a0, 4($t0) # Loads the second word, which is the key that was pressed
    beq $a0, 32, handle_spacebar_pressed
    beq $a0, 'a', handle_a_pressed
    beq $a0, 'A', handle_a_pressed
    beq $a0, 'd', handle_d_pressed
    beq $a0, 'D', handle_d_pressed
    beq $a0, 'q', handle_escape_key
    beq $a0, 'Q', handle_escape_key
    j moving_game_loop
  
handle_escape_key:
    j exit
  
handle_d_pressed:
    lw $t0, PADDLE_LOC_LEFT
    lw $t1, PADDLE_LOC_RIGHT
    
    beq $t1, 0x100096f8, moving_game_loop
    
    addi, $t2, $zero, 0x000000
    
    sw $t2, 0($t0)
    addi $t0, $t0, 4
    sw $t0, PADDLE_LOC_LEFT
    
    addi $t2, $zero, 0xffffff
    
    addi $t1, $t1, 4
    sw $t2, 0($t1)
    sw $t1, PADDLE_LOC_RIGHT
    
    addi $t8, $zero, 0
    j moving_game_loop
    
handle_a_pressed:
    lw $t0, PADDLE_LOC_LEFT
    lw $t1, PADDLE_LOC_RIGHT
    
    beq $t0, 0x10009684, moving_game_loop
    
    addi, $t2, $zero, 0x000000
    
    sw $t2, 0($t1)
    addi $t1, $t1, -4
    sw $t1, PADDLE_LOC_RIGHT
    
    addi $t2, $zero, 0xffffff
    addi $t0, $t0, -4
    sw $t2, 0($t0)
    sw $t0, PADDLE_LOC_LEFT
    
    addi $t8, $zero, 0
    j moving_game_loop
    
handle_spacebar_pressed:
    # Shoot the ball upwards
    j moving_game_loop
    
    
exit:
li $v0, 10 # terminate the program gracefully
syscall

setup_border_and_paddle_and_ball:
    add $v0, $ra, $zero
    
    # Left Wall
    li $a3, 0xfffffe
    li $a2, 96
    li $a1, 1
    addi $a0, $zero, 0x10008000 
    
    jal draw_rect
    
    # Paddle
    li $a3, 0xffffff
    li $a2, 1
    li $a1, 8
    addi $a0, $zero, 128
    addi $t0, $zero, 45
    mult $a0, $a0, $t0
    addi $a0, $a0, 0x10008000 
    lw $t0, PADDLE_LOC_LEFT
    add $a0, $a0, $t0
    sw $a0, PADDLE_LOC_LEFT
    addi $t0, $a0, 28
    sw $t0, PADDLE_LOC_RIGHT
    
    jal draw_rect
    
    # Ball
    li $a3, 0xffffff
    li $a2, 1
    li $a1, 1
    addi $a0, $zero, 128
    addi $t0, $zero, 42
    mult $a0, $a0, $t0
    addi $a0, $a0, 0x10008000 
    addi $a0, $a0, 64
    sw $a0, BALL_LOC
    
    jal draw_rect
    
    # Right Wall
    li $a3, 0xfffffd
    li $a2, 96
    li $a1, 1
    addi $a0, $zero, 0x10008000 
    addi $a0, $a0, 124
    
    jal draw_rect
    
    # Ceiling
    li $a3, 0xfffffc
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