#!/bin/bash

src=$1
inform=$2
param=$3


eval "/usr/local/bin/mediainfo --Inform=${inform}\;%${param}% ${src}"