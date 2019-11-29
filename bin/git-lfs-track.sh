#!/bin/bash
set -euo pipefail

if [[ $# < 1 ]]; then
    echo "Usage: $(basename "$0") repo_path [min_file_size_to_track=5]"
    echo "Usage: $(basename "$0") /path/to/git/repo 5"
    exit 1
fi

cd "$1"

size=${2:-5}

find . -type f -not -path '*/.git/*' -size +${size}M -exec git lfs track {} \;

git add .gitattributes
