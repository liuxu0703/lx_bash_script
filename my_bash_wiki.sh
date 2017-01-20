#!/bin/bash

# author : liuxu
# date   : 2016-10-24
# util functions for writting sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP_FILE=/tmp/namestring_$(date +%m%d%H%M%S)

#====================================
#needed by every sh

DEBUG() {
    if $DEBUG; then
        $@
    fi
}

ERRORTRAP() {
    local shell_name=`basename $0`
    echo "==================="
    echo "MY SCRIPT ERROR: "
    echo "NAME: $shell_name"
    echo "ERRNO: $?"
    echo "==================="
}
trap "ERRORTRAP" ERR

CLEAR_WORK() {
    if [ -e $TMP_DIR ]; then
        rm $TMP_DIR
    fi
}
trap "CLEAR_WORK" EXIT

function Help() {
cat <<EOF

--------------------------------------------------------------------------------
USAGE:

OPTIONS:

DESCRIPTION:
--------------------------------------------------------------------------------

EOF
}

#====================================
#util functions

# see if $1 is interger or not
# if $2, $3 is presented, see if $1 is inside [$2, $3] (both $2 and $2 are included)
# $2 and $3 should be interger
# yield true or false
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

#pick an appropriate adb
function ReadyADB() {
    [ "$UID" = "0" ] && SUDO= || SUDO=sudo
    if [ -f $PROJECT_PATH/out/host/linux-x86/bin/adb ]; then
        ADB="$SUDO $PROJECT_PATH/out/host/linux-x86/bin/adb"
    else
        ADB="$SUDO /usr/local/bin/adb"
    fi
    DEBUG echo "ADB: $ADB"
}

#====================================
# process args and opts

#process options
function ProcessOptions() {
    while getopts ":txdul:" opt; do
        DEBUG echo "opt: $opt"
        case "$opt" in
            "t")
                B_TOUCH_ENABLED="true"
                ;;
            "x")
                B_PUSH_TO_PHONE="false"
                ;;
            "u")
                B_UPDATE_API="true"
                ;;
            "d")
                DEBUG="true"
                ;;
            "l")
                optarg=$OPTARG
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
    DEBUG echo "args: $@"
    if [ $# -eq 0 ]; then
        echo "no args present, print help"
    fi

    for arg in $@; do
        echo $arg
    done
}

ProcessOptions "$@"
arg_start=$?
ProcessArgs "${@:$arg_start}"

#====================================
# loop example

# 'for' loop example 1
for s in Shire RiverRun Moria Rohan Gondor MinasMorgul Mordor; do
    echo "a tour to Middle Earth: $s"
done

# 'for' loop example 2
for ((i=1; i<=9; ++i)); do
    echo "how many free cities are there across the narrow sea? $i"
done

# 'for' loop example 3
ARRAY=(WinterFall Eyrie RiverRun CasterlyRock StormsEnd HighGarden SunSpear)
for castle in ${ARRAY[*]}; do
    echo "high sits of Seven Kingdom: $castle"
done

# 'for' loop example 4
for i in {1..7}; do
   echo "Voldemort will return in book $i ."
done

# 'for' loop example 4
# last param is step. bellow segment will print 5 lines
for i in {1..10..2}; do
   echo "the bear and the maiden fair. $i"
done

#====================================
# array example

# evaluation example1
declare -a Starks
Starks[0]=Rob
Starks[1]=Jon
Starks[2]=Sansa
Starks[3]=Arya
Starks[4]=Brandon
Starks[5]=Rickon

Lannisters=([0]=Jaime [1]=Ceise [2]=Tyrion)
Baratheons=(Robert Stannis Renly)

# get
echo "oldest of the Starks: ${Starks[0]}"

# print all values in an array
echo "Eddard Stark's: ${Starks[*]}"
echo "Eddard Stark's: ${Starks[@]}"

# length of an array
echo "Tywin Lannister has ${#Lannisters[@]} children"

#====================================
# misc

# redirect std out and std err to a same file
find $HOME -name .bashrc > /tmp/tmp_find_log 2>&1
find $HOME -name .bashrc &> /tmp/tmp_find_log

# drop all output
ls /home 1>$- 2>$-






