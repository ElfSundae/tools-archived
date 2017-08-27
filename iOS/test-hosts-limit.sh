#!/bin/sh
#
# Test limitation of iOS hosts file.
# Run this script AS ROOT on an iOS Device.
#
#
#【测试结论】
# hosts 不可用不是 iOS 的限制，而是因为在 DNS 查询时不合适的 hosts 文件会导致
# mDNSResponder 进程挂掉。此时网络连接是正常的，某些 app 或聊天系统可以正常使用，因为
# 他们自己实现的 DNS 查询，例如微信、QQ 。
#
#       Hardware Model:      iPhone7,1
#       Process:             mDNSResponder [98799]
#       Path:                /usr/sbin/mDNSResponder
#       Identifier:          mDNSResponder
#       Code Type:           ARM-64 (Native)
#       Parent Process:      launchd [1]
#
#       OS Version:          iOS 9.3.3 (13G34)
#
#       Exception Type:  EXC_RESOURCE
#       Exception Subtype: CPU
#       Exception Message: (Limit 50%) Observed 52% over 180 secs
#       Exception Note:  NON-FATAL CONDITION (this is NOT a crash)
#
# 从 crash 报告看，应该是在解析 hosts 文件时消耗过多 CPU 导致被挂掉。
#
#【一些命令】
#   killall -HUP SpringBoard
#   ps -A | grep mDNSResponder
#   killall -HUP mDNSResponderHelper
#   killall -HUP mDNSResponder
#   launchctl load -w /System/Library/LaunchDaemons/com.apple.mDNSResponder.plist
#   launchctl unload /System/Library/LaunchDaemons/com.apple.mDNSResponder.plist
#
#【测试数据】
#
# 4077 80188 /etc/hosts
# 4004 78655 /etc/hosts
# 4009 78760 /etc/hosts
# 4002 78613 /etc/hosts

HOSTS_FILE="/etc/hosts"

restore_default_hosts()
{
    cat <<'EOT' > "$HOSTS_FILE"
127.0.0.1 localhost
::1 localhost
EOT

    chown root:wheel "$HOSTS_FILE"
    chmod 644 "$HOSTS_FILE"

    launchctl unload /System/Library/LaunchDaemons/com.apple.mDNSResponder.plist &>/dev/null
    launchctl load -w /System/Library/LaunchDaemons/com.apple.mDNSResponder.plist &>/dev/null
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

## parameters: <safeLineNumber> <maxTestLines>
test_line_limit()
{
    if [[ $# > 0 ]]; then safeNumber=$1; else safeNumber=4000; fi
    if [[ $# > 1 ]]; then maxTest=$2; else maxTest=10000; fi

    ip="200.0.0.0"
    num=$(atoi $ip)
    lineStart=$(cat "$HOSTS_FILE" | wc -l)
    ((lineStart++))
    for (( i = $lineStart; i <= $maxTest; i++ )); do
        if [[ $i -lt $safeNumber ]]; then
            echo "$ip $i.cn" >> "$HOSTS_FILE"
        else
            echo "$ip $i.cn" | tee -a "$HOSTS_FILE"
        fi

        if [[ $i -gt $safeNumber ]]; then
            status=$(check_reachability)
            if [[ $status != 0 ]] ; then
                sed -i '$ d' "$HOSTS_FILE"  # Remove the last line
                echo "Connection failure: $status"
                echo "Lines  Count(bytes)  File"
                wc -lc "$HOSTS_FILE"
                break
            fi
        fi

        ((num+=1))
        ip=$(itoa $num)
    done
}

usage()
{
    script=$(basename $0)
    usage=$(cat <<EOT
$script - Test limitation of iOS hosts file

Usage: $script <testcase|command> <options>

Commands:
    restore         Restore the default hosts file
    respring        Respring iOS

Testcase and Options:
    line
    --safe-lines        Specify a safe line number that should not check network reachability, default is 4000
    --max-test-lines    default is 10000

    -h|--help           show this help
EOT
)
    echo "$usage"
}

if [[ $# > 0 ]]; then
    TESTCASE=$1
    shift
else
    usage; exit 0
fi

SAFE_LINES=4000
MAX_TEST_LINES=10000

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage; exit 0
            ;;
        --safe-lines*)
            SAFE_LINES=`echo $1 | sed -e 's/^[^=]*=//g'`
            shift
            ;;
        --max-test-lines*)
            MAX_TEST_LINES=`echo $1 | sed -e 's/^[^=]*=//g'`
            shift
            ;;
        *)
            break
            ;;
    esac
done


case "$TESTCASE" in
    restore)
        restore_default_hosts
        ;;
    respring)
        killall -HUP SpringBoard
        ;;
    line)
        restore_default_hosts
        test_line_limit $SAFE_LINES $MAX_TEST_LINES
        ;;
    *)
        usage
        ;;
esac
