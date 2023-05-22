#!/bin/bash

#	Author: Konstantin Winkel

#   EXIT CODES:
#   0: No Error
#   1: Parameter Error
#   2: Package installation failure


cd "$(dirname "$0")"

ALL_RODOS_COMPILE_PARAMS=(discovery linux-makecontext on-posix64 skith efr32fg1p linux-x86 on-posixmac gecko on-posix sf2)
RODOS_COMPILE_PARAMS=()
SUPPORTED_SETUP_PARAMS=(discovery linux-x86 raspbian)

NUM_PARAMS=$#
ALL_PARAMS=( "$@" )

COMPILE_ONLY=false
ON_RASPBIAN=false

function helpFunction {
	echo -e "\033[1mHow to use:\033[0m"
	echo -e "Run './setup.sh' to setup the workspace."
	echo -e "This includes checking if all required packages are installed (and, if not, installing them.), cloning the RODOS and compiling it for the required platform."
	echo -e "\n"
	echo -e "\033[1mExamples:\033[0m"
	echo -e "'./setup.sh discovery'	clones RODOS and compiles it for the STM32F4 Discovery board"
	echo -e "'./setup.sh discovery linux-x86' same as above, but compiles it for both Linux and Discovery board"	
	echo -e "'./setup.sh -c linux-x86' only compiles RODOS for linux"
	echo -e "\n"
	echo -e "\033[1mParameters:\033[0m"
	echo -e "	-c 	only compiles RODOS for the specified platform (should only be used after this script already ran at least once)"
	echo -e "	-h 	shows this text explaination but does nothing else"  
	echo -e "\n"
	echo -e "\033[1mCurrently supported setup parameters\033[0m"

	for i in "${SUPPORTED_SETUP_PARAMS[@]}"
	do
		echo -e "	- $i"
	done

	exit 0
}

function configure {

	if [[ $NUM_PARAMS -lt 1 ]]; then
		echo -e "\033[1;31mERROR\033[0m: Invalid Parameters, use parameter -h for more info"
		exit 1
	fi

	for var in "${ALL_PARAMS[@]}"
	do
		if [ "$var" = "-h" ]; then
			helpFunction
			exit 0;
		elif [ "$var" = "-c" ]; then
			COMPILE_ONLY=true
		elif [[ "${SUPPORTED_SETUP_PARAMS[*]}" =~ "${var}" ]]; then
			RODOS_COMPILE_PARAMS+=($var)
			if [ "$var" = "raspbian" ]; then
				ON_RASPBIAN=true
			fi
		elif [[ "${ALL_RODOS_COMPILE_PARAMS[*]}" =~ "${var}" ]]; then
			RODOS_COMPILE_PARAMS+=($var)
			echo -e "\033[1;31mWARNING\033[0m: Using parameters compatible that are not supported in this workspace but can build RODOS is not recommended, proceed with care..."
		else
			echo -e "\033[1;31mERROR\033[0m: Invalid Parameters, use parameter -h for more info"
			exit 1
		fi
	done
}

#function to check and, if necessary, install a package
function CheckAndInstallPackage {

	local OUTPUT="Checking for $1:"
	local PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $1 2>/dev/null |grep "install ok installed") >/dev/null

	if [ "" = "$PKG_OK" ]; then
		OUTPUT="$OUTPUT \033[1;31mNOT FOUND\033[0m"
		echo -e ${OUTPUT}
	elif [ "install ok installed" = "$PKG_OK" ]; then
		OUTPUT="$OUTPUT \033[1;32mFOUND\033[0m"
		echo -e ${OUTPUT}
		return
	fi

	echo -e "Installing package $1"
	sudo apt-get --yes install $1

	echo -e "\nChecking if install was successful"
	local OUTPUT="Checking for $1:"
	local PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $1 2>/dev/null |grep "install ok installed") >/dev/null

	if [ "" = "$PKG_OK" ]; then
		OUTPUT="$OUTPUT \033[1;31mNOT FOUND\033[0m"
		echo -e ${OUTPUT}
		echo -e "\033[1;31mERROR\033[0m: Package $1 could not be installed, please try manual installation."
		exit 2
	elif [ "install ok installed" = "$PKG_OK" ]; then
		OUTPUT="$OUTPUT \033[1;32mFOUND\033[0m"
		echo -e ${OUTPUT}
	fi
}

function buildRodos {
	echo -e "Building RODOS for $1"

	source setenvs.sh > /dev/null
	if [ "$1" = "raspbian" ]; then
		rodos-lib.sh on-posix
	else
		rodos-lib.sh $1
	fi
}

function enableExecutionPermissions {

	if sudo chmod +rwx scripts/$1 2>/dev/null ; then
		echo -e "$1 \033[1;32mENABLED\033[0m"
	else
		echo -e "$1 \033[1;31mDISABLED\033[0m - please check permissions manually"
	fi
}

configure

#move to top directory
cd ..

if [ "$COMPILE_ONLY" = false ]; then
	echo -e "\nChecking required packages\n"
	CheckAndInstallPackage "apt-utils"
	CheckAndInstallPackage "clang"
	CheckAndInstallPackage "clang-format"
	CheckAndInstallPackage "clang-tools"
	CheckAndInstallPackage "gdb"
	
	if [ "$ON_RASPBIAN" = false ]; then
		CheckAndInstallPackage "gcc-multilib"
		CheckAndInstallPackage "g++-multilib"
	fi
	
	CheckAndInstallPackage "gcc-arm-none-eabi"
	CheckAndInstallPackage "binutils-arm-none-eabi"
	CheckAndInstallPackage "libnewlib-arm-none-eabi"
	CheckAndInstallPackage "cmake"

	#clone RODOS
	echo -e "\nCloning RODOS\n"
	git clone https://gitlab.com/rodos/rodos
fi

cd rodos
#(git checkout a71ba2141cdf2e8c56eff041c1dec6113b0b9419) > /dev/null #revert to last know workin master for STM boards

echo -e "\nCompiling RODOS\n"
for i in "${RODOS_COMPILE_PARAMS[@]}"
do
	buildRodos $i
	echo -e "\n"
done

cd ..

if [ "$COMPILE_ONLY" = false ]; then

	echo -e "Enableing execution permissions\n"

	enableExecutionPermissions build-for-linux.sh
	enableExecutionPermissions build-for-discovery.sh
	enableExecutionPermissions build-for-raspbian.sh

fi

echo -e "\nSetup Complete\n"
exit 0
