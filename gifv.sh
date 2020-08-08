#!/bin/bash

origin_file_name="${1%.*}"

origin_codec=$(ffprobe -v error -show_streams -select_streams v "$1" | perl -nle'print $& while m{(?<=^codec_name\=).*$}g')
if [ $origin_codec = "h264" ]
then
    ffmpeg \
        -i "$1" \
        -c:v copy \
        -an \
        "${origin_file_name}-an.mp4"
    origin_size=$(wc -c "${origin_file_name}-an.mp4" | perl -nle'print $& while m{(?<=^\s)\d*}g')
    if (( $origin_size < 10000000 ))
    then
        mv "${origin_file_name}-an.mp4" "${origin_file_name}-gifv.mp4"
        exit 0
    else
        rm "${origin_file_name}-an.mp4"
    fi
else
    ffmpeg \
        -i "$1" \
        -c:v libx264 \
        -an \
        "${origin_file_name}-an.mp4"
    origin_size=$(wc -c "${origin_file_name}-an.mp4" | perl -nle'print $& while m{(?<=^\s)\d*}g')
    if (( $origin_size < 10000000 ))
    then
        mv "${origin_file_name}-an.mp4" "${origin_file_name}-gifv.mp4"
        exit 0
    else
        rm "${origin_file_name}-an.mp4"
    fi
fi

origin_duration=$(ffprobe -v error -show_streams -select_streams v "$1" | perl -nle'print $& while m{(?<=^duration\=)\d*\.\d*}g')
target_video_bitrate_kbit_s=$(\
    awk \
    -v duration="$origin_duration" \
    'BEGIN { print  ( ( 10 * 8192.0 ) / ( 1.048576 * duration ) ) }')

ffmpeg \
    -y \
    -i "$1" \
    -c:v libx264 \
    -b:v "$target_video_bitrate_kbit_s"k \
    -pass 1 \
    -an \
    -f mp4 \
    /dev/null \
&& \
ffmpeg \
    -i "$1" \
    -c:v libx264 \
    -b:v "$target_video_bitrate_kbit_s"k \
    -pass 2 \
    -an \
    "${origin_file_name}-gifv.mp4"
