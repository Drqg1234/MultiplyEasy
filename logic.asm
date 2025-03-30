.data
    # Declare global variables
	.globl board           # Game board (4x4 grid)
	.globl cards           # List of card values (paired)
	.globl num_matched     # Tracks the number of matched pairs
	.globl revealed        # Tracks which cards have been revealed
	.globl expressions     # Array holding expressions for the cards

    # Variable definitions
	.align 2              
	board: .space 64      # Space for a 4x4 board (16 cards)
	cards: .word 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8  # Card values (paired)
	expressions: .space 80 # Space for 16 card expressions (strings)
	board_values: .asciiz " 2*4   8  12*2  24  12*1  12   2*5  10   3*2   6  5*19  95  11*1  11   2*9  18  "
	num_matched: .word 0  # Initialize matched pairs counter
	revealed: .space 16   # Tracks revealed cards (0 or 1 for each card)

    # Message strings for user interaction
	prompt: .asciiz "Welcome to Multiply Easy! Enter 1 if you're ready: "
	invalid: .asciiz "That wasn't a valid input, try again? \n"
	newline: .asciiz "\n"
	start_msg: .asciiz "Go!\n"
	match_message: .asciiz "Not Bad!\n"
	no_match_message: .asciiz "Not quite... Try Again!\n"

.text
    # Declare global functions so the main function can access them
	.globl start
	.globl check_match
 	.globl is_game_over

# Start of the game
start:
	la $a0, prompt        # Load the address of the start prompt
	li $v0, 4             # Syscall for printing a string
	syscall               # Display the start prompt message

    # Reading user input
	li $v0, 5             # Syscall for reading an integer (user input)
	syscall               # Get input from user
	move $t0, $v0         # Store the user input in $t0 to check it

	j validate            # Jump to input validation section

# Input Validation
validate:
	li $t1, 1             # Set the value to check for valid input (1)
	beq $t0, $t1, ready_to_play  # If input is 1, proceed to game start
    
    # If the input is not valid, jump to invalid_input section
invalid_input:
	la $a0, invalid       # Load address of invalid input message
	li $v0, 4             # Syscall for printing a string
	syscall               # Display the invalid input message
	j start               # Loop back to start the game (allow user to try again)

# Game Ready to Play
ready_to_play:
	la $t1, board_values  # Load the board values (expressions)
	la $a0, start_msg     # Load address of the ready message
	li $v0, 4             # Syscall for printing a string
	syscall               # Display the "Go!" message

    # Formatting - printing a newline
	la $a0, newline  
	li $v0, 4             
	syscall               # Print newline
    
	j save_state          # Jump to save the current state (registers)

# Not ready for play (invalid choice input)
not_ready:
	la $a0, invalid       # Load address of invalid input message
	li $v0, 4             # Syscall for printing a string
	syscall               # Display the invalid input message
	j start               # Loop back to start the game (allow user to try again)

# Save current state of registers
save_state:   
    # Allocate space on the stack to save registers
	addi $sp, $sp, -20    # Adjust stack pointer to save space
	sw $ra, 16($sp)       # Save the return address
	sw $s0, 12($sp)       # Save register s0
	sw $s1, 8($sp)        # Save register s1
	sw $s2, 4($sp)        # Save register s2
	sw $s3, 0($sp)        # Save register s3
    
    j get_board_from_array  # Jump to get_board_from_array to load board values

# Load the game board from the array of expressions
get_board_from_array:
	la $t0, expressions   # Load the address of expressions array
	li $t2, 0             # Initialize counter for copying bytes
	li $t3, 80            # Total number of bytes to copy from expressions

# Save expressions to be loaded onto the board
save_expressions:
	lb $t4, ($t1)         # Load a byte from the expressions array
	sb $t4, ($t0)         # Store the byte to the board space
	addi $t0, $t0, 1      # Move to the next byte in the board
	addi $t1, $t1, 1      # Move to the next byte in expressions array
	addi $t2, $t2, 1      # Increment byte counter
	blt $t2, $t3, save_expressions  # Loop if more bytes need to be copied
    
	li $s0, 15            # Set the starting index for card shuffle
	la $s1, board         # Load address of the board
	la $s2, cards         # Load address of the cards array
	la $s3, expressions   # Load address of the expressions array

    # Reset the board (revealed cards)
	la $t0, revealed      
	li $t1, 16            # Set number of cards to reset

end_reset:
    #shuffle cards
shuffle_loop:
	addi $a0, $s0, 1      # Set upper bound = current position + 1
	jal randomizer         # Call randomizer function to get a random index
	move $t3, $v0         # Save the random index to temporary register $t3

	sll $t4, $s0, 2       # Multiply current position by 4 (to get byte offset)
	sll $t5, $t3, 2       # Multiply random position by 4 (to get byte offset)
	add $t6, $s2, $t4     # Get address of the current card
	add $t7, $s2, $t5     # Get address of the random card

    # Card swap
	lw $t8, ($t6)         # Load the current card value into $t8
	lw $t9, ($t7)         # Load the random card value into $t9
	sw $t9, ($t6)         # Store the random card value at the current card's address
	sw $t8, ($t7)         # Store the current card value at the random card's address

	mul $t4, $s0, 5       # Multiply current position by 5 (to get byte offset for expressions)
	mul $t5, $t3, 5       # Multiply random position by 5 (to get byte offset for expressions)
	add $t6, $s3, $t4     # Get address of the current card's expression
	add $t7, $s3, $t5     # Get address of the random card's expression

	li $t1, 5             # Set counter for copying 5 bytes (expression length)
expression_swap:
	lb $t8, ($t6)         # Load byte from current expression into $t8
	lb $t9, ($t7)         # Load byte from random expression into $t9
	sb $t9, ($t6)         # Store random byte at current expression's address
	sb $t8, ($t7)         # Store current byte at random expression's address
	addi $t6, $t6, 1      # Move to the next byte in the current expression
	addi $t7, $t7, 1      # Move to the next byte in the random expression
	addi $t1, $t1, -1     # Decrement counter
	bgtz $t1, expression_swap  # Repeat until all 5 bytes are swapped

	addi $s0, $s0, -1     # Decrement the current position counter
	bgez $s0, shuffle_loop  # If position is >= 0, continue shuffling

	li $t0, 0             # Initialize loop counter for copying cards
	li $t1, 16            # Total number of cards (16)
copy_loop:
	sll $t2, $t0, 2       # Multiply the loop counter by 4 (byte offset)
	add $t3, $s2, $t2     # Get address of the current card in the cards array
	add $t4, $s1, $t2     # Get address of the current card in the board

    # Load card from cards array and store it on the board
	lw $t5, ($t3)         # Load the card value into $t5
	sw $t5, ($t4)         # Store the card value on the board

	addi $t0, $t0, 1      # Increment loop counter
	blt $t0, $t1, copy_loop  # Repeat until all 16 cards are copied

    # Reset matched pairs counter
	sw $zero, num_matched

    # Restore saved registers from stack
	lw $ra, 16($sp)
	lw $s0, 12($sp)
	lw $s1, 8($sp)
	lw $s2, 4($sp)
	lw $s3, 0($sp)
	addi $sp, $sp, 20     # Restore the stack pointer
	jr $ra                # Return to the caller

# Function to check if two cards match, returns 1 if match, 0 if not
check_match:
    # Save registers before using them
	addi $sp, $sp, -20    # Allocate space on the stack
	sw $ra, 16($sp)       # Save return address
	sw $s0, 12($sp)       # Save s0 register (first card position)
	sw $s1, 8($sp)        # Save s1 register (second card position)
	sw $s2, 4($sp)        # Save s2 register (board base address)
	sw $s3, 0($sp)        # Save s3 register (second card value)

	move $s0, $a0         # Store the first card position in $s0
	move $s1, $a1         # Store the second card position in $s1

	la $s2, board         # Load base address of the board into $s2

    # Get the addresses of the two cards
	sll $t0, $s0, 2       # Multiply first card position by 4 (byte offset)
	sll $t1, $s1, 2       # Multiply second card position by 4 (byte offset)
	add $t0, $s2, $t0     # Add offset to board base to get first card's address
	add $t1, $s2, $t1     # Add offset to board base to get second card's address

    # Load the card values
	lw $s2, ($t0)         # Load the first card value into $s2
	lw $s3, ($t1)         # Load the second card value into $s3

    # Mark cards as revealed
	la $t0, revealed      # Load base address of the revealed cards array
	add $t1, $t0, $s0     # Get the address of the first revealed card
	add $t2, $t0, $s1     # Get the address of the second revealed card
	li $t3, 1             # Load value 1 (revealed)
	sb $t3, ($t1)         # Mark first card as revealed
	sb $t3, ($t2)         # Mark second card as revealed

    # Compare the card values
	bne $s2, $s3, no_match  # If cards don't match, jump to no_match label

    # If cards match, increment num_matched counter
	lw $t0, num_matched   # Load the current matched pairs count
	addi $t0, $t0, 1      # Increment the matched pairs count
	sw $t0, num_matched   # Store the updated count

    # Display the board and match message
	jal display_board     # Call the display_board function
	la $a0, match_message # Load address of match message
	li $v0, 4             # Syscall to print string
	syscall               # Display the match message

	li $v0, 1             # Set return value to 1 (true)
	j check_match_end     # Jump to the end of the function

no_match:
    # Show the cards for one second while they are revealed
	sw $ra, 16($sp)       # Save the return address before calling display_board
	jal display_board     # Call the display_board function

	la $a0, no_match_message  # Load address of "no match" message
	li $v0, 4             # Syscall to print string
	syscall               # Display the "no match" message

	la $a0, newline       # Load address of newline string
	li $v0, 4             # Syscall to print string
	syscall               # Print newline

    # Wait for 2 seconds before hiding cards
	li $v0, 32            # Syscall for delay
	li $a0, 1250          # 1250ms delay
	syscall               # Wait for 2 seconds

    # Hide the revealed cards (set them back to 0)
	la $t0, revealed      # Load the revealed cards array
	add $t1, $t0, $s0     # Get address of the first revealed card
	add $t2, $t0, $s1     # Get address of the second revealed card
	sb $zero, ($t1)       # Hide the first card
	sb $zero, ($t2)       # Hide the second card

    # Display the board without the revealed cards
	jal display_board     # Call the display_board function

	lw $ra, 16($sp)       # Restore the return address from the stack

    # Return 0 (false) to indicate no match
	li $v0, 0

check_match_end:
    # Restore registers and return to the caller
	lw $ra, 16($sp)
	lw $s0, 12($sp)
	lw $s1, 8($sp)
	lw $s2, 4($sp)
	lw $s3, 0($sp)
	addi $sp, $sp, 20     # Restore the stack pointer
	jr $ra                # Return to the caller

# Function to check if the game is over (8 matched pairs)
is_game_over:
	lw $t0, num_matched   # Load current number of matched pairs
	li $t1, 8             # Total number of matched pairs required
	beq $t0, $t1, game_over  # If matched pairs = 8, the game is over
	li $v0, 0             # Game is not over
	jr $ra                # Return to the caller

game_over:
	li $v0, 1             # Game over (return 1)
	jr $ra                # Return to the caller
