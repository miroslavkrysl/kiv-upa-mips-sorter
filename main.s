	# Start .text segment (program code)
	.text
	
	.globl	main
main:
	la		$s0, d_array						# init $s0 as int array pointer
	li		$s1, 0								# init as array length

	la		$a0, d_in_msg
	jal		f_print_line						# print input prompt mesage

main__input_loop:
	la		$a0, d_buffer
	la		$a1, 128							# buffer size
	jal		f_read_line							# read line from input
	
	la		$a0, d_buffer
	jal		f_str_len							# determine the string length, result in $v0
	
	beq		$v0, 0, main__input_loop_exit		# if $v0 = 0 -> blank line read

	la		$a0, d_buffer
	jal		f_strhex_to_int						# convert string to integer, result in $v0

	bne		$v1, 0, main__input_loop_error		# check the error return value (0 = OK)
	
	la		$a0, d_in_ok_msg
	jal		f_print_line						# print error mesage

	sw		$v0, 0($s0)							# save the read integer into the array
	addi	$s0, $s0, 4							# increment the int array pointer
	addi	$s1, $s1, 1							# increment the array length

	j		main__input_loop

main__input_loop_error:
	la		$a0, d_in_error_msg
	jal		f_print_line						# print error mesage

	j		main__input_loop

main__input_loop_exit:
	bne		$s1, 0, main__sort					# check if some integers given

	la		$a0, d_no_in_msg
	jal		f_print_line						# print no integers given error mesage

	j		exit

main__sort:
	la		$a0, d_array
	move	$a1, $s1 
	jal		f_insert_sort						# sort the integers

	la		$s0, d_array						# ser $s0 as int array pointer
	
	# compute last item adress
	li		$s2, 4								# load int size = 4 for multiplication
	move	$t0, $s1							# load array size
	addi	$t0, $t0, -1						# decrement array size by one
	mult	$s2, $t0							# multiply array size by int size
	mflo	$s2									# move multiplication result (array range in bytes)
	add		$s2, $s2, $s0						# add first item addres to array range (in bytes) = last item adress

main__print_loop:
	lw		$a0, 0($s0)
	la		$a1, d_buffer
	jal		f_int_to_strhex						# convert integer to hex string

	la		$a0, d_buffer
	jal		f_print_line						# print integer

	addi	$s0, $s0, 4							# increment int array pointer

	bgt		$s0, $s2, exit						# array pointer out of range
	j		main__print_loop

	# exit program
exit:
	li		$v0, 10								# exit syscall code = 10
	syscall




	# @function void insert_sort(int *array, int size)
	# @param array $a0 - Int array pointer
	# @param size $a1 - Array size
	#
	# Sort the array of integers in the ascending order using the insertion sort algorithm.
f_insert_sort:
	blt		$a1, 2, insert_sort__exit			# if size of the array < 2, then already sorted

	move	$t0, $a0							# set $t4 as the first item pointer

	# compute last item adress
	li		$t1, 4								# load int size = 4 for multiplication
	move	$t2, $a1							# load array size
	addi	$t2, $t2, -1						# decrement array size by one
	mult	$t1, $t2							# multiply array size by int size
	mflo	$t1									# move multiplication result (array range in bytes)
	add		$t1, $t1, $t0						# add first item addres to array range (in bytes) = last item adress
	
	move	$t2, $a0							# initialize the outer loop pointer - pivot int
	addi	$t2, $t2, 4							# set the outer pointer to the second item
insert_sort__out_loop:
	lw		$t4, 0($t2)							# load pivot int

	move	$t3, $t2							# initialize the inner loop pointer - comparing int
	addi	$t3, $t3, -4						# set the comparing int pointer one item left of the pivot int
insert_sort__in_loop:
	lw		$t5, 0($t3)							# load comparing int
	bgt		$t4, $t5, insert_sort__out_loop_end	# pivot int is greater than comparing int -> break inner loop
	
	sw		$t5, 4($t3)							# store comparing int one position right
	addi	$t3, $t3, -4						# decrement the comparing int pointer

	blt		$t3, $t0, insert_sort__out_loop_end	# comparing int pointer is out of range

	j		insert_sort__in_loop

insert_sort__out_loop_end:
	sw		$t4, 4($t3)							# store pivot into it's right position
	
	addi	$t2, $t2, 4							# increment the pivot int pointer
	bgt		$t2, $t1, insert_sort__exit			# pivot int pointer is out of range

	j		insert_sort__out_loop

insert_sort__exit:
	jr		$ra									# jump back to caller




	# @function int str_len(char *src)
	# @param src $a0 - String source address
	# @return $v0 - String length without the null-terminated character
	#
	# Compute the string length.
f_str_len:
	move	$t0, $a0							# initialize the char pointer
	li		$t1, 0								# initialize the char counter

str_len__loop:
	lb		$t2, 0($t0)
	beq		$t2, 0, str_len__exit				# null-termination character reached
	addi	$t0, 1								# increment char pointer
	addi	$t1, 1								# increment char counter

	j		str_len__loop

str_len__exit:
	move	$v0, $t1							# move char count to the return register $v0
	
	jr		$ra									# jump back to caller




	# @function void read_line(char *dest_buffer, int buffer_size)
	# @param dest_buffer $a0 - Read string destination address
	# @param buffer_size $a1 - Buffer size
	#
	# Read string until the newline character occurs.
	# If the buffer's max capacity is reached, end the reading and print
	# the new line char to indicate that the reading was terminated.
f_read_line:
	move	$t0, $a0							# this will serve as a buffer's next char pointer
	add		$t1, $t0, $a1						# compute buffer's last usable address
	addi	$t1, $t1, -1						# reserve the last address for the null-terminating character

read_line__loop:
	beq		$t0, $t1, read_line__max_reached	# buffer's max size reached
	
	li		$v0, 12								# read char syscall code = 8
	syscall										# read char is stored in $v0
	
	beq		$v0, '\n', read_line__end_string	# end line reached
	
	sb		$v0, 0($t0)							# store char into the buffer
	addi	$t0, $t0, 1							# update the buffer's next char pointer

	j		read_line__loop
		
read_line__max_reached:
	li		$a0, '\n'							# load new line char as an arg for the print char syscall
	li		$v0, 11								# print char syscall code = 11
	syscall										# print the new line to indicate that the reading was terminated

read_line__end_string:
	li		$t2, 0								# load null-terminating char to $t2
	sb		$t2, 0($t0)							# terminate the string - save null char into the buffer
	
	jr		$ra									# jump back to caller




	# @function void print_line(char *source)
	# @param source $a0 - Printed string source address
	#
	# Print string from the source address, append the newline character
	# to the end of the printed string.
f_print_line:
	li		$v0, 4								# print string syscall code = 8
	syscall										# uses $a0, $a1 which are given as function arguments
	
	li		$v0, 11								# print char syscall code = 8
	li		$a0, '\n'							# load '\n' for the print char syscall
	syscall										# print '\n'

	jr		$ra									# jump back to caller




	# @function int strhex_to_int(char *source)
	# @param source $a0 - String source address
	# @return $v0 - Resulting integer
	# @return $v1 - 0 on success, 1 on error
	#
	# Convert the hexadecimal number given as a string to an integer.
f_strhex_to_int:
	# save registers on the stack
	addi	$sp, $sp, -20						# adjust the stack pointer
	sw		$s0, 0($sp)
	sw		$s1, 4($sp)
	sw		$s2, 8($sp)
	sw		$s3, 12($sp)
	sw		$s4, 16($sp)

	# prepare registers
	move	$s0, $a0							# char pointer
	li		$s1, 0								# char counter
	li		$s2, 0								# result
	li		$s3, 0								# fail
	li		$s4, 8								# max number of hex chars per integer
	li		$t0, 0								# for loading chars

	# check whether the string starts with "0x"
	lb		$t0, 0($a0)							# load first char
	li		$t1, '0'							# load char '0' for comparison
	bne		$t0, $t1, strhex_to_int__tr_zeros	# if not beginning with "0"

	lb		$t0, 1($a0)							# load second char
	li		$t1, 'x'							# load char 'x' for comparison
	bne		$t0, $t1, strhex_to_int__tr_zeros	# if not beginning with "0x"

	# skip first two chars "0x"
	li		$s0, 2								# set char pointer to third char

strhex_to_int__tr_zeros:	
	# skip trailing zeros

strhex_to_int__tr_zeros_loop:
	lb		$t0, 0($s0)							# load next char
	bne		$t0, $t1, strhex_to_int__convert	# if not '0', end the loop
	addi	$s0, $s0, 1							# move pointer to next char
	j		strhex_to_int__tr_zeros_loop

strhex_to_int__convert:
	# convert the characters one by one

	# load chars for comparison
	li		$t1, '0'
	li		$t2, '9'
	li		$t3, 'A'
	li		$t4, 'F'
	li		$t5, 'a'
	li		$t6, 'f'

	lb		$t0, 0($s0)							# load next char
strhex_to_int__convert_loop:
	# check whether the char is a hexadecimal char
	blt		$t0, $t1, strhex_to_int__fail		# < '0' not a hex char
	ble		$t0, $t2, strhex_to_int__digit		# <= '9' a digit
	blt		$t0, $t3, strhex_to_int__fail		# < 'A' not a hex char
	ble		$t0, $t4, strhex_to_int__char_up	# <= 'F' an upper char
	blt		$t0, $t5, strhex_to_int__fail		# < 'a' not a hex char
	ble		$t0, $t6, strhex_to_int__char_low	# <= 'f' an upper char

strhex_to_int__digit:
	sub		$t0, $t0, $t1						# value -= '0'
	j		strhex_to_int__convert_loop_end
	
strhex_to_int__char_up:
	addi	$t0, $t0, 10						# value += 10
	sub		$t0, $t0, $t3						# value -= 'A'
	j		strhex_to_int__convert_loop_end

strhex_to_int__char_low:
	addi	$t0, $t0, 10						# value += 10
	sub		$t0, $t0, $t5						# value -= 'a'

strhex_to_int__convert_loop_end:
	add		$s2, $s2, $t0						# add value of char to result
	addi	$s1, $s1, 1							# update char counter
	addi	$s0, $s0, 1							# update char pointer
	
	lb		$t0, 0($s0)							# load next char
	
	# check for the end of string
	beq		$t0, $zero, strhex_to_int__exit		# end of string = 0

	# check if max number of hex chars reached
	beq		$s1, $s4, strhex_to_int__fail
	
	sll		$s2, $s2, 4							# shift result four bits (one char) left
	j		strhex_to_int__convert_loop

strhex_to_int__exit:
	move	$v0, $s2							# move result to $v0
	move	$v1, $s3							# move fail value to $v1
	
	# load registers back from the stack
	lw		$s0, 0($sp)
	lw		$s1, 4($sp)
	lw		$s2, 8($sp)
	lw		$s3, 12($sp)
	lw		$s4, 16($sp)
	addi	$sp, $sp, 20						# adjust stack pointer back to initial value

	jr		$ra									# jump back to caller

strhex_to_int__fail:
	# not a hex char
	li		$s3, 1								# set fail value
	j		strhex_to_int__exit




	# @function void int_to_strhex(int a, char *dest)
	# @param a $a0 - An integer
	# @param dest $a1 - String destination address (min size = 11 including the null-terminating char)
	#
	# Convert the given integer into a hexadecimal number string representation in the form "0x00FFAAFF".
f_int_to_strhex:
	move	$t0, $a0							# move integer to $t0
	move	$t1, $a1							# init as the char pointer
	li		$t2, 0								# clear $t2 for number to char computation
	addi	$t3, $a1, 2							# set $t3 as a pointer to the first char of the number

	li		$t4, '0'							# load char '0'
	sb		$t4, 0($t1)							# store '0' into the string address
	addi	$t1, $t1, 1							# increment the char pointer
	li		$t4, 'x'							# load char 'x'
	sb		$t4, 0($t1)							# store 'x' into the string address
	
	addi	$t1, $t1, 9							# set char pointer to the string end
	li		$t4, 0								# load the null-terminating char to $t4
	sb		$t4, 0($t1)							# terminate the string - save null char into the string end
	
	addi	$t1, $t1, -1						# decrement the char pointer

int_to_strhex__loop:
	andi	$t2, $t0, 15						# load first 4 bits (= 1 char) into the $t2

	bge		$t2, 10, int_to_strhex__char		# 10 - 15 is char else 0 - 9 is digit
	addi	$t2, $t2, '0'						# add char's '0' value to the number
	j		int_to_strhex__loop_end

int_to_strhex__char:
	addi	$t2, $t2, 'A'						# add char's 'A' value to the number

int_to_strhex__loop_end:
	sb		$t2, 0($t1)							# store next char into the string

	beq		$t1, $t3, int_to_strhex__exit		# the whole int was converted
	
	addi	$t1, $t1, -1						# decrement the char pointer
	srl		$t0, $t0, 4							# shift the integer four bits (one char) right
	j		int_to_strhex__loop

int_to_strhex__exit:
	jr 		$ra									# jump back to caller




	# Start .data segment (data!)
	.data
d_in_msg:		.asciiz	"Zadejte cisla v sestnactkove soustave (0xFFFFFFFF). Jednotliva cisla potvrdte entrem a po poslednim cisle entr stinsknete jeste jednou."
d_in_error_msg:	.asciiz	"Spatne zadane cislo. Zkuste cislo zadat znovu:"
d_in_ok_msg:	.asciiz	"Ok"
d_no_in_msg:	.asciiz	"Nebyla zadana zadna cisla."
d_sorted_msg:	.asciiz	"Serazena cisla:"
d_buffer:		.space	128
d_array:		.space	1024