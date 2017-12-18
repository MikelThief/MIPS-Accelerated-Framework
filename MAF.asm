##############################
#                            #
#            MIPS            #
#    Accelerated Framework   #
#                            #
#        MichaĹ‚ Bator        #
#    ECOAR Winter sem 2017   #
##############################
.data

    #################################
    # DEFINE CONSTANTS
    #################################
    .eqv PRINT_INT 1
    .eqv PRINT_FLOAT 2
    .eqv PRINT_DOUBLE 3
    .eqv PRINT_STR 4

    .eqv INPUT_INT 5
    .eqv INPUT_FLOAT 6
    .eqv INPUT_DOUBLE 7
    .eqv INPUT_STR 8

    .eqv END 10
    .eqv PRINT_CHAR 11

    .eqv FILE_OPEN 13
    .eqv FILE_READ 14
    .eqv FILE_WRITE 15
    .eqv FILE_CLOSE 16

    .eqv PRINT_HEX 34
    .eqv PRINT_IEEE 35
#################################
# File IO Macros
# Contains helpful macros for general files.
#################################

    #################################
    # Open the text file in the OS so it can be accessed (reading/writing)
    # Type: int
    # Arguments:
    #   %s = name of file we want to open
    #   %mode = mode for opening the file (read only, read/write, etc)
    #   %buffer = the space or input buffer we want to load the file contents to
    #   %max_chars = the maximum number of characters to read
    #################################
    .macro read_file(%s, %flags, %mode, %buffer, %max_chars)
        addi $sp, $sp, -12
        sw $a0, ($sp)
        sw $a1, 4($sp)
        sw $a2, 8($sp)

        la $a0, %s # Load the file name
        li $a1, 0 # Flag 0 for reading
        move $a2, %mode # Copy the file open mode. Default is 0.
        li $v0, 13 
        syscall # File descriptor now $v0

        # Read the file
        move $a0, $v0 # Get the file descriptor
        la $a1, %buffer
        move $a2, %max_chars
        li $v0, 14
        syscall

        # $v0 will store the number of chars we read.

        lw $a0, ($sp)
        lw $a1, 4($sp)
        lw $a2, 8($sp)
        addi $sp, $sp, 12
    .end_macro

    #################################
    # Writes content from memory buffer to file by overwriting existing file.
    # Type: void
    # Arguments:
    #   %s = the name of the file
    #   %mode = open file mode (Default 0)
    #   %text = the memory address (label) of the text we want to write
    #   %text_len = the length of the text
    #################################
    .macro write_file(%s, %mode, %text, %text_len)
        addi $sp, $sp, -12
        sw $a0, ($sp)
        sw $a1, 4($sp)
        sw $a2, 8($sp)
        
        la $a0, %s # Load the file name
        li $a1, 1
        move $a2, %mode # Copy the file open mode
        li $v0, 13 
        syscall

        move $a0, $v0
        la $a1, %text
        move $a2, %text_len
        li $v0, 15
        syscall

        lw $a0, ($sp)
        lw $a1, 4($sp)
        lw $a2, 8($sp)
        addi $sp, $sp, 12
    .end_macro

    #################################
    # Check BMP file if it matches the type
    # Type: int
    # Arguments:
    #   %errorLabel = error branch's name to jump if error occurs
    #################################
    .macro check_if_BMP(%errorLabel)
        addi $sp, $sp, -8
        sw $t0, ($sp)
        sw $t1, 4($sp)

        # check if our file is a bitmap
	    li	$t0, 0x4D42 				# 0X4D42 = signature for a bitmap (hexadecimal "BM")
	    lhu	$t1, header				    # the signature is stored in the first two bytes (header+0)
		# lhu  loads the first 2 bytes into $t1 register

        bne	$t0, $t1, %errorLabel

        lw $t0, ($sp)
        lw $t1, 4($sp)
        addi $sp, $sp, 8
    .end_macro

    #################################
    # Check BMP file if it is 24b
    # Type: int
    # Arguments:
    #   %errorLabel = error branch's name to jump if error occurs
    #   %header - variable containing BMP's header
    #################################
    .macro check_24b_BMP(%errorLabel, %header)
        addi $sp, $sp, -8
        sw $t0, ($sp)
        sw $t1, 4($sp)

        # check if the bitmap is actually 24 bits
	    li	$t0, 24					        # store 24 into $t0, as it should be 24b uncompressed bitmap
	    lb	$t1, %header+28				
							
	    bne	$t0, $t1, %errorLabel			# checking if it matches task criteria

        lw $t0, ($sp)
        lw $t1, 4($sp)
        addi $sp, $sp, 8
    .end_macro

#################################
# Numeric conversion macros
# Allows for conversion from int to float or double
#################################   
# Data section carried over

    #################################
    # Converts given immediate int number to float number
    # Type: void
    # Arguments:
    #   %f_reg = target Coprocessor's 1 floating point register
    #   %value = value to convert
    #################################
    .macro	int_to_float_cp1 (%f_reg, %value)
	    addi $sp, $sp, -4	# sp++
	    li $at, %value		# at = %value
	    sw $at, ($sp)		# push(at)
	    lwc1 %f_reg, ($sp)	# %f_reg = pop()
	    addi $sp, $sp, 4 	# sp--
	    cvt.s.w %f_reg,%f_reg	# %f_reg = (float)%f_reg
    .end_macro

    #################################
    # Converts given immediate int number to double number
    # Type: void
    # Arguments:
    #   %f_reg = target Coprocessor's 1 floating point register
    #   %value = value to convert
    #################################
    .macro	int_to_double_cp1 (%f_reg, %value)
	    addi $sp, $sp, -4	# sp++
	    li $at, %value		# at = %value
	    sw $at, ($sp)		# push(at)
	    lwc1 %f_reg, ($sp)	# %f_reg = pop()
	    addi $sp, $sp, 4 	# sp--
	    cvt.d.w %f_reg,%f_reg	# %f_reg = (double)%f_reg
    .end_macro

#################################
# Standard macro functions.
# All used registers are saved and restored automatically.
#################################

    #################################
    # Prints instant-defined string ending with new line.
    # Type: Void
    # Arguments:
    #   %s = string to print like "samplestring"
    # Output: samplestring
    #################################
    .macro println_instant_str(%s)
    	.data
    NameOfFile: .asciiz  %s
    new_line: .asciiz "\n"
        .text
        addi $sp, $sp, -8
        sw $a0, ($sp)
        sw $v0, 4($sp)

        la  $a0, s_to_print
        li $v0, PRINT_STR
        syscall
        
        la  $a0, new_line
        syscall

        lw $a0, ($sp)
        lw $v0, 4($sp)
        addi $sp, $sp, 8
    .end_macro

    #################################
    # Generic for loop. Does not guarantee body's register restoration.
    # Arguments for %from and %to can be either a register name or an immediate value.
    # %bodyMacroName should be name of a macro that has no parameters.
    # Type: Void
    # Arguments:
    #   regIterator = register that is being used as counter
    #   %from = lower loop's boundary value
    #   %to = upper loop's boundary value
    #   %bodyMacroName - macro to be used as loop's body
    #################################)
	.macro for(%regIterator, %from, %to, %bodyMacroName)
    addi $sp, $sp, -4
    sw %regIterator, ($sp)

	add %regIterator, $zero, %from
	Loop:
	%bodyMacroName ()
	add %regIterator, %regIterator, 1
	ble %regIterator, %to, Loop

    lw %regIterator, ($sp)
    addi $sp, $sp, 4
	.end_macro

    #################################
    # Saves user's console input string in a label
    # Type: Void
    # Arguments:
    #   %s = string to save data "samplestring" of asciiz format
    #################################
    .macro read_str(%s, %length)
        addi $sp, $sp, -24
        sw $a0, ($sp)
        sw $v0, 4($sp)
        sw $a1, 8($sp)
        sw $t0, 12($sp)
        sw $t1, 16($sp)
        sw $t2, 20($sp)

        # read the input file name
	    li 	$v0, 8					# syscall-8 read string
	    la	$a0, %s		            # load address of the %s
	    li 	$a1, %length			# load the maximum number of characters to read
	    syscall

        # cut the '\n' from the %s
        cutN:
	        move $t0, $zero		# load 0 to $t0 to make sure that it starts from the beginning of the string
	        li	 $t2, '\n'		# load the '\n' character to the $t2 register for comparing in findN

        findN:
	        lb	    $t1, %s($t0)			# read the %s 
	        beq	    $t1, $t2, removeN		# check for '\n'
	        addi 	$t0, $t0, 1				
	        j 	    findN

	    # remove the '\n' and replace with '\0'
        removeN:
	        li	$t1, '\0'					# replace '\n' with '\0'
	        sb	$t1, %s($t0)
    
        lw $a0, ($sp)
        lw $v0, 4($sp)
        lw $a1, 8($sp)
        lw $t0, 12($sp)
        lw $t1, 16($sp)
        lw $t2, 20($sp)
        addi $sp, $sp, 24
    .end_macro


    #################################
    # Prints instant-defined string ending with new line.
    # Type: Void
    # Arguments:
    #   %s = string to print like "samplestring"
    # Output: samplestring
    #################################
    .macro println_instant_str(%s)
    	.data
    s_to_print: .asciiz  %s
    new_line: .asciiz "\n"
        .text
        addi $sp, $sp, -8
        sw $a0, ($sp)
        sw $v0, 4($sp)

        la  $a0, s_to_print
        li $v0, PRINT_STR
        syscall
        
        la  $a0, new_line
        syscall

        lw $a0, ($sp)
        lw $v0, 4($sp)
        addi $sp, $sp, 8
    .end_macro

    #################################
    # Prints instant-defined string.
    # Type: Void
    # Arguments:
    #   %s = string to print like "samplestring"
    # Output: samplestring
    #################################
    .macro print_instant_str(%s)
    	.data
    s_to_print: .asciiz  %s
        .text
        addi $sp, $sp, -8
        sw $a0, ($sp)
        sw $v0, 4($sp)

        la  $a0, s_to_print
        li $v0, PRINT_STR
        syscall

        lw $a0, ($sp)
        lw $v0, 4($sp)
        addi $sp, $sp, 8
    .end_macro

    #################################
    # Prints instant-defined string with preceding [DEBUG].
    # Type: Void
    # Arguments:
    #   %s = string to print like "samplestring"
    # Output: [DEBUG] samplestring
    #################################
    .macro debug_log(%s)
    	.data
    s_to_print: .asciiz  %s
    new_line: .asciiz "\n"
    log_msg: .asciiz "[DEBUG] "
        .text
        addi $sp, $sp, -8
        sw $a0, ($sp)
        sw $v0, 4($sp)

        la $a0, log_msg
        li $v0, PRINT_STR
        syscall

        la  $a0, s_to_print
        syscall
        
        la  $a0, new_line
        syscall

        lw $a0, ($sp)
        lw $v0, 4($sp)
        addi $sp, $sp, 8
    .end_macro

    #################################
    # Prints instant-defined string with preceding [EXCEPTION].
    # Then come back to main, reloading program execution.
    # Type: Void
    # Arguments:
    #   %s = string to print like "samplestring"
    # Output: [EXCEPTION] samplestring
    #################################
    .macro raise_exception(%s)
    	.data
    s_to_print: .asciiz  %s
    new_line: .asciiz "\n"
    log_msg: .asciiz "[EXCEPTION] "
        .text
        addi $sp, $sp, -8
        sw $a0, ($sp)
        sw $v0, 4($sp)

        la $a0, log_msg
        li $v0, PRINT_STR
        syscall

        la  $a0, s_to_print
        syscall
        
        la  $a0, new_line
        syscall
        syscall
        syscall

        lw $a0, ($sp)
        lw $v0, 4($sp)
        addi $sp, $sp, 8

        j main
    .end_macro

    #################################
    # Terminates program
    # Type: Void
    #################################
    .macro exit
        li $v0, END
        syscall
    .end_macro

    #################################
    # Prints defined string at %label
    # Type: Void
    # Arguments:
    #   %label = label in data section
    #################################
    .macro print_mem_str(%label)
        addi $sp, $sp, -8
        sw $a0, ($sp)
        sw $v0, 4($sp)

        la $a0, %label
        li $v0, PRINT_STR
        syscall

        lw $a0, ($sp)
        lw $v0, 4($sp)
        addi $sp, $sp, 8
    .end_macro

    #################################
    # Prints int at %label
    # Type: Void
    # Arguments:
    #   %label = label in data section
    #################################
    .macro print_mem_word(%label)
        addi $sp, $sp, -8
        sw $a0, ($sp)
        sw $v0, 4($sp)

        lw $a0, %label
        li $v0, PRINT_INT
        syscall

        lw $a0, ($sp)
        lw $v0, 4($sp)
        addi $sp, $sp, 8
    .end_macro

    #################################
    # Prints int at %label
    # Type: Void
    # Arguments:
    #   %label = label in data section
    #################################
    .macro print_mem_double(%label)
        addi $sp, $sp, -12
        sw $f0, ($sp)
        sw $f1, 4($sp)
        sw $v0, 8($sp)

        ldc1 $f0, %label
        add.d $f12, $f2, $0
        syscall

        sw $f0, ($sp)
        sw $f1, 4($sp)
        sw $v0, 8($sp)
        addi $sp, $sp, 12
    .end_macro

    #################################
    # Prints chars, strings, floats, integers, octal and hex values based on code given.
    # Type: Void
    # Arguments:
    #   %reg = register with content
    #   %code = code for associated data-type
    #################################
    .macro print_reg(%reg, %code)
        addi $sp, $sp, -8
        sw $a0, ($sp)
        sw $v0, 4($sp)

        move $a0, %reg
        li $v0, %code
        syscall

        lw $a0, ($sp)
        lw $v0, 4($sp)
        addi $sp, $sp, 8
    .end_macro

    #################################
    # Prints chars, strings, floats, integers, octal and hex values based on code given with a new line terminator
    # Type: Void
    # Arguments:
    #   %reg = register with content
    #   %code = print code for associated data-type
    #################################
    .macro println_reg(%reg, %code)
        	.data
    	new_line: .asciiz "\n"
    	.text
        addi $sp, $sp, -8
        sw $a0, ($sp)
        sw $v0, 4($sp)

        move $a0, %reg
        li $v0, %code
        syscall

        la $a0, new_line
        li $v0, PRINT_STR
        syscall

        lw $a0, ($sp)
        lw $v0, 4($sp)
        addi $sp, $sp, 8
    .end_macro

    #################################
    # Push register value onto the stack i.e save in memory
    # Type: Void
    # Arguments:
    #   %reg = register
    #################################
    .macro save_reg_to_stack(%reg)
        addi $sp, $sp, -4
        sw %reg, ($sp)
    .end_macro

    #################################
    # Load register with value on top of stack then pop from stack
    # Type: Void
    # Arguments:
    #   %reg = register
    #################################
    .macro save_stack_to_reg(%reg)
        lw %reg, ($sp)
        addi $sp, $sp, 4
    .end_macro

    #################################
    # Gets length of string
    # Type: int
    # Arguments:
    #   %str = string address from register
    # Returns:
    #   $v0 = length of string
    # @requires MAF_extra.asm
    #################################
    .macro str_len(%str)
        addi $sp, $sp, -8
        sw $a0, ($sp) # Overrided by function
        sw $t0, 4($sp)

        move $a0, %str
        jal func_str_len

        lw $a0, ($sp)
        lw $t0, 4($sp)
        addi $sp, $sp, 8
    .end_macro

    #################################
    # Gets length of string from memory
    # Type: int
    # Arguments:
    #   %str = string from memory
    # Returns:
    #   $v0 = length of string
    # @requires MAF_extra.asm
    #################################
    .macro str_len_mem(%str)
        addi $sp, $sp, -8
        sw $a0, ($sp) # Overrided by function
        sw $t0, 4($sp)

        la $a0, %str
        jal func_str_len

        lw $a0, ($sp)
        lw $t0, 4($sp)
        addi $sp, $sp, 8
    .end_macro
