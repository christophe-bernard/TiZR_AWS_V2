#!/bin/bash
unid=$1
name=$2
while true ; do `/usr/local/bin/s3cmd sync --delete-removed --force /mnt/hlsLive/${unid}/${name}* s3://encoding-0.hls.live/${unid}/ &` ; sleep 5; done
