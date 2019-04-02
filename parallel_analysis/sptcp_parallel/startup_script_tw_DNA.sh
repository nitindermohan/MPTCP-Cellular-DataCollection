#!/bin/bash

SLEEPTIMER=8

### The program follows a simple state machine logic, ##
### it is driven by three states, marked with three   ##
### flags; INSERTED, CONNECT and CONNECTED. Each of   ##
### the flags have been explained below.	      ##

INSERTED=0	# flag for if BOTH the USB modems have inserted
CONNECT=0 	# flag if BOTH modems have been registered with the /dev/ttyUSB
CONNECTED=0	# flag when BOTH modems have been connected to the internet and
		# have a valid IP
#########################################################

### Variables for control messages in the script ##
RETRIES=0
MAXRETRIES=5
STOPPER=1
#########################################################

### Log File
logFile="/home/pi/Documents/logfile.txt"

#echo $(date -u) "Starting startup script." >> $logFile

## Add a if condition which checks whether the SD card is about
## to be full. If yes, it will send an email to Alex  
mailFile="/home/pi/Documents/mailfile"

## First check on reboot if the mailtag is present already such 
## that we dont keep spamming.
memFile="/home/pi/Documents/usage.txt"

## Set MPTCP configuration here
#sudo sysctl -w net.ipv4.tcp_congestion_control=balia

while true
do

	### Printing all flags for DEBUG ##
	if [ "$CONNECTED" == "0" ]
	then
		echo $(date -u) "INSERTED: $INSERTED, CONNECT: $CONNECT, CONNECTED: $CONNECTED, RETRIES: $RETRIES" >> $logFile
	fi

	### Lets set the flags first ###
	################################

	## First for INSERTED
	result=`lsusb | grep D-Link`
	result1=`lsusb | grep 2020`

	if ([ "$result" ] || [ "$result1" ])
	then
		INSERTED=1
	else
		INSERTED=0
	fi

	### If the devices have been inserted, we register it ##
	########################################################

	if ([ "$INSERTED" == "1" ] && [ "$CONNECT" == "0" ])
	then
		#install the Telewell device as usb-serial
		sudo usb_modeswitch -c /etc/usb_modeswitch.conf
		sleep $SLEEPTIMER

		sudo modprobe option
		sleep $SLEEPTIMER
		#map both devices to ttyUSB
		#Telewell
		sudo sh -c "echo 2020 2033 > /sys/bus/usb-serial/drivers/option1/new_id"
		sleep $SLEEPTIMER
		#DLink
		#sudo sh -c "echo 2001 7e35 > /sys/bus/usb-serial/drivers/option1/new_id"
		#sleep $SLEEPTIMER
	fi

	### Set the flag here for CONNECT
	if ([ `ifconfig | grep wwan | wc -l` == 1 ]) #check if the USB modem has been registered
	then
		if [ "$CONNECT" == "0" ]
		then
			echo $(date -u) "Devices have been registered. Well Done." >> $logfile
		fi
		CONNECT=1
		#exit			#comment this if you want the script to run
	else
		echo $(date -u) "Devices not registered, Try again." >> $logFile
		CONNECT=0
	fi


	## here we dial into the network and get IP addresses
	if ([ "$CONNECT" == "1" ] && [ "$CONNECTED" == "0" ]) #if the devices have been connected
	then
		# sudo wvdial Telia &
		# pid1=$!
		# echo $(date -u) "First wvdial PID is $pid1" >> $logFile
		# sleep $SLEEPTIMER

		sudo wvdial DNA &
		pid2=$!
		echo $(date -u) "Second wvdial PID is $pid2" >> $logFile
		sleep $SLEEPTIMER

	fi

	## Here we need to check if the connection was successful
	if [ `ifconfig | grep ppp | wc -l` == 2 ] #check if the modem has been registered as PPP device
	then
		if [ "$CONNECTED" == "0" ]
		then
			echo $(date -u) "Connection Successful" >> $logFile
		fi
		CONNECTED=1
		RETRIES=0	#reset the retries

		sudo chmod 666 /dev/ttyUSB*	#give read access to USB modem serial device

	else
		echo $(date -u) "Connection unsucessful. Killing any on-going connections." >> $logFile
		sudo pkill wvdial
		sleep $SLEEPTIMER

		RETRIES=$((RETRIES+1))
		CONNECTED=0
		STOPPER=1
	fi

	# once we have established the connection, we start collecting data and spawn the test script
	if ([ "$CONNECTED" == "1" ])
	then

		if [[ "$STOPPER" -le "1" ]] #stop spamming message on terminal
		then
			echo $(date -u) "Devices have been connected. Enjoy!" >> $logFile

			# set the CREG command to give base station ID
			screen -S screenscraper -dm /dev/ttyUSB2
			screen -S screenscraper -X stuff "AT+CREG=2\r"
			screen -S screenscraper -X quit

			#screen -S screenscraper -dm /dev/ttyUSB6
			#screen -S screenscraper -X stuff "AT+CREG=2\r"
			#screen -S screenscraper -X quit

			#echo AT+CREG=2 | atinout - /dev/ttyUSB2 -
			#echo AT+CREG=2 | atinout - /dev/ttyUSB6 -

			STOPPER=$STOPPER+1
		fi

		## Here we will check whether we have enough data for memory. If not, 
		## we will not start data transfer
		memory=`df -h | grep /dev/root | awk '{print $5}' | tr -d %`
		echo $(date -u) `df -h | grep root` > $memFile
		#scp $memFile nmohan@melkki.cs.helsinki.fi:/home/fs/nmohan/public_html/softwares/

		if [ "$memory" -ge "95" ]
		then
			#if [ ! -e $mailFile ]
			#then
				#echo "Hey! This is the raspberryPi from beyond. The memory card in me is about to be full. Please transfer data first." | mail -s "#raspberry" trigger@applet.ifttt.com
				#echo "Hey! This is the raspberryPi from beyond. The memory card in me is about to be full. Please transfer data first." | mail -s "RaspberryPi memory full" aleksandr.zavodovski@gmail.com
				#touch $mailFile
			#fi
			echo $(date -u) "The data disk has become full. Stopping data transfer" >> $logFile
			sleep 600
			sudo poweroff
		fi

		echo $(date -u) "Starting data collection" >> $logFile
		./home/pi/Documents/network-quality-modded_sptcp2.sh

	fi

	if [ "$RETRIES" == "$MAXRETRIES" ]
	then
		echo $(date -u) "Number of retries exceeded. Restarting RPi. Fingers crossed!" >> $logFile
		echo "The connection retry has exceeded the limit, will restart in 3 mins. If testing, kill this process within next 3 minutes"
		sleep 180
		sudo reboot
	fi
done
