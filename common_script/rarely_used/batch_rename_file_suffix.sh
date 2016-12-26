#!/bin/bash
#       AUTHOR : liuxu-0703@163.com

#v1.0   2016-10-20
#       batch rename file suffix

TARGET_DIR=$(pwd)
OLD_SUFFIX=
NEW_SUFFIX=


#====================================

function ShellHelp() {
cat <<EOF

--------------------------------------------------------------------------------
NAME:
batch_rename_suffix.sh

USAGE:
batch_rename_suffix.sh [-d target_dir] old_suffix new_suffix

OPTIONS:
-d: target dir, will rename files under this dir. default is current dir.

DESCRIPTION:
rename suffix of files under target dir from old_suffix to new_suffix.
files without such a suffix as old_suffix will not be touched.
--------------------------------------------------------------------------------

EOF
}

#process options
function ProcessOptions() {
    while getopts ":hd:" opt; do
        case "$opt" in
            "h")
                ShellHelp
                exit 0
                ;;
            "d")
                TARGET_DIR=$(readlink -f $OPTARG)
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
    OLD_SUFFIX=$1
    NEW_SUFFIX=$2
}

#====================================

ProcessOptions "$@"
arg_start=$?
ProcessArgs "${@:$arg_start}"

if [ ! -d $TARGET_DIR ]; then
    echo "* specified dir is not a directory: $TARGET_DIR"
    ShellHelp
    exit 2;
fi

if [ "$OLD_SUFFIX" == "" -o "$NEW_SUFFIX" == "" ]; then
    echo "* specified suffix empty, old: $OLD_SUFFIX , new: $NEW_SUFFIX"
    ShellHelp
    exit 1;
fi

cd $TARGET_DIR
file_arr=$(ls *$OLD_SUFFIX 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "* no files found under $TARGET_DIR with suffix $OLD_SUFFIX"
    exit 4
fi

file_count=${#file_arr[*]}
if [ $file_count -eq 0 ]; then
    echo "* no files found under $TARGET_DIR with suffix $OLD_SUFFIX"
    exit 4
fi

for f in ${file_arr[*]}; do
    rename=$(basename $f | awk -F $OLD_SUFFIX '{print $1}')$NEW_SUFFIX
    mv $TARGET_DIR/$f $TARGET_DIR/$rename
    ret=$?
    if [ $ret == 0 ]; then
        echo "rename $TARGET_DIR/$f to $TARGET_DIR/$rename"
    else
        echo "rename $TARGET_DIR/$f to $TARGET_DIR/$rename fail ($ret)"
    fi
done

