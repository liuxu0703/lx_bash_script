#!/bin/bash

# author : liuxu
# date   : 2016-10-24

GIT_DIR=/cloud/wwwsys
GIT_PROJ_NAME=$(git remote -v | head -n1 | awk '{print $2}' | sed 's/.*\///' | sed 's/\.git//')
SERVER_SET_CONFIG="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"/server_set.xml
EXECUTOR_SH=/usr/git_income/kaiba_server_script/dev_tools/server_set_executor/server_set_executor.sh
DEPLOY_SH=/usr/git_income/kaiba_server_script/dev_tools/server_set_executor/tasks/git_deploy.sh


#===============================================


function ShellHelp() {
cat <<EOF
--------------------------------------------------------------------------------
USAGE:
部署当前项目到集群服务器.
deploy.sh

将集群服务器上的当前项目回滚到最后一次执行部署时的状态("r" for "roll back").
deploy.sh -r

列出集群服务器上的当前项目能回滚到的最后一次执行部署时的 commit id.
deploy.sh -l
--------------------------------------------------------------------------------
EOF
}

function CreateServerSetXml() {
cat > $SERVER_SET_CONFIG <<EOF
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
            <server ip="121.41.53.240" user="techops" />
        </servers>
    </server_set>

</ServerSetManager>
EOF

    if [ $? -ne 0 ]; then
        LogE "create server set config fail: $SERVER_SET_CONFIG"
        return 1
    fi
    return 0
}


#===============================================


if [ ! -e $SERVER_SET_CONFIG ]; then
    CreateServerSetXml
fi

if [ "$1" == "-h" ]; then
    ShellHelp
elif [ "$1" == "-l" ]; then
    cmd="$EXECUTOR_SH -s -c $SERVER_SET_CONFIG $DEPLOY_SH -b $GIT_DIR -n $GIT_PROJ_NAME -l"
    echo "cmd: $cmd"
    eval "$cmd"
else
    git_cmd=
    if [ "$1" == "-r" ]; then
        git_cmd=reset
    else
        git_cmd=pull
    fi
    cmd="$EXECUTOR_SH -s -c $SERVER_SET_CONFIG $DEPLOY_SH -b $GIT_DIR -n $GIT_PROJ_NAME -g $git_cmd"
    echo "cmd: $cmd"
    eval "$cmd"
fi

