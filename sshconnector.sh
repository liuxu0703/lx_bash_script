#!/bin/bash

#       AUTHOR : liuxu-0703@163.com

#v1.0   2016-05-25
#       list and connect to remote ssh server


DEBUG="false"

SCRIPT_PATH="$(cd "$(dirname ${BASH_SOURCE[0]})" && pwd)"
HOST_MANAGER_PY=$SCRIPT_PATH/ssh_host_set_manager.py
HOST_XML=$SCRIPT_PATH/ssh_host_set.xml
HOST_MANAGER="python $HOST_MANAGER_PY"

DEBUG() {
    if [ "$DEBUG" == "true" ]; then
        $@
    fi
}

function ShellHelp() {
cat <<EOF

--------------------------------------------------------------------------------
NAME:
ssh_host_connector.sh

USAGE:
ssh_host_connector.sh [-d host_name]

OPTIONS:
-d: print host connect info with given host name

DESCRIPTION:
connect to ssh remote server use hosts defined in ssh_host_set.xml
--------------------------------------------------------------------------------

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
        gedit $HOST_XML
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

if [ "$1" == "-h" ]; then
    ShellHelp
    exit
else
    SelectHost
fi
