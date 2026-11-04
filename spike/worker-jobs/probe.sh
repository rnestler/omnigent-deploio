#!/bin/sh
# Logs one BOOT line when a worker starts, then idles. A second BOOT line from
# the same worker means it restarted. Prints no env values except SPIKE_VALUE.
echo "BOOT ${1:-unnamed} $(date +%T) pid=$$ spike=${SPIKE_VALUE:-unset} pid1=$(tr '\0' ' ' </proc/1/cmdline)"
exec sleep infinity
