#!/bin/bash

#	Author: Konstantin Winkel

#	EXIT CODES:
#	0: No Error
#	1: Parameter Error
#	2: Compilation Error
#	3: RODOS not found
#	100: Help function exit
#	127: Unkown Error

#change into scripts directory for consistent behaviour
cd "$(dirname "$0")"

#source RODOS, if not found abort
if ! source ../rodos/setenvs.sh > /dev/null ; then 
    echo -e "\033[1;31mERROR\033[0m RODOS not found, aborting.."
	exit 3
fi

#definition of variables
KEEP_COMPILATION_LOG=false
SHOW_COMPILATION_OUTPUT=false
COMPILE_ALL=true
COMPILE_FROM_FILE=false
FILES_TO_COMPILE="*.cpp"
SOURCE_DIR="rodos_src"

NUM_PARAMS=$#
ALL_PARAMS=( "$@" )
ALL_RODOS_COMPILE_PARAMS=(discovery linux-makecontext on-posix64 skith efr32fg1p linux-x86 on-posixmac gecko on-posix sf2)
SUPPORTED_SETUP_PARAMS=(discovery linux raspbian)
COMPILE_TARGET=$1
UPPER_NAME=""
LOWER_NAME=""

#check if compile parameter is ok
if ! [[ "${ALL_RODOS_COMPILE_PARAMS[*]}" =~ "${COMPILE_TARGET}" ]]; then
	if ! [[ "${SUPPORTED_SETUP_PARAMS[*]}" =~ "${COMPILE_TARGET}" ]]; then
		exit 1
	fi
fi

function readConfig {
	IFS=$'\n' read -d '' -r -a CONFIG < ../workspace.config
	SRC_DIR_LINE_RAW=("${CONFIG[0]}")
	SRC_DIR_LINE=($SRC_DIR_LINE_RAW)
	SOURCE_DIR="${SRC_DIR_LINE[1]}"
}

function setSpecialCompileTargets {
	if [ "$COMPILE_TARGET" = "raspbian" ]; then
		COMPILE_TARGET="on-posix"
	fi
}

function setUpperAndLower {
	if [ "$COMPILE_TARGET" = "discovery" ]; then
		UPPER_NAME="the STM32F4 Discover Board"
		LOWER_NAME="discovery"
	elif [ "$COMPILE_TARGET" = "raspbian" ]; then
		UPPER_NAME="RaspbianOS"
		LOWER_NAME="raspbian"
	elif [ "$COMPILE_TARGET" = "linux-x86" ]; then
		UPPER_NAME="Linux"
		LOWER_NAME="linux"
	fi
}

#defines the generic help function
function helpFunction {

	echo -e "\033[1mPrerequisits:\033[0m"
	echo -e "Make sure './setup.sh' has been run at least once and RODOS is compiled for $UPPER_NAME."
	echo -e "You can do that by running './setup.sh -c $LOWER_NAME'."
	echo -e "\n"
    echo -e "\033[1mHow to use:\033[0m"
	echo -e "Run './build-for-$LOWER_NAME.sh' to compile files from the rodos_src directory and execute them on $UPPER_NAME."
	echo -e "\n"
	echo -e "\033[1mExamples:\033[0m"
	echo -e "'./build-for-$LOWER_NAME.sh'			compiles and executes all the files in rodos_src"
	echo -e "'./build-for-$LOWER_NAME.sh HelloWorld.cpp' 	only compiles and executes HelloWorld.cpp"
	echo -e "'./build-for-$LOWER_NAME.sh -f'		compiles and executes all the files specified in CompileList.txt"
	echo -e "\n"
	echo -e "\033[1mParameters:\033[0m"
	echo -e "    -f	   compiles and executes all files specified in CompileList.txt"
	echo -e "    -h	   shows this text explaination but does nothing else"
	echo -e "    -l	   doesnt remove the log file after compilation"
	echo -e "    -s	   shows the compiler output during compilation"
	
	exit 100
}

#defines the function for setting the required variables, depending on parameters
function configure  {

	for var in "${ALL_PARAMS[@]}"
	do
        if [ "$var" = "$COMPILE_TARGET" ]; then
            continue 1
		elif [ "$var" = "-h" ]; then # -h to show help
			setUpperAndLower
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

	setSpecialCompileTargets
}

#defines the function that compiles the files
function compileFiles {
	if [ "$SHOW_COMPILATION_OUTPUT" = true ]; then
		rodos-executable.sh $COMPILE_TARGET $FILES_TO_COMPILE 2>&1 | tee -a CompilationLog.txt
	else
		rodos-executable.sh $COMPILE_TARGET $FILES_TO_COMPILE 2> CompilationLog.txt
	fi
}

#defines the function that reads the files to compile the CompileList.txt
function readCompileList {

	echo "Reading CompileList.txt"

	FILES_TO_COMPILE=""

	while IFS= read -r line || [[ -n "$line" ]]; do
		FILES_TO_COMPILE="$FILES_TO_COMPILE $line"
	done < "CompileList.txt"

}

#defines the funtion that handles the main program flow
function executeFunction {

	readConfig

	cd ..

	if [ "$COMPILE_FROM_FILE" = true ]; then
		readCompileList
	fi

	rm tst 2> /dev/null

	cd $SOURCE_DIR

	echo "Compiling code..."

	if ! compileFiles ; then
  		echo "Compilation error, check CompilationLog for more information"
		mv CompilationLog.txt ..
		exit 2
	fi
	
    if [ "$KEEP_COMPILATION_LOG" = false ]; then
		rm CompilationLog.txt
	else 
		mv CompilationLog.txt ..
	fi

	echo "Moving executable to top directory..."
    mv tst ..
    cd ..

	exit 0
}

configure
executeFunction