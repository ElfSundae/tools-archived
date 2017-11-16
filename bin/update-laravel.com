#!/bin/sh

. $HOME/.bash_profile

echo "======================="
date

ROOT="/data/www/laravel.com"

if ! [[ -d "$ROOT" ]]; then
    git clone git://github.com/ElfSundae/laravel.com.git -b mirror-site "$ROOT"
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

build-laravel.com "$ROOT" \
    --root-url="https://laravel.com" \
    china-cdn \
    local-cdn \
    remove-ga \
    remove-ads \
    cache

date
