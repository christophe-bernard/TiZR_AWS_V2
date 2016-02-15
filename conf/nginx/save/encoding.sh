#!/bin/bash
app=$1
name=$2
query_string=$3
# echo var : app=$app, name=$name, query_string=$query_string >> /tmp/debug_profil

# Start sync content with S3 bucket
sudo start-stop-daemon --start --quiet --background --make-pidfile --pidfile /var/run/sync_bucket_live_${name}.pid --exec /opt/tizr/sync_bucket/sync_bucket_live.sh


# Expected query string variables :
# - unid


# Quality constants
quality_pixel_factor=331776
quality_bandwidth_factor=600 # Raise to increase quality
bandwidth_measures=50 #Number of iteration to compute the media bandwidth

declare -A encoding_profile
num_rows=5 # 5 encoding profile
num_columns=4 # Width / Height / Video datarate / Audio datarate

# Profile 1
encoding_profile[1,1]=256
encoding_profile[1,2]=144
encoding_profile[1,3]=135000
encoding_profile[1,4]=32000

# Profile 2
encoding_profile[2,1]=512
encoding_profile[2,2]=288
encoding_profile[2,3]=381000
encoding_profile[2,4]=96000

# Profile 3
encoding_profile[3,1]=768
encoding_profile[3,2]=432
encoding_profile[3,3]=700000
encoding_profile[3,4]=128000

# Profile 4
encoding_profile[4,1]=1024
encoding_profile[4,2]=576
encoding_profile[4,3]=1078000
encoding_profile[4,4]=128000

# Profile 5
encoding_profile[5,1]=1280
encoding_profile[5,2]=720
encoding_profile[5,3]=1506000
encoding_profile[5,4]=128000

# Directory to be synchronised with S3 Live bucket
hls_path_live="/mnt/hlsLive"

# Directory to be synchronised with S3 VOD bucket
hls_path_vod="/mnt/hlsVod"

# Local storage for recorded stream
local_hls_path_vod="/var/www/hlsVod"

# Explode query string (variable and values)
saveIFS=$IFS
IFS='=&'
parm=($query_string)
IFS=$saveIFS
for ((i=0; i<${#parm[@]}; i+=2))
do
	declare var_${parm[i]}=${parm[i+1]}
done


# Check if live unid directory exists, else, create it
if [ ! -d "$hls_path_live/$var_unid" ];then
	mkdir $hls_path_live/$var_unid
	cp $hls_path_live/crossdomain.xml $hls_path_live/$var_unid/
fi

# Check if VOD unid directory exists, else, create it
if [ ! -d "$hls_path_vod/$var_unid" ];then
	mkdir $hls_path_vod/$var_unid
	cp $hls_path_vod/crossdomain.xml $hls_path_vod/$var_unid/
fi


# Inbound stream specifications (width, height, video bitrate), wait for 50 datarate values
src=$local_hls_path_vod/$name.flv
k=0
while [ -z "$src_width" ] || [ -z "$src_height" ] || [ -z "$src_videodatarate_tmp" ] || (($k < $bandwidth_measures)) ; do
	src_width=$(mediainfo --Inform=Video\;%Width% $src)
	src_height=$(mediainfo --Inform=Video\;%Height% $src)
	src_videodatarate_tmp=$(mediainfo --Inform=General\;%OverallBitRate% $src)
	if [ "$src_videodatarate_tmp" ]; then
		src_videodatarate_total=$(($src_videodatarate_total + $src_videodatarate_tmp))
		k=$((k+1))
	fi
	# echo src_videodatarate_tmp pendant : $src_videodatarate_tmp, k: $k >> /tmp/debug_profil
done

src_videodatarate=$(($src_videodatarate_total / $bandwidth_measures))
# echo src_videodatarate final : $src_videodatarate >> /tmp/debug_profil


# Select profile to apply
ideal_videodatarate=$(printf %.0f $(echo $src_width $src_height $quality_pixel_factor $quality_bandwidth_factor| awk '{print ((($1*$2)/($3))^0.75)*$4}'))
src_nb_pixels=$(($src_width*$src_height))

# Potential profile
for ((i=1;i<=num_rows;i++)) do
	nb_pixel_profile=$((${encoding_profile[$i,1]}*${encoding_profile[$i,2]}))
	if (($src_nb_pixels >= $nb_pixel_profile)); then
		potential_profile[$i]=$i
	else
		break
	fi
done
nb_potential_profile=${#potential_profile[@]}


# Final profile
for ((i=1;i<=nb_potential_profile;i++)) do
	if (($src_videodatarate >= ${encoding_profile[$i,3]})); then
		selected_profile[$i]=$i
	else
		selected_profile[$i]=1 # Default : lowest profile
		break
	fi
done

nb_selected_profile=${#selected_profile[@]}


# Create meta m3u8 manifest if needed (ie more than one stream)
if (($nb_selected_profile > 1)); then
	# m3u8 for Live
	echo "#EXTM3U" > $hls_path_live/$var_unid/${name}.m3u8
	echo "#EXT-X-VERSION:3" >> $hls_path_live/$var_unid/${name}.m3u8
	# m3u8 for Vod
	echo "#EXTM3U" > $hls_path_vod/$var_unid/${name}.m3u8
	echo "#EXT-X-VERSION:3" >> $hls_path_vod/$var_unid/${name}.m3u8	
	for ((i=1;i<=nb_selected_profile;i++)) do
		media_rate=$((${encoding_profile[$i,3]}+${encoding_profile[$i,4]}))
		# m3u8 for Live
		echo "#EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=$media_rate" >> $hls_path_live/$var_unid/${name}.m3u8
		echo "${name}_level$i/index.m3u8" >> $hls_path_live/$var_unid/${name}.m3u8
		# m3u8 for Vod
		echo "#EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=$media_rate" >> $hls_path_vod/$var_unid/${name}.m3u8
		echo "${name}_level$i/index.m3u8" >> $hls_path_vod/$var_unid/${name}.m3u8
	done
fi


# Encoding command for live content
sleep 3 # Wait 3 seconds before processing input file
encoding_command_header="ffmpeg -re -i $local_hls_path_vod/$name.flv -threads auto "
if (($nb_selected_profile == 1)); then
	encoding_command_body+="-c:v libx264 -profile:v baseline -level 3.0 -g 10 -b:v ${encoding_profile[$i,3]} -vf scale=${encoding_profile[$i,1]}:-1 -c:a aac -ac 1 -strict -2 -b:a ${encoding_profile[$i,4]} -f flv \"rtmp://localhost app=hls playpath=$var_unid/${name}?unid=$var_unid\" "	
else
	for ((i=1;i<=nb_selected_profile;i++)) do
		encoding_command_body+="-c:v libx264 -profile:v baseline -level 3.0 -g 10 -b:v ${encoding_profile[$i,3]} -vf scale=${encoding_profile[$i,1]}:-1 -c:a aac -ac 1 -strict -2 -b:a ${encoding_profile[$i,4]} -f flv \"rtmp://localhost app=hls playpath=$var_unid/${name}_level$i?unid=$var_unid\" "
	done
	
#	echo $m3u8_body >> $hls_path_live/$var_unid/${name}.m3u8
fi

encoding_command_footer="2>>/var/log/ffmpegLog/hls-${name}.log"

encoding_command=$encoding_command_header$encoding_command_body$encoding_command_footer

# echo encoding command : $encoding_command  >> /tmp/debug_profil
eval "$encoding_command"

