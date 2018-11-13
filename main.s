# Simple input/output in MIIPS assembly
# From: http://labs.cs.upt.ro/labs/so2/html/resources/nachos-doc/mipsf.html

	# Start .text segment (program code)
	.text
	
	.globl	main
main:
	la		$a0, d_buffer						# read destination address
	li		$a1, 10								# read destination address
	jal		f_read_string

	# exit program
exit:
	li		$v0, 10								# exit syscall code = 10
	syscall


	# @function int read_hex()
	# @return $v0 An integer
	# @return $v1 0 on success, 1 on error
	#
	# Read a string representation of a hexadecimal number from the input
	# and convert it to an integer of max size 32 bits.
f_read_hex:
	nop		# todo: implement
	jr		$ra									# jump back to caller	



	# @function void read_string(char *dest, int n)
	# @param dest $a0 - Read string destination address
	# @param n $a1 - Number of chars to be read
	#
	# Read string of lenght n into the destination address.
f_read_string:
	li		$v0, 8								# read string syscall code = 8
	syscall										# uses $a0, $a1 which are given as function arguments
	jr		$ra									# jump back to caller



	# @function void print_string(char *source)
	# @param source $a0 - Printed string source address
	#
	# Print string from the source address.
f_print_string:
	li		$v0, 4								# print string syscall code = 8
	syscall										# uses $a0, $a1 which are given as function arguments
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

	jr $ra										# jump back to caller

strhex_to_int__fail:
	# not a hex char
	li		$s3, 1								# set fail value
	j		strhex_to_int__exit



	# @function void int_to_strhex(int a, char *dest)
	# @param a $a0 - An integer
	# @param dest $a1 - String destination address
	#
	# Convert the given integer into a hexadecimal number.
f_int_to_strhex:
	nop											# todo: implement
	jr $ra										# jump back to caller



	# Start .data segment (data!)
	.data
d_in_msg:		.asciiz	"Zadejte cisla v sestnactkove soustave (0xFFFFFFFF). Jednotliva cisla potvrdte entrem a po poslednim cisle entr stinsknete jeste jednou."
d_bad_in_msg:	.asciiz	"Spatne zadane cislo:"
d_out_msg:		.asciiz	"Serazena cisla:"
d_newline:		.asciiz	"\n"
d_buffer:		.space 128
d_test_string:	.asciiz "19afAFFf"