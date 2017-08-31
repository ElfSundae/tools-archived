#!/bin/sh
#
# Test limitation of iOS hosts file.
#
# Usage: $ test-hosts-limit.sh -h
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
# 从系统日志看，也可能是 mDNSResponder 的 bug 导致的：错误
# `Property list invalid for format: 200 (property lists cannot contain NULL)`
#
# `mDNSResponderHelper` 是 `mDNSResponder` 的守护进程。
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
# | Lines | Size(bytes) |
# 4077 80188 /etc/hosts
# 4145 81559 /etc/hosts
# 4123 81119 /etc/hosts
# 4402 86845 /etc/hosts
# 4711 93172 /etc/hosts

HOSTS_FILE="/etc/hosts"

flush_dns_cache()
{
    killall -HUP mDNSResponder &>/dev/null
}

reload_mDNSResponder()
{
    launchctl unload /System/Library/LaunchDaemons/com.apple.mDNSResponder.plist &>/dev/null
    launchctl load -w /System/Library/LaunchDaemons/com.apple.mDNSResponder.plist &>/dev/null
}

restore_default_hosts()
{
    cat <<'EOT' > "$HOSTS_FILE"
127.0.0.1 localhost
::1 localhost
EOT

    chown root:wheel "$HOSTS_FILE"
    chmod 644 "$HOSTS_FILE"

    flush_dns_cache
    sleep 1
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
            sleep 0.2

            status=$(check_reachability)
            if [[ $status != 0 ]] ; then
                sed -i '$ d' "$HOSTS_FILE"  # Remove the last line
                echo "Connection failure: $status"
                echo "Lines  Size(bytes)  File"
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
    cat <<EOT
Test limitation of iOS hosts file.

Note: Run this script AS ROOT on an iOS Device.
    Before running every test, you should restore hosts file, respring
    SpringBoard and toggle Airplane Mode to make network reachable.

Usage: $script <testcase|command> <options>

Commands:
    flush           Flush DNS cache
    restore         Restore the default hosts file
    respring        Respring iOS

Testcase and Options:
    line                Test max line of hosts file
    --safe-lines        Specify a safe line number that should not check
                        network reachability, default is 4000
    --max-test-lines    Default is 10000
    -a|--append         Append contents to the current hosts file instead of
                        creating a new one

    domain              Test max domains pre line

    -h|--help           show this help
EOT
}

if [[ $# > 0 ]]; then
    TESTCASE=$1
    shift
else
    usage
    exit 0
fi

SAFE_LINES=4000
MAX_TEST_LINES=10000
APPEND=0

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
        -a|--append)
            APPEND=1
            shift
            ;;
        *)
            break
            ;;
    esac
done


case "$TESTCASE" in
    flush)
        flush_dns_cache
        ;;
    restore)
        restore_default_hosts
        ;;
    respring)
        killall -HUP SpringBoard
        ;;
    line)
        if [[ $APPEND == 0 ]]; then
            restore_default_hosts
        fi
        test_line_limit $SAFE_LINES $MAX_TEST_LINES
        ;;
    domain)
        echo "TODO..."
        ;;
    *)
        usage
        ;;
esac
