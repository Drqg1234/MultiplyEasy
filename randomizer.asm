.text
	.globl randomizer

# This module generates a random number
# Used in logic.asm to randomize the table
randomizer:
    	# Saving return address
    	addi $sp, $sp, -4
    	sw $ra, ($sp)
    
    	li $v0, 42          # Range
    	move $a1, $a0       # Upper bound
    	li $a0, 0           # 0 = id for generating random num
    	syscall        
    
    	# Putting result in return register
    	move $v0, $a0
    
    	lw $ra, ($sp) # Restoring address
    	addi $sp, $sp, 4
    	jr $ra 			# Return to the caller
    
