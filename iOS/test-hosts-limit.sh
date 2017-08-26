#!/bin/sh

# Test limitation of iOS hosts file.
# Run this script by the root user on an iOS Device.
#
# Result:
# About 4000 lines limit.

HOSTS_FILE="/etc/hosts"

restore_default_hosts()
{
    cat <<'EOT' > "$HOSTS_FILE"
127.0.0.1 localhost
::1 localhost
EOT

    chown root:wheel "$HOSTS_FILE"
    chmod 644 "$HOSTS_FILE"
}

# From https://gist.github.com/jjarmoc/1299906
# Returns the integer representation of an IP arg, passed in ascii dotted-decimal notation (x.x.x.x)
atoi()
{
    IP=$1; IPNUM=0
    for (( i=0 ; i<4 ; ++i )); do
        ((IPNUM+=${IP%%.*}*$((256**$((3-${i}))))))
        IP=${IP#*.}
    done
    echo $IPNUM
}

# From https://gist.github.com/jjarmoc/1299906
# Returns the dotted-decimal ascii form of an IP arg passed in integer format
itoa()
{
    a=$(($(($(($((${1}/256))/256))/256))%256))
    b=$(($(($((${1}/256))/256))%256))
    c=$(($((${1}/256))%256))
    d=$((${1}%256))
    echo $a.$b.$c.$d
}

check_reachability()
{
    host="baidu.com"
    if [[ $# > 0 ]]; then host=$1; fi

    ping -c1 -q "$host" &>/dev/null
    echo $?
}

check_reachability_and_exit()
{
    status=$(check_reachability)
    if [[ $status != 0 ]] ; then
         echo "Connection failure: $status"
         echo "Lines  Count(bytes)  File"
         wc -lc "$HOSTS_FILE"
         exit
    fi
}

## parameters: <safeLineNumber> <maxTestLines>
test_line_limit()
{
    if [[ $# > 0 ]]; then safeNumber=$1; else safeNumber=3990; fi
    if [[ $# > 1 ]]; then maxTest=$2; else maxTest=10000; fi

    ip="200.0.0.0"
    num=$(atoi $ip)
    lineStart=$(cat "$HOSTS_FILE" | wc -l)
    ((lineStart++))
    for (( i = $lineStart; i <= $maxTest; i++ )); do
        echo "$ip $i.cn" | tee -a "$HOSTS_FILE"

        if [[ $i -gt $safeNumber ]]; then
            check_reachability_and_exit
        fi

        ((num+=1))
        ip=$(itoa $num)
    done
}

restore_default_hosts
test_line_limit 3990 10000
