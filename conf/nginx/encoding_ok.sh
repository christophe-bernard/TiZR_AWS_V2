#!/bin/bash
app=$1
name=$2
query_string=$3

# Expected query string variables :
# - unid
# - bw : bandwidth
# - w : width
# - h : height

# Quality constants
quality_pixel_factor=331776
quality_bandwidth_factor=600 # Raise to increase quality

declare -A encoding_profile
num_rows=5 # 5 encoding profile
num_columns=4 # Width / Height / Video datarate / Audio datarate

# Profile 1
encoding_profile[1,1]=256
encoding_profile[1,2]=144
encoding_profile[1,3]=135
encoding_profile[1,4]=32

# Profile 2
encoding_profile[2,1]=512
encoding_profile[2,2]=288
encoding_profile[2,3]=381
encoding_profile[2,4]=96

# Profile 3
encoding_profile[3,1]=768
encoding_profile[3,2]=432
encoding_profile[3,3]=700
encoding_profile[3,4]=128

# Profile 4
encoding_profile[4,1]=1024
encoding_profile[4,2]=576
encoding_profile[4,3]=1078
encoding_profile[4,4]=128

# Profile 5
encoding_profile[5,1]=1280
encoding_profile[5,2]=720
encoding_profile[5,3]=1506
encoding_profile[5,4]=128








# Explode query string (variable and values)
saveIFS=$IFS
IFS='=&'
parm=($query_string)
IFS=$saveIFS
for ((i=0; i<${#parm[@]}; i+=2))
do
	declare var_${parm[i]}=${parm[i+1]}
done

# Debug
# echo 1/ ${app} ${name} $var_unid $var_bw $var_w $var_h

# Inbound stream specifications
spec=$(/opt/tizr/multimedia/bin/ffmpeg -i rtmp://localhost/${app}/${name} 2>&1| grep '\(width\|height\|videodatarate\|audiodatarate\)')

spec_array=($spec)
src_width=$(printf %.0f ${spec_array[1]})
src_height=$(printf %.0f ${spec_array[3]})
src_videodatarate=$(printf %.0f ${spec_array[5]})
src_audiodatarate=$(printf %.0f ${spec_array[7]})
src_nb_pixels=$(($src_width*$src_height))


# Encoding template
if (("$var_bw" > "1000000")); then
	var_bw_low=200K
	var_bw_mid=350K
	var_bw_hi=700K
	var_w_low=160
	var_w_mid=240
	var_w_hi=360
elif (("$var_bw" > "500000")); then
	var_bw_low=210K
	var_bw_mid=350K
	var_bw_hi=500K
	var_w_low=160
	var_w_mid=240
	var_w_hi=360
else
	var_bw_low=200K
	var_bw_mid=300K
	var_bw_hi=300K
	var_w_low=160
	var_w_mid=160
	var_w_hi=160
fi

# Check if unid directory exists, else, create it
if [ ! -d "/mnt/hlsLive/$var_unid" ];then
	mkdir /mnt/hlsLive/$var_unid
	# echo "dir does not exist -> mkdir $var_unid" >> /tmp/debug_encoding
fi

# Debug
#echo "/opt/tizr/multimedia/bin/ffmpeg -i rtmp://localhost/${app}/${name} -threads 2 \
#-c:v libx264 -profile:v baseline -g 10 -b:v $var_bw_low -vf scale=$var_w_low:-1 -c:a aac -ac 1 -strict -2 -b:a 64k -f flv \"rtmp://localhost app=hls playpath=$var_unid/${name}_low?unid=$var_unid\" \
#-c:v libx264 -profile:v baseline -g 10 -b:v $var_bw_mid -vf scale=$var_w_mid:-1 -c:a aac -ac 1 -strict -2 -b:a 128k -f flv \"rtmp://localhost app=hls playpath=$var_unid/${name}_mid?unid=$var_unid\" \
#-c:v libx264 -profile:v baseline -g 10 -b:v $var_bw_hi -vf scale=$var_w_hi:-1 -c:a aac -ac 1 -strict -2 -b:a 128k -f flv \"rtmp://localhost app=hls playpath=$var_unid/${name}_hi?unid=$var_unid\""  >> /tmp/debug_encoding

# Encoding command for live content
/opt/tizr/multimedia/bin/ffmpeg -i rtmp://localhost/${app}/${name} -threads 2 \
-c:v libx264 -profile:v baseline -g 10 -b:v $var_bw_low -vf scale=$var_w_low:-1 -c:a aac -ac 1 -strict -2 -b:a 64k -f flv "rtmp://localhost app=hls playpath=$var_unid/${name}_low?unid=$var_unid" \
-c:v libx264 -profile:v baseline -g 10 -b:v $var_bw_mid -vf scale=$var_w_mid:-1 -c:a aac -ac 1 -strict -2 -b:a 128k -f flv "rtmp://localhost app=hls playpath=$var_unid/${name}_mid?unid=$var_unid" \
-c:v libx264 -profile:v baseline -g 10 -b:v $var_bw_hi -vf scale=$var_w_hi:-1 -c:a aac -ac 1 -strict -2 -b:a 128k -f flv "rtmp://localhost app=hls playpath=$var_unid/${name}_hi?unid=$var_unid" \
2>>/var/log/ffmpegLog/hls-${name}.log;
