#!/bin/bash

# Add to cron:
# IPMI check for sel:
#12 * * * * /usr/local/sbin/ipmi-check-sel.sh


LOGDIR=/var/log/ipmi-sel
DOMAIN="DOMAIN.local"
BLACKLIST4HOST=BLACKHOST\|OLDHOST-ilo\|BLACKHOST-ILO
TEMPFILE="/tmp/hosts-ilo"
PASS4IPMI="CHANGE"
ERRSTR="SEL has no entries"\|"Received an Unexpected RAKP"\|"no response from RAKP"\|"Close Session command failed"\|"Get Device ID command failed"\|"Error sending request"\|"Get SEL Info command failed"


host -l ${DOMAIN} | grep -i "\-ilo" | egrep -iv ${BLACKLIST4HOST} | awk '{print $1}' > ${TEMPFILE}

exec < ${TEMPFILE}
while read string 
do 

 ipmitool -I lanplus -H $string -U ipmimon -P ${PASS4IPMI} sel list  > $LOGDIR/$string.tmp 2>&1
 egrep -q "${ERRSTR}" $LOGDIR/$string.tmp 
 if [ $? -eq 0 ] ; then
  continue
 else 
  mv $LOGDIR/$string.tmp $LOGDIR/$string.new
 fi

   if [ -e $LOGDIR/$string ] ; then
	diff -q $LOGDIR/$string.new $LOGDIR/$string > /dev/null
	if [ $? -ne 0 ] ; then
	  echo "New System Event Log strings for $string:"
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
