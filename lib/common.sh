#!/bin/bash


exitfn() {
    echo "$2"
    exit "$1"
}


log() {
    local logline="$USER $1"
    echo "$logline" >> infra.txt
}
