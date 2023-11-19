#!/bin/bash

#	Author: Konstantin Winkel

#	EXIT CODES:
#	0: No Error
#	1: Parameter Error
#   128: Error changing directories

#change into scripts directory for consistent behaviour
cd "$(dirname "$0")/.." || exit 128

source scripts/util/config-util.sh
source scripts/util/platform-util.sh

ALL_PARAMS=( "$@" )

function changePreferedList {
    readConfig
    CONFIG[2]="list_pref: $1"
    writeConfig
}

function changeSourceDirectory {
    readConfig
    CONFIG[0]="src_dir: $1"
    CURRENT_PATH="$(pwd)"

    if cd ../"$1" 2>/dev/null; then
        cd "$CURRENT_PATH" || exit 128
    else
        mkdir -p ../"$1"
    fi

    writeConfig
}

function changePreferredTarget {
    readConfig

    if [[ ! "${SUPPORTED_PLATFORMS[*]}" =~ "$1" ]]; then
        echo -e "\033[1;31mERROR\033[0m - new target preference not in list of supported targets"
        exit 1
    fi

    CONFIG[1]="target_pref: $1"
    writeConfig
}

function helpFunction {
    echo -e "\033[1mHow to use:\033[0m"
    echo -e "Use this script to change the variables of workspace.config."
    echo -e "Of course, if you know what you're doing, you can also manually change the values yourself."
    echo -e "However, it is recommended to use this script as it makes sure that the new values are valid."
    echo -e "\033[1mExample:\033[0m"
    echo -e "'./configure-workspace.sh -target_pref discovery' changes the target preference to discovery"
    echo -e "\033[1mParameters:\033[0m"
    echo -e "    -h              shows this help text"
    echo -e "    -s              shows the current config"
    echo -e "    -default        revert config back to default"
    echo -e "    -list_pref      change the compile list preference"
    echo -e "    -src_dir        change the source directory"
    echo -e "    -target_pref    change the prefered target of build.sh"
    exit "$1"
}

function configure {
    if [ "${ALL_PARAMS[0]}" = "-h" ]; then
        helpFunction 0 
    elif [ "${ALL_PARAMS[0]}" = "-s" ]; then
        showConfig
    elif [ "${ALL_PARAMS[0]}" = "-default" ]; then
        revert2Default
    elif [ "${ALL_PARAMS[0]}" = "-src_dir" ]; then
        changeSourceDirectory "${ALL_PARAMS[1]}"
    elif [ "${ALL_PARAMS[0]}" = "-target_pref" ]; then
        changePreferredTarget "${ALL_PARAMS[1]}"
    elif [ "${ALL_PARAMS[0]}" = "-list_pref" ];then
        changePreferedList "${ALL_PARAMS[1]}"
    else
        echo -e "\033[1;31mERROR\033[0m invalid parameters"
        helpFunction 1
    fi
}

configure