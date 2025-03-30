.data
    	# String constants used for displaying messages
    	msg_prompt1:     .asciiz "Enter 1st card to flip! (number input 0-15): "
    	msg_prompt2:     .asciiz "Enter 2nd card to flip! (number input 0-15): "
    	msg_invalid:  	 .asciiz "\nInvalid input. Try again.\n"
    	msg_new_line:    .asciiz "\n"
    	msg_space:       .asciiz " "
    	msg_space_2:	 .asciiz "  "
    	msg_tab:	 .asciiz "\t"
    	msg_hidden:      .asciiz "  ?  "
    	msg_border:      .asciiz "\n -------------------------------\n"
    	msg_vert_line:   .asciiz "|"

.text
    	.globl display_board
    	.globl get_user_input

# Displaying the board at the current state
# Used in logic.asm
display_board:
    # Saving registers to preserve their values across function calls
	addi $sp, $sp, -16          # Adjust stack pointer
	sw $ra, 12($sp)             # Save return address
	sw $s0, 8($sp)              # Save register $s0
	sw $s1, 4($sp)              # Save register $s1
	sw $s2, 0($sp)              # Save register $s2

    # Initializing variables
	li $s0, 0                   # Rows counter
	li $s1, 0                   # Positions counter
	la $s2, board               # Load board base address
	la $s3, expressions         # Load expressions base address
    
    # Print the board
print_row:
    # Print row border
	la $a0, msg_border
	li $v0, 4
	syscall

    # Print left vertical border
	la $a0, msg_vert_line
	li $v0, 4
	syscall
    
	li $t6, 0                  # Counter for columns
	mul $t7, $s0, 4            # Calculate starting position in the row
    
print_row_numbers:
    # Print space before number
	la $a0, msg_space_2
    	li $v0, 4
    	syscall

    # Print the number for this position
	move $a0, $t7
	li $v0, 1
	syscall
	
    # Print tab space
	la $a0, msg_tab
    	li $v0, 4
    	syscall
	
    # Print vertical border after number
	la $a0, msg_vert_line
	li $v0, 4
	syscall
	
    # Increment position and column counter
	addi $t7, $t7, 1
	addi $t6, $t6, 1        
	blt $t6, 4, print_row_numbers # Repeat until all 4 columns are displayed

    # Print new line after row
	la $a0, msg_new_line
	li $v0, 4
	syscall
	
    	li $t0, 0
    
    # Print each card in the row
print_card:
    # Check if the card is revealed
	la $t1, revealed
	add $t1, $t1, $s1      
	lb $t2, ($t1)            # Load revealed status for current card
    
	la $a0, msg_vert_line
	li $v0, 4
	syscall
    
    # Print space before card value
	la $a0, msg_space
	li $v0, 4
	syscall
    
    # If the card isn't revealed, print hidden status
	beqz $t2, print_hidden
    
    # Print the value of the card if it is revealed
	mul $t3, $s1, 5         
	add $t4, $s3, $t3       # Get address of the card's value in expressions

	li $t5, 5                # Counter for printing characters
print_card_value:
	lb $a0, ($t4)            # Load current character of card value
	li $v0, 11               # Print the character
	syscall
	addi $t4, $t4, 1         # Move to next character
	addi $t5, $t5, -1         # Decrement counter
	bgtz $t5, print_card_value    # Loop until all characters printed

    # Print space after the card value
	la $a0, msg_space
	li $v0, 4
	syscall

	# Go to the next card
	j go_next
    
print_hidden:
    # Print hidden card status
	la $a0, msg_hidden
	li $v0, 4
	syscall
    
    # Print space after the hidden card
	la $a0, msg_space
	li $v0, 4
	syscall

go_next:
    # Increment position counter
	addi $t0, $t0, 1     
	addi $s1, $s1, 1      
	blt $t0, 4, print_card  # Print next card until all 4 cards in the row are processed

    # Print vertical border at the end of the row
	la $a0, msg_vert_line
	li $v0, 4
	syscall

    # Move to the next row
	addi $s0, $s0, 1    
	blt $s0, 4, print_row  # Print the next row if there are more rows

    # Print final border at the bottom of the board
	la $a0, msg_border
	li $v0, 4
	syscall
	
    # Restore saved registers
	lw $ra, 12($sp)         # Restore return address
	lw $s0, 8($sp)          # Restore register $s0
	lw $s1, 4($sp)          # Restore register $s1
	lw $s2, 0($sp)          # Restore register $s2
	addi $sp, $sp, 16       # Restore stack pointer
	jr $ra                  # Return from function

# Getting user input
get_user_input:
    	# Saving return address for input handling
    	addi $sp, $sp, -4
    	sw $ra, ($sp)
    
    	# Prompt user for the first card to flip
    	li $v0, 4
    	la $a0, msg_prompt1
    	syscall
    
    	li $v0, 5  	
    	syscall
    
    	# Validating the first input (ensure it's in the range 0-15)
    	bltz $v0, invalidInput      # If negative, go to invalid input
    	bge $v0, 16, invalidInput   # If greater than 15, go to invalid input
    
    	# Check if the first card is already revealed
    	la $t0, revealed
    	add $t0, $t0, $v0
    	lb $t1, ($t0)
    	bnez $t1, invalidInput      # If revealed, go to invalid input
    
    	# Save the first input to a temporary register
    	move $t2, $v0
    
    	# Prompt user for the second card to flip
    	li $v0, 4
    	la $a0, msg_prompt2
    	syscall
    
    	li $v0, 5  
    	syscall
    
    	# Validating the second input (ensure it's in the range 0-15)
    	bltz $v0, invalidInput      # If negative, go to invalid input
    	bge $v0, 16, invalidInput   # If greater than 15, go to invalid input
    
    	# Check if the second card is already revealed
    	la $t0, revealed
    	add $t0, $t0, $v0
    	lb $t1, ($t0)
    	bnez $t1, invalidInput      # If revealed, go to invalid input
    
    	# Ensure the second card is not the same as the first
    	beq $v0, $t2, invalidInput  # If same as first, go to invalid input
    
    	# Store the valid inputs
    	move $a1, $v0    
    	move $a0, $t2    
    
    	# Restore stack and return to the caller
    	lw $ra, ($sp)
    	addi $sp, $sp, 4
    	jr $ra

invalidInput:
    	# Print invalid input message
    	li $v0, 4
    	la $a0, msg_invalid
    	syscall
    
    	# Restore stack and prompt user again
    	addi $sp, $sp, 4
    	j get_user_input
