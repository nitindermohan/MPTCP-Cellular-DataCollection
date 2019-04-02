#!/bin/bash

count=0
filePath=`pwd`

while true
do
	timestamp=`date "+%Y-%m-%d_%H-%M-%S"`
	echo "Server connection opening at" $(date -u)
#	sudo timeout 900 tcpdump -i any -s 88 -w "$filePath/data/Telia/$timestamp.pcap" &
#	sleep 1
	nc -l -p 1240
	count=$(($count+1))
	sudo pkill nc

	# kill tcpdump
#	pid=$(ps -e | pgrep tcpdump)
#	sudo kill -2 $pid
done
