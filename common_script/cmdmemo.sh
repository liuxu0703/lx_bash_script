#!/bin/bash
# author : liuxu-0703@163.com

CMD_DIR=$(dirname $0)/docs/cmdmemo_doc
EDITOR=vim

#====================================

function ShellHelp() {
cat <<EOF
USAGE:
cmdmemo.sh <cmd>     :  show cmd memo
cmdmemo.sh -e <cmd>  :  edit cmd memo
cmdmemo.sh -l        :  show available cmd memo
cmdmemo.sh -h        :  print help
EOF
}

#process options
function ProcessOptions() {
    while getopts ":hle:" opt; do
        case "$opt" in
            "h")
                ShellHelp
                exit
                ;;
            "l")
                ls $CMD_DIR
                exit
                ;;
            "e")
                cmd=$OPTARG
                if [ "$cmd" == "" ]; then
                    ShellHelp
                elif [ -f "$CMD_DIR/$cmd" ]; then
                    $EDITOR $CMD_DIR/$cmd &
                else
                    echo "memo file does not exist for command $cmd"
                    read -p "do you want to create new memo file for $cmd ? "
                    if [[ ( "$REPLY" == "y" ) || ( "$REPLY" == "Y" ) || ( "$REPLY" == "yes" ) ]]; then
                        echo "$cmd" > $CMD_DIR/$cmd
                        $EDITOR $CMD_DIR/$cmd &
                    fi
                fi
                exit
                ;;
            "?")
                #Unknown option
                echo "* unknown option: $opt"
                echo
                ShellHelp
                exit
                ;;
            ":")
                #an option needs a value, which, however, is not presented
                echo "* option -$opt needs a value, but it is not presented"
                echo
                ShellHelp
                exit
                ;;
            *)
                #unknown error, should not occur
                echo "* unknown error while processing options and params"
                echo
                ShellHelp
                exit
                ;;
        esac
    done
    return $OPTIND
}

#====================================

ProcessOptions "$@"

if [ -f "$CMD_DIR/$1" ]; then
    echo "----------------------------------------------------"
    more $CMD_DIR/$1
    echo "----------------------------------------------------"
else
    echo "cmd $1 does not have a memo."
    ShellHelp
fi

