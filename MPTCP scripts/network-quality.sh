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
	./home/pi/Documents/data-transfer.sh
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

	dataYES=`ps -aux | awk '{print $2}' | grep $dataPID`
	if [ -z "$dataYES" ]
	then
		## We have entered this condition because the data collection
		## script is currently not running. We need to decide whether
		## we start a new data collection script here.

		## Has enough time passed since our last data collection? (i.e. more than X minutes)
		diff=$SECONDS

		## If application is not running, set log time to passive by default.
		## It will change to active if a new script is spawned
		SLEEPTIMER=$passiveTime

		if [ $((($diff / 60) % 60)) -ge $waitTime ]
		then
			# First get the last X recorded values of signal strength from both modems
			signalUSB1=(`grep -R "+CSQ:" $usb1Path/* | tail -n $mobility | awk -F'[:, ]' '{print $4}'`)
			signalUSB2=(`grep -R "+CSQ:" $usb2Path/* | tail -n $mobility | awk -F'[:, ]' '{print $4}'`)

			usb1Unique=`unique_values "${signalUSB1[@]}"`
			usb2Unique=`unique_values "${signalUSB2[@]}"`

			#Now check if there was any change in values
			if [ $usb1Unique == "0" ] || [ $usb2Unique == "0" ];
			then
				#change in signal strength detected here
				#start process
				run_dataScript &
				dataPID=$!
				SECONDS=0

				SLEEPTIMER=$activeTime
			fi
		else
			## We will enter this part if data collection
			## is not running and the RPi is still or not
			## much time has elapsed till the last data
			## collection. At this point, we cango into
			## passive mode and reduce the signal logging
			## time period.
			SLEEPTIMER=$passiveTime
			echo $(date -u) "Mobility detected. Too soon to start data transfer. Will have to wait $waitTime minutes." >> $log
		fi

	#else
		## We will enter this condition because the data collection
		## script is currently ongoing. Keep in active state
		#echo "Data transfer currently ruuning."
	fi

	sleep $SLEEPTIMER

done








