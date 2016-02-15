#!/bin/bash
path=$1
filename=$2
dirname=$3
basename=$4
query_string=$5
# echo path=$path, filename=$filename dirname=$dirname, basename=$basename, query_string=$query_string >> /tmp/debug_record_hls


# Local directory to be synchronised with Live S3 bucket
hls_path_live="/mnt/hlsLive"

# Local directory to be synchronised with VOD S3 bucket
hls_path_vod="/mnt/hlsVod"

# Local VOD storage
local_hls_path_vod="/var/www/hlsVod"

#HLS fragment size
hls_fragment=5


# Explode query string (variable and values)
saveIFS=$IFS
IFS='=&'
parm=($query_string)
IFS=$saveIFS
for ((i=0; i<${#parm[@]}; i+=2))
do
	declare var_${parm[i]}=${parm[i+1]}
done


# Check if unid directory exists, else, create it
if [ ! -d "$hls_path_vod/$var_unid" ];then
	mkdir $hls_path_vod/$var_unid
fi

# Remove <unid> prefix
prefix="${var_unid}%2F"
clean_basename=${basename/$prefix/}
original_stream_name=${clean_basename/_level?/}


# Create subdir structure
if [ ! -d "$hls_path_vod/$var_unid/${clean_basename}" ];then
	mkdir $hls_path_vod/$var_unid/${clean_basename}
fi

if [ ! -d "$local_hls_path_vod/$var_unid/${clean_basename}" ];then
	mkdir $local_hls_path_vod/${clean_basename}
fi



# Segment file to HLS
segment_cmd="/opt/tizr/multimedia/bin/ffmpeg -i ${path} -c copy -map 0 -vbsf h264_mp4toannexb -f segment -segment_time $hls_fragment -segment_list_flags cache -f ssegment -segment_list ${dirname}/${clean_basename}/index.m3u8 -segment_format mpegts ${dirname}/${clean_basename}/%d.ts"
# echo segment_cmd=$segment_cmd >> /tmp/debug_record_hls

eval "$segment_cmd"

# Move HLS files to s3 bucket
mv ${dirname}/${clean_basename}* $hls_path_vod/$var_unid/
rm -rf $path

# Delete local flv and HLS live files
rm -rf $hls_path_live/$var_unid/${clean_basename}*

# delete meta m3u8
meta_m3u8=${clean_basename/_level1/}
rm -rf $hls_path_live/$var_unid/$meta_m3u8.m3u8

# Stop syncrhonise live content with S3 bucket and syncrhonise VOD files
sleep 10;
sudo start-stop-daemon --stop --remove-pidfile --pidfile /var/run/sync_bucket_live_${original_stream_name}.pid
#sudo rm /var/run/sync_bucket_live_${original_stream_name}.pid
sudo /usr/local/bin/s3cmd sync --delete-removed /mnt/hlsLive/ s3://encoding-0.hls.live
sudo /usr/local/bin/s3cmd sync /mnt/hlsVod/ s3://encoding-0.hls.vod

# Delete local VOD files
rm -rf $hls_path_vod/$var_unid/${original_stream_name}*

# API call on completed
curl "http://localhost/on_vod_ready?unid=$var_unid&name=$original_stream_name";
