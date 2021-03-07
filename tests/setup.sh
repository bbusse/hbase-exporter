#!/usr/bin/env bash

check_dependencies() {
    for i in "${DEPS[@]}"
    do
        if [[ -z $(which "${i}") ]]; then
            error "Could not find ${i}"
            exit 1
        fi
    done
}

extract_archive() {
    printf "Extracting %s archive\n" "$1"
    if ! tar xfz "${1}"; then
        printf "Failed to extract archive: %s\n" "$1"
        exit 1
    fi
}

compare_checksum() {
    local r
    CKSUM=$(sha512 -q "${1}")
    if ! [ "$CKSUM" = "$2" ]; then
        r=1
    else
        r=0
    fi
    echo "$r"
}

write_file() {
    printf "Writing %s\n" "$1"
    printf "%s" "$2" > "$1"
}

run() {
    local pid
    printf "Starting %s\n" "$2"
    if $($1 > /dev/null 2>&1 &); then
        printf "Started %s successfully\n" "$2"
        pid=$!
    else
        printf "Failed to start %s\n" "$2"
        pid="-1"
    fi
    echo "$pid"
}
