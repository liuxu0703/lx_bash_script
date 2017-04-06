#!/bin/bash
# record android screen as gif file. use ctrl-c to terminate screen recording.
# author : liuxu-0703@163.com

#========================================================
# define param group here

QUALITY_1=("360x640"  1000000  4  25)
QUALITY_2=("360x640"  1000000  5  20)
QUALITY_3=("360x640"  1000000  10  10)
QUALITY_4=("720x1280"  1000000  4  25)
QUALITY_5=("720x1280"  1000000  5  20)

#========================================================

QUALITY=(${QUALITY_2[@]})

RESOLUTION=${QUALITY[0]}
BIT_RATE=${QUALITY[1]}
GIF_FPS=${QUALITY[2]}
GIF_DELAY=${QUALITY[3]}

# GIF_FPS and GIF_DELAY must meet the following condition:
# GIF_FPS * GIF_DELAY = 100

OUTPUT_FILE_NAME=android_screen_record.$(date +%m%d%H%M%S).gif
OUTPUT_FILE_DIR=$(pwd)
OUTPUT_VIDEO_NAME=screenrecord_$(date +%m%d%H%M%S).mp4
OUTPUT_VIDEO_DEVICE_DIR=/sdcard
TMP_DIR=/tmp/android_screen_to_gif_$(date +%m%d%H%M%S)

RECORDING=true

# you may use adb by absolute file path. if so, specify it here
ADB="adb"

#========================================================

# catch ctrl-c signal
CTRL_C() {
    if $RECORDING; then
        echo "stop recording. start convert..."
        RECORDING=false
    else
        # ctrl-c hit but not for stop recording, just exit.
        exit $?
    fi

    # adb screenrecord may still deal with mp4 file creating,
    # just wait for it a little while.
    sleep 2s
    adb pull $OUTPUT_VIDEO_DEVICE_DIR/$OUTPUT_VIDEO_NAME $TMP_DIR
    if [ -f $TMP_DIR/$OUTPUT_VIDEO_NAME ]; then
        echo "converting file: $TMP_DIR/$OUTPUT_VIDEO_NAME"
        MP4ToGIF $TMP_DIR/$OUTPUT_VIDEO_NAME
    else
        echo "* create screen record mp4 fail"
        exit 2
    fi
}
trap CTRL_C SIGINT

# catch script exit event
CLEAR_WORK() {
    if [ -e $TMP_DIR ]; then
        # since the tmp files have been put into /tmp/ dir, they will get
        # removed on system reboot. thus we are in no hurry to remove them now.
        # un-commit this line if you want to remove tmp files immediately after script run
        #rm $TMP_DIR
        echo
    fi
}
trap "CLEAR_WORK" EXIT

#========================================================

function Help() {
cat <<"EOF"

--------------------------------------------------------------------------------
USAGE:
android_screen2gif.sh [-r resoltion] [-b bit-rate] [-f video_fps] [-d gif_delay] [-o output_dir]

OPTIONS:
-r:  set screen record video resolution. eg: 720x1280. default 360x640
-b:  set screen record video bit rate. default is 1000000 (1M)
-f:  set gif frame per second. default is 5.
-d:  set gif delay between frames. default is 20.
-o:  set output directory. default is current directory

DESCRIPTION:
record android screen as gif file. use ctrl-c to terminate screen recording.
--------------------------------------------------------------------------------

EOF
}

function MP4ToGIF() {
    echo "*** extract frames ***"
    mkdir $TMP_DIR/frames
    ffmpeg -i $1 -r $GIF_FPS "$TMP_DIR/frames/frame-%03d.jpg"
    echo "*** convert frames to gif ***"
    convert -delay $GIF_DELAY -loop 0 "$TMP_DIR/frames/*.jpg" $OUTPUT_FILE_DIR/$OUTPUT_FILE_NAME
    echo "result gif file:"
    echo $OUTPUT_FILE_DIR/$OUTPUT_FILE_NAME
}

#process options
function ProcessOptions() {
    while getopts ":r:b:f:d:o:h" opt; do
        case "$opt" in
            "h")
                Help
                exit 0
                ;;
            "r")
                RESOLUTION=$OPTARG
                ;;
            "b")
                BIT_RATE=$OPTARG
                ;;
            "f")
                GIF_FPS=$OPTARG
                ;;
            "d")
                GIF_DELAY=$OPTARG
                ;;
            "o")
                OUTPUT_FILE_DIR=$OPTARG
                ;;
            "?")
                #Unknown option
                echo "* unknown option: $opt"
                Help
                exit
                ;;
            ":")
                #an option needs a value, which, however, is not presented
                echo "* option -$opt needs a value, but it is not presented"
                Help
                exit
                ;;
            *)
                #unknown error, should not occur
                echo "* unknown error while processing options and params"
                Help
                exit
                ;;
        esac
    done
    return $OPTIND
}

#========================================================

ProcessOptions "$@"

if [ ! -d "$OUTPUT_FILE_DIR" ]; then
    echo "* output dir not exists: $OUTPUT_FILE_DIR"
    exit 1
fi
if [ ! -e $TMP_DIR ]; then
    mkdir $TMP_DIR
fi
if [ ! -e $TMP_DIR ]; then
    echo "* tmp dir not exists: $TMP_DIR"
    exit 1
fi

echo "params: $RESOLUTION, $BIT_RATE, $GIF_FPS, $GIF_DELAY"
adb shell screenrecord --verbose --size $RESOLUTION --bit-rate $BIT_RATE $OUTPUT_VIDEO_DEVICE_DIR/$OUTPUT_VIDEO_NAME
