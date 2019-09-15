#!/bin/sh

ROOT="/data/www"
DOMAIN="laravel.com"
REPO="git://github.com/ElfSundae/laravel.com.git"
BRANCH="master"

config()
{
    echo "local-cdn china-cdn remove-ga remove-ads skip-api"
}

if [[ -n $1 ]]; then
    DOMAIN=$1
    shift
fi

ROOT="$ROOT/$DOMAIN"

if ! [[ -d "$ROOT" ]]; then
    git clone $REPO -b $BRANCH "$ROOT"
fi

cd "$ROOT"

for version in 5.1 5.2 5.3 5.4 5.5; do
    path="resources/docs/zh/$version"
    if ! [[ -d "$path" ]]; then
        git clone git://github.com/laravel-china/laravel-docs.git --single-branch --branch="$version" "$path"
    else
        git -C "$path" reset --hard -q
        git -C "$path" clean -dfx -q
        git -C "$path" pull origin "$version"
    fi
done

build-laravel.com "$ROOT" --root-url="https://$DOMAIN" $(config) "$@"
