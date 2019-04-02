#/bin/bash

sessionName="$1"

a=`screen -ls | grep -o "[0-9]*\.$sessionName"`

for session in $a;
do
	screen -S  "${session}" -X quit;
done



