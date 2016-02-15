#!/bin/bash
unid=$1
mp4_low=$2
mp4_mid=$3
mp4_hi=$4
rate_low=$5
rate_mid=$6
rate_hi=$7
query_string=$8

# Explode query string (variable and values)
saveIFS=$IFS
IFS='=&'
parm=($query_string)
IFS=$saveIFS
for ((i=0; i<${#parm[@]}; i+=2))
do
	declare var_${parm[i]}=${parm[i+1]}
	# echo ${parm[i]} - ${parm[i+1]}  >> /tmp/query_string
done

# Remove <unid> prefix
prefix=${unid}%2F
clean_mp4_low=${mp4_low/$prefix/}
clean_mp4_mid=${mp4_mid/$prefix/}
clean_mp4_hi=${mp4_hi/$prefix/}

# Keep basename
mp4_low_filebase="`basename "${clean_mp4_low%.*}"`"
mp4_mid_filebase="`basename "${clean_mp4_mid%.*}"`"
mp4_hi_filebase="`basename "${clean_mp4_hi%.*}"`"
mp4_filebase=${mp4_low_filebase/_low/}

# <unid>%2Fa4_hi.mp4
echo ${mp4_filebase} - ${mp4_low_filebase} - ${mp4_mid_filebase} - ${mp4_hi_filebase}
	
# Segment mp4 files
/opt/tizr/multimedia/bin/ffmpeg -i ${mp4_low} -c copy -map 0 -vbsf h264_mp4toannexb -f segment -segment_time 5 -segment_list_flags cache -f ssegment -segment_list ${mp4_low_filebase}.m3u8 -segment_format mpegts ${mp4_low_filebase}-%d.ts
/opt/tizr/multimedia/bin/ffmpeg -i ${mp4_mid} -c copy -map 0 -vbsf h264_mp4toannexb -f segment -segment_time 5 -segment_list_flags cache -f ssegment -segment_list ${mp4_mid_filebase}.m3u8 -segment_format mpegts ${mp4_mid_filebase}-%d.ts
/opt/tizr/multimedia/bin/ffmpeg -i ${mp4_hi} -c copy -map 0 -vbsf h264_mp4toannexb -f segment -segment_time 5 -segment_list_flags cache -f ssegment -segment_list ${mp4_hi_filebase}.m3u8 -segment_format mpegts ${mp4_hi_filebase}-%d.ts

# create variant m3u8
echo "#EXTM3U" > ${mp4_filebase}.m3u8
echo "#EXT-X-VERSION:3" >> ${mp4_filebase}.m3u8
echo "#EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=${rate_low}" >> ${mp4_filebase}.m3u8
echo "${mp4_low_filebase}.m3u8" >> ${mp4_filebase}.m3u8
echo "#EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=${rate_mid}" >> ${mp4_filebase}.m3u8
echo "${mp4_mid_filebase}.m3u8" >> ${mp4_filebase}.m3u8
echo "#EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=${rate_hi}" >> ${mp4_filebase}.m3u8
echo "${mp4_hi_filebase}.m3u8"  >> ${mp4_filebase}.m3u8

