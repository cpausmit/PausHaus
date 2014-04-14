#!/bin/bash
# --------------------------------------------------------------------------------------------------
# Installation script for the PausHaus Package.
#
# - assumes you sudo rights (entry in /etc/sudoers)
#
# TODO:
#
# - find the temparature usb device automatically and allow users to write (lsusb)
#
#                                                                              C.Paus (Apr 13, 2014)
# --------------------------------------------------------------------------------------------------
# first install all necessary packages (fedora style)

sudo yum -y install fuse fuse-libs libmtp simple-mtpfs \
                    libusb libusb-devel libusb1 libusb1-devel \
                    rrdtool rrdtool-perl

# install the Temperature package
if [ -d "Temperature" ]
then
  cd Temperature
  make clean
  make
  sudo make install
  cd - >& /dev/null
fi

# configuration parameters (this needs more work but for now)
export PAUSHAUS_USER=ana
export PAUSHAUS_GROUP=ana

# copy the software
if [ -d "/usr/local/PausHaus" ]
then
  # make sure to remove completely the previous installed software
  sudo rm -rf /usr/local/PausHaus
fi
sudo cp -r ../PausHaus /usr/local

if [ "`hostname | tr [A-Z] [a-z]`" == "`echo pausserv.home | tr [A-Z] [a-z] `" ]
then
  
  # create log file directory structure (on server only)
  sudo mkdir -p /var/log/PausHaus/RrdLogger
  
  # the owner has to be $PAUSHAUS_USER:$PAUSHAUS_GROUP, this user runs the process
  sudo chown ${PAUSHAUS_USER}:${PAUSHAUS_GROUP} -R /var/log/PausHaus
  
  # stop potentially existing server process
  if [ -e "/etc/init.d/rrdloggerd" ]
  then
    sudo /etc/init.d/rrdloggerd stop
  fi
  
  # copy RrdLogger daemon
  sudo cp /usr/local/PausHaus/RrdLogger/rrdloggerd /etc/init.d/
  
  # start new server
  sudo /etc/init.d/rrdloggerd status
  sudo /etc/init.d/rrdloggerd start
  sleep 2
  sudo /etc/init.d/rrdloggerd status
  
  # start on boot
  sudo chkconfig --level 345 rrdloggerd on
fi

exit 0
