#!/bin/bash

#	Author: Konstantin Winkel

#   EXIT CODES:
#   0: No Error
#   1: Parameter Error
#   2: Package installation failure
#	128: Error changing directories

cd "$(dirname "$0")/.." || exit 128

source scripts/util/config-util.sh
source scripts/util/platform-util.sh

RODOS_COMPILE_PARAMS=()

NUM_PARAMS=$#
ALL_PARAMS=( "$@" )

COMPILE_ONLY=false
UPDATE_RODOS=false
REVERT_RODOS=false
ON_RASPBIAN=false

WORKSPACE_PATH="$(pwd)"

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
	echo -e "   -r  revert to recent working RODOS version" 
	echo -e "   -u  update and recompile RODOS"
	echo -e "\n"
	echo -e "\033[1mCurrently supported setup parameters\033[0m"

	for i in "${SUPPORTED_PLATFORMS[@]}"
	do
		echo -e "	- $i"
	done

	exit 0
}

function configure {

	if [[ $NUM_PARAMS -lt 1 ]]; then
		echo -e "\033[1;31mERROR\033[0m: Invalid Parameters"
		helpFunction
		exit 1
	fi

	for var in "${ALL_PARAMS[@]}"
	do	
		#if its a platform -> add it to the compile list
		if [[ "${SUPPORTED_PLATFORMS[*]}" =~ "${var}" ]]; then
			RODOS_COMPILE_PARAMS+=("$var")
			if [ "$var" = "raspbian" ]; then
				ON_RASPBIAN=true
			fi
			continue 1
		elif [[ "${ALL_RODOS_COMPILE_PARAMS[*]}" =~ "${var}" ]]; then
			RODOS_COMPILE_PARAMS+=("$var")
			echo -e "\033[1;31mWARNING\033[0m: Using parameters compatible that are not supported in this workspace but can build RODOS is not recommended, proceed with care..."
			continue 1
		fi
		
		#if not a platform -> its a parameter
		case "$var" in
			-h)
				helpFunction
				exit 0
				;;
			-c)
				COMPILE_ONLY=true
				;;
			-r)
				REVERT_RODOS=true
				;;
			-u)
				UPDATE_RODOS=true
				;;
			*) #catch all other parameters
				echo -e "\033[1;31mERROR\033[0m: Invalid Parameters"
				helpFunction
				exit 1
				;;
		esac
	done
}

#function to check and, if necessary, install a package
function CheckAndInstallPackage {

	local OUTPUT="Checking for $1:"
	local PKG_OK
	
	PKG_OK=$(dpkg-query -W --showformat='${Status}\n' "$1" 2>/dev/null | grep "install ok installed") >/dev/null

	if [ "" = "$PKG_OK" ]; then
		OUTPUT="$OUTPUT \033[1;31mNOT FOUND\033[0m"
		echo -e "${OUTPUT}"
	elif [ "install ok installed" = "$PKG_OK" ]; then
		OUTPUT="$OUTPUT \033[1;32mFOUND\033[0m"
		echo -e "${OUTPUT}"
		return
	fi

	echo -e "Installing package $1"
	sudo apt-get --yes install "$1"

	echo -e "\nChecking if install was successful"
	OUTPUT="Checking for $1:"
	PKG_OK=$(dpkg-query -W --showformat='${Status}\n' "$1" 2>/dev/null |grep "install ok installed") >/dev/null

	if [ "" = "$PKG_OK" ]; then
		OUTPUT="$OUTPUT \033[1;31mNOT FOUND\033[0m"
		echo -e "${OUTPUT}"
		echo -e "\033[1;31mERROR\033[0m: Package $1 could not be installed, please try manual installation."
		exit 2
	elif [ "install ok installed" = "$PKG_OK" ]; then
		OUTPUT="$OUTPUT \033[1;32mFOUND\033[0m"
		echo -e "${OUTPUT}"
	fi
}

function buildRodos {

	if [[ "$1" = "<none>" ]]; then
		return
	fi

	echo -e "Building RODOS for $1"

	cd "$WORKSPACE_PATH"/rodos || exit 128

	source setenvs.sh > /dev/null
	if [ "$1" = "raspbian" ]; then
		rodos-lib.sh on-posix
	elif [ "$1" = "linux" ]; then
		rodos-lib.sh linux-x86
	else
		rodos-lib.sh "$1"
	fi

	cd ..

	setCompiledPlatform "$1"
}

function buildPlatforms {
	echo -e "\nCompiling RODOS\n"

	cd "$WORKSPACE_PATH"/rodos || exit 128

	for i in "${RODOS_COMPILE_PARAMS[@]}"
	do
		buildRodos "$i"
		echo -e "\n"
	done

}

function enableExecutionPermissions {

	if sudo chmod +rwx "$1" 2>/dev/null ; then
		echo -e "$1 \033[1;32mENABLED\033[0m"
	else
		echo -e "$1 \033[1;31mDISABLED\033[0m - please check permissions manually"
	fi
}

function updateRODOS {
	echo -e "pulling newest RODOS version"
	
	cd "$WORKSPACE_PATH/rodos" || exit 128
	git pull

	buildPlatforms

	echo -e "done"
}

function revertRODOS {
	echo -e "reverting RODOS to last working version"

	cd "$WORKSPACE_PATH/rodos" || exit 128
	git checkout a71ba2141cdf2e8c56eff041c1dec6113b0b9419 

	buildPlatforms

	echo -e "done"
}

function checkAllPackages {
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
}

function setAllScriptPermissions {
	echo -e "Enableing execution permissions\n"

	cd "$WORKSPACE_PATH/scripts" || exit 128

	enableExecutionPermissions configure-workspace.sh
	enableExecutionPermissions build.sh
	enableExecutionPermissions build/build-generic.sh
	enableExecutionPermissions build/build-for-linux.sh
	enableExecutionPermissions build/build-for-discovery.sh
	enableExecutionPermissions build/build-for-raspbian.sh
	enableExecutionPermissions util/config-util.sh
	enableExecutionPermissions util/platform-util.sh
}

function runSetupScript {
	cd "$WORKSPACE_PATH" || exit 128

	if $UPDATE_RODOS ; then
		readConfig
		updateRODOS
		exit 0
	fi

	if $REVERT_RODOS ; then
		readConfig
		revertRODOS
		exit 0
	fi

	if $COMPILE_ONLY ; then
		readConfig
		buildPlatforms
		exit 0
	fi

	checkAllPackages

	#clone RODOS
	echo -e "\nCloning RODOS\n"
	git clone https://gitlab.com/rodos/rodos


	echo -e "\nCompiling RODOS\n"
	readConfig

	cd rodos || exit 128
	buildPlatforms

	setAllScriptPermissions

	echo -e "\nSetup Complete\n"
	exit 0
}

configure

runSetupScript
