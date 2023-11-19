#!/bin/bash

#	Author: Konstantin Winkel

#	EXIT CODES:
#	0: No Error
#	1: Parameter Error
#	2: Compilation Error
#	3: RODOS not found
#	127: Unkown Error
#	128: Error changing directories

#change into scripts directory for consistent behaviour
cd "$(dirname "$0")" || exit 128

ALL_PARAMS=( "$@" )

(./build-generic.sh discovery "${ALL_PARAMS[@]}")
BUILD_GENERIC_RETURN=$?

#check if helpfunction was executed
if [ $BUILD_GENERIC_RETURN -eq 100 ]; then
	exit 0
fi

#check if program encountered any errors
if [ $BUILD_GENERIC_RETURN -ne 0 ]; then
	exit $BUILD_GENERIC_RETURN
fi

#create binary and flash
cd ../..
echo "Creating binary executable..."
arm-none-eabi-objcopy -S -O binary tst myExe.bin

echo "Flashing board..."
cp myExe.bin "/media/$USER/DIS_F407VG"

echo "Removing temporary files..."
rm myExe.bin
rm tst