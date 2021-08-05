.data
	displayAddress:  .word 0x10008000
	
	backgroundColor: .word 0x000000
	centiBodyColor:  .word 0x00ff00
	centiHeadColor:  .word 0xff0000
	blasterColor: 	 .word 0xcccc00
	mushroomColor:   .word 0x964b00
	shotsColor:      .word 0xff9800
	
	centipedLocation:     .word 224, 225, 226, 227, 228, 229, 230, 231, 232, 233
	centipedHead:	      .word 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
	centipedDirection:    .word 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
	
	fleaLocation: .word -1, -1
	fleaBuffer: .word 0, 6
	
	bugLocation:      .word 16
	
	speedBuffer:	  .word 0, 7
	
	projectileLoc: 	  .word -1
	projBuffer:	  .word 0, 1
	
	prevNumShrooms:  .word 16
	maxNumShrooms:   .word 60
	numShrooms:      .word 16
	mushroomAddress: .word 0x10040000
	
	lives: .word 5
	score: .word 0
	
.text

main: 
	jal draw_bg
	jal shroom_gen
	jal draw_top_scoreboard
	jal display_score
	jal display_lives
Loop:
	jal disp_centiped
	jal disp_blaster
	jal disp_shot
	jal draw_mushrooms
	jal display_flea
	jal should_create_more_shrooms
	jal check_centipede_dead
	jal check_if_player_dead
	jal should_deploy_paratrooper_sgt_flea
	jal move_flea
	jal move_centipede
	jal move_shot
	jal check_keystroke
	jal delay
	
	j Loop
	
Exit:
	li $v0, 10 # terminate the program gracefully
	syscall


#functions
draw_top_scoreboard:
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	lw $t0, displayAddress		
	addi $t1, $t0, 896			
	li $t2, 0x808080
			
draw_sb_loop:
	sw $t2, 0($t0)				
	addi $t0, $t0, 4			
	blt $t0, $t1, draw_sb_loop
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra


draw_bg:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t0, displayAddress		
	addi $t1, $t0, 4096			
	lw $t2, backgroundColor				
draw_bg_loop:
	sw $t2, 0($t0)				
	addi $t0, $t0, 4			
	blt $t0, $t1, draw_bg_loop
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

## arg1, max range
get_random_number:
  	li $v0, 42           # Service 42, random int bounded
  	li $a0, 0            # Select random generator 0 
  	syscall              # Generate random int (returns in $a0)
  	jr $ra
  	
# function to display blaster shot
disp_shot:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t0, projectileLoc
	bne $t0, -1, has_fired
	j disp_shot_finish
	has_fired:
	lw $t1, displayAddress
	lw $t2, shotsColor
	
	sll $t0, $t0, 2
	add $t1, $t1, $t0
	sw $t2, 0($t1)
	
disp_shot_finish:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

shoot:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $t0, projectileLoc
	lw $t1, 0($t0)
	beq $t1, -1, can_shoot
	j exit_shoot
	can_shoot:
	lw $t2, bugLocation
	addi $t3, $t2, 960
	sw $t3, 0($t0)
	
exit_shoot:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
move_shot:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	
	la $t0, projectileLoc
	lw $t1, 0($t0)
	bne $t1, -1, has_fired3
	j exit_move_shot
	has_fired3:
	
	jal save_temp_regs
	la $a0, projBuffer
	jal allowed_move
	jal restore_temp_regs
	
	beq $v0, 1, can_move_shot
	j exit_move_shot
	
	
can_move_shot:
	
	lw $t2, displayAddress  
	lw $t3, backgroundColor	
	sll $t4, $t1, 2
	add $t4, $t4, $t2
	sw $t3, 0($t4)	
	
	slti $t2, $t1, 264
	li $v0, 0
	beq $t2, 1, remove_shot
	
	jal save_temp_regs
	addi $a0, $t1, -32
	blt $t1, 960, use_curr
	move $a0, $t1
	use_curr:
	li $a1, 1
	jal check_mushroom_collision
	addi $sp, $sp, -4
	sw $v0, 0($sp)
	jal check_shot_centi_collision
	lw $t9, 0($sp)
	addi $sp, $sp, 4
	or $v0, $t9, $v0
	jal restore_temp_regs
		
	
	beqz $v0, no_shot_collision
remove_shot:
	li $t2, -1
	sw $t2, 0($t0)
	bne $v0, 3, no_head
	li $a0, 100
	j change_score
no_head:
	bne $v0, 2, no_body
	li $a0, 10
	j change_score
no_body:
	bne $v0, 1, no_shroom
	li $a0, 300
	j change_score
no_shroom:
	li $a0, 0
	
change_score:
	jal save_temp_regs
	jal update_score
	jal restore_temp_regs
	
	j exit_move_shot
no_shot_collision:
	addi $t2, $t1, -32
	sw $t2, 0($t0)
	jal save_temp_regs
	jal disp_shot
	jal restore_temp_regs
	
exit_move_shot:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
  
# function to display bug blaster
disp_blaster:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $t0, bugLocation	# load the address of buglocation from memory
	lw $t1, 0($t0)		# load the bug location itself in t1
	
	lw $t2, displayAddress  # $t2 stores the base address for display	
	lw $t3, blasterColor	# $t3 stores the yellow colour code
	
	sll $t4,$t1, 2
	add $t4, $t2, $t4
	addi $t4, $t4, 3968
	sw $t3, 0($t4)		# paint the first (top-left) unit yellow.
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
 
# function to display a centipede
disp_centiped:
	# move stack pointer a word and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	addi $a3, $zero, 10	  # load a3 with the loop count (10)
	la $a1, centipedLocation  # load the address of the array into $a1
	la $a2, centipedDirection # load the address of the array into $a2
	la $s0, centipedHead
	
arr_loop:	#iterate over the loops elements to draw each body in the centiped
	lw $t1, 0($a1)		 # load a word from the centipedLocation array into $t1
	lw $t5, 0($a2)		 # load a word from the centipedDirection  array into $t5
	lw $t6, 0($s0)		 # load a word from the cetipedeHead array into $t6
	
	beq $t1, -1, dont_update_2

	lw $t2, displayAddress  # $t2 stores the base address for display
	lw $t3, centiBodyColor	# $t3 stores the green colour code
	lw $t7, centiHeadColor  # $t7 stores the red color code
	
	sll $t4,$t1, 2		# $t4 is the bias of the old body location in memory (offset*4)
	add $t4, $t2, $t4	# $t4 is the address of the old bug location
	
	bne $t6, 1, not_head
	sw $t7, 0($t4)
	not_head:
	bnez $t6, not_body
	sw $t3, 0($t4)		# paint the body with green
	not_body:
	
dont_update_2:	
	addi $a1, $a1, 4	 # increment $a1 by one, to point to the next element in the array
	addi $a2, $a2, 4
	addi $s0, $s0, 4
	addi $a3, $a3, -1	 # decrement $a3 by 1
	bne $a3, $zero, arr_loop
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

# Function to Draw Mushrooms
draw_mushrooms:	
	addi $sp, $sp, -4	# Store return address onto stack
	sw $ra, 0($sp)
	
	lw $t0, displayAddress
	li $t1, 0
	lw $t2, mushroomColor
	lw $t3, mushroomAddress
	lw $t6, numShrooms
	
	beqz $t6, exit_draw_mushrooms
draw_shroom_loop:		#Loop over each mushroom, and draw it onto the display
	lh $t4, 0($t3)
	lh $t5, 2($t3)
	addi $t3, $t3, 4
	mul $t4, $t4, 4
	mul $t5, $t5, 128
	add $t4, $t4, $t5
	add $t0, $t0, $t4
	sw $t2, 0($t0)
	addi $t1, $t1, 1
	lw $t0, displayAddress
	blt $t1, $t6, draw_shroom_loop

exit_draw_mushrooms:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
# function to detect any keystroke
check_keystroke:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t8, 0xffff0000
	beq $t8, 1, get_keyboard_input # if key is pressed, jump to get this key
	addi $t8, $zero, 0
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
# function to get the input key
get_keyboard_input:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t2, 0xffff0004
	addi $v0, $zero, 0	#default case
	bne $t2, 0x6A, not_j
	jal respond_to_j
	not_j:
	bne $t2, 0x6B, not_k
	jal respond_to_k
	not_k:
	bne $t2, 0x78, not_x
	jal respond_to_x
	not_x:
	bne $t2, 0x73, not_s
	jal respond_to_s
	not_s:
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
# Call back function of j key
respond_to_j:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $t0, bugLocation	# load the address of buglocation from memory
	lw $t1, 0($t0)		# load the bug location itself in t1
	
	beq $t1, 0, skip_movement # prevent the bug from getting out of the canvas
		
	lw $t2, displayAddress  # $t2 stores the base address for display
	lw $t3, blasterColor	# $t3 stores the blaster colour code
	
	sll $t4,$t1, 2		# $t4 the bias of the old buglocation
	add $t4, $t2, $t4	# $t4 is the address of the old bug location
	addi $t4, $t4, 3964
	sw $t3, 0($t4)		# paint the first (top-left) unit blaster color.
	
	lw $t3, backgroundColor	# $t3 stores the black colour code
	sll $t4,$t1, 2		# $t4 the bias of the old buglocation
	add $t4, $t2, $t4	# $t4 is the address of the old bug location
	addi $t4, $t4, 3968
	sw $t3, 0($t4)		# paint the first (top-left) unit black.
	
	addi $t1, $t1, -1	# move the bug one location to the right
skip_movement:
	sw $t1, 0($t0)		# save the bug location
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

# Call back function of k key
respond_to_k:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $t0, bugLocation	# load the address of buglocation from memory
	lw $t1, 0($t0)		# load the bug location itself in t1
	

	beq $t1, 31, skip_movement2 #prevent the bug from getting out of the canvas
	
	lw $t2, displayAddress  # $t2 stores the base address for display

	lw $t3, blasterColor	# $t3 stores the black colour code
	
	sll $t4,$t1, 2		# $t4 the bias of the old buglocation
	add $t4, $t2, $t4	# $t4 is the address of the old bug location
	addi $t4, $t4, 3972
	sw $t3, 0($t4)		# paint the first (top-left) unit blaster color.
	
	lw $t3, backgroundColor	# $t3 stores the black colour code
	
	sll $t4,$t1, 2		# $t4 the bias of the old buglocation
	add $t4, $t2, $t4	# $t4 is the address of the old bug location
	addi $t4, $t4, 3968
	sw $t3, 0($t4)		# paint the block with black
	
	addi $t1, $t1, 1	# move the bug one location to the right
skip_movement2:
	sw $t1, 0($t0)		# save the bug location

	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
respond_to_x:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	jal shoot
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
respond_to_s:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
move_centipede:
	addi $sp, $sp, -4	# Add Return Address to stack
	sw $ra, 0($sp)
	
	la $t1, centipedLocation
	la $t2, centipedDirection
	li $t3, 0
	
	jal save_temp_regs
	la $a0, speedBuffer
	jal allowed_move
	jal restore_temp_regs
	beq $v0, 1, can_move_centi
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
can_move_centi:
	lw $t4, displayAddress
	lw $t0, backgroundColor
	
	lw $t6, 0($t1)	# Location
	lw $t7, 0($t2)	# Direction
	
	beq $t6, -1, dont_update
	
	sll $t8, $t6, 2
	add $t8, $t8, $t4
	sw $t0, 0($t8)

	# Iterate through all centipede positions and update by 1 position over
	# Within iteration, check if we will hit a wall, and if we do go down
move_centipede_loop:
	lw $t6, 0($t1)	# Location
	lw $t7, 0($t2)	# Direction
	li $s2, 0
	sll $s3, $t3, 2
	la $s4, centipedHead
	add $s4, $s4, $s3
	lw $s4, 0($s4)
	
	beq $t6, -1, dont_update
	
	beq $t3, 0, is_tail
	lw $t9, -4($t1)
	bne $t9, -1, is_tail
	move $s1, $t6	
	bne $s4, 1, not_head2
	li $s2, 1
	j is_tail
not_head2:	
	sll $t8, $s1, 2
	add $t8, $t8, $t4
	sw $t0, 0($t8)
	
is_tail: 
	beq $s4, 1, is_head
	lw $t9, 4($t1)
	sub $t9, $t9, $t6
	add $t6, $t6, $t9
	j exit_centi_move
	
is_head:
	bne $t7, 1, move_left			#  Moving Right
			
	addi $t5, $t6, -31			#  Checks collison of right wall
	li $s0, 32				
	div $t5, $s0
	mfhi $t5				
	beq  $t5, 0, move_downward_right
	
	jal save_temp_regs			# Checks collison of mushroom
	addi $a0, $t6, 1
	jal check_collision_with_player
	jal restore_temp_regs	
	beq $v0, 1, complete_exit
	li $a1, 0
	jal save_temp_regs			
	jal check_mushroom_collision
	jal restore_temp_regs
	beq $v0, 1, move_downward_right

			
	addi $t6, $t6, 1			# Actually move right
	j exit_centi_move
	
move_left:					# Moving Left	
	li $s0, 32				# Checks collison of left wall
	div $t6, $s0	
	mfhi $t5
	beq  $t5, 0, move_downward_left
	
	jal save_temp_regs			## Checks collison of mushroom ##
	addi $a0, $t6, -1
	jal check_collision_with_player
	jal restore_temp_regs
	beq $v0, 1, complete_exit
	li $a1, 0
	jal save_temp_regs				
	jal check_mushroom_collision		#				#
	jal restore_temp_regs			#				#
	beq $v0, 1, move_downward_left		#################################
			
	addi $t6, $t6, -1			# Actually move left
	j exit_centi_move

move_downward_right:
	blt $t6, 992, less_992
	addi $t6, $t6, -32
	j greater_992
less_992:
	addi $t6, $t6, 32
greater_992:
	li $t7, 0
	sw $t7, 0($t2)
	j exit_centi_move
move_downward_left:
	blt $t6, 992, less_992_2
	addi $t6, $t6, -32
	j greater_992_2
less_992_2:
	addi $t6, $t6, 32
greater_992_2:
	li $t7, 1
	sw $t7, 0($t2)
	j exit_centi_move
	
exit_centi_move:
	bne $s2, 1, not_tail
	lw $t9, centiHeadColor
	sll $t8, $t6, 2
	add $t8, $t8, $t4
	sw $t9, 0($t8)
	
	sll $t8, $s1, 2
	add $t8, $t8, $t4
	sw $t0, 0($t8)
not_tail: 
	sw $t6, 0($t1)

dont_update:	
	addi $t1, $t1, 4
	addi $t2, $t2, 4
	addi $t3, $t3, 1

	blt $t3, 10, move_centipede_loop

complete_exit:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	

# Function to check mushroom collison:
# Returns 1 if an object will collide into a mushroom if moved
# Arguments: 
# - arg 0: takes in next position of the object to check collision
# - arg 1: 1 if u want to destroy mushrooms on collision 0 otherwise
check_mushroom_collision:
	
	# move stack pointer a word and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t0, mushroomAddress
	lw $t1, numShrooms
	li $t2, 0
	
	beqz $t1, no_collision
	
	sll $t6, $a0, 2
	
	# Loop over all the mushroom positions 
collision_loop:
	
	# Get mushroom x.y
	lh $t3, 0($t0)
	lh $t4, 2($t0)
	
	# Convert x and y into display addressable
	sll $t3, $t3, 2
	sll $t4, $t4, 7
	add $t3, $t3, $t4
	
	bne $t3, $t6, no_collision
	li $v0, 1
	bne $a1, 1, no_destroy
	move $a0, $t2
	jal remove_mushroom
no_destroy:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
no_collision:
	
	addi $t2, $t2, 1
	addi $t0, $t0, 4
	blt $t2, $t1, collision_loop
	
	li $v0, 0
	lw $ra, 0($sp)
	addi $sp, $sp, 4	
	jr $ra

# Function to check mushroom collison:
# Returns 1 if a shot will collide into a centi body if moved
# Arguments: 
# - arg 0: takes in next position of the object to check collision against centi
check_shot_centi_collision:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	li $v0, 2
	la $t0, centipedLocation
	la $t1, centipedHead
	li $t2, 0
	
centi_collision_loop:
	lw $t3, 0($t0)
	lw $t4, 0($t1)
	
	bne $t3, $a0, no_shot_collision2
	bne $t4, 1, hit_body		
	li $v0, 3
	bnez $t2, not_0th
	j has_no_left2
not_0th:	
	j not_0th2
has_no_left:
	j has_no_left2
hit_body:	
	bnez $t2, not_0th2
	j has_no_left2
not_0th2:	
	lw $t5, -4($t0)
	beq $t5, -1, has_no_left2	
	li $t3, -1
	sw $t3, 0($t0)
	sw $zero, 0($t1)
	li $t3, 1
	sw $t3, -4($t1)
	
	j create_mushroom_on_collision
has_no_left2:	
	li $t3, -1
	sw $t3, 0($t0)
	sw $zero, 0($t1)	
	j create_mushroom_on_collision
	
no_shot_collision2:
	addi $t0, $t0, 4
	addi $t1, $t1, 4
	addi $t2, $t2, 1
	blt $t2, 10, centi_collision_loop
	
	li $v0, 0
	j exit_centi_collision
create_mushroom_on_collision:
	jal save_temp_regs
	jal make_mushroom
	jal restore_temp_regs
	j exit_centi_collision
	
exit_centi_collision:
	lw $ra, 0($sp)
	addi $sp, $sp, 4	
	jr $ra
	
#####################################################
# -a0 location to place shroom in pixel number
make_mushroom:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t0, mushroomAddress
	la $t8, numShrooms
	lw $t1, 0($t8)
	
	li $t9, 32
	div $a0, $t9
	mfhi $t2
	sub $t3, $a0, $t2
	div $t3, $t3, 32
	
	sll $t1, $t1, 2
	add $t0, $t0, $t1
	sh $t2, 0($t0)
	addi $t0, $t0, 2
	sh $t3, 0($t0)
	
	lw $t1, 0($t8)
	addi $t1, $t1, 1
	sw $t1, 0($t8)
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4	
	jr $ra
	
save_temp_regs:
	addi $sp, $sp, -4
	sw $t0, 0($sp)	
	addi $sp, $sp, -4
	sw $t1, 0($sp)	
	addi $sp, $sp, -4
	sw $t2, 0($sp)	
	addi $sp, $sp, -4
	sw $t3, 0($sp)	
	addi $sp, $sp, -4
	sw $t4, 0($sp)
	addi $sp, $sp, -4
	sw $t5, 0($sp)
	addi $sp, $sp, -4
	sw $t6, 0($sp)	
	addi $sp, $sp, -4
	sw $t7, 0($sp)	
	addi $sp, $sp, -4
	sw $t8, 0($sp)	
	addi $sp, $sp, -4
	sw $t9, 0($sp)

	jr $ra
	
restore_temp_regs:
	lw $t9, 0($sp)
	addi $sp, $sp, 4	
	lw $t8, 0($sp)
	addi $sp, $sp, 4
	lw $t7, 0($sp)
	addi $sp, $sp, 4
	lw $t6, 0($sp)
	addi $sp, $sp, 4
	lw $t5, 0($sp)
	addi $sp, $sp, 4	
	lw $t4, 0($sp)
	addi $sp, $sp, 4	
	lw $t3, 0($sp)
	addi $sp, $sp, 4	
	lw $t2, 0($sp)
	addi $sp, $sp, 4	
	lw $t1, 0($sp)
	addi $sp, $sp, 4	
	lw $t0, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
##################################################
# a0 - address to buffer size 2 array
# v0 - 1 if can move, 0 if not
allowed_move:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	move $t5, $a0
	lw $t8, 0($t5)
	lw $t9, 4($t5)
	
	beq $t8, $t9, allow_move
	addi $t8, $t8, 1
	sw $t8, 0($t5)
	
	li $v0, 0
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
allow_move:
	li $t8, 0
	sw $t8, 0($t5)
	
	li $v0, 1
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

update_score:
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	lw $t0, score
	add $t0, $t0, $a0
	sw $t0, score
	jal save_temp_regs
	jal display_score
	jal restore_temp_regs
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

display_score:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
		
	li $t0, 0
	li $t1, 60
	li $t2, 10
	li $t3, 0x800020
display_score_loop:
	
	move $a0, $t2
	move $a1, $t1
	move $a2, $t3
	jal save_temp_regs
	jal calculate_number_in_col
	move $a0, $v0
	jal display_number
	jal restore_temp_regs
	addi $t1, $t1, -4
	mul $t2, $t2, 10
	addi $t0, $t0, 1
	blt $t0, 5, display_score_loop

	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
calculate_number_in_col:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t1, score
	move $t2, $a0
	div $t1, $t2
	mfhi $t3

	div $t2, $t2, 10
	div $t1, $t2
	mfhi $t4
	sub $t3, $t3, $t4
	div $t3, $t3, $t2

	move $v0, $t3
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
update_lives:
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	lw, $t0, lives
	addi $t0, $t0, -1
	sw $t0, lives
	jal save_temp_regs
	jal display_lives
	jal restore_temp_regs
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

display_lives:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $a0, lives
	li $a1, 33
	li $a2, 0xffd700
	jal display_number
	
	lw $t0, displayAddress
	addi $t1, $a1, 68
	sll $t1, $t1, 2
	add $t1, $t0, $t1
	
	sw $a2, 0($t1)
	sw $a2, -124($t1)
	sw $a2, 8($t1)

	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
display_number:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t1, displayAddress
	move $t2, $a2
	
	sll $t3, $a1, 2	
	add $t3, $t3, $t1
	
	jal save_temp_regs
	jal clear_3x5_gray
	jal restore_temp_regs
	
	beq $a0, 0, display_0
	beq $a0, 1, display_1
	beq $a0, 2, display_2
	beq $a0, 3, display_3
	beq $a0, 4, display_4
	beq $a0, 5, display_5
	beq $a0, 6, display_6
	beq $a0, 7, display_7
	beq $a0, 8, display_8
	beq $a0, 9, display_9

display_0:
	sw $t2, 0($t3)
	sw $t2, 4($t3)
	sw $t2, 8($t3)
	sw $t2, 128($t3)
	sw $t2, 136($t3)
	sw $t2, 256($t3)
	sw $t2, 264($t3)
	sw $t2, 384($t3)
	sw $t2, 392($t3)
	sw $t2, 516($t3)
	sw $t2, 520($t3)
	sw $t2, 512($t3)
	j exit_display_number	
display_1:
	sw $t2, 8($t3)
	sw $t2, 136($t3)
	sw $t2, 264($t3)
	sw $t2, 392($t3)
	sw $t2, 520($t3)
	j exit_display_number
display_2:
	sw $t2, 0($t3)
	sw $t2, 4($t3)
	sw $t2, 8($t3)
	sw $t2, 136($t3)
	sw $t2, 264($t3)
	sw $t2, 260($t3)
	sw $t2, 256($t3)
	sw $t2, 384($t3)
	sw $t2, 512($t3)
	sw $t2, 516($t3)
	sw $t2, 520($t3)
	j exit_display_number
display_3:
	sw $t2, 0($t3)
	sw $t2, 4($t3)
	sw $t2, 8($t3)
	sw $t2, 136($t3)
	sw $t2, 264($t3)
	sw $t2, 260($t3)
	sw $t2, 256($t3)
	sw $t2, 392($t3)
	sw $t2, 520($t3)
	sw $t2, 516($t3)
	sw $t2, 512($t3)
	j exit_display_number
display_4:
	sw $t2, 0($t3)
	sw $t2, 8($t3)
	sw $t2, 128($t3)
	sw $t2, 136($t3)
	sw $t2, 256($t3)
	sw $t2, 260($t3)
	sw $t2, 264($t3)
	sw $t2, 392($t3)
	sw $t2, 520($t3)
	j exit_display_number
display_5:
	sw $t2, 0($t3)
	sw $t2, 4($t3)
	sw $t2, 8($t3)
	sw $t2, 128($t3)
	sw $t2, 256($t3)
	sw $t2, 260($t3)
	sw $t2, 264($t3)
	sw $t2, 392($t3)
	sw $t2, 520($t3)
	sw $t2, 516($t3)
	sw $t2, 512($t3)
	j exit_display_number
display_6:
	sw $t2, 384($t3)
	j display_5
display_7:
	sw $t2, 0($t3)
	sw $t2, 4($t3)
	j display_1
display_8:
	sw $t2, 4($t3)
	sw $t2, 8($t3)
	sw $t2, 136($t3)
	j display_6
display_9:
	sw $t2, 128($t3)
	sw $t2, 256($t3)
	sw $t2, 260($t3)
	j display_7

exit_display_number:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

clear_3x5_gray:
	lw $t1, displayAddress
	li $t2, 0x808080	
	sll $t3, $a1, 2	
	add $t3, $t3, $t1
	sw $t2, 0($t3)
	sw $t2, 4($t3)
	sw $t2, 8($t3)
	sw $t2, 128($t3)
	sw $t2, 132($t3)
	sw $t2, 136($t3)
	sw $t2, 256($t3)
	sw $t2, 260($t3)
	sw $t2, 264($t3)	
	sw $t2, 384($t3)
	sw $t2, 388($t3)
	sw $t2, 392($t3)	
	sw $t2, 512($t3)
	sw $t2, 516($t3)
	sw $t2, 520($t3)
	jr $ra

remove_mushroom:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t0, numShrooms
	lw $t1, mushroomAddress
	sll $t4, $t0, 2
	addi $t4, $t4, -4
	add $t2, $t1, $t4
	sll $t5, $a0, 2
	add $t3, $t1, $t5
	
	lw $t5, 0($t3)
	
	lw $t0, 0($t2)
	sw $t0, 0($t3)
	sw $zero, 0($t2)
	lw $t0, numShrooms
	addi $t0, $t0, -1
	sw $t0, numShrooms
	
	lw $t0, displayAddress
	li $t1, 0
	
	andi $t6, $t5, 0x0000ffff 
	andi $t7, $t5, 0xffff0000 
	srl $t7, $t7, 16
	
	lw $t8, displayAddress
	sll $t6, $t6, 2
	sll $t7, $t7, 7
	add $t6, $t6, $t7
	add $t8, $t6, $t8
	sw $zero, 0($t8)
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

	
check_centipede_dead:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	li $v0, 0
	la $t0, centipedLocation
	li $t1, 0
	li $t4, 0
	
check_centipede_dead_loop:
	lw $t2, 0($t0)
	
	bne $t2, -1, check_centipede_dead_exit
	addi $t4, $t4, 1
	addi $t1, $t1, 1
	addi $t0, $t0, 4

	blt $t1, 10, check_centipede_dead_loop
	
	bne $t4, 10, check_centipede_dead_exit
	li $v0, 1
	jal save_temp_regs
	jal reset_centipede
	jal restore_temp_regs
	
check_centipede_dead_exit:	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra	

reset_centipede:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	li $t0, 0
	li $t1, 224
	li $t3, 1
	
reset_centipede_loop:
	sll $t2, $t0, 2
	
	lw $t4, centipedLocation($t2)
	beq $t4, -1, dont_need_to_clear
	lw $t5, displayAddress  
	lw $t6, backgroundColor	
	sll $t4, $t4, 2
	add $t4, $t4, $t5
	sw $t3, 0($t4)	
dont_need_to_clear:
	sw $t1, centipedLocation($t2)
	sw $zero, centipedHead($t2)

	sw $t3, centipedDirection($t2)
	
	
	addi $t0, $t0, 1
	addi $t1, $t1, 1
	blt $t0, 10, reset_centipede_loop
	
	sw $t3, centipedHead($t2)

	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra


move_flea:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $t0, fleaLocation
	lw $t1, 0($t0)
	lw $t0, 4($t0)
	bne $t1, -1, deployed_flea
	j exit_move_flea
	deployed_flea:
	
	jal save_temp_regs
	la $a0, fleaBuffer
	jal allowed_move
	jal restore_temp_regs
	
	beq $v0, 1, can_move_flea
	j exit_move_flea
can_move_flea:
	lw $t2, displayAddress  
	lw $t3, backgroundColor	
	sll $t4, $t1, 2
	add $t4, $t4, $t2
	sw $t3, 0($t4)	

	sgt $t3, $t0, 991
	
	# Check Collision with bug blaster
	jal save_temp_regs
	addi $a0, $t0, 32
	jal check_collision_with_player
	jal restore_temp_regs

did_not_hit_player:
	bne $t3, 1, not_at_bottom
	lw $t2, displayAddress  
	lw $t3, backgroundColor	
	sll $t4, $t0, 2
	add $t4, $t4, $t2
	sw $t3, 0($t4)
		
	li $t3, -1
	sw $t3, fleaLocation
	sw $t3, fleaLocation + 4
	sw $zero, fleaBuffer

	j exit_move_flea
not_at_bottom:
	
	addi $t1, $t1, 32
	addi $t0, $t0, 32
	sw $t1, fleaLocation
	sw $t0, fleaLocation + 4
	
	jal display_flea
	
exit_move_flea:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

deploy_paratrooper_sgt_flea:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $t0, fleaLocation
	add $a1, $zero, 32
	jal get_random_number
	addi $t1, $a0, 224
	sw $t1, 0($t0)
	addi $t1, $t1, 32
	sw $t1, 4($t0)
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

should_deploy_paratrooper_sgt_flea:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	# Will deploy flea on random based on a uniform probability distribution
	add $a1, $zero, 100
	jal get_random_number
	
	lw $t0, fleaLocation
	seq $t0, $t0, -1
	seq $t1, $a0, 20
	and $t1, $t1, $t0
	bne $t1, 1, dont_deploy
	jal deploy_paratrooper_sgt_flea
	
dont_deploy:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
display_flea:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $t0, fleaLocation	
	lw $t1, 0($t0)		
	lw $t0, 4($t0)		
	
	lw $t2, displayAddress  	
	li $t3, 0x800080	
	li $t5, 0xffffff	
	
	sll $t4,$t1, 2
	add $t4, $t2, $t4
	sw $t5, 0($t4)
		
	sll $t4,$t0, 2
	add $t4, $t2, $t4
	sw $t3, 0($t4)	
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
check_collision_with_player:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	li $v0, 0
	lw $t0, bugLocation
	addi $t0, $t0, 992
	bne $t0, $a0, did_not_hit_player2
	lw $t4, displayAddress
	lw $t9, backgroundColor
	sll $t8, $t0, 2
	add $t8, $t8, $t4
	sw $t9, 0($t8)
	li $t3, 16
	sw $t3, bugLocation
	li $v0, 1
	jal update_lives
	jal reset_centipede
did_not_hit_player2:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	

should_create_more_shrooms:
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	lw $t0, numShrooms
	bgt $t0, 10, dont_create_more
	jal save_temp_regs
	jal check_centipede_dead
	jal restore_temp_regs
	bne $v0, 1, dont_create_more
	lw $t1, prevNumShrooms
	lw $t2, maxNumShrooms
	addi $t1, $t1, 3
	blt $t1, $t2, dont_cap
	move $t1, $t2
	dont_cap:
	sw $t1, numShrooms
	sw $t1, prevNumShrooms
	jal shroom_gen
	
dont_create_more:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
shroom_gen:
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	li $t0, 0		# Counter for number of shrooms
	lw $t1, numShrooms 	# Maximum number of shrooms to load in initially
	lw $t2, mushroomAddress # Positions of shrooms
	
shroom_init_loop:
	
	add $a1, $zero, 32          
	jal get_random_number   #Get random X position
	sh $a0, 0($t2) 		# Store the x position of the mushroom
	add $t7,$zero, $a0
	
	add $a1, $zero, 32          
	jal get_random_number 	#Get random Y position
	
	bgt $a0, 7, NOT_TOP	#If the y pos is below the 3 rows then add 3 to it
	addi $a0, $a0, 8
NOT_TOP:
	
	blt $a0, 29, NOT_BOT	#If the y pos it above row 29 sub 3 to it
	subi $a0, $a0, 3
NOT_BOT:
	
	addi $t4, $zero, 0	
	lw $t5, mushroomAddress
dup_pos:			# Iterate over all mushroom positions in the heap and 
	lb $t8, 0($t5)		# check if the positions equal both generate x and y
	lb $t6, 2($t5)
	addi $t4, $t4, 1
	addi $t5, $t5, 2

	seq $t8, $t8, $t7
	seq $t6, $t6, $a0
	and $t8, $t8, $t6
	bne $t8, 0, shroom_init_loop
	blt $t4, $t0, dup_pos

	sh $a0, 2($t2)
	#increment shroom counter
	addi $t0, $t0, 1
	
	# Go to next address for mushroom data
	addi $t2, $t2, 4
	blt $t0, $t1, shroom_init_loop
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
check_if_player_dead:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t0, lives
	bnez $t0, not_dead
	jal display_game_over
	j Exit
not_dead:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

display_game_over:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	jal draw_bg
	lw $t0, displayAddress
	li $t1, 0xffffff
	li $t2, 0xff0000
	
	addi $t0, $t0, 896
	sw $t1, 48($t0)
	sw $t1, 52($t0)
	sw $t1, 56($t0)
	sw $t1, 60($t0)
	sw $t1, 64($t0)
	sw $t1, 68($t0)
	sw $t1, 72($t0)
	
	addi $t0, $t0, 128
	sw $t1, 40($t0)
	sw $t1, 44($t0)
	sw $t1, 48($t0)
	sw $t1, 52($t0)
	sw $t1, 56($t0)
	sw $t1, 60($t0)
	sw $t1, 64($t0)
	sw $t1, 68($t0)
	sw $t1, 72($t0)
	sw $t1, 76($t0)
	sw $t1, 80($t0)
	
	addi $t0, $t0, 128
	sw $t1, 40($t0)
	sw $t1, 44($t0)
	sw $t1, 48($t0)
	sw $t1, 52($t0)
	sw $t1, 56($t0)
	sw $t1, 60($t0)
	sw $t1, 64($t0)
	sw $t1, 68($t0)
	sw $t1, 72($t0)
	sw $t1, 76($t0)
	sw $t1, 80($t0)
	
	addi $t0, $t0, 128
	sw $t1, 36($t0)
	sw $t1, 40($t0)
	sw $t1, 44($t0)
	sw $t1, 48($t0)
	sw $t1, 52($t0)
	sw $t1, 56($t0)
	sw $t1, 60($t0)
	sw $t1, 64($t0)
	sw $t1, 68($t0)
	sw $t1, 72($t0)
	sw $t1, 76($t0)
	sw $t1, 80($t0)
	sw $t1, 84($t0)
	
	addi $t0, $t0, 128
	sw $t1, 36($t0)
	sw $t1, 40($t0)
	sw $t1, 44($t0)
	sw $t1, 48($t0)
	sw $t1, 52($t0)
	sw $t1, 56($t0)
	sw $t1, 60($t0)
	sw $t1, 64($t0)
	sw $t1, 68($t0)
	sw $t1, 72($t0)
	sw $t1, 76($t0)
	sw $t1, 80($t0)
	sw $t1, 84($t0)
	
	addi $t0, $t0, 128
	sw $t1, 32($t0)
	sw $t1, 36($t0)
	sw $t1, 56($t0)
	sw $t1, 60($t0)
	sw $t1, 84($t0)
	sw $t1, 88($t0)
	
	addi $t0, $t0, 128
	sw $t1, 32($t0)
	sw $t1, 36($t0)
	sw $t1, 56($t0)
	sw $t1, 60($t0)
	sw $t1, 84($t0)
	sw $t1, 88($t0)
	
	addi $t0, $t0, 128
	sw $t1, 32($t0)
	sw $t1, 56($t0)
	sw $t1, 60($t0)
	sw $t1, 88($t0)
	addi $t0, $t0, 128
	sw $t1, 32($t0)
	sw $t1, 56($t0)
	sw $t1, 60($t0)
	sw $t1, 88($t0)
	addi $t0, $t0, 128
	sw $t1, 32($t0)
	sw $t1, 56($t0)
	sw $t1, 60($t0)
	sw $t1, 88($t0)
	addi $t0, $t0, 128
	sw $t1, 32($t0)
	sw $t1, 56($t0)
	sw $t1, 60($t0)
	sw $t1, 88($t0)
	
	addi $t0, $t0, 128
	sw $t1, 32($t0)
	sw $t1, 36($t0)
	sw $t1, 40($t0)
	sw $t1, 56($t0)
	sw $t1, 60($t0)
	sw $t1, 76($t0)
	sw $t1, 80($t0)
	sw $t1, 84($t0)
	
	addi $t0, $t0, 128
	sw $t1, 40($t0)
	sw $t1, 44($t0)
	sw $t1, 48($t0)
	sw $t1, 52($t0)
	sw $t1, 56($t0)
	sw $t1, 60($t0)
	sw $t1, 64($t0)
	sw $t1, 68($t0)
	sw $t1, 72($t0)
	sw $t1, 76($t0)
	sw $t1, 80($t0)
	
	addi $t0, $t0, 128
	sw $t1, 40($t0)
	sw $t1, 44($t0)
	sw $t1, 48($t0)
	sw $t1, 52($t0)
	sw $t1, 64($t0)
	sw $t1, 68($t0)
	sw $t1, 72($t0)
	sw $t1, 76($t0)
	
	addi $t0, $t0, 128
	sw $t1, 40($t0)
	sw $t1, 44($t0)
	sw $t1, 48($t0)
	sw $t1, 52($t0)
	sw $t1, 64($t0)
	sw $t1, 68($t0)
	sw $t1, 72($t0)
	sw $t1, 76($t0)
	
	addi $t0, $t0, 128
	sw $t1, 40($t0)
	sw $t1, 44($t0)
	sw $t1, 48($t0)
	sw $t1, 52($t0)
	sw $t1, 56($t0)
	sw $t1, 60($t0)
	sw $t1, 64($t0)
	sw $t1, 68($t0)
	sw $t1, 72($t0)
	sw $t1, 76($t0)
	
	addi $t0, $t0, 128
	sw $t1, 40($t0)
	sw $t1, 48($t0)
	sw $t1, 52($t0)
	sw $t1, 60($t0)
	sw $t1, 64($t0)
	sw $t1, 72($t0)
	sw $t1, 76($t0)
	
	addi $t0, $t0, 128
	sw $t1, 40($t0)
	sw $t1, 48($t0)
	sw $t1, 52($t0)
	sw $t1, 60($t0)
	sw $t1, 64($t0)
	sw $t1, 72($t0)
	sw $t1, 76($t0)
	
	addi $t0, $t0, 256
	sw $t2, 24($t0)
	sw $t2, 28($t0)
	sw $t2, 32($t0)
	sw $t2, 36($t0)
	sw $t2, 44($t0)
	sw $t2, 48($t0)
	sw $t2, 52($t0)
	sw $t2, 56($t0)
	sw $t2, 64($t0)
	sw $t2, 68($t0)
	sw $t2, 72($t0)
	sw $t2, 76($t0)
	sw $t2, 84($t0)
	sw $t2, 88($t0)
	sw $t2, 92($t0)
	sw $t2, 96($t0)
	
	addi $t0, $t0, 128
	sw $t2, 24($t0)
	sw $t2, 36($t0)
	sw $t2, 44($t0)
	sw $t2, 64($t0)
	sw $t2, 76($t0)	
	sw $t2, 84($t0)
	sw $t2, 96($t0)
	
	addi $t0, $t0, 128
	sw $t2, 24($t0)
	sw $t2, 36($t0)
	
	sw $t2, 44($t0)
	sw $t2, 48($t0)
	sw $t2, 52($t0)
	sw $t2, 56($t0)
	
	sw $t2, 64($t0)
	sw $t2, 68($t0)
	sw $t2, 72($t0)
	sw $t2, 76($t0)
	sw $t2, 84($t0)
	sw $t2, 96($t0)
	
	addi $t0, $t0, 128
	sw $t2, 24($t0)
	sw $t2, 36($t0)
	sw $t2, 44($t0)
	sw $t2, 64($t0)
	sw $t2, 76($t0)
	sw $t2, 84($t0)
	sw $t2, 96($t0)
	
	addi $t0, $t0, 128
	sw $t2, 24($t0)
	sw $t2, 28($t0)
	sw $t2, 32($t0)
	sw $t2, 36($t0)	
	sw $t2, 44($t0)
	sw $t2, 48($t0)
	sw $t2, 52($t0)
	sw $t2, 56($t0)
	sw $t2, 64($t0)
	sw $t2, 76($t0)
	
	sw $t2, 84($t0)
	sw $t2, 88($t0)
	sw $t2, 92($t0)
	sw $t2, 96($t0)
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
delay:
	# move stack pointer a word and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	li $v0, 32
	li $a0, 7	
	syscall

	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
