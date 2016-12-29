#!/bin/bash

# AUTHOR : liuxu
# date   : 2016-10-14
#
# 1./cloud/logs/*.log 移到 /cloud/logs/backlog/*.log.YYYYMMDD 同时生成原来相同文件名的文件
# 2.每天零点执行shell脚本
# 3.重启/usr/local/nginx/sbin/nginx -s reload


SOURCE_DIR=/cloud/logs
TARGET_DIR=
SUFFIX=$(date -d yesterday +%Y%m%d)
NGINX=/usr/local/nginx/sbin/nginx
B_VALIDATE=false

TIME=$(date +"%Y-%m-%d %H:%M:%S")
MV_HISTORY=

#====================================

DEBUG=false

DEBUG() {
    if $DEBUG; then
        $@
    fi
}

function ShellHelp() {
cat <<EOF
--------------------------------------------------------------------------------
USAGE:
nginx_log_splitter.sh [-s source_dir] [-t target_dir] [-n nginx_cmd]

OPTIONS:
-h:  print help
-v:  ("v" for validate) validate environment, will not move logs, will not reload nginx
-s:  ("s" for source) log dir
-t:  ("t" for target) target dir. default is $SOURCE_DIR/backlog/
-n:  ("n" for nginx) specify nginx command path. default value is $NGINX
--------------------------------------------------------------------------------
EOF
}

#process options
function ProcessOptions() {
    while getopts ":hvs:t:n:" opt; do
        DEBUG echo "opt: $opt"
        case "$opt" in
            "h")
                ShellHelp
                exit 0
                ;;
            "v")
                B_VALIDATE=true
                ;;
            "s")
                SOURCE_DIR=$OPTARG
                ;;
            "t")
                TARGET_DIR=$OPTARG
                ;;
            "n")
                NGINX=$OPTARG
                ;;
            "?")
                #Unknown option
                echo "* unknown option: $opt"
                ;;
            ":")
                #an option needs a value, which, however, is not presented
                echo "* option -$opt needs a value, but it is not presented"
                ;;
            *)
                #unknown error, should not occur
                echo "* unknown error while processing options and params"
                ;;
        esac
    done
    return $OPTIND
}

function Log() {
    if $B_VALIDATE; then
        echo $1
    else
        echo $1 | tee -a $MV_HISTORY
    fi
}


#====================================

DEBUG echo "[$TIME] script begin"

ProcessOptions "$@"

if [ ! -d "$SOURCE_DIR" ]; then
    echo "[$TIME] source dir does not exist: $SOURCE_DIR"
    exit 1
fi

if [ "$TARGET_DIR" == "" ]; then
    TARGET_DIR=$SOURCE_DIR/backlog
fi
DEBUG echo "[$TIME] target dir: $TARGET_DIR"

if [ ! -d "$TARGET_DIR" ]; then
    mkdir $TARGET_DIR
    if [ $? != 0 ]; then
        echo "[$TIME] target dir create fail: $TARGET_DIR"
        exit 2
    fi
fi

MV_HISTORY=$TARGET_DIR/mv_history
if [ ! -e "$NGINX" ]; then
    Log "[$TIME] nginx cmd file does not exist: $NGINX"
    exit 3
fi

cd $SOURCE_DIR
log_arr=$(ls *.log 2>/dev/null)
if [ $? -ne 0 ]; then
    Log "[$TIME] no log file found under $SOURCE_DIR"
    exit 4
fi

log_count=${#log_arr[*]}
if [ $log_count -eq 0 ]; then
    Log "[$TIME] no log file found under $SOURCE_DIR"
    exit 4
fi

if $B_VALIDATE; then
    echo "[$TIME] vadilation success"
    exit 0
fi

for f in ${log_arr[*]}; do
    mv $SOURCE_DIR/$f $TARGET_DIR/$f.$SUFFIX
    ret=$?
    if [ $ret == 0 ]; then
        echo "[$TIME] mv $SOURCE_DIR/$f to $TARGET_DIR/$f.$SUFFIX" | tee -a $MV_HISTORY
        touch $SOURCE_DIR/$f
    else
        echo "[$TIME] mv $SOURCE_DIR/$f to $TARGET_DIR/$f.$SUFFIX fail ($ret)" | tee -a $MV_HISTORY
    fi
done

$NGINX -s reload
