#!/bin/bash

serverIP="52.58.198.215"

serverPort="1234"
serverAddress="http://$serverIP"

videoOutfix="onDemand_2014_05_09.mpd"

folder_prefix="/home/pi/Documents/results/collected_data"
videoPath="$folder_prefix/video"
path1s="$videoPath/1s"
path6s="$videoPath/6s"
path15s="$videoPath/15s"

if [ ! -e $folder_prefix ]
then
	mkdir -p $path1s $path6s $path15s
fi

echo "Selected IP address: $serverIP"

## Setting flags
VIDEOTIME=180
SLEEPTIMER=60

onePath="$serverAddress/1sec/BigBuckBunny_1s_$videoOutfix"
sixPath="$serverAddress/6sec/BigBuckBunny_6s_$videoOutfix"
fifPath="$serverAddress/15sec/BigBuckBunny_15s_$videoOutfix"

echo $onePath $sixPath $fifPath

while true
do

	timestamp=`date -d '1 hour ago' "+%Y-%m-%d_%H-%M-%S"`

	####################################
	###### Network test for Video ######
	###################################

	# play 1s segment
	sudo tcpdump -i any -s 88 -w "$path1s/$timestamp.pcap" &
	sleep 1

	sudo -u pi cvlc --play-and-exit $onePath --run=$VIDEOTIME

	#Kill tcpdump
	pid=$(ps -e | pgrep tcpdump)
	sudo kill $pid

	sleep $SLEEPTIMER

	# play 6s segment
	sudo tcpdump -i any -s 88 -w "$path6s/$timestamp.pcap" &
	sleep 1

	sudo -u pi cvlc --play-and-exit $sixPath --run=$VIDEOTIME

	#Kill tcpdump
	pid=$(ps -e | pgrep tcpdump)
	sudo kill $pid

	sleep $SLEEPTIMER

	#play 15s segment
	sudo tcpdump -i any -s 88 -w "$path15s/$timestamp.pcap" &
	sleep 1

	sudo -u pi cvlc --play-and-exit $fifPath --run=$VIDEOTIME

	#Kill tcpdump
	pid=$(ps -e | pgrep tcpdump)
	sudo kill $pid

	sleep $SLEEPTIMER

done
