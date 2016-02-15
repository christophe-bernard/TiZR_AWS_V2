#!/bin/bash

src_w=$1
src_h=$2
src_videorate=$3

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

f1="%$((${#num_rows}+1))s"
f2=" %9s"

printf "$f1" ''






for ((j=1;j<=num_columns;j++)) do
    printf "$f1" $j
    for ((i=1;i<=num_rows;i++)) do
        printf "$f2" ${encoding_profile[$i,$j]}
    done
    echo
done

echo
echo


src_nb_pixel=$(($src_w*$src_h))
echo nb pixel source : $src_nb_pixel

# Potential profile
for ((i=1;i<=num_rows;i++)) do
	nb_pixel_profile=$((${encoding_profile[$i,1]}*${encoding_profile[$i,2]}))
	if (($src_nb_pixel >= $nb_pixel_profile)); then
		potential_profile[$i]=$i
	else
		break
	fi
done
echo
nb_potential_profile=${#potential_profile[@]}

echo Potential Selection : $nb_potential_profile
for selection in ${potential_profile[*]}
do
	echo $selection;
done


# Selected profile
for ((i=1;i<=nb_potential_profile;i++)) do
	if (($src_videorate >= ${encoding_profile[$i,3]})); then
		selected_profile[$i]=$i
	else
		break
	fi
done
echo

nb_selected_profile=${#selected_profile[@]}

echo Final Selection : $selected_profile
for selection in ${selected_profile[*]}
do
	echo $selection;
done



