#!/bin/bash

_url="https://twitter.com"
_url="https://developers.google.com"
_url="https://github.com"

_times=${1:-6}

_totalTime=0

_test()
{
    result=$(curl -s -o /dev/null -w "%{http_code} %{time_total}" "$1")
    IFS=' ' read code time <<< $result

    _totalTime=$(bc -l <<< "${_totalTime}+${time}")

    if (( $code >= 200 )) && (( $code < 400 )); then
        code="✅ $code"
    else
        code="❌ $code"
    fi

    echo "$code ${time}s"
}

echo $_url

for (( i=0; i<$_times; i++ )); do
    _test $_url
done

_avgTime=$(bc -l <<< "scale=6; ${_totalTime}/${_times}")
echo "Average time: ${_avgTime}s"
