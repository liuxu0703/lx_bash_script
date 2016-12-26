#!/bin/bash
# author : liuxu-0703@163.com
# date   : 2016-08-31
# clone and config project

source conf/gerrit_config

PROJECT_NAME=
PROJECT_BRANCH=master
USER_NAME=
USER_EMAIL=

#===================================================

function ShellHelp() {
cat <<EOF

--------------------------------------------------------------------------------
USAGE:
gitclone.sh project_name

DESCRIPTION:
clone and config project
--------------------------------------------------------------------------------

EOF
}

#process options
function ProcessOptions() {
    while getopts ":hb:" opt; do
        case "$opt" in
            "h")
                ShellHelp
                exit 0
                ;;
            "b")
                PROJECT_BRANCH=$OPTARG
                ;;
            "?")
                #Unknown option
                echo "* unknown option: $opt"
                ShellHelp
                exit
                ;;
            ":")
                #an option needs a value, which, however, is not presented
                echo "* option -$opt needs a value, but it is not presented"
                ShellHelp
                exit
                ;;
            *)
                #unknown error, should not occur
                echo "* unknown error while processing options and params"
                ShellHelp
                exit
                ;;
        esac
    done
    return $OPTIND
}

#process args
function ProcessArgs() {
    PROJECT_NAME=$1
}

#===================================================

ProcessOptions "$@"
arg_start=$?
ProcessArgs "${@:$arg_start}"

if [ "$PROJECT_NAME" == "" ]; then
    echo "need a git project name"
    ShellHelp
    exit 1
fi
if [ "$PROJECT_BRANCH" == "" ]; then
    PROJECT_BRANCH=master
fi
if [ "$USER_NAME" == "" ]; then
    USER_NAME=$USER
fi
USER_EMAIL=$(GetReviewerEmail $USER_NAME)

cmd="git clone -b $PROJECT_BRANCH ssh://$USER_NAME@$GIT_ADDR:$GIT_PORT/$PROJECT_NAME.git"
echo $cmd
$cmd
if [ $? -ne 0 ]; then
    exit 1
fi

cd $PROJECT_NAME
if [ $? -ne 0 ]; then
    echo "can not access $PROJECT_NAME dir. pls config project manully."
    exit 1
fi

git config user.name "$USER_NAME"
git config user.email "$USER_EMAIL"

git config remote.origin.url "ssh://$USER_NAME@$GIT_ADDR:$GIT_PORT/$PROJECT_NAME.git"
git config remote.review.pushurl "ssh://$USER_NAME@$GIT_ADDR:$GIT_PORT/$PROJECT_NAME.git"
git config remote.review.push "HEAD:refs/for/$PROJECT_BRANCH"

gitdir=$(git rev-parse --git-dir)
scp -p -P $GIT_PORT $USER_NAME@$GIT_ADDR:hooks/commit-msg ${gitdir}/hooks/

echo
echo "project configration:"
cat .git/config

git config --global alias.co checkout
git config --global alias.st status
git config --global alias.ci commit
git config --global alias.br branch
