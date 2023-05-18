#!/bin/bash

#	Author: Konstantin Winkel

#	EXIT CODES:
#	0: No Error
#	1: Parameter Error
#	2: Compilation Error
#	3: RODOS not found
#	127: Unkown Error

#change into scripts directory for consistent behaviour
cd "$(dirname "$0")"

#definition of variables
KEEP_COMPILATION_LOG=false
SHOW_COMPILATION_OUTPUT=false
COMPILE_ALL=true
COMPILE_FROM_FILE=false
FILES_TO_COMPILE="*.cpp"

NUM_PARAMS=$#
ALL_PARAMS=( "$@" )

#defines the help function
function helpFunction {

	echo "Prerequisits:"
	echo "1. Make sure RODOS is in its correct location"
	echo "2. Make sure that RODOS is build for the STM32F4 Discovery Board"
	echo "3. Move all files you want to compile and flash into the 'rodos_src' directory"
	echo "4. Make sure RODOS is sourced by going into the RODOS directory and running 'source setenvs.sh'"
	echo -e "\n"
	echo -e "Note: \nStep 4 is not necessary, as the script will try and source RODOS itself if it doesnt find the compiler. \nHowever, sourcing RODOS once manually is far more efficient. \n"

	echo "How to use:"
	echo "Run './falsh.sh' to flash all .cpp files in the directory 'rodos_src' onto the Discovery Board."
	echo "If you only want to flash certain files, for example test.cpp, add then name as a parameter: './flash.sh test.cpp'"
	echo -e "\n"
	echo "Parameters:"
	echo "	-f	flash all files specified in FlashList.txt"
	echo "	-h	shows this text explaination but does nothing else"
	echo "	-l	doesnt remove the log file after compilation"
	echo "	-s	shows the compiler output during compilation"

	exit 0
}

#defines the function for setting the required variables, depending on user parameters
function configure  {

	for var in "${ALL_PARAMS[@]}"
	do
		if [ "$var" = "-h" ]; then # -h to show help
			helpFunction
		elif [ "$var" = "-f" ]; then # -f to compile from file
			COMPILE_FROM_FILE=true
		elif [ "$var" = "-l" ]; then # -l to keep the compilation log
			KEEP_COMPILATION_LOG=true
		elif [ "$var" = "-s" ]; then # -s to show compilation output in console and write to file
			SHOW_COMPILATION_OUTPUT=true
		elif [[ $var =~ .*cpp.* ]]; then # cpp file -> add to compile list
			if [ "$COMPILE_ALL" = true ]; then
				COMPILE_ALL=false
				FILES_TO_COMPILE=$var
			else
				FILES_TO_COMPILE="$FILES_TO_COMPILE $var"
			fi
		fi
	done

}

#defines the function that compiles the variables
function compileFiles {
	if [ "$SHOW_COMPILATION_OUTPUT" = true ]; then
		rodos-executable.sh discovery $FILES_TO_COMPILE 2>&1 | tee -a CompilationLog
	else
		rodos-executable.sh discovery $FILES_TO_COMPILE 2> CompilationLog
	fi
}

#defines the function that reads the files to flash from FlashList.txt
function readFlashList {

	echo "Reading CompileList.txt"

	FILES_TO_COMPILE=""

	while IFS= read -r line || [[ -n "$line" ]]; do
		FILES_TO_COMPILE="$FILES_TO_COMPILE $line"
	done < "CompileList.txt"

}

#defines the funtion for compiling and flashing the code onto the STM board, also does lots of error handling
function executeFunction {

	cd ..

	if [ "$COMPILE_FROM_FILE" = true ]; then
		readFlashList
	fi

	cd rodos_src

	echo "Compiling code..."
	compileFiles

	if grep -q "command not found" "CompilationLog" ; then
		echo "Compiler not found, trying to source RODOS..."
		cd ../rodos
		source setenvs.sh 1> /dev/null 	2> /dev/null || RODOS_NOT_FOUND=true #this should work, be careful though
		cd ../rodos_src

		if [ "$RODOS_NOT_FOUND" = true ]; then
			echo "RODOS was not found, aborting..."
			exit 3
		else
			echo "RODOS successfully sourced."
			echo "Retrying compilation..."
			COMPILER_NOT_FOUND=false
			compileFiles || COMPILER_NOT_FOUND=true

			if [ "$COMPILER_NOT_FOUND" = true ]; then
				echo "Unknown error, check CompilationLog for more information"
				exit 127
			fi
		fi
	fi

	CHECK_FOR_FILE=$(ls -1)
	if [[ $CHECK_FOR_FILE != *"tst"* ]]; then
  		echo "Compilation error, check CompilationLog for more information"
		mv CompilationLog ..
		exit 2
	fi

	echo "Creating binary executable..."
	arm-none-eabi-objcopy -S -O binary tst myExe.bin

	echo "Flashing board..."
	cp myExe.bin /media/$USER/DIS_F407VG

	echo "Removing temporary files..."
	rm myExe.bin
	rm tst
	if [ "$KEEP_COMPILATION_LOG" = false ]; then
		rm CompilationLog
	else 
		mv CompilationLog ..
	fi


	exit 0
}

configure
executeFunction