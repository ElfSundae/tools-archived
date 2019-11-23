#!/bin/bash
set -euo pipefail

MIRRORS_ROOT="/data/mirrors"

mkdir -p "$MIRRORS_ROOT"

exit

# _sync git_url [fork_name]
_sync()
{
    # doc: https://help.github.com/en/articles/duplicating-a-repository
    _upstream_url=$1
    if [[ $_upstream_url != *.git ]]; then
        _upstream_url="$_upstream_url.git"
    fi

    _fork_name=$2
    if ! [ $_fork_name ]; then
        _fork_name=$(basename "$_upstream_url" .git)
    fi

    echo "=> Syncing $_fork_name from $_upstream_url"

    cd "$MIRRORS_ROOT"

    if ! [ -d "$_fork_name" ]; then
        git clone "$_upstream_url" "$_fork_name" >> /dev/null 2>&1
    fi

    cd "$_fork_name"
    git remote set-url --push origin "git@github.com:ElfSundae/$_fork_name.git"

    git fetch -p origin
    # https://gist.github.com/grimzy/a1d3aae40412634df29cf86bb74a6f72
    git branch -r | grep -v '\->' | while read remote; do git branch --track "${remote#origin/}" "$remote"; done >> /dev/null 2>&1
    git pull --prune --all --tags -q

    git push --prune --all
    git push --tags
}
