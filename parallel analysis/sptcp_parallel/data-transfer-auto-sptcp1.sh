#!/bin/bash

serverIP="52.58.198.215"

serverPort="1234"
#serverPort="1240"

serverAddress="http://$serverIP"

folder_prefix="/home/pi/Documents/results/collected_data"
curlPath="$folder_prefix/curl"
ncPath="$folder_prefix/nc"
filePath="/home/pi/Documents/data"
curlformat="/home/pi/Documents/curl-format.txt"

if [ ! -e $folder_prefix ]
then
	mkdir -p $curlPath $ncPath
fi

echo "Selected IP address: $serverIP"

## Setting flags
curlFLAG=1
ncFLAG=1
WAITTIMER=120

while true
do

	#calculate time until next two minutes
	SLEEPTIMER=$(($WAITTIMER - $(date +%S) ))
	echo $SLEEPTIMER
	sleep $SLEEPTIMER

	timestamp=`date -d '1 hour ago' "+%Y-%m-%d_%H-%M-%S"`

	echo "Starting at $timestamp"

	# create filepaths
	curlFile="$curlPath/$timestamp.txt"
	ncFile="$ncPath/$timestamp.txt"


	#################################
	###### Network test for NC ######
	#################################

	if [ $ncFLAG == "1" ]
	then
		touch $ncFile

		sudo tcpdump -i any -s 88 -w "$ncPath/$timestamp.pcap" &
		sleep 1

		echo "----- 300 MB -----" >> $ncFile
		(time nc -q0 $serverIP $serverPort < $filePath/300M.img) &>> $ncFile
		echo $'\n' >> $ncFile

		#echo "----- 50 MB -----" >> $ncFile
		#(time nc -q0 $serverIP $serverPort < $filePath/50M.img) &>> $ncFile
		#echo $'\n' >> $ncFile

		# echo "----- 10 MB -----" >> $ncFile
		# (time nc -q0 $serverIP $serverPort < $filePath/10M.img) &>> $ncFile
		# echo $'\n' >> $ncFile

		# echo "----- 1 MB -----" >> $ncFile
		# (time nc -q0 $serverIP $serverPort < $filePath/1M.img) &>> $ncFile
		# echo $'\n' >> $ncFile

		# echo "----- 100 KB -----" >> $ncFile
		# (time nc -q0 $serverIP $serverPort < $filePath/100K.img) &>> $ncFile
		# echo $'\n' >> $ncFile

		# echo "----- 10 KB -----" >> $ncFile
		# (time nc -q0 $serverIP $serverPort < $filePath/10K.img) &>> $ncFile
		# echo $'\n' >> $ncFile

		#Kill tcpdump
		pid=$(ps -e | pgrep tcpdump)
		sudo kill -2 $pid
	fi

	###### NC test over ########
	############################

	###################################
	###### Network test for cURL ######
	###################################

	if [ $curlFLAG == "1" ]
	then
		touch $curlFile

		sudo tcpdump -i any -s 88 -w "$curlPath/$timestamp.pcap" &
		sleep 1

		echo "----- 300 MB -----" >> $curlFile
		curl -w "@$curlformat" -o /dev/null --remote-name $serverAddress/300M.img >> $curlFile

		# echo "----- 50 MB -----" >> $curlFile
		# curl -w "@$curlformat" -o /dev/null --remote-name $serverAddress/50M.img >> $curlFile

		# echo "----- 10 MB -----" >> $curlFile
		# curl -w "@$curlformat" -o /dev/null --remote-name $serverAddress/10M.img >> $curlFile

		# echo "----- 1 MB -----" >> $curlFile
		# curl -w "@$curlformat" -o /dev/null --remote-name $serverAddress/1M.img >> $curlFile

		# echo "----- 100 KB -----" >> $curlFile
		# curl -w "@$curl-format" -o /dev/null --remote-name $serverAddress/100K.img >> $curlFile

		# echo "----- 10 KB -----" >> $curlFile
		# curl -w "@$curlformat" -o /dev/null --remote-name $serverAddress/10K.img >> $curlFile


		#Kill tcpdump
		pid=$(ps -e | pgrep tcpdump)
		sudo kill -2 $pid
	fi

	###### cURL test over ########
	##############################

done
