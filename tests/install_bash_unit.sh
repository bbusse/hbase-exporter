#!/usr/bin/env bash

install() {
    if [ -f "bash_unit" ]; then
        printf "bash_unit test framework exists\n"
    else
        curl -o /tmp/install.sh -sLO "$1"
        chmod +x /tmp/install.sh
        /tmp/install.sh
    fi
}

install https://raw.githubusercontent.com/pgrange/bash_unit/master/install.sh
