#!/bin/bash
query_string=$1

# Debug
echo var1 : $1 >> /tmp/debug_dynamic_path

# Explode query string (variable and values)
saveIFS=$IFS
IFS='=&'
parm=($query_string)
IFS=$saveIFS
for ((i=0; i<${#parm[@]}; i+=2))
do
	declare var_${parm[i]}=${parm[i+1]}
	echo var : $var_parm[$i]  >> /tmp/debug_dynamic_path
done

dynamic_path_cmd="ln -s  /mnt/hlsLive /mnt/hlsLive/$var_unid"
echo dynamic_path_cmd : $dynamic_path_cmd >>  /tmp/debug_dynamic_path

eval $dynamic_path_cmd
