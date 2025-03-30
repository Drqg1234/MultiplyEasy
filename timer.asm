.data
    	startTime:      .word 0
    	currentTime:    .word 0
    	elapsedTime:    .word 0
    	secondsMsg:     .asciiz " seconds\n"
.text 
	.globl startTimer
	.globl updateTimer

# This module creates a timer that keeps track of your time in the game

startTimer:
    	li $v0, 30             	# Hold time in v0
    	syscall
    	sw $a0, startTime      	# Save startTime
    	jr $ra

updateTimer:
    	li $v0, 30             	# Current time in v0
    	syscall
    	sw $a0, currentTime	# Save current time
    
    	# Calculating time
    	lw $t0, startTime
    	sub $t1, $a0, $t0	# Subtracting startTime and currentTime
    	div $t1, $t1, 1000    	# Divide milliseconds by 1000 to put in seconds
    	sw $t1, elapsedTime	# Save time
    	
    	li $v0, 1
    	lw $a0, elapsedTime 	# Displaying time
    	syscall

	# Print secondsMsg
    	li $v0, 4
    	la $a0, secondsMsg
    	syscall
    
    	jr $ra 			# Return to the caller
