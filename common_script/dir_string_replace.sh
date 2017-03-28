#!/bin/bash

# author : liuxu
# date   : 2017-02-28
# replace strings under dir

DEBUG=false

ORIGIN_STR=
TARGET_STR=
TARGET_DIR=$(pwd)

#====================================

DEBUG() {
    if $DEBUG; then
        $@
    fi
}

function Help() {
cat <<EOF

--------------------------------------------------------------------------------
USAGE:
dir_string_replace.sh [-p path] origin_string target_string

OPTIONS:
-p: path. default is current dir.

DESCRIPTION:
replace origin_string with target_string on all files under given path.
--------------------------------------------------------------------------------

EOF
}

#process options
function ProcessOptions() {
    while getopts ":hp:" opt; do
        DEBUG echo "opt: $opt"
        case "$opt" in
            "h")
                Help
                exit 0
                ;;
            "p")
                TARGET_DIR=$OPTARG
                ;;
            "?")
                #Unknown option
                echo "* unknown option: $opt"
                Help
                exit 1
                ;;
            ":")
                #an option needs a value, which, however, is not presented
                echo "* option -$opt needs a value, but it is not presented"
                Help
                exit 1
                ;;
            *)
                #unknown error, should not occur
                echo "* unknown error while processing options and params"
                Help
                exit 1
                ;;
        esac
    done
    return $OPTIND
}

#process args
function ProcessArgs() {
    DEBUG echo "args: $@"
    if [ $# -eq 0 ]; then
        Help
    fi

    local i=0
    for arg in $@; do
        [ $i -eq 0 ] && ORIGIN_STR=$arg
        [ $i -eq 1 ] && TARGET_STR=$arg
        let i++
    done
}

#====================================


ProcessOptions "$@"
arg_start=$?
ProcessArgs "${@:$arg_start}"

DEBUG echo "origin string: $ORIGIN_STR"
DEBUG echo "target string: $TARGET_STR"
DEBUG echo "target path: $TARGET_DIR"

if [ ! -d "$TARGET_DIR" ]; then
    echo "target dir not exits: $TARGET_DIR"
    exit 2
fi

if [ "$ORIGIN_STR" == "" -o "TARGET_STR" == "" ]; then
    echo "need two strings: origin string and target string"
    exit 3
fi

echo
grep -rs --color "$ORIGIN_STR"

if [ $? -ne 0 ]; then
    echo "find no \"$ORIGIN_STR\" under \"$TARGET_DIR\""
    echo
    exit 4
fi

echo
read -p "replace with \"$TARGET_STR\" ? (Y/n): "
if [[ ( "$REPLY" == "n" ) || ( "$REPLY" == "N" ) ]]; then
    exit 0
else
    grep -rls "$ORIGIN_STR" | xargs -i sed -i "s/$ORIGIN_STR/$TARGET_STR/" "{}"
fi

