#!/bin/bash
# author : liuxu-0703@163.com

# v1.0  2016-05-25
#       list and connect to remote ssh server


DEBUG=false

SCRIPT_PATH="$(cd "$(dirname ${BASH_SOURCE[0]})" && pwd)"
SCRIPT_CONF_DIR=$HOME/.lx_bash_conf
HOST_XML=$SCRIPT_CONF_DIR/ssh_host_set.xml
HOST_MANAGER_PY=$SCRIPT_PATH/ssh_host_set_manager.py
HOST_MANAGER="python $HOST_MANAGER_PY $HOST_XML"

DEBUG() {
    if $DEBUG; then
        $@
    fi
}

function ShellHelp() {
cat <<EOF

--------------------------------------------------------------------------------
USAGE:
ssh_host_connector.sh [-e] [-h]

OPTIONS:
-e: gedit configuration xml file
-h: print help

DESCRIPTION:
connect to ssh remote server use hosts defined in ssh_host_set.xml
--------------------------------------------------------------------------------

EOF
}

function CreateConf() {
    if [ ! -d $SCRIPT_CONF_DIR ]; then
        mkdir $SCRIPT_CONF_DIR
    fi

cat > $HOST_XML <<EOF
<?xml version="1.0" encoding="utf-8"?>
<SshHostmanager>

    <host
        name="sample_host_1"
        ip="1.1.1.1"
        port=""
        user="user"
        index="1"
        password="123456"
        enabled="true" />

    <host
        name="sample_host_2"
        ip="2.2.2.2"
        port=""
        user="root"
        index="1"
        password="654321"
        enabled="true" />

</SshHostmanager>
EOF
}

#see if $1 is interger or not
#if $2, $3 is presented, see if $1 is inside [$2, $3]
#yield true or false
#if present, $2 and $3 should be interger
function IsInterger() {
    local ret       #return value

    if [[ $1 =~ [0-9]+ ]]; then     #make sure input is interger
        ret="true"
    else
        ret="false"
    fi

    if [ "$ret" == "false" -o $# -eq 1 ]; then
        echo $ret
        return
    fi

    if [[ ( $1 -ge $2 ) && ( $1 -le $3 ) ]]; then      #make sure $n is inside the range
        ret="true"
    else
        ret="false"
    fi

    echo $ret
}

function printHostAttr() {
    echo $1 | awk -F "$2=" '{print $2}' | awk -F "," '{print $1}'
}

function SelectHost() {
    local A_HOSTS
    local tmp_arr
    local length
    
    local arr_host
    local arr_host_user
    local arr_host_name
    local arr_host_ip
    local arr_host_port

    local selection
    
    tmp_arr=$($HOST_MANAGER -l)
    for s in $tmp_arr; do
        DEBUG echo $s
        length=${#A_HOSTS[*]}
        A_HOSTS[$length]=$s
    done
    
    echo
    echo "Host Connector Menu: "
    local count=${#A_HOSTS[*]}
    local i=0
    while [ $i -lt $count ]; do
        selection=""
        index=$(expr $i + 1)
        arr_host=${A_HOSTS[$i]}
        arr_host_ip=$(printHostAttr $arr_host "host_ip")
        arr_host_port=$(printHostAttr $arr_host "host_port")
        arr_host_name=$(printHostAttr $arr_host "host_name")
        arr_host_user=$(printHostAttr $arr_host "user_name")
        arr_host_pwd=$(printHostAttr $arr_host "password")
        if [ $count -ge 10 -a $index -lt 10 ]; then
            selection="[ $index]."
        else
            selection="[$index]."
        fi
        selection="$selection $arr_host_name - $arr_host_ip"
        if [ ! "$arr_host_port" == "" ]; then
            selection="${selection}:${arr_host_port}"
        fi
        selection="$selection as $arr_host_user"
        echo "  $selection"
        let i++
    done
   
    if [ $count -ge 10 ]; then
        space=" "
    else
        space=""
    fi
    echo "  [${space}S]. List All Host Detail"
    echo "  [${space}E]. Edit ssh_host_set.xml"
    echo "  [${space}X]. Do Nothing and Exit"
    read -p "choose a keywordset: "

    if [[ ( "$REPLY" == "x" ) || ( "$REPLY" == "X" ) ]]; then
        echo
        exit
    elif [[ ( "$REPLY" == "s" ) || ( "$REPLY" == "S" ) ]]; then
        echo
        echo "*****************************************************"
        echo "*. Host List Detail :"
        echo 
        $HOST_MANAGER -d
        echo "*****************************************************"
        SelectHost
    elif [[ ( "$REPLY" == "e" ) || ( "$REPLY" == "E" ) ]]; then
        vim $HOST_XML
        echo
        exit
    elif [ $(IsInterger $REPLY 1 ${#A_HOSTS[*]}) == "true" ]; then
        n=$(expr $REPLY - 1)
    else
        echo
        echo "Invalidate Selection !!!"
        echo
        exit
    fi
    
    arr_host=${A_HOSTS[$n]}
    arr_host_ip=$(printHostAttr $arr_host "host_ip")
    arr_host_port=$(printHostAttr $arr_host "host_port")
    arr_host_name=$(printHostAttr $arr_host "host_name")
    arr_host_user=$(printHostAttr $arr_host "user_name")
    arr_host_pwd=$(printHostAttr $arr_host "password")
    
    local ssh_command
    if [ "$arr_host_port" == "" ]; then
        ssh_command="$arr_host_user@${arr_host_ip}"
    else
        ssh_command="$arr_host_user@${arr_host_ip}:${arr_host_port}"
    fi
    
    if [ "$arr_host_pwd" == "" -o $(which sshpass) == "" ]; then
        echo "connect by ssh $ssh_command"
        ssh $ssh_command 
    else
        echo "connect by [ssh $ssh_command] with password"
        sshpass -p $arr_host_pwd ssh $ssh_command
    fi
}

#=============================
#main()

if [ ! -f $HOST_XML ]; then
    CreateConf
fi
if [ "$1" == "-h" ]; then
    ShellHelp
    exit
fi
if [ "$1" == "-e" ]; then
    if [ -f $HOST_XML ]; then
        vim $HOST_XML
    else
        echo "conf xml file not found: $HOST_XML"
    fi
    exit
fi

SelectHost

