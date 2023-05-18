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
    echo "TODO"
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
		rodos-executable.sh linux-x86 $FILES_TO_COMPILE 2>&1 | tee -a CompilationLog
	else
		rodos-executable.sh linux-x86 $FILES_TO_COMPILE 2> CompilationLog
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
	
    if [ "$KEEP_COMPILATION_LOG" = false ]; then
		rm CompilationLog
	else 
		mv CompilationLog ..
	fi

	echo "Moving executable to top directory..."
    mv tst ..
    cd ..

    echo -e "Running executable... \n"
    ./tst



	exit 0
}

configure
executeFunction