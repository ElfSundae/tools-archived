#!/bin/sh

# 快手视频去水印
# Web: https://dy.kukutool.com/kuaishou
# JS: https://mini2.fccabc.com/static/js/kuaishou.v3.js


url='http://www.gifshow.com/s/LfgGoEzI'
random=`awk -v min=152497338832332 -v max=99552497338832332 'BEGIN{srand(); print int(min+rand()*(max-min+1))}'`
sign=`printf "$url@&^$random" | md5sum | awk '{print $1}'`

data="{\"sourceURL\":\"$url\",\"e\":\"$sign\",\"r\":\"$random\"}"

curl -X POST 'https://mini2.fccabc.com/kuaishou' \
    --silent \
    -H 'Accept: application/json, text/plain, */*' \
    -H 'Referer: https://dy.kukutool.com/kuaishou?i=1' \
    -H 'Origin: https://dy.kukutool.com' \
    -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36' \
    -H 'Content-Type: application/x-www-form-urlencoded;charset=UTF-8' \
    --data "$data" \
    --compressed | json_pp
