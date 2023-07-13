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

ALL_PARAMS=( "$@" )

IFS=$'\n' read -d '' -r -a CONFIG < ../workspace.config
SRC_DIR_LINE_RAW=("${CONFIG[1]}")
SRC_DIR_LINE=($SRC_DIR_LINE_RAW)
TARGET_PREF="${SRC_DIR_LINE[1]}"


if [ "$TARGET_PREF" = "linux" ]; then
    ./build/build-for-linux.sh "${ALL_PARAMS[@]}"
elif [ "$TARGET_PREF" = "raspbian" ]; then
    ./build/build-for-raspbian.sh "${ALL_PARAMS[@]}"
elif [ "$TARGET_PREF" = "discovery" ]; then 
    ./build/build-for-discovery.sh "${ALL_PARAMS[@]}"
else 
    exit 1
fi
