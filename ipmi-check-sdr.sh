#!/bin/bash

# Add to cron:
# IPMI check for sdr:
#34 9,12,15 * * 1-5 /usr/local/sbin/ipmi-check-sdr.sh


LOGDIR=/var/log/ipmi-sdr
DOMAIN="DOMAIN.local"
BLACKLIST4HOST=BLACKHOST\|OLDHOST-ilo\|BLACKHOST-ILO
TEMPFILE="/tmp/hosts-ilo"
PASS4IPMI="CHANGE"


host -l ${DOMAIN} | grep -i "\-ilo" | egrep -iv ${BLACKLIST4HOST} | awk '{print $1}' > ${TEMPFILE}

exec < ${TEMPFILE}
while read string 
do 
ipmitool -I lanplus -H $string -U ipmimon -P ${PASS4IPMI} sdr 2>&1 | egrep -vw ok\|disabled\|"Not Readable"\|nr  >$LOGDIR/$string.new 
if [ -s $LOGDIR/$string ] ; then
	diff -q $LOGDIR/$string.new $LOGDIR/$string > /dev/null
	if [ $? -ne 0 ] ; then
	  echo "diff $LOGDIR/$string.new $LOGDIR/$string:"
	  diff $LOGDIR/$string.new $LOGDIR/$string
	fi
# Save old log with bigger size:
	if [[ $(stat -c%s $LOGDIR/$string) -gt $(stat -c%s $LOGDIR/$string.new) ]]; then 
		mv $LOGDIR/$string $LOGDIR/$string.old
	fi
fi

mv $LOGDIR/$string.new $LOGDIR/$string

done
