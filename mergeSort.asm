# This MIPS assembly program implements an iterative merge sort to sort an integer list.
# 
# Program Structure:
# 1. `main`: The main function, which initializes and calls helper functions to:
#    - Read input size and list elements from the user.
#    - Print the original list.
#    - Perform iterative merge sort.
#    - Print the sorted list.
# 
#2.   mergeSort subroutine: Implements an iterative merge sort on an array(of maximum size 32).Modifies the original array.
# 
# Inputs:
# - $a0: Size of the array (n).
# - $a1: Base address of the array to sort.
# 
# Operation:
# - Uses an iterative, bottom-up approach to merge sort, starting with subarrays 
#   of size 1 and doubling the size with each iteration until it reaches the 
#   array's total size.
# - Allocates temporary storage on the heap for merging sorted subarrays.
# - In each iteration, it merges adjacent subarrays of the current size, 
#   storing the result in the temporary array and copying it back to the 
#   original array.
# 
# Registers used:
# - $s0: Current subarray size (starting from 1 and doubling each iteration).
# - $s1: Left boundary of the current subarray to be merged.
# - $s3: Address of temporary storage on the heap for the merge results.
# C - code:
#void mergeSort(int *array, int n) {
#    for (int size = 1; size < n; size *= 2) {
#        for (int left = 0; left < n; left += 2 * size) {
#            int mid = (left + size - 1 < n) ? left + size - 1 : n - 1;
#            int right = (left + 2 * size - 1 < n) ? left + 2 * size - 1 : n - 1;
#            merge(array, left, mid, right);
#        }
#    }
#}


		
		.data
n: 			.space 4	# Reserve space for integer n (size of list)
list: 			.space 128	# Reserve space for an integer array of up to 32 integers (128 bytes)	 
nPrompt: 		.asciiz "Enter size of list (n) : " 
listInputPrompt: 	.asciiz "Enter integers for sorting : \n"
originalListPrompt: 	.asciiz "Original list is: "
sortedListPrompt: 	.asciiz "\n Sorted list is: "

		.text
		.globl main
main:
	la $a1,n	# Load address of n into $a1
	la $a2, list	# Load address of list into $a2
	jal readInput	# Call readInput function to read list size and elements

	la $a0, originalListPrompt	# Load address of prompt "Original list is: "
	li $v0, 4			# Print string syscall
	syscall
	lw $a1, n			# Load size of list (n) into $a1
	jal printList			# Call printList to display the original list

	lw $a0, n			# Load list size (n) into $a0
	la $a1, list			# Load address of list into $a1
	jal mergeSort			# Call mergeSort to sort the list

	la $a0, sortedListPrompt	# Load address of prompt "Sorted list is: "
	li $v0, 4			# Print string syscall
	syscall
	lw $a1, n			# Load size of list (n) into $a1
	jal printList			# Call printList to display the sorted list

finish:
	li $v0, 10              # Exit program
	syscall



# mergeSort function: sorts the list using an iterative merge sort
# $a0=n (size), $a1=unordered list, $s3=address for temporary storage (heap)
mergeSort:
	addi $sp,$sp, -4	# Allocate space for return address on stack
	sw $ra, 0($sp) 		# Save return address
 
	addi $sp, $sp, -4	# Allocate space for list size on stack
	sw $a0, 0($sp)		# Save list size (n)
	li $a0, 128		# Set amount to allocate (128 bytes for temp array)
	li $v0, 9		# Syscall code for sbrk (allocate memory)
	syscall
	add $s3, $v0, $0	# Store the address of allocated memory in $s3
	lw $a0, 0($sp)		# Restore list size (n)
	addi $sp, $sp, 4	# Deallocate stack space used for list size

	li $s0, 1		# Initialize subarray size to 1
sortingloop1:
	bge $s0, $a0, exitsortingloop1	# Exit if subarray size >= n
	li $s1, 0			# Initialize left boundary of current subarray
sortingloop2:
	bge $s1, $a0, exitsortingloop2	# Exit inner loop if left boundary >= n
	add $t0, $s0, $s1		# Calculate mid = left + size - 1
	addi $t0,$t0, -1
	addi $t1, $a0, -1
	ble $t0, $t1,midismin		# If mid <= n-1, use mid; otherwise, set mid = n-1
	add $t0, $t1, $0
midismin:
	add $t2, $s0, $s1		# Calculate right = left + 2 * size - 1
	add $t2, $t2, $s0
	addi $t2, $t2, -1
	ble $t2, $t1, rightismin	 # If right <= n - 1, keep right; else, set right = n - 1
	add $t2, $t1, $0
rightismin:
	addi $sp, $sp, -16		# Save registers on stack before calling merge
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	sw $a0, 8($sp)
	sw $a1, 12($sp)
	sll $t3, $s1, 2			# Calculate base address for left part of list to merge
	add $a0, $a1, $t3
	addi $t3, $t0, 1		# Calculate base address for right part of list to merge
	sll $t3, $t3, 2
	add $a1, $a1, $t3
	sll $t3, $s1, 2
	add $a2, $s3, $t3		# Set base address for merged array for temporary storage in heap 
	sub $s0, $t0, $s1
	addi $s0, $s0, 1		# Calculate size of left part of list to merge
	sub $s1, $t2, $t0		# Calculate size of right part of list to merge
	jal merge			# Call merge function
	lw $s0, 0($sp)			# Restore registers after merge
	lw $s1, 4($sp)
	lw $a0, 8($sp)
	lw $a1, 12($sp)
	addi $sp, $sp, 16
	sll $t3, $s0, 1			# Increment left boundary for next merge
	add $s1, $s1, $t3
	j sortingloop2			# Repeat inner sorting loop
exitsortingloop2:
	li $t3,0
movefromheaptolistloop:
	bge $t3, $a0, exitmovefromheaptolistloop	# Copy result from heap to list after every iteration in inner loop
	sll $t4, $t3, 2
	add $t5, $t4, $s3				# Get element from heap
	lw $t6, 0($t5)
	add $t5, $t4, $a1				# Write to original list
	sw $t6, 0($t5)
	addi $t3, $t3, 1
	j movefromheaptolistloop
exitmovefromheaptolistloop:
	sll $s0, $s0, 1		# Double subarray size
	j sortingloop1
exitsortingloop1:
	lw $ra, 0($sp) 		 # Restore return address
	addi $sp,$sp, 4		# Adjust stack pointer
	jr $ra			# Return


# readInput function: reads list size and elements from user input
readInput:
	la $a0, nPrompt		# Prompt for list size
	li $v0, 4
	syscall

	li $v0, 5		# Syscall code for reading integer
	syscall
	sw $v0, 0($a1)		# Store input in n

	la $a0, listInputPrompt	# Prompt for list elements
	li $v0, 4
	syscall

	li $t1,0		# Initialize index
	lw $t2,0($a1)		# Load size of list
inputLoop: 
	beq $t1, $t2, exit	# Exit loop if all elements read
	li $v0, 5
	syscall
	sll $t4, $t1,2
	add $t4, $t4, $a2
	sw $v0, 0($t4)		# Store element in list
	addi $t1, $t1, 1
	j inputLoop
exit:
	jr $ra			# Return



# printList function: prints all elements of the list
printList:
        addi $t0, $0, 0         # Initialize index $t0 to 0
printloop:
        # Loop until all elements in mergedList are printed
        bge $t0, $a1, exitprintloop      # If index >= size of mergedList, exit

        # Calculate the address of mergedList[$t0] and load the element
        sll $t1, $t0, 2         # Multiply $t0 by 4 to get byte offset (4 bytes per word)
        add $t1, $t1, $a2       # Add offset to base address of mergedList
        lw  $t2, 0($t1)         # Load mergedList[$t0] into $t2

        # Print the current element
        li  $v0, 1              # Load syscall code for print integer
        move $a0, $t2           # Move the integer to be printed into $a0
        syscall

        # Print a comma (',') after each element
        li $v0, 11              # Load syscall code for print character
        li $a0,  0x2C           # Load ASCII code for ',' into $a0
        syscall

        # Increment index and repeat
        addi $t0, $t0, 1        # Increment index $t0
        j printloop                  # Jump to loop to print next element

exitprintloop:
        jr $ra                  # Return to caller



# Merge function: merges list1 and list2 into mergedList
merge:
        addi $t0, $0, 0         # Initialize index $t0 for list1
        addi $t1, $0, 0         # Initialize index $t1 for list2
        addi $t6, $0, 0         # Initialize index $t6 for mergedList

loop1:  
        # Check if either list1 or list2 is exhausted
        bge $t0, $s0, loop2     # If $t0 >= size of list1, go to loop2
        bge $t1, $s1, loop2     # If $t1 >= size of list2, go to loop2

        # Load list1[$t0] and list2[$t1]
        sll $t2, $t0, 2         # Multiply $t0 by 4 to get byte offset for list1
        add $t2, $t2, $a0       # Calculate address of list1[$t0]
        lw  $t3, 0($t2)         # Load list1[$t0] into $t3

        sll $t4, $t1, 2         # Multiply $t1 by 4 to get byte offset for list2
        add $t4, $t4, $a1       # Calculate address of list2[$t1]
        lw  $t5, 0($t4)         # Load list2[$t1] into $t5

        # Compare list1[$t0] and list2[$t1], place smaller in mergedList
        bgt $t3, $t5, addFromList2  # If list1[$t0] > list2[$t1], go to addFromList2

        # Add list1[$t0] to mergedList
        sll $t7, $t6, 2         # Multiply $t6 by 4 for byte offset of mergedList
        add $t7, $a2, $t7       # Calculate address of mergedList[$t6]
        sw  $t3, 0($t7)         # Store list1[$t0] into mergedList[$t6]
        addi $t6, $t6, 1        # Increment mergedList index
        addi $t0, $t0, 1        # Increment list1 index
        j loop1                 # Repeat the loop

addFromList2:
        # Add list2[$t1] to mergedList
        sll $t7, $t6, 2         # Multiply $t6 by 4 for byte offset of mergedList
        add $t7, $a2, $t7       # Calculate address of mergedList[$t6]
        sw  $t5, 0($t7)         # Store list2[$t1] into mergedList[$t6]
        addi $t6, $t6, 1        # Increment mergedList index
        addi $t1, $t1, 1        # Increment list2 index
        j loop1                 # Repeat the loop

loop2:
        # Copy remaining elements from list1 to mergedList
        bge $t0, $s0, loop3     # If $t0 >= size of list1, go to loop3
        sll $t2, $t0, 2         # Multiply $t0 by 4 to get byte offset for list1
        add $t2, $t2, $a0       # Calculate address of list1[$t0]
        lw  $t3, 0($t2)         # Load list1[$t0] into $t3
        sll $t7, $t6, 2         # Multiply $t6 by 4 for byte offset of mergedList
        add $t7, $a2, $t7       # Calculate address of mergedList[$t6]
        sw  $t3, 0($t7)         # Store list1[$t0] into mergedList[$t6]
        addi $t6, $t6, 1        # Increment mergedList index
        addi $t0, $t0, 1        # Increment list1 index
        j loop2                 # Repeat the loop

loop3:  
        # Copy remaining elements from list2 to mergedList
        bge $t1, $s1, endOfMerge  # If $t1 >= size of list2, end merge
        sll $t4, $t1, 2         # Multiply $t1 by 4 to get byte offset for list2
        add $t4, $t4, $a1       # Calculate address of list2[$t1]
        lw  $t5, 0($t4)         # Load list2[$t1] into $t5
        sll $t7, $t6, 2         # Multiply $t6 by 4 for byte offset of mergedList
        add $t7, $a2, $t7       # Calculate address of mergedList[$t6]
        sw  $t5, 0($t7)         # Store list2[$t1] into mergedList[$t6]
        addi $t6, $t6, 1        # Increment mergedList index
        addi $t1, $t1, 1        # Increment list2 index
        j loop3                 # Repeat the loop

endOfMerge:
        jr $ra                  # Return to caller
