#!/bin/bash

#	Author: Konstantin Winkel

#	EXIT CODES:
#	0: No Error
#	1: Parameter Error
#	2: Compilation Error
#	3: RODOS not found
#	127: Unkown Error
#   128 Error changing directories

#change into scripts directory for consistent behaviour
cd "$(dirname "$0")/.." || exit 128

ALL_PARAMS=( "$@" )

source scripts/util/config-util.sh

readConfig

if [ "$TARGET_PREF" = "linux" ]; then
    ./scripts/build/build-for-linux.sh "${ALL_PARAMS[@]}"
elif [ "$TARGET_PREF" = "raspbian" ]; then
    ./scripts/build/build-for-raspbian.sh "${ALL_PARAMS[@]}"
elif [ "$TARGET_PREF" = "discovery" ]; then 
    ./scripts/build/build-for-discovery.sh "${ALL_PARAMS[@]}"
else 
    exit 1
fi
