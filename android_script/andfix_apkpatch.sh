#!/bin/bash

# AUTHOR : liuxu
# util functions for writting sh

APKPATCH=/home/lx/android_tools/tools/apkpatch.sh
KEYSTORE=/home/lx/android_tools/signature_keys/eco_key_hz
KEY_PWD=sdyk1571
KEY_ALIAS=china

#====================================
#needed by every sh

DEBUG() {
    if $DEBUG; then
        $@
    fi
}

function ShellHelp() {
cat <<EOF
--------------------------------------------------------------------------------
USAGE:
andfix_apkpatch.sh -t old_apk -f new_apk
--------------------------------------------------------------------------------

EOF
}


#process options
function ProcessOptions() {
    while getopts ":f:t:o:" opt; do
        case "$opt" in
            "t")
                OLD_APK=$OPTARG
                ;;
            "f")
                NEW_APK=$OPTARG
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

ProcessOptions "$@"

if [ "$OLD_APK" == "" -o "$NEW_APK" == "" ]; then
    ShellHelp
else
    $APKPATCH -f $NEW_APK -t $OLD_APK -o ./ -k $KEYSTORE -p $KEY_PWD -a $KEY_ALIAS -e $KEY_PWD
fi


