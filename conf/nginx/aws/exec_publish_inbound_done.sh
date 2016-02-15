#!/bin/bash
aws_cmd="aws cloudwatch put-metric-data --metric-name EncoderInboundUnpublishCount --namespace \"TiZR\" --value 1 --timestamp $(date -u +%Y-%m-%dT%H:%M:%S.000Z)"
# echo "aws_cmd : $aws_cmd" >> /tmp/debug_aws
eval "$aws_cmd"

