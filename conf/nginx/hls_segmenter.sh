#!/bin/bash
basename=/mnt/warehouse/grouch_core/live/grouch_ramdisk
mkdir -p $basename/$1
(
cd $basename/$1
/usr/local/bin/ffmpeg -i rtmp://172.16.1.14/publish/$1 \
    -acodec copy \
    -f segment \
    -flags -global_header \
    -map 0 \
    -vbsf h264_mp4toannexb \
    -segment_wrap 10 \
    -segment_format mpegts \
    -segment_list_flags +live \
    -segment_list_type m3u8 \
    -segment_list live.m3u8 \
    -vcodec libx264 \
    -b:v 2M \
    -segment_list $1.2M.m3u8 \
    $1-%03d.2M.ts \
    \
    -b:v 1M \
    -segment_list $1.1M.m3u8 \
    $1-%03d.1M.ts \
    \
    -b:v 500k \
    -segment_list $1.500k.m3u8 \
    $1-%03d.500k.ts \
    \
    -b:v 250k \
    -segment_list $1.250k.m3u8 \
    $1-%03d.250k.ts
)

/opt/tizr/multimedia/bin/ffmpeg -i rtmp://localhost/${app}/${name} -threads 2 \
-c:v libx264 -profile:v baseline -g 10 -b:v $var_bw_low -vf scale=$var_w_low:-1 -c:a aac -ac 1 -strict -2 -b:a 64k -f flv "rtmp://localhost app=hls playpath=$var_unid/${name}_low?unid=$var_unid" \
-c:v libx264 -profile:v baseline -g 10 -b:v $var_bw_mid -vf scale=$var_w_mid:-1 -c:a aac -ac 1 -strict -2 -b:a 128k -f flv "rtmp://localhost app=hls playpath=$var_unid/${name}_mid?unid=$var_unid" \
-c:v libx264 -profile:v baseline -g 10 -b:v $var_bw_hi -vf scale=$var_w_hi:-1 -c:a aac -ac 1 -strict -2 -b:a 128k -f flv "rtmp://localhost app=hls playpath=$var_unid/${name}_hi?unid=$var_unid" \
2>>/var/log/ffmpegLog/hls-${name}.log;


ffmpeg 
                " -i " . $filepath .
                " -c copy -map 0 -vbsf h264_mp4toannexb -f segment -segment_time 10 -segment_list_flags cache -f ssegment -segment_list " .
                $m3u8_filepath .
                " -segment_format mpegts " .
                " -segment_list_entry_prefix " . fileTools::file_filename($filename) . "/ " .
                fileTools::file_filename($filename) . "/s%d.ts" .
                
ffmpeg -i a4_low.mp4 -i a4_mid.mp4 -i a4_hi.mp4 -c copy -map 0 -vbsf h264_mp4toannexb -f segment -segment_time 5 -segment_list_flags cache -f ssegment -segment_list a4.m3u8 -segment_format mpegts -segment_list_entry_prefix ./ s%d.ts