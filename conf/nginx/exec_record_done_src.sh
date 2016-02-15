#!/bin/bash
path=$1
dirname=$2
basename=$3
query_string=$4

# S3 bucket VOD Mount point
hls_path_vod="/mnt/hlsVod"

# Debug
# echo $1 $2 $3 $4 >> /tmp/debug_record

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

# Check if unid directory exists, else, create it
if [ ! -d "/mnt/hlsVod/$var_unid" ];then
	mkdir /mnt/hlsVod/$var_unid
fi


# Move recorded mp4 files to s3 bucket
ffmpeg -y -i ${path} -c copy ${dirname}/${basename}.mp4 && rm ${path} && mv ${dirname}/${basename}.mp4 $hls_path_vod/$var_unid
