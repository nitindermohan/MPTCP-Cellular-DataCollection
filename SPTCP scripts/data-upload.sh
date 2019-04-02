#!/bin/bash

## Formatting guide
#sshAddress="nmohan@melkki.cs.helsinki.fi"
sshAddress="nmohan@melkinkari.cs.helsinki.fi"

ssh_path="/home/fs/nmohan/public_html/ramptcp/"

if [ -z "$1" ]
then
	folder_prefix="dataBackup_"
else
	folder_prefix="$1/dataBackup_"
fi

results="/home/pi/Documents/results"

timestamp=`date "+%Y-%m-%d_%H-%M"`

folder="$folder_prefix$timestamp"
fullPath="$ssh_path$folder"

echo $fullPath

ssh $sshAddress "mkdir -p $fullPath"

scp -r $results "$sshAddress:$fullPath"

#sudo rm -r $results

#sudo reboot
