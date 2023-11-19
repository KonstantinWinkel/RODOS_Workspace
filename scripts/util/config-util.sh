#!/bin/bash

CONFIG=( "" )
COMPILED_PLATFORMS=( "" )

function readConfig {
    IFS=$'\n' read -d '' -r -a CONFIG < ../workspace.config
    IFS=' ' read -r -a COMPILED_PLATFORMS <<< "${CONFIG[3]}"
}

function writeConfig {
    > ../workspace.config

    for var in "${CONFIG[@]}"
	do
        echo $var >> ../workspace.config
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
    local platform_string=""
    local platform_found=false

    for arg in "$@"
    do
        if [[ "${COMPILED_PLATFORMS[1]}" = "<none>" ]]; then
            COMPILED_PLATFORMS[1]="$arg"
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

        COMPILED_PLATFORMS+=($arg)
    done

    for platform in "${COMPILED_PLATFORMS[@]}"
    do
        platform_string="$plaform_string $platform"
    done

    CONFIG[3]="$platform_string"

    writeConfig
}