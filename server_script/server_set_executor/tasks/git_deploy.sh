#!/bin/bash

# author : liuxu
# date:  : 2016-10-21
# deploy to remote server using git


PROJ_NAME=
PROJ_BRANCH=master
PROJ_BASE_DIR=/cloud/wwwsys
USER_NAME=techops
USER_EMAIL=$USER_NAME@czfw.cn
GIT_ADDR="121.40.91.109"
GIT_PORT="29418"
GIT_CMD=
GIT_CMD_OPT=

GIT_LAST_COMMIT_LOG=last_deploy_commit_log

B_PRINT_LAST_COMMIT_LOG=false

#====================================


function ShellHelp() {
cat <<EOF

--------------------------------------------------------------------------------
USAGE:
git_deploy.sh [-b project_base_dir] -n project_name -g pull
git_deploy.sh [-b project_base_dir] -n project_name -g reset [-o commit_id]
git_deploy.sh [-b project_base_dir] -n project_name -g clone [-B branch_name]
git_deploy.sh [-b project_base_dir] -n project_name -l

OPTIONS:
-b: 项目目录所在目录
-n: 项目名称
-g: git命令,可用命令为 pull, reset, clone.
-o: 在指定git命令为 reset 时,可以指定一个回滚的 commit_id. 默认回滚到最后一次更新的 commit id.
-B: 在指定git命令为 clone 时,可以指定初始化哪个branch.
-l: 列出指定项目的最后一次部署的 commit id.
--------------------------------------------------------------------------------

EOF
}

#process options
function ProcessOptions() {
    while getopts ":hln:g:o:b:B:" opt; do
        case "$opt" in
            "h")
                ShellHelp
                exit 0
                ;;
            "n")
                PROJ_NAME=$OPTARG
                ;;
            "g")
                GIT_CMD=$OPTARG
                ;;
            "o")
                GIT_CMD_OPT=$OPTARG
                ;;
            "b")
                PROJ_BASE_DIR=$OPTARG
                ;;
            "B")
                PROJ_BRANCH=$OPTARG
                ;;
            "l")
                B_PRINT_LAST_COMMIT_LOG=true
                ;;
            "?")
                #Unknown option
                echo "unknown option: $opt"
                ShellHelp
                exit 1
                ;;
            ":")
                #an option needs a value, which, however, is not presented
                echo "option -$opt needs a value, but it is not presented"
                ShellHelp
                exit 1
                ;;
            *)
                #unknown error, should not occur
                echo "unknown error while processing options and params"
                ShellHelp
                exit 1
                ;;
        esac
    done
    return $OPTIND
}

function git_clone() {
    cd $PROJ_BASE_DIR
    if [ $? -ne 0 ]; then
        echo "can not access $PROJ_BASE_DIR dir."
        exit 4
    fi

    git clone -b $PROJ_BRANCH "ssh://$USER_NAME@$GIT_ADDR:$GIT_PORT/$PROJ_NAME.git"
    if [ $? -ne 0 ]; then
        exit 4
    fi

    cd $PROJ_BASE_DIR/$PROJ_NAME
    if [ $? -ne 0 ]; then
        echo "can not access $PROJ_NAME dir. config project manully."
        exit 0
    fi

    git config user.name "$USER_NAME"
    git config user.email "$USER_EMAIL"
    git config remote.origin.url "ssh://$USER_NAME@$GIT_ADDR:$GIT_PORT/$PROJ_NAME.git"
    git config remote.review.pushurl "ssh://$USER_NAME@$GIT_ADDR:$GIT_PORT/$PROJ_NAME.git"
    git config remote.review.push "HEAD:refs/for/$PROJ_BRANCH"

    local gitdir=$(git rev-parse --git-dir)
    scp -p -P $GIT_PORT $USER_NAME@$GIT_ADDR:hooks/commit-msg ${gitdir}/hooks/
}

function git_pull() {
    if [ ! -d $PROJ_BASE_DIR/$PROJ_NAME ]; then
        echo "project $PROJ_NAME has not init under $PROJ_BASE_DIR yet. try init it."
        git_clone
    fi
    cd $PROJ_BASE_DIR/$PROJ_NAME
    if [ $? -ne 0 ]; then
        echo "can not access $PROJ_BASE_DIR/$PROJ_NAME dir."
        exit 2
    fi

    local last_commit_id=$(git log | head -1  | awk '{print $2}')
    local cmd_message=$(git pull)
    if [ $? -eq 0 -a ! "$cmd_message" == "Already up-to-date." ]; then
        echo $last_commit_id > $PROJ_BASE_DIR/$PROJ_NAME/$GIT_LAST_COMMIT_LOG
    fi
}

function git_reset() {
    echo "project $PROJ_BASE_DIR/$PROJ_NAME roll back!!!"
    if [ ! -d $PROJ_BASE_DIR/$PROJ_NAME ]; then
        echo "project $PROJ_NAME has not init under $PROJ_BASE_DIR yet"
        exit 3
    fi
    cd $PROJ_BASE_DIR/$PROJ_NAME
    if [ $? -ne 0 ]; then
        echo "can not access $PROJ_BASE_DIR/$PROJ_NAME dir."
        exit 3
    fi
    if [ "$GIT_CMD_OPT" == "" ]; then
        if [ -f $PROJ_BASE_DIR/$PROJ_NAME/$GIT_LAST_COMMIT_LOG ]; then
            GIT_CMD_OPT=$(head -1 $PROJ_BASE_DIR/$PROJ_NAME/$GIT_LAST_COMMIT_LOG)
            if [ $? -ne 0 ]; then
                GIT_CMD_OPT=""
            fi
        else
            echo "last commit log file does not exists: $PROJ_BASE_DIR/$PROJ_NAME/$GIT_LAST_COMMIT_LOG"
        fi
    fi
    if [ "$GIT_CMD_OPT" == "" ]; then
        echo "a commit id should be specified by -o options, or should come from last commit log file. both failed."
        exit 3;
    fi
    echo "about to reset to commit id: $GIT_CMD_OPT"
    git reset --hard $GIT_CMD_OPT
}


#====================================


ProcessOptions "$@"

if [ "$PROJ_NAME" == "" ]; then
    echo "a project name must be specified."
    exit 1
fi
if [ "$PROJ_BRANCH" == "" ]; then
    PROJ_BRANCH=master
fi
if [ ! -d $PROJ_BASE_DIR ]; then
    echo "project base dir not exist: $PROJ_BASE_DIR"
    exit 1
fi

if $B_PRINT_LAST_COMMIT_LOG; then
    if [ -f $PROJ_BASE_DIR/$PROJ_NAME/$GIT_LAST_COMMIT_LOG ]; then
        last_commit_id=$(head -1 $PROJ_BASE_DIR/$PROJ_NAME/$GIT_LAST_COMMIT_LOG)
        if [ $? -ne 0 -o "$last_commit_id" == "" ]; then
            echo "can not read from $PROJ_BASE_DIR/$PROJ_NAME/$GIT_LAST_COMMIT_LOG"
            exit 1
        else
            echo "project $PROJ_BASE_DIR/$PROJ_NAME last deploy commit id: $last_commit_id"
        fi
    else
        echo "can not read from $PROJ_BASE_DIR/$PROJ_NAME/$GIT_LAST_COMMIT_LOG , not exits"
        exit 1
    fi
    exit 0
fi

if [ "$GIT_CMD" == "" ]; then
    echo "a git cmd must be specified. available cmds: pull, reset, clone"
    exit 1
fi

case "$GIT_CMD" in
    "pull")
        git_pull
        ;;
    "reset")
        git_reset
        ;;
    "clone")
        git_clone
        ;;
    *)
        #unknown error, should not occur
        echo "cmd $GIT_CMD not supported."
        ShellHelp
        exit 1
        ;;
esac
