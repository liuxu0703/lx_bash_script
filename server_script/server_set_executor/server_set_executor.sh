#!/bin/bash

# author : liuxu
# date:  : 2016-10-21
# run task on server set


# fixed environment vars
DEBUG=false
EXECUTE_USER=techops
LOG_DIR=/home/$EXECUTE_USER/.server_admin_script_logs
LOG_PATH=$LOG_DIR/server_set_executor.$(date +"%Y%m%d%").log
TMP_LOG_PATH=/tmp/server_set_executor_$USER_$(date +"%Y%m%d%H%M%S").log
SERVER_SET_XML_DIR=$HOME/.kaiba_server_script
SERVER_SET_XML=$SERVER_SET_XML_DIR/server_set.xml
SERVER_SET_MANAGER_PY=$(cd "$(dirname ${BASH_SOURCE[0]})" && pwd)/server_set_parser.py
SERVER_SET_MANAGER="python $SERVER_SET_MANAGER_PY"

# executor info
CUR_TIME=$(date +"%Y-%m-%d %H:%M:%S")
CUR_USER=$USER
CUR_CMD="$@"

# vars
SERVER_SET_NAME=
SERVER_LIST=
SERVER_TASK=
CMD_OUTPUT_FILE=
B_RUN_SCRIPT=false


#====================================


DEBUG() {
    if $DEBUG; then
        $@
    fi
}

CLEAR_WORK() {
    LogI "[END][CMD][$CUR_CMD]"
    DEBUG echo "clear work, save log from $TMP_LOG_PATH to $LOG_PATH"
    if [ -e $TMP_LOG_PATH ]; then
        exe mkdir $LOG_DIR 1>/dev/null 2>/dev/null
        exe sh -c "cat $TMP_LOG_PATH >> $LOG_PATH"
        if [ $? -eq 0 ]; then
            rm $TMP_LOG_PATH
            DEBUG echo "clear work, save log success, delete tmp log"
        fi
    fi
}
trap "CLEAR_WORK" EXIT

function ShellHelp() {
cat <<EOF

--------------------------------------------------------------------------------
USAGE:

选择一个服务器集并执行命令. cmd可带参数. 脚本参数必须写在cmd之前.
若没有 -u 参数则会使用默认账户(非当前账户)执行命令.
若没有 -n 参数则会提供一个服务器集菜单进行选择.
若没有 -c 参数则会使用当前用户的服务器集配置.
若没有 -s 参数则 cmd 会被当做普通命令执行; 若 -s 参数则 cmd 会被当做脚本执行
server_set_executor.sh [-u user] [-c server_set.xml] [-n server_set_name] [-o file_name] [-s] cmd

编辑当前用户的服务器集配置文件,若没有则创建.
server_set_executor.sh -e

OPTIONS:
-h: 打印帮助.
-e: 编辑服务器集配置文件.
-c: 不使用当前用户的服务器集配置文件,指定外部配置文件.
-n: 从配置中 选择名字为 server_set_name 的服务器集执行命令.
-s: 指定命令来自脚本文件.
-u: 指定执行命令所用账户.
-o: 将各个服务器中执行命令的输出保存至指定文件

DESCRIPTION:
选择服务器集,并对其列表中的服务器依次执行远程命令.远程命令通过ssh执行.
例子: 在列表中的所有服务器的/tmp目录下新建测试文件:
server_set_executor.sh touch /tmp/test_$(date +%Y%m%d%H%M%S)

EOF
echo "命令默认以 $EXECUTE_USER 账户执行,并可由 -u 参数指定账户."
echo "当前用户服务器集配置文件: $SERVER_SET_XML"
echo "执行日志(全部用户): $LOG_PATH"
echo "--------------------------------------------------------------------------------"
echo
}

function exe() {
    sudo -u $EXECUTE_USER "$@" 2>&1
}

function LogD() {
    DEBUG echo "[$CUR_TIME][I][$CUR_USER] $@"
}

function LogI() {
    echo "[$CUR_TIME][I][$CUR_USER] $@" | tee -a $TMP_LOG_PATH
}

function LogE() {
    echo "[$CUR_TIME][E][$CUR_USER] $@" | tee -a $TMP_LOG_PATH
}

function LogW() {
    echo "[$CUR_TIME][W][$CUR_USER] $@" | tee -a $TMP_LOG_PATH
}

#process options
function ProcessOptions() {
    while getopts ":hdesn:c:o:u:" opt; do
        DEBUG echo "opt: $opt"
        case "$opt" in
            "h")
                ShellHelp
                exit 0
                ;;
            "d")
                DEBUG=true
                ;;
            "s")
                B_RUN_SCRIPT=true;
                ;;
            "e")
                if [ ! -e $SERVER_SET_XML ]; then
                    CreateServerSetXml
                fi
                if [ -e $SERVER_SET_XML ]; then
                    vim $SERVER_SET_XML
                else
                    echo "server set config not exist: $SERVER_SET_XML"
                fi
                exit 0
                ;;
            "n")
                SERVER_SET_NAME=$OPTARG
                ;;
            "c")
                SERVER_SET_XML=$(readlink -f $OPTARG)
                if [ ! -e $SERVER_SET_XML ]; then
                    LogE "server set config not exist: $SERVER_SET_XML"
                    exit 1
                fi
                ;;
            "o")
                CMD_OUTPUT_FILE=$OPTARG
                ;;
            "u")
                EXECUTE_USER=$OPTARG
                ;;
            "?")
                #Unknown option
                LogE "unknown option: $opt"
                ShellHelp
                exit 1
                ;;
            ":")
                #an option needs a value, which, however, is not presented
                LogE "option -$opt needs a value, but it is not presented"
                ShellHelp
                exit 1
                ;;
            *)
                #unknown error, should not occur
                LogE "unknown error while processing options and params"
                ShellHelp
                exit 1
                ;;
        esac
    done
    return $OPTIND
}

#see if $1 is interger or not
#if $2, $3 is presented, see if $1 is inside [$2, $3]
#yield true or false
#if present, $2 and $3 should be interger
function IsInterger() {
    local ret
    #make sure input is interger
    if [[ $1 =~ [0-9]+ ]]; then
        ret="true"
    else
        ret="false"
    fi
    if [ "$ret" == "false" -o $# -eq 1 ]; then
        echo $ret
        return
    fi
    #make sure $n is inside the range
    if [[ ( $1 -ge $2 ) && ( $1 -le $3 ) ]]; then
        ret="true"
    else
        ret="false"
    fi
    echo $ret
}

function CreateServerSetXml() {
    if [ ! -d $SERVER_SET_XML_DIR ]; then
        mkdir $SERVER_SET_XML_DIR
    fi

cat > $SERVER_SET_XML <<EOF
<?xml version="1.0" encoding="utf-8"?>
<ServerSetManager>

    <server_set>
        <name>test</name>
        <active>true</active>
        <servers>
            <server ip="121.40.91.109" user="techops" />
        </servers>
    </server_set>

    <server_set>
        <name>web</name>
        <active>true</active>
        <servers>
            <server ip="121.41.49.165" user="techops" />
            <server ip="121.40.142.43" user="techops" />
        </servers>
    </server_set>

</ServerSetManager>
EOF

    if [ $? -ne 0 ]; then
        LogE "create server set config fail: $SERVER_SET_XML"
        return 1
    fi
    return 0
}

function SelectServerSet() {
    local set_list
    local tmp_arr
    local length

    tmp_arr=$($SERVER_SET_MANAGER -f $SERVER_SET_XML -l)
    for s in $tmp_arr; do
        set_list[$length]=$s
        let length++
    done

    DEBUG echo "set_list : ${set_list[*]}"

    echo
    echo "server set menu: "
    local i=0
    while [ $i -lt ${#set_list[*]} ]; do
        index=$(expr $i + 1)
        echo "  [$index]. ${set_list[$i]}"
        let i++
    done

    echo "  [L]. List all server set detail"
    echo "  [E]. Edit server set config xml"
    echo "  [X]. Do nothing and exit"
    read -p "choose a server set: "

    if [[ ( "$REPLY" == "x" ) || ( "$REPLY" == "X" ) ]]; then
        exit
    elif [[ ( "$REPLY" == "l" ) || ( "$REPLY" == "L" ) ]]; then
        echo
        echo "server set detail:"
        $SERVER_SET_MANAGER -f $SERVER_SET_XML -L
        SelectServerSet
    elif [[ ( "$REPLY" == "e" ) || ( "$REPLY" == "E" ) ]]; then
        vim $SERVER_SET_XML
        exit 0
    elif [ $(IsInterger $REPLY 1 ${#set_list[*]}) == "true" ]; then
        echo
        n=$(expr $REPLY - 1)
    else
        echo "invalidate selection !!!"
        exit 1
    fi

    SERVER_SET_NAME=$(echo ${set_list[$n]} | awk -F ":" '{print $1}')
}

function ExecuteTask() {
    #name=web1,ip=121.41.49.165,port=22,user=techops
    local server=$1
    LogD "server info: $server"
    local ip=$(echo $server | awk -F "," '{print $2}' | awk -F "=" '{print $2}')
    local port=$(echo $server | awk -F "," '{print $3}' | awk -F "=" '{print $2}')
    local user=$(echo $server | awk -F "," '{print $4}' | awk -F "=" '{print $2}')
    if [ "$ip" == "" ]; then
        LogE "run task on server fail, ip empty"
        return 1
    fi
    if [ "$user" == "" ]; then
        LogE "run task on server $ip:$port fail, user empty"
        return 2
    fi

    if [ "$port" == "" ]; then
        LogI "about to run \"$SERVER_TASK\" on \"$user@$ip\""
    else
        LogI "about to run \"$SERVER_TASK\" on \"$user@$ip port $port\""
    fi

    cmd="exe ssh"
    if [ ! "$port" == "" ]; then
        cmd="$cmd -p $port"
    fi
    cmd="$cmd $user@$ip"
    if $B_RUN_SCRIPT; then
        cmd="$cmd \"bash -s --\" <"
    fi
    cmd="$cmd $SERVER_TASK"
    LogD "final cmd: $cmd"

    if [ ! "$CMD_OUTPUT_FILE" == "" ]; then
        local parent=$(dirname $CMD_OUTPUT_FILE)
        if [ ! -d $parent ]; then
            LogW "output file $CMD_OUTPUT_FILE parent not exists"
            CMD_OUTPUT_FILE=""
        else
            touch $CMD_OUTPUT_FILE
            if [ $? -ne 0 ]; then
                CMD_OUTPUT_FILE=""
            fi
        fi
    fi

    if [ ! "$CMD_OUTPUT_FILE" == "" ]; then
        echo "########################################################################" | tee -a $CMD_OUTPUT_FILE
        echo "$cmd" | tee -a $CMD_OUTPUT_FILE
        echo "########################################################################" | tee -a $CMD_OUTPUT_FILE
        eval $cmd | tee -a $CMD_OUTPUT_FILE
    else
        echo "########################################################################"
        echo "$cmd"
        echo "########################################################################"
        eval $cmd
    fi
}


#====================================

DEBUG echo "script begin"

ProcessOptions "$@"
arg_start=$?
SERVER_TASK="${@:$arg_start}"

# invoke input password at the beginning
sudo -u $EXECUTE_USER echo
if [ $? -ne 0 ]; then
    LogE "try execute command with user $EXECUTE_USER fail"
    exit 1
fi

if [ ! -e $SERVER_SET_XML ]; then
    CreateServerSetXml
fi
if [ ! -e $SERVER_SET_XML ]; then
    LogE "server set config file not found: $SERVER_SET_XML"
    exit 1
fi

if [ "$SERVER_TASK" == "" ]; then
    LogE "task empty"
    exit 1
fi

if [ "$SERVER_SET_NAME" == "" ]; then
    SelectServerSet
fi

DEBUG echo "server set name: $SERVER_SET_NAME"
if [ "$SERVER_SET_NAME" == "" ]; then
    LogE "server set name empty"
fi

SERVER_LIST=$($SERVER_SET_MANAGER -f $SERVER_SET_XML -n $SERVER_SET_NAME)
if [ ${#SERVER_LIST[*]} -eq 0 ]; then
    LogE "no server under server set $SERVER_SET_NAME"
    exit 1
fi

current_dir=$(pwd)
LogI "[BEGIN][CMD][$CUR_CMD]"
LogI "[BEGIN][DIR][$current_dir]"
for server in ${SERVER_LIST[*]}; do
    ExecuteTask $server
done

