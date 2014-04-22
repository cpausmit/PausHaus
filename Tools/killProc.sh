#!/bin/bash
#--------------------------------------------------------------------------------------------------
# Kill all processes which in 'ps auxw' match a given pattern. This is dangerous, but hell,
# life is an adventure.
#                                                                         V1.0 Ch.Paus: 03 Jun 2010
#--------------------------------------------------------------------------------------------------
# get command line arguments
USER=$1
PATTERN=$2
if [ "$USER" == "" ] || [ "$PATTERN" == "" ]
then
  echo ""
  echo " usage: killProc.sh  <user>  <pattern> "
  echo ""
  exit 1
fi

# make a list of pids
pids=`ps auxw|grep ^$USER|grep -v killProc.sh|grep -v grep|grep $PATTERN |tr -s ' '|cut -d' ' -f2`

# loop through the list and kill'em
for pid in $pids
do
  echo "  -> killing pid: $pid"
  kill $pid
done
