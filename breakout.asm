################ CSC258H1S Winter 2023 Assembly Final Project ##################
# This file contains our implementation of Breakout.
#
# Student 1: Aviraj Newatia, 1007837708
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       2
# - Unit height in pixels:      2
# - Display width in pixels:    64
# - Display height in pixels:   128
# - Base Address for Display:   0x10008000 ($gp)
######################## Controls ########################
# - a : Move Paddle Left
# - d : Move Paddle Right
# - spacebar : Launch Ball/Resume Game
# - p : pause/resume game
# - q : quit game
# - r : restart game
##############################################################################

.data
displayAddress: .word 0x10008000 # Set the location of the display in memory to a variable
ADDR_KBRD: .word 0xffff0000 # Set the location of the keyboard input to a variable
PADDLE_LOC_LEFT: .word 48 # Set the initial offset of the left corner of the paddle, to be set to absolute location later
PADDLE_LOC_RIGHT: .word 56 # Set the initial offset of the right corner of the paddle, to be set to absolute location later
BALL_LOC: .word 0 # Initialise the location of the ball to 0, to be set later
BALL_ANGLE: .word -124 # - 124 is right 45, - 132 is left 45, this is the value that gets added to the current location of the ball to move it in the right direction
REFRESH_RATE: .word 64 # Refresh rate of the screen which is updated to speed up the ball movement as the game progresses

.text
.globl main
lw $t0, displayAddress # Load the address for the display into t0
li $t1, 0xff0000 	# $t1 stores the red colour code
li $t2, 0x00ff00 	# $t2 stores the green colour code
li $t3, 0xff0000 	# $t3 stores the blue colour code

main: # This is the main game function

    jal layout_grid # jump and come back from the brick grid layout
    
    # Memory wipe? Memory wipe, don't have to worry about previous values
    
    jal setup_border_and_paddle_and_ball # jump and come back from printing out the walls and the paddle and the ball
    
    # Memory wipe, can use all registers
    
    jal game_loop # Move to the stationary game loop, its ready to play now
    
    j exit # If control flow reaches this point, which it should not, exit the program
  
reset_variables: # Function to reset all of the variables in memory so that the screen can be redrawn for the restart function
    addi $t0, $zero, 48
    sw $t0, PADDLE_LOC_LEFT
    
    addi $t0, $zero, 56
    sw $t0, PADDLE_LOC_RIGHT
    
    addi $t0, $zero, 0
    sw $t0, BALL_LOC
    
    addi $t0, $zero, -124
    sw $t0, BALL_ANGLE
    
    addi $t0, $zero, 64
    sw $t0, REFRESH_RATE
      
    lw $t0, displayAddress
      
    jr $ra
    
game_loop: # Game loop for being paused and before the game starts
    lw $t0, ADDR_KBRD # Load the address of the keyboard
    lw $t8, 0($t0) # Load the beginning of the data at the address
    beq $t8, 1, handle_keyboard_input_stat # If a key has been pressed, handle which key it was
    j game_loop # Loop back to stationary game loop
    
paused_game_loop: # Game loop for being paused and before the game starts
    lw $t0, ADDR_KBRD # Load the address of the keyboard
    lw $t8, 0($t0) # Load the beginning of the data at the address
    beq $t8, 1, handle_keyboard_input_paused # If a key has been pressed, handle which key it was
    j paused_game_loop # Loop back to stationary game loop
    
moving_game_loop: # Game loop for while the game is running
    lw $t0, ADDR_KBRD # Load keyboard address
    lw $t8, 0($t0) # Load the beginning of the data
    beq $t8, 1, handle_keyboard_input # Check and handle keyboard input
    jal move_ball # Move to the function that handles ball movement and collision and store current address in $ra
    
    j moving_game_loop # Loop

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
    lw $a0, REFRESH_RATE
    syscall
    
    # Check if ball has reached the bottom of the screen and if so, end game
    lw $v0, PADDLE_LOC_RIGHT
    addi $v0, $v0, 128
    bgt $t3, $v0, exit_loop
    
    jr $ra # jump back to the moving game loop

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
    beq $a2, 0xffffff, bounce_right
    
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
    beq $a2, 0xffffff, bounce_left
    
    # Delete brick: check horizontally for all connected coloured pixels and colour them black, the location is $t4
    add $t4, $t3, -4
    add $t5, $t4, $zero
    j delete_brick_loop_left
    
delete_brick_bounce:
    # If ball was moving up then bounce down, if ball was moving down then bounce up
    
    addi $t9, $a1, 0 # Temporarily store the value of $a1 in $t9 so it can be retrieved later
    
    # Play sound on brick hit
    addi $v0, $zero, 33
    addi $a0, $zero, 64
    addi $a1, $zero, 50
    addi $a2, $zero, 20
    addi $a3, $zero, 50
    syscall
    
    addi $a1, $t9, 0 # Retrieve value of $a1 from $t9
    
    # Load the refresh rate into $t9 and reduce it and store it back in refresh rate
    lw $t9, REFRESH_RATE
    addi $t9, $t9, -1
    sw $t9, REFRESH_RATE
    
    bgez $a1 bounce_paddle # If the ball was moving downwards then bounce it up
    blez $a1 bounce_roof # If the ball was moving upwards then bounce it down
    
delete_brick_loop_right:
    # Reset $t5
    addi $t5, $t4, 4
    j delete_brick_actual_loop_part_right
    
delete_brick_actual_loop_part_right:
    # Get the value of the colour at $t5
    lw $t6, 0($t5)
    
    # If the brick has been painted entirely black (destroyed) then handle the bouncing
    beq $t6, 0x000000, delete_brick_bounce
    
    # Store painting colour in $t7
    # Store painting colour in $t7
    beq $t6, 0x222222, set_blackr
    addi $t7, $zero, 0x222222
    j skipr
    set_blackr:
        addi $t7, $zero, 0x000000 
    skipr:
        # Paint it black
        sw $t7, 0($t5)
        
        # Move $t5 left
        addi $t5, $t5, 4
        
        # Sleep
        addi $v0, $zero, 32
        addi $a0, $zero, 34
        syscall
        
        j delete_brick_actual_loop_part_right # loop
    
delete_brick_loop_left:
    # Temporarily use $t5 to store which pixel you are deleting
    
    # Get the value of the colour at $t5
    lw $t6, 0($t5)
    
    # If the colour is black then loop right
    beq $t6, 0x000000, delete_brick_loop_right
    
    # Store painting colour in $t7
    beq $t6, 0x222222, set_blackl
    addi $t7, $zero, 0x222222
    j skipl
    set_blackl:
        addi $t7, $zero, 0x000000 
    skipl:
        # Paint it black
        sw $t7, 0($t5)
        
        # Move $t5 left
        addi $t5, $t5, -4
        
        # Sleep
        addi $v0, $zero, 32
        addi $a0, $zero, 34
        syscall
        
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
    addi $a1, $zero, -132 # Movement modifier upleft
    
    add $t3, $t3, $a1
    
    j bounce_end

bounce_upright:
    addi $a1, $zero, -124 # movement modifier upright
    
    add $t3, $t3, $a1
    
    j bounce_end
    
bounce_downleft:
    addi $a1, $zero, 124 # movement modifier downleft
    
    add $t3, $t3, $a1
    
    j bounce_end

bounce_downright:
    addi $a1, $zero, 132 # movement modifier downright
    
    add $t3, $t3, $a1
    
    j bounce_end

bounce_end:
    # Paint it white
    addi $t1, $zero, 0xffffff
    sw $t1, 0($t3)
    
    # Store the new location in the variable and the new current movement angle
    sw $t3, BALL_LOC
    sw $a1, BALL_ANGLE
    
    jr $ra

handle_keyboard_input:
    lw $a0, 4($t0) # Loads the second word, which is the key that was pressed
    beq $a0, 'a', handle_a_pressed
    beq $a0, 'A', handle_a_pressed
    beq $a0, 'd', handle_d_pressed
    beq $a0, 'D', handle_d_pressed
    beq $a0, 'q', handle_escape_key
    beq $a0, 'Q', handle_escape_key
    beq $a0, 'p', handle_p_pressed
    beq $a0, 'P', handle_p_pressed
    beq $a0, 'r', handle_r_pressed
    beq $a0, 'R', handle_r_pressed
    j moving_game_loop
    
handle_keyboard_input_stat:
    lw $a0, 4($t0) # Loads the second word, which is the key that was pressed
    beq $a0, 32, handle_spacebar_pressed
    beq $a0, 'a', handle_a_pressed_stat
    beq $a0, 'A', handle_a_pressed_stat
    beq $a0, 'd', handle_d_pressed_stat
    beq $a0, 'D', handle_d_pressed_stat
    beq $a0, 'q', handle_escape_key
    beq $a0, 'Q', handle_escape_key
    beq $a0, 'r', handle_r_pressed
    beq $a0, 'R', handle_r_pressed
    j game_loop
    
handle_keyboard_input_paused:
    lw $a0, 4($t0) # Loads the second word, which is the key that was pressed
    beq $a0, 32, handle_spacebar_pressed
    beq $a0, 'q', handle_escape_key
    beq $a0, 'Q', handle_escape_key
    beq $a0, 'p', handle_spacebar_pressed
    beq $a0, 'P', handle_spacebar_pressed
    beq $a0, 'r', handle_r_pressed
    beq $a0, 'R', handle_r_pressed
    j paused_game_loop
    
handle_keyboard_input_exit:
    lw $a0, 4($t0) # Loads the second word, which is the key that was pressed
    beq $a0, 'q', handle_escape_key
    beq $a0, 'Q', handle_escape_key
    beq $a0, 'r', handle_r_pressed
    beq $a0, 'R', handle_r_pressed
    j exit_loop
    
handle_r_pressed: # Restart command, jump back to main
    
    jal reset_variables # reset all of the variables so main works again
    
    # Paint over everything
    # Repaint everything
    
    lw $a0, displayAddress # Starting location
    
    addi $a1, $zero, 64 # Width
    addi $a2, $zero, 128 # Height
    addi $a3, $zero, 0x000000 # Colour
    
    
    jal draw_rect
    
    lw $t0, displayAddress # Starting location
    addi $v1, $zero, 0
    
    j main # restart and go to the beginning of main to restart the game
  
handle_p_pressed:
    j paused_game_loop # move to the paused game loop to pause the game
  
handle_escape_key:
    j exit # jump to the exit function to terminate the program gracefully
  
handle_d_pressed:
    lw $t0, PADDLE_LOC_LEFT # Load the locations of the paddle, left and right corner
    lw $t1, PADDLE_LOC_RIGHT
    
    beq $t1, 0x10009e78, moving_game_loop # If the right corner of the paddle is at the wall, go back to the game loop
    
    addi, $t2, $zero, 0x000000
    
    # Move the locations of the left and right paddle edges in memory
    sw $t2, 0($t0)
    addi $t0, $t0, 4
    sw $t0, PADDLE_LOC_LEFT
    
    addi $t2, $zero, 0xffffff
    
    addi $t1, $t1, 4
    sw $t2, 0($t1)
    sw $t1, PADDLE_LOC_RIGHT
    
    addi $t8, $zero, 0
    j moving_game_loop # GO back to the game loop
    
handle_d_pressed_stat: # same thing as above but for stationary game, moves ball too
    lw $t0, PADDLE_LOC_LEFT
    lw $t1, PADDLE_LOC_RIGHT
    
    beq $t1, 0x10009e78, game_loop
    
    addi, $t2, $zero, 0x000000
    
    sw $t2, 0($t0)
    addi $t0, $t0, 4
    sw $t0, PADDLE_LOC_LEFT
    
    addi $t2, $zero, 0xffffff
    
    addi $t1, $t1, 4
    sw $t2, 0($t1)
    sw $t1, PADDLE_LOC_RIGHT
    
    addi $t2, $zero, 0x000000
    lw $t0, BALL_LOC
    sw $t2, 0($t0)
    addi $t2, $zero, 0xffffff
    addi $t0, $t0, 4
    sw $t2, 0($t0)
    sw $t0, BALL_LOC
    
    addi $t8, $zero, 0
    j game_loop
    
handle_a_pressed:
    lw $t0, PADDLE_LOC_LEFT # load paddle locations
    lw $t1, PADDLE_LOC_RIGHT
    
    beq $t0, 0x10009e04, moving_game_loop # if left wall reached, dont move
    
    addi, $t2, $zero, 0x000000
    
    # else update paddle painting and memory locations
    sw $t2, 0($t1)
    addi $t1, $t1, -4
    sw $t1, PADDLE_LOC_RIGHT
    
    addi $t2, $zero, 0xffffff
    addi $t0, $t0, -4
    sw $t2, 0($t0)
    sw $t0, PADDLE_LOC_LEFT
    
    addi $t8, $zero, 0
    j moving_game_loop # go back to game loop
    
handle_a_pressed_stat: # same as above but for the stationary game, moves ball too
    lw $t0, PADDLE_LOC_LEFT
    lw $t1, PADDLE_LOC_RIGHT
    
    beq $t0, 0x10009e04, game_loop
    
    addi, $t2, $zero, 0x000000
    
    sw $t2, 0($t1)
    addi $t1, $t1, -4
    sw $t1, PADDLE_LOC_RIGHT
    
    addi $t2, $zero, 0xffffff
    addi $t0, $t0, -4
    sw $t2, 0($t0)
    sw $t0, PADDLE_LOC_LEFT
    
    addi $t2, $zero, 0x000000
    lw $t0, BALL_LOC
    sw $t2, 0($t0)
    addi $t2, $zero, 0xffffff
    addi $t0, $t0, -4
    sw $t2, 0($t0)
    sw $t0, BALL_LOC
    
    addi $t8, $zero, 0
    j game_loop
    
handle_spacebar_pressed:
    # Shoot the ball upwards
    j moving_game_loop
    
exit_loop:
    # Loop for when the game ends, waits to see if quit or restart is pressed
    lw $t0, ADDR_KBRD
    lw $t8, 0($t0)
    beq $t8, 1, handle_keyboard_input_exit
    
    j exit_loop
    
exit:

# Play sound to lose game
    addi $v0, $zero, 33
    addi $a0, $zero, 64
    addi $a1, $zero, 50
    addi $a2, $zero, 50
    addi $a3, $zero, 50
    syscall

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
    addi $t0, $zero, 60
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
    addi $t0, $zero, 58
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