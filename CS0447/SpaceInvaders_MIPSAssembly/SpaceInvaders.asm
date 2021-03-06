#Written by Tyler Raborn

.data

#the data structure in memory:
bufferStartPtr: .word #static pointer
.align 2
.space 128 #128 / 4 = 32 words
bufferEndPtr: .word  #staic pointer 





.align 4
.space 4
curPos: .half #current position of astronaut

.align 4
.space 4
testMsg: .asciiz "BOOM!\n"

.align 4
.space 4
msg: .asciiz "-- GAME OVER --\n"
msg2: .asciiz "\n"
welcome: .asciiz "Welcome to ALIENS - Press b on the keypad to begin! \n"
right: .asciiz "right\n"
left: .asciiz "left\n"
killCount: .asciiz "Number of aliens peacefully dispersed is "
shotsFired: .asciiz "Number of rubber phaser firings is "
victoryMsg: .asciiz "\nEarth was saved!\n"
defeatMsg: .asciiz "\nEarth was lost.\n"
nl: .asciiz "\n"




.text
#int kills = 0;
add $s3, $0, $0 #variable for holding number of kills

#int shotsFired = 0;
add $s5, $0, $0

#int timeKeep


##########################################################################################
#void initialize();
##########################################################################################
la $a0, welcome #welcome msg
li $v0, 4
syscall


initialize:
lbu $t0, 0xffff0000 #value for keypress

beq $t0, 1, readButton #if key is pressed, go to readButton
 
j initialize

readButton:
sb $0, 0xffff0000 #resets read value 

lhu $t1, 0xffff0004
beq $t1, 0x42, gamePrologue #if 'b' pressed continue on


j initialize

##########################################################################################
#void gamePrologue();
##########################################################################################
gamePrologue:
add $s6, $0, $0 #variable for counting time
la $a0, msg2 #welcome msg2
li $v0, 4
syscall

jal alienGen # draws the randomized aliens

#this block draws the astronaut but ALSO stores his x grid position into label curPos, the address of which is permanantly stored in $s4
la $s4, curPos

la $s0, bufferStartPtr #pointers to the beginning of structure in memory, for adding/removing 
la $s1, bufferStartPtr
la $s2, bufferEndPtr #static end pointer



#the astronaut himself
li $a0, 31 
sb $a0, ($s4) #stores 0d31 in address stored in register $s4
li $a1, 63
li $a2, 0x2
jal _setLED

##########################################################################################
#main game loop
##########################################################################################
gameLoop:
addi $s6, $s6, 1 #increments time counter
beq $s6, 1200, gameOver # 600 * 100ms = 1 min, this keeps checking for when 2 minutes has passed

lbu $t0, 0xffff0000
beq $t0, 1, readKey #determines which key has been pressed


midGameLoop: #middle of loop for the above functions to return to

jal system_Pause
jal iterate
sw $0, ($s1) #erase current contents

j gameLoop

######################################################
#void readKey(); Function is called when loop detects a keypress. Defaults to "phaserFire", or the up arrow, if other conditionals return false
#####################################################
readKey:
#addi $sp, $sp, -4
#sw $ra, 0($sp)

sb $0, 0xffff0000 #reset 0xffff0000

lhu $t0, 0xffff0004

#each key has a value
beq $t0, 0xE0, phaserFire
beq $t0, 0xE1, gameOver
beq $t0, 0xE2, moveLeft
beq $t0, 0xE3, moveRight

jal gameOver




j midGameLoop


#################################################
#void phaserFire($a0 = x, $a1 = y, $a2 = color); #reads astronaut LED status, loads phaser into queue for animation. Event stored in queue as "a0a1a2a2"
#################################################
phaserFire:
lbu $t0, ($s4) #moves astronaut cur pos into t0, it represents the x position
li $t1, 62 #b/c this is where all phasers start
li $t2, 1 #id

sb $t0, 0($s1) #stores x coordinate
sb $t1, 1($s1) #stores y coordinate
sb $t2, 2($s1) #stores event id
addi $s1, $s1, 4 #increments add pointer by 4 bytes

addi $s5, $s5, 1

move $a0, $t0 #draws initial phaser blast
move $a1, $t1
li $a2, 0x1
jal _setLED

j midGameLoop



#####################################
#moveRight(); moves astronaut right. Uses global position variable in $s4.
#####################################
moveRight:

#-------------
#remove previous location
#-------------
lbu $t0, ($s4)

beq $t0, 63, moveRightEnd

#draws a blank at current location of astronaut
lbu $a0, ($s4) 
li $a1, 63
li $a2, 0x00
#increments astronaut position
addi $t0, $t0, 1
#saves new value of $t0 into address located in $s4
sb $t0, ($s4)
jal _setLED #calls setLED(), draws a blank at current location of astronaut

#-------------
#draw astronaut at new pos
#-------------
lbu $a0, ($s4)
li $a1, 63
li $a2, 0x2
jal _setLED

moveRightEnd:

j gameLoop



##########################################################################################
#moveLeft(); moves astronaut left. Uses global position variable in $s4.
##########################################################################################
moveLeft:
#-------------
#remove previous location
#-------------
lbu $t0, ($s4)
beq $t0, $0, moveLeftEnd
#draws a blank at current location of astronaut
lbu $a0, ($s4) 
li $a1, 63
li $a2, 0x00
#decrements astronaut position
addi $t0, $t0, -1
#saves new value of $t0 into address located in $s4
sb $t0, ($s4)
jal _setLED #calls setLED(), draws a blank at current location of astronaut

#-------------
#draw astronaut at new pos
#-------------
lbu $a0, ($s4)
li $a1, 63
li $a2, 0x2
jal _setLED

moveLeftEnd:
j gameLoop














#####################################################################################################
#an autonomous function that iterates through the entire structure
#####################################################################################################
iterate:
addi $sp, $sp, -4
sw $ra, 0($sp)


la $s1, bufferStartPtr

iterateLoop:
beq $s0, $s2, iterateExit #once pointer reaches end of data structure, exit loop


lbu $t0, 2($s0) #load ID byte at position of pointer offset 2

beq $t0, 1, phaserIncrement #if event ID = 1 = phaser, branch to phaserIncrement
beq $t0, 2, waveIncrement #if event ID = 2 = explosion, branch to waveIncrement

midLoop: #halfway through the loop, this branch is the return point for explosion/phaser draw funcs


addi $s0, $s0, 4 #increment pointer by 4 bytes
j iterateLoop



iterateExit:
la $s0, bufferStartPtr#RESET POINTER BACK TO BEGINNING OF data structure

lw $ra, 0($sp)
addi $sp, $sp, 4
jr $ra


#####################################################################################################
#draws and updates the phaser/coordinates
#####################################################################################################
phaserIncrement: #takes data out of buffer, modifies it, and sticks it right back in
#read coordinates
lbu $a0, 0($s0) #x
lbu $a1, 1($s0) #y
beq $a1, 0, phaserIncrementComplete



#erase current phaser
li $a2, 0x0
jal _setLED


#update y coordinate
addi $a1, $a1, -1

jal _getLED
bne $v0, 0x3, drawPhaser #if v0 contains an alien, do not skip ahead...

j drawExplosion #jump to the drawExplosion function


drawPhaser: #jump point assuming no aliens are detected
#draw new phaser
li $a2, 0x1
jal _setLED

#store coordinates back in queue
li $a2, 1
sb $a0, 0($s1)
sb $a1, 1($s1) #stores y+1 into the queue at pointer s1
sb $a2, 2($s1)
addi $s1, $s1, 4

j midLoop #return to the middle of the iterate loop

phaserIncrementComplete: #should also remove event from data structure...

li $a2, 0x0
jal _setLED

#sw $0, ($s0)
j midLoop #return to the middle of the iterate loop






drawExplosion: #initial function for creating an explosion event. only called when alien first encountered

li $a2, 2 #event ID
li $t0, 1 #level of phaser
sb $a0, 0($s1) #store x coord
sb $a1, 1($s1) #store y coord
sb $a2, 2($s1) #event id = 2
sb $a3, 3($s1) #explosion stage = 1
addi $s1, $s1, 4 #increment counter

li $a2, 0x0
jal _setLED

#good place for a kill counter?
addi $s3, $s3, 1 #increment number of kills

#------------a0 + 1---------
add $a0, $a0, 2
li $a2, 0x0
jal _setLED

add $a1, $a1, 2
jal _setLED

add $a1, $a1, -4
jal _setLED
#--------------------------

lbu $a0, 0($s0) #x coordinate
lbu $a1, 1($s0) #y coordinate


#-------------a0 - 1-------
add $a0, $a0, -2
li $a2, 0x0
jal _setLED

add $a1, $a1, 2
jal _setLED

add $a1, $a1, -4
jal _setLED
#--------------------------

lbu $a0, 0($s0) #x coordinate
lbu $a1, 1($s0) #y coordinate

#------------$a0 = 0--------------
addi $a1, $a1, -2
jal _setLED

addi $a1, $a1, 4
jal _setLED
#--------------------------
lbu $a0, 0($s0) #x coordinate
lbu $a1, 1($s0) #y coordinate
lbu $a2, 3($s0) #wave stage

li $a2, 5 #wave id

li $t0, 2 #event id
sb $a0, 0($s1)
sb $a1, 1($s1)
sb $t0, 2($s1)
sb $a2, 3($s1)
addi $s1, $s1, 4 #increment pointer

j midLoop #continue drawing the phaser


##########################################################################################
#waveIncrement(); - branches here if wave event is detected in queue.#takes out of s0 and stores in s1
##########################################################################################
waveIncrement:
#a0 = x coord
#a1 = y coord
#a2 = event id
#t0 = explosion stage

#unloads data
lbu $a0, 0($s0) #x coordinate
lbu $a1, 1($s0) #y coordinate
lbu $a2, 3($s0) #stage

#draws black pixel to make alien disappear

#directs the program flow based on the current stage of the explosion in the event queue
beq $a2, 1, waveOne
beq $a2, 2, waveTwo
beq $a2, 3, waveThree
beq $a2, 4, waveFour
beq $a2, 5, waveFive





#################################################################################
waveOne: #if $a2 == 1. a0 = x, a1 = y, #draws initial yellow ring

#------------a0 + 1---------
add $a0, $a0, 1
li $a2, 0x1
jal _setLED
bne $v0, 0x3, w1
j drawExplosion
w1:
jal _setLED

add $a1, $a1, 1
jal _setLED
bne $v0, 0x3, w2
j drawExplosion
w2:
jal _setLED

add $a1, $a1, -2
jal _setLED
bne $v0, 0x3, w3
j drawExplosion
w3:
jal _setLED
#--------------------------

lbu $a0, 0($s0) #x coordinate
lbu $a1, 1($s0) #y coordinate


#-------------a0 - 1-------
add $a0, $a0, -1
li $a2, 0x1
jal _setLED
bne $v0, 0x3, w4
j drawExplosion
w4:
jal _setLED

add $a1, $a1, 1
jal _setLED
bne $v0, 0x3, w5
j drawExplosion
w5:
jal _setLED

add $a1, $a1, -2
jal _setLED
bne $v0, 0x3, w6
j drawExplosion
w6:
jal _setLED
#--------------------------

lbu $a0, 0($s0) #x coordinate
lbu $a1, 1($s0) #y coordinate

#------------$a0 = 0--------------
addi $a1, $a1, -1
jal _setLED
bne $v0, 0x3, w7
j drawExplosion
w7:
jal _setLED

addi $a1, $a1, 2
jal _setLED
bne $v0, 0x3, w8
j drawExplosion
w8:
jal _setLED
#--------------------------
lbu $a0, 0($s0) #x coordinate
lbu $a1, 1($s0) #y coordinate
lbu $a2, 3($s0) #wave stage

li $a2, 2 #wave id

li $t0, 2 #event id
sb $a0, 0($s1)
sb $a1, 1($s1)
sb $t0, 2($s1)
sb $a2, 3($s1)
addi $s1, $s1, 4 #increment pointer

j waveExit
#####################################################################


#####################################################################
waveTwo:   # a0 = x, a1 = y if $a2 == 2

lbu $a0, 0($s0) #x coordinate
lbu $a1, 1($s0) #y coordinate

#------------a0 + 1---------
add $a0, $a0, 1
li $a2, 0x0
jal _setLED

add $a1, $a1, 1
jal _setLED

add $a1, $a1, -2
jal _setLED
#--------------------------

lbu $a0, 0($s0) #x coordinate
lbu $a1, 1($s0) #y coordinate


#-------------a0 - 1-------
add $a0, $a0, -1
li $a2, 0x0
jal _setLED

add $a1, $a1, 1
jal _setLED

add $a1, $a1, -2
jal _setLED
#--------------------------

lbu $a0, 0($s0) #x coordinate
lbu $a1, 1($s0) #y coordinate

#------------$a0 = 0--------------
addi $a1, $a1, -1
jal _setLED

addi $a1, $a1, 2
jal _setLED
#--------------------------

lbu $a0, 0($s0) #x coordinate
lbu $a1, 1($s0) #y coordinate
li $a2, 3


#needs 4 sb commands and an addi
#moves on to stage 3
li $t0, 2 #event id
sb $a0, 0($s1)
sb $a1, 1($s1)
sb $a2, 3($s1) #stores updated wave stage
sb $t0, 2($s1) #stores event id
addi $s1, $s1, 4 #increments pointer


#test message
#la $a0, testMsg
#li $v0, 4
#syscall

j waveExit

waveThree: # a0 = x, a1 = y #if $a2 == 3


#------------a0 + 1---------
add $a0, $a0, 2
li $a2, 0x1
jal _setLED
bne $v0, 0x3, w9
j drawExplosion
w9:
jal _setLED

add $a1, $a1, 2
jal _setLED
bne $v0, 0x3, w10
j drawExplosion
w10:
jal _setLED

add $a1, $a1, -4
jal _setLED
bne $v0, 0x3, w11
j drawExplosion
w11:
jal _setLED
#--------------------------

lbu $a0, 0($s0) #x coordinate
lbu $a1, 1($s0) #y coordinate


#-------------a0 - 1-------
add $a0, $a0, -2
li $a2, 0x1
jal _setLED
bne $v0, 0x3, w12
j drawExplosion
w12:
jal _setLED

add $a1, $a1, 2
jal _setLED
bne $v0, 0x3, w13
j drawExplosion
w13:
jal _setLED

add $a1, $a1, -4
jal _setLED
bne $v0, 0x3, w4
j drawExplosion
w14:
jal _setLED
#--------------------------

lbu $a0, 0($s0) #x coordinate
lbu $a1, 1($s0) #y coordinate

#------------$a0 = 0--------------
addi $a1, $a1, -2
jal _setLED
bne $v0, 0x3, w15
j drawExplosion
w15:
jal _setLED

addi $a1, $a1, 4
jal _setLED
bne $v0, 0x3, w16
j drawExplosion
w16:
jal _setLED
#--------------------------
lbu $a0, 0($s0) #x coordinate
lbu $a1, 1($s0) #y coordinate
lbu $a2, 3($s0) #wave stage

li $a2, 4 #wave id

li $t0, 2 #event id
sb $a0, 0($s1)
sb $a1, 1($s1)
sb $t0, 2($s1)
sb $a2, 3($s1)
addi $s1, $s1, 4 #increment pointer

j waveExit

waveFour:  # a0 = x, a1 = y #if $a2 == 4

#------------a0 + 1---------
add $a0, $a0, 2
li $a2, 0x0
jal _setLED

add $a1, $a1, 2
jal _setLED

add $a1, $a1, -4
jal _setLED
#--------------------------

lbu $a0, 0($s0) #x coordinate
lbu $a1, 1($s0) #y coordinate


#-------------a0 - 1-------
add $a0, $a0, -2
li $a2, 0x0
jal _setLED

add $a1, $a1, 2
jal _setLED

add $a1, $a1, -4
jal _setLED
#--------------------------

lbu $a0, 0($s0) #x coordinate
lbu $a1, 1($s0) #y coordinate

#------------$a0 = 0--------------
addi $a1, $a1, -2
jal _setLED

addi $a1, $a1, 4
jal _setLED
#--------------------------
lbu $a0, 0($s0) #x coordinate
lbu $a1, 1($s0) #y coordinate
lbu $a2, 3($s0) #wave stage

li $a2, 5 #wave id

li $t0, 2 #event id
sb $a0, 0($s1)
sb $a1, 1($s1)
sb $t0, 2($s1)
sb $a2, 3($s1)
addi $s1, $s1, 4 #increment pointer

j waveExit

waveFive:  # a0 = x, a1 = y #if $a2 == 5

j waveExit


waveExit:
j midLoop


##########################################################################################
#alienGen(); - generates randomized green pixels (sorry, ALIENS!) across the 64x64 plane
##########################################################################################
alienGen:
addi $sp, $sp, -4
sw $ra, 0($sp)

li $t8, 63
alienLoop: #ensures 64 aliens are present.

beq $t8, $0, alienLoop_epilogue

#x coordinate
jal randGen
move $a0, $t0
#y coordinate
jal randGen
move $a1, $t0

#calls LED function
li $a2, 0x3
jal _setLED

addi $t8, $t8, -1
j alienLoop

alienLoop_epilogue:
lw $ra, 0($sp)
addi $sp, $sp, 4
jr $ra


##########################################################################################
#int randGen(); - returns randomized int in $t0
##########################################################################################
randGen:
addi $sp, $sp, -12
sw $sp, 0($sp)
sw $a0, 4($sp)
sw $a1, 8($sp)

li $a0, 1 #random num seed
li $a1, 62 # range
li $v0, 42 
syscall
move $t0, $a0

lw $sp, 0($sp)
lw $a0, 4($sp)
lw $a1, 8($sp)
addi $sp, $sp, 12
jr $ra





##########################################################################################
#void system_Pause(); function for forcing a 100ms pause
##########################################################################################
system_Pause:
addi $sp, $sp, -4
sw $ra, 0($sp)

#SYSTEM PAUSE 100MS
li $v0, 32
li $a0, 100
syscall



lw $ra, 0($sp)
addi $sp, $sp, 4

jr $ra








	###############################################################
	# LED functions
	###############################################################
	
	# void _setLED(int x, int y, int color)
	#   sets the LED at (x,y) to color
	#   color: 0=off, 1=red, 2=orange, 3=green
	#
	# arguments: $a0 is x, $a1 is y, $a2 is color
	# trashes:   $t0-$t3
	# returns:   none
	#
_setLED:
	# range checks
	bltz	$a0,_setLED_exit
	bltz	$a1,_setLED_exit
	bge	$a0,64,_setLED_exit
	bge	$a1,64,_setLED_exit
	
	# byte offset into display = y * 16 bytes + (x / 4)
	sll	$t0,$a1,4      # y * 16 bytes
	srl	$t1,$a0,2      # x / 4
	add	$t0,$t0,$t1    # byte offset into display
	li	$t2,0xffff0008	# base address of LED display
	add	$t0,$t2,$t0    # address of byte with the LED
	# now, compute led position in the byte and the mask for it
	andi	$t1,$a0,0x3    # remainder is led position in byte
	neg	$t1,$t1        # negate position for subtraction
	addi	$t1,$t1,3      # bit positions in reverse order
	sll	$t1,$t1,1      # led is 2 bits
	# compute two masks: one to clear field, one to set new color
	li	$t2,3		
	sllv	$t2,$t2,$t1
	not	$t2,$t2        # bit mask for clearing current color
	sllv	$t1,$a2,$t1    # bit mask for setting color
	# get current LED value, set the new field, store it back to LED
	lbu	$t3,0($t0)     # read current LED value	
	and	$t3,$t3,$t2    # clear the field for the color
	or	$t3,$t3,$t1    # set color field
	sb	$t3,0($t0)     # update display
_setLED_exit:	
	jr	$ra
	
	# int _getLED(int x, int y)
	#   returns the value of the LED at position (x,y)
	#
	#  arguments: $a0 holds x, $a1 holds y
	#  trashes:   $t0-$t2
	#  returns:   $v0 holds the value of the LED (0 or 1)
	#
_getLED:
	# range checks
	bltz	$a0,_getLED_exit
	bltz	$a1,_getLED_exit
	bge	$a0,64,_getLED_exit
	bge	$a1,64,_getLED_exit
	
	# byte offset into display = y * 16 bytes + (x / 4)
	sll  $t0,$a1,4      # y * 16 bytes
	srl  $t1,$a0,2      # x / 4
	add  $t0,$t0,$t1    # byte offset into display
	la   $t2,0xffff0008
	add  $t0,$t2,$t0    # address of byte with the LED
	# now, compute bit position in the byte and the mask for it
	andi $t1,$a0,0x3    # remainder is bit position in byte
	neg  $t1,$t1        # negate position for subtraction
	addi $t1,$t1,3      # bit positions in reverse order
    	sll  $t1,$t1,1      # led is 2 bits
	# load LED value, get the desired bit in the loaded byte
	lbu  $t2,0($t0)
	srlv $t2,$t2,$t1    # shift LED value to lsb position
	andi $v0,$t2,0x3    # mask off any remaining upper bits
_getLED_exit:	
	jr   $ra
	
	

##########################################################################################
#void gameOver(); exits the game
##########################################################################################
gameOver:
la $a0, msg #exit message
li $v0, 4
syscall

la $a0, killCount #prints kill msg
li $v0, 4
syscall

move $a0, $s3 #number of kills
li $v0, 1
syscall

la $a0, nl # new line
li $v0, 4
syscall

la $a0, shotsFired #prints kill msg
li $v0, 4
syscall

move $a0, $s5 ## of shots fired
li $v0, 1
syscall

bne $s3, 64, sadEnding
la $a0, victoryMsg
li $v0, 4
syscall

li $v0, 10 #endgame
syscall


sadEnding:
la $a0, defeatMsg
li $v0, 4
syscall

li $v0, 10 #endgame
syscall
