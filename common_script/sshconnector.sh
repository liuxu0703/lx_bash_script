#!/bin/bash
# author : liuxu-0703@163.com

# v1.0  2016-05-25
#       list and connect to remote ssh server


DEBUG="false"

SCRIPT_PATH="$(cd "$(dirname ${BASH_SOURCE[0]})" && pwd)"
SCRIPT_CONF_DIR=$HOME/.lx_bash_conf
HOST_XML=$SCRIPT_CONF_DIR/ssh_host_set.xml
HOST_MANAGER_PY=$SCRIPT_PATH/ssh_host_set_manager.py
HOST_MANAGER="python $HOST_MANAGER_PY $HOST_XML"

DEBUG() {
    if [ "$DEBUG" == "true" ]; then
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

    <host>
        <name>sample_host_1</name>
        <ip>1.1.1.1</ip>
        <port></port>
        <user>root</user>
        <password>123456</password>
        <index>1</index>
        <enabled>true</enabled>
    </host>

    <host>
        <name>sample_host_2</name>
        <ip>2.2.2.2</ip>
        <port></port>
        <user>liuxu</user>
        <password>654321</password>
        <index>2</index>
        <enabled>true</enabled>
    </host>

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

function SelectHost() {
    DEBUG echo "A_HOSTS : ${A_HOSTS[*]}"
    local A_HOSTS
    local tmp_arr
    local length
    
    tmp_arr=$($HOST_MANAGER -l)
    for s in $tmp_arr; do
        length=${#A_HOSTS[*]}
        A_HOSTS[$length]=$s
    done
    
    DEBUG echo "A_HOSTS : ${A_HOSTS[*]}"
    
    echo
    echo "Host Connector Menu: "
    local i=0
    while [ $i -lt ${#A_HOSTS[*]} ]; do
        index=$(expr $i + 1)
        echo "  [$index]. ${A_HOSTS[$i]}"
        let i++
    done
    
    echo "  [S]. List All Host Detail"
    echo "  [E]. Edit ssh_host_set.xml"
    echo "  [X]. Do Nothing and Exit"
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
    
    local name=$(echo ${A_HOSTS[$n]} | awk -F "(" '{print $1}')
    local ip=$($HOST_MANAGER -i $name)
    local port=$($HOST_MANAGER -p $name)
    local user=$($HOST_MANAGER -u $name)
    local password=$($HOST_MANAGER -w $name)
    
    local ssh_command
    if [ "$port" == "" ]; then
        ssh_command="$user@$ip"
    else
        ssh_command="$user@$ip:$port"
    fi
    
    if [ "$password" == "" -o $(which sshpass) == "" ]; then
        echo "connect by ssh $user@$ip"
        ssh $user@$ip
    else
        echo "connect by [ssh $ssh_command] with password [$password]"
        sshpass -p $password ssh $user@$ip
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

