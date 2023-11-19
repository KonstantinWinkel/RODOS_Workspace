#!/bin/bash

#	Author: Konstantin Winkel

CONFIG=( )

export SRC_DIR=""
export TARGET_PREF=""
export LIST_PREF=""
export COMPILED_PLATFORMS=( )

function readConfig {
    local config_line=""
    local i=0

    IFS=$'\n' read -d '' -r -a CONFIG < workspace.config
    
    for config_option in "${CONFIG[@]}"
    do
        IFS=' ' read -r -a config_line <<< "$config_option"

        case "$i" in
            0)
                SRC_DIR="${config_line[1]}"
                ;;
            1)
                TARGET_PREF="${config_line[1]}"
                ;;
            2)
                LIST_PREF="${config_line[1]}"
                ;;
            3)
                for compiled_platform in "${config_line[@]}"
                do
                    if [[ "$compiled_platform" = "compiled_for:" ]]; then
                        continue 1
                    fi

                    COMPILED_PLATFORMS+=("$compiled_platform")
                done
                ;;
            *)
                echo -e "\033[1;35mWARNING\033[0m - config was altered manually: $config_option unkown" 
                ;;
        esac

        ((i+=1))
    done
}

function writeConfig {
    true > workspace.config

    for var in "${CONFIG[@]}"
	do
        echo "$var" >> workspace.config
    done
}

function revert2Default {
    CONFIG[0]="src_dir: rodos_src"
    CONFIG[1]="target_pref: linux"
    CONFIG[2]="list_pref: CompileList.txt" 
    CONFIG[3]="compiled_for: <none>"
    writeConfig
}

function showConfig {
    readConfig

    for var in "${CONFIG[@]}"
    do
        echo "$var"
    done
}

#TODO maybe check if platform is valid/supported
function setCompiledPlatform {
    local platform_string="compiled_for:"
    local platform_found=false

    for arg in "$@"
    do  
        echo "${COMPILED_PLATFORMS[0]}"
        if [[ "${COMPILED_PLATFORMS[0]}" = "<none>" ]]; then
            COMPILED_PLATFORMS[0]="$arg"
            continue 1
        fi

        for platform in "${COMPILED_PLATFORMS[@]}"
        do
            if [[ "$platform" = "$arg" ]]; then
                platform_found=true
                break
            fi
        done

        if $platform_found ; then
            continue 1
        fi

        COMPILED_PLATFORMS+=("$arg")
    done

    for platform in "${COMPILED_PLATFORMS[@]}"
    do
        if [[ "$platform" = "compiled_for:" ]]; then
            continue 1
        fi

        platform_string="$platform_string $platform"
    done

    CONFIG[3]="$platform_string"

    writeConfig
}