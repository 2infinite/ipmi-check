#!/bin/bash

# Add to cron:
# IPMI check for sel info:
#52 9-19 * * 1-5 /usr/local/sbin/ipmi-check-sel-info.sh


LOGDIR=/var/log/ipmi-sel-info
DOMAIN="DOMAIN.local"
BLACKLIST4HOST=BLACKHOST\|OLDHOST-ilo\|BLACKHOST-ILO
TEMPFILE="/tmp/hosts-ilo"
PASS4IPMI="CHANGE"


host -l ${DOMAIN} | grep -i "\-ilo" | egrep -iv ${BLACKLIST4HOST} | awk '{print $1}' > ${TEMPFILE}

exec < ${TEMPFILE}
while read string 
do 
ipmitool -I lanplus -H $string -U ipmimon -P ${PASS4IPMI} sel info 2>&1 | egrep -wi Overflow > $LOGDIR/$string.new
if [ -s $LOGDIR/$string ] ; then
	egrep -wi Overflow $LOGDIR/$string.new | egrep -wiq true
	if [ $? -eq 0 ] ; then
		echo "$string: SEL is Overflow, clearing the contents of the SEL:"
		ipmitool -I lanplus -H $string -U ipmimon -P ${PASS4IPMI} sel clear
		ERR=$?
		if [ $ERR -eq 0 ] ; then
			echo "Done"
		else echo "Error: $ERR when exec: ipmitool -I lanplus -H $string  sel clear"
		fi
	fi
# Save old log with bigger size:
	if [[ $(stat -c%s $LOGDIR/$string) -gt $(stat -c%s $LOGDIR/$string.new) ]]; then 
		mv $LOGDIR/$string $LOGDIR/$string.old
	fi
fi

mv $LOGDIR/$string.new $LOGDIR/$string

done
