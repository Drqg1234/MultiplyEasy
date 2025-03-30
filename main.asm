.data
	win_message:    .asciiz "You win!\n"
	play_prompt:    .asciiz "Play again? (enter 'y' or 'n'): "
	replay_message: .asciiz "\nOnce more!\n"
	exit_message:   .asciiz "\n"
	invalid_message: .asciiz "Invalid input. Try again?\n"
	newline:        .asciiz "\n"

.text
	.globl main

main:
    # Initialize and set up the game board
	jal start

    # Display the initial game board
	jal display_board

    # Start and display the timer
	jal startTimer
	jal updateTimer

game_loop:
    # Get user input for card flips
	jal get_user_input

    # Check if the selected cards match
	jal check_match

    # Check if all cards are matched (game over condition)
	jal is_game_over
	beq $v0, 1, end_game     # If game over, go to end_game

    # Update the timer and loop back for the next turn
	jal updateTimer
	j game_loop


end_game:
    # Display win message
	li $v0, 4
	la $a0, win_message
	syscall

    # Print final time
	jal updateTimer

ask_replay:
    # Prompt the user to play again
	la $a0, play_prompt
	li $v0, 4
	syscall

    # Get user input (y/n)
	li $v0, 12  # Read character
	syscall
	move $t0, $v0  # Store user input in $t0

    # Check if input is 'y' or 'n'
	li $t1, 121  # ASCII value for 'y'
	li $t2, 110  # ASCII value for 'n'

	beq $t0, $t1, replay_game  # If 'y', restart the game
	beq $t0, $t2, exit_game    # If 'n', exit the game

    # Handle invalid input
	la $a0, invalid_message
	li $v0, 4
	syscall
	j ask_replay

replay_game:
    # Display replay message
	la $a0, replay_message
	li $v0, 4
	syscall

    # Restart the game
	j main

exit_game:
    # Display exit message
	la $a0, exit_message
	li $v0, 4
	syscall

    # Exit program
	li $v0, 10
	syscall
