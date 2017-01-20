#!/bin/bash
# author : liuxu-0703@163.com
# date   : 2016-08-31
# I can't memorize "git push" command with reviewers, that's why this sh is written.


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CMD=
BRANCH=

source $SCRIPT_DIR/conf/gerrit_config
declare -a REVIEWERS

#====================================

DEBUG() {
    if [ "$DEBUG" == "true" ]; then
        $@
    fi
}

function ShellHelp() {
cat <<EOF

--------------------------------------------------------------------------------
USAGE:
gitpush.sh [-b branch] [reviewers ...]

# 将本地当前分支推送到远端 develop 分支,并邀请 liux@czfw.cn 和 fancc@czfw.cn 进行审核
gitpush.sh -b develop liux@czfw.cn fancc@czfw.cn

# 将本地当前分支推送到远端同名分支,并邀请 liux@czfw.cn 和 fancc@czfw.cn 进行审核
gitpush.sh liux@czfw.cn fancc@czfw.cn

# 将本地当前分支推送到远端同名分支,并选择审核者
gitpush.sh
--------------------------------------------------------------------------------

EOF
}

#see if $1 is interger or not
#if $2, $3 is presented, see if $1 is inside [$2, $3]
#yield true or false
#if present, $2 and $3 should be interger
function IsInteger() {
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

function SelectReviewer() {
    local idx=1
    
    echo
    echo "Already Picked Reviewers: ${REVIEWERS[@]}"
    echo
    echo "Available Commconly Used Reviewers:"
    
    for reviewer in ${DEVELOPERS[@]}; do
        local reviewer_email=$(GetReviewerEmail $reviewer)
        echo "  [$idx]. $reviewer_email"
        let idx++
    done
    
    echo "  [X]. Done Picking"
    read -p "Pick a Reviewer ['Enter' to finish pick]: "
    
    if [ $(IsInteger $REPLY 1 ${#DEVELOPERS[*]}) == "true" ]; then
        local n=$(expr $REPLY - 1)
        local reviewer=${DEVELOPERS[$n]}
        local length=${#REVIEWERS[@]}
        REVIEWERS[$length]=$(GetReviewerEmail $reviewer)
        SelectReviewer
    elif [[ ( "$REPLY" == "" ) || ( "$REPLY" == "x" ) || ( "$REPLY" == "X" ) ]]; then
        return
    else
        echo
        echo "Invalidate Selection !!!"
        echo
        exit
    fi
}

function ProcessOptions() {
    while getopts ":hb:" opt; do
        DEBUG echo "opt: $opt"
        case "$opt" in
            "h")
                ShellHelp
                exit
                ;;
            "b")
                BRANCH=$OPTARG
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

function ProcessArgs() {
    DEBUG echo "args: $@"
    if [ $# -eq 0 ]; then
        SelectReviewer
    fi

    for arg in $@; do
        length=${#REVIEWERS[@]}
        REVIEWERS[$length]=$arg
    done
}

#====================================

ProcessOptions "$@"
arg_start=$?
ProcessArgs "${@:$arg_start}"

if [ "$BRANCH" == "" ]; then
    BRANCH=$(git branch | awk '{print $2}')
    BRANCH=$(echo $BRANCH)
fi
if [ "$BRANCH" == "" ]; then
    echo
    echo "* A branch must be specified."
    ShellHelp
    exit
fi

CMD="git push --receive-pack='git receive-pack "
for reviewer in ${REVIEWERS[@]}; do
    CMD="$CMD --reviewer $reviewer"
done
CMD="$CMD' review HEAD:refs/for/$BRANCH"

echo "git command generated: "
echo $CMD
eval "$CMD"  #use eval to prevent ' from being ignored

#read -p "Is it right? ['Enter' to confirm]: "
#echo
#if [ "$REPLY" == "" ]; then
#    eval "$CMD"  #use eval to prevent ' from being ignored
#else
#    exit
#fi
