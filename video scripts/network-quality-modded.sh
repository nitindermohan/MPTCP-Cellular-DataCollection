#!/bin/bash

### Log file
log="/home/pi/Documentslogfile.txt"

## handle script kill
gotSignal(){
	echo $(date -u) "Handling things gracefully here!" >> $log
	#kill any open screen sessions
	screen -S screenscraper -X quit
	screen -S screenscraper1 -X quit
	wait
	exit
}

unique_values() {
	arr=("$@")
	if awk 'v && $1!=v{ exit 1 }{ v=$1 }' <(printf "%d\n" "${arr[@]}");
	then
		echo "1"
	else
		echo "0"
	fi
}
#if all values in the array are unique, the function will return 1, else 0

run_dataScript() {
	echo $(date -u) "Mobility detected. Starting data transfer!" >> $log
	#./home/pi/Documents/data-transfer-auto.sh	#curl and nc script
	./home/pi/Documents/data-transfer-video.sh	#video transfer
}

## Formatting guide
folder_prefix="/home/pi/Documents/results/network_quality"
usb1Path="$folder_prefix/ttyUSB1"
usb2Path="$folder_prefix/ttyUSB5"

#Important variables
passiveTime=1 		#sleep for 10 seconds when collecting signals
activeTime=1
SLEEPTIMER=$passiveTime	#default capture time is passiveTime
dataPID="null"
waitTime=5		#how many minutes to wait before starting data captures while mobile
mobility=30		#how many past signal strength values to look at to determine mobility. Default 1 minute (mobility*passiveTime).

if [ ! -e $folder_prefix ]
then
	mkdir -p $usb1Path $usb2Path
fi

trap "gotSignal" SIGINT

### Track time
SECONDS=0

### start data transfer script here
run_dataScript &

while true
do
	echo $(date -u) "Starting network quality script" >> $log
	timestamp=`date "+%Y-%m-%d_%H-%M-%S"`

	## logging for first USB modem
	screen -S screenscraper -dm -L $usb1Path/$timestamp.txt /dev/ttyUSB2
	screen -S screenscraper -X stuff "AT+CSQ\r"
	#sleep 1
	screen -S screenscraper -X stuff "AT+CREG?\r"
	sleep 1
	./home/pi/Documents/screen_killer.sh screenscraper
	#screen -S screenscraper -X quit

	## logging for second USB modem
	screen -S screenscraper1 -dm -L $usb2Path/$timestamp.txt /dev/ttyUSB6
	screen -S screenscraper1 -X stuff "AT+CSQ\r"
	#sleep 1
	screen -S screenscraper1 -X stuff "AT+CREG?\r"
	sleep 1
	./home/pi/Documents/screen_killer.sh screenscraper1
	#screen -S screenscraper1 -X quit

	sleep $SLEEPTIMER

done








