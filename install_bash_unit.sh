#!/usr/bin/env bash

install() {
    if [ -f "bash_unit" ]; then
        printf "bash_unit exists\n"
    else
        curl -o /tmp/install.sh -sLO $1
        chmod +x /tmp/install.sh
        /tmp/install.sh
    fi
}

install https://raw.githubusercontent.com/bbusse/bash_unit/freebsd-compat/install.sh
