#!/bin/bash

trap "exit" SIGHUP SIGINT SIGTERM

if [[ $# < 1 ]]; then
    echo "Retry command execution if failed."
    echo "Usage: $0 COMMAND"
    exit 1
fi

$@ || $0 "$@"
