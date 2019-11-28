#!/bin/bash
set -euo pipefail

if [[ $# < 1 ]]; then
    echo "Usage: $0 source [repo-name]"
    exit 1
fi

SOURCE=${1%/}
REPO_NAME=${2:-$(basename $SOURCE .git)}
MIRROR="git@github.com:ElfSundae/$REPO_NAME.git"
REPO_PATH="/data/mirrors/$REPO_NAME"

sync-git-mirror.sh $SOURCE $MIRROR --path="$REPO_PATH"
