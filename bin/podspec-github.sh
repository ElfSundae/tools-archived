#!/bin/bash

if [[ $# < 1 ]]; then
    echo "Missing pod name."
    echo "Usage: $(basename $0) pod_name [pod_name] ..."
    exit 1
fi

for (( i = 1; i <= $#; i++ )); do
    name=${!i}
    md5=$(md5 -q -s $name)
    dir="${md5:0:1}/${md5:1:1}/${md5:2:1}"
    url="https://github.com/CocoaPods/Specs/tree/master/Specs/$dir/$name"
    echo $url

    if [[ $i == 1 ]]; then
        open "$url"
    fi
done
