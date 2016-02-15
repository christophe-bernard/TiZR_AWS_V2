#!/bin/bash
query_string=$1

# Debug
# echo $1 $2 $3 $4 >> /tmp/debug_dynamic_path

# Explode query string (variable and values)
saveIFS=$IFS
IFS='=&'
parm=($query_string)
IFS=$saveIFS
for ((i=0; i<${#parm[@]}; i+=2))
do
	declare var_${parm[i]}=${parm[i+1]}
done

if [ ! -L /mnt/hlsLive/$var_unid ];then
	ln -s /mnt/hlsLive/tmp/ /mnt/hlsLive/$var_unid
fi
