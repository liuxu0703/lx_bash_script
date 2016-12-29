#!/bin/bash

# author : liuxu
# date:  : 2016-10-21
# test remote server task

echo "test task, args: $@"
mkdir /tmp/test_remote_task
touch /tmp/test_remote_task/test_touch_file_$(date +%Y%m%d%H%M%S)
