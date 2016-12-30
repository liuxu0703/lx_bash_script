#!/bin/bash
# author : liuxu

BASH_RC=$HOME/.bashrc
PROFILE=/etc/profile
IMPORT_SCRIPT=$(readlink -f ./import_lx_cmd.sh)
ENV_SCRIPT=

IMPORT_MESSAGE="import my script path and commands"

function AppendToEnvScript() {
cat <<EOF >> $ENV_SCRIPT

#===========================================
# $IMPORT_MESSAGE
source $IMPORT_SCRIPT
#===========================================

EOF
}

if [ ! -f $IMPORT_SCRIPT ]; then
    echo "import script not exists: $IMPORT_SCRIPT"
else
    if [ "$UID" = "0" ]; then
        # current user is root, setup in /etc/profile
        ENV_SCRIPT=$PROFILE
    else
        # current user is not root, setup in ~/.bashrc
        ENV_SCRIPT=$BASH_RC
    fi

    import_script_name=$(basename $IMPORT_SCRIPT)
    #line=$(sed -n "/$import_script_name/p" $ENV_SCRIPT)
    line=$(sed -n "/$IMPORT_MESSAGE/p" $ENV_SCRIPT)
    if [ "$line" == "" ]; then
        # import script has not yet been put into env script
        AppendToEnvScript
        if [ $? -eq 0 ]; then
            echo "script setup done: $ENV_SCRIPT"
        else
            echo "script setup fail: $ENV_SCRIPT"
        fi
    else
        # inport script has already been put into env script, do nothing
        echo "script already setup in $ENV_SCRIPT"
    fi
fi
