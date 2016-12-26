#!/bin/bash
# author : liuxu-0703@163.com
# date   : 2016-01-01
#
# execute this script use "source" or "." in ~/.bashrc or /etc/profile
# to import bellow command into environment.

# back up the given path.
function backup() {
    local BACKUP_DIR=$HOME/backup_dir
    local BACKUP_SUFFIX="bkp"
    local BACKUP_INFO_FILE="~backup_infos"
    
    local day=$(date +%F)
    local time=$(date +%H%M%S)
    
    if [ $# -eq 0 -o "$1" == "-h" ]; then
        echo "backup usage:"
        echo "backup file   : backup the given file or dir"
        echo "backup -l     : list backup files for today"
        return 0
    fi
    
    if [ "$1" == "-l" ]; then
        if [ -f $BACKUP_DIR/$day/$BACKUP_INFO_FILE ]; then
            cat $BACKUP_DIR/$day/$BACKUP_INFO_FILE
        else
            echo "* no backup files for today yet"
        fi
        return 0
    fi
    
    if [ ! -e "$1" ]; then
        echo "* the given path does not exists."
        return 1
    fi
    
    if [ ! -d $BACKUP_DIR ]; then
        mkdir $BACKUP_DIR
    fi
    if [ ! -d $BACKUP_DIR/$day ]; then
        mkdir $BACKUP_DIR/$day
    fi
    
    local param=$1
    local full_path=$(readlink -f $param)
    local file_name=$(basename $full_path)
    local backup_path=$BACKUP_DIR/$day/$file_name"."$time"."$BACKUP_SUFFIX
    cp -r $full_path $backup_path
    
    if [ $? -eq 0 ]; then
        echo "$full_path  -->  $backup_path" >> $BACKUP_DIR/$day/$BACKUP_INFO_FILE
        echo "backup success."
        echo "origin: $full_path"
        echo "backup: $backup_path"
    else
        echo "backup failed."
    fi
}

# change directory to the given dir, or parent dir if what is given is a file.
function cdd() {
    if [ $# -eq 0 ]; then
        echo "cdd usage:"
        echo "cdd file   : go to parent dir of the file, or the file itself if it is an dir"
        return
    fi
    
    if [ ! -e "$1" ]; then
        echo "* the given path does not exists."
        return 1
    elif [ -d "$1" ]; then
        cd "$1"
        return 0
    fi
    
    local param=$1
    local full_path=$(readlink -f $param)
    local parent_dir=$(dirname $param)
    cd $parent_dir
}

# go to project root dir. for git projects only.
function gitroot() {
    local git_dir=$(git rev-parse --git-dir)
    if [ $? -ne 0 ]; then
        echo "* not in directory or sub-directory of a git project. pls check."
        return 1
    fi
    local proj_dir=$(readlink -f $(dirname $git_dir))
    cd $proj_dir
}


