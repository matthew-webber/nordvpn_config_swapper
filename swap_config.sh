#!/bin/bash

# The following will update the router with a chosen NordVPN config file given the FILE_PATH as an argument to this script by 1) uploading it to the /etc/openvpn/ dir and 2) editing the /etc/init.d/openvpn config to point to the file.
# If the config file already exists in /etc/openvpn/, 1) above will be skipped and only 2) above will be performed

# Ex. ./swap_config.sh server123.vpn.com

# if no file given, exit
: ${1?No file passed to script, exiting...}

FILE_PATH=$1
FILE_NAME=${FILE_PATH##*/}
SSH_TARGET="root@192.168.1.1"


echo "Source: $FILE_PATH"
echo "Target: $SSH_TARGET"
echo -n "Press any key to continue or Ctrl+C to quit."
read -n 1 response

echo 'Starting script...'

if ssh $SSH_TARGET "test -e /etc/openvpn/$FILE_NAME"
then
  # the ovpn file already exists, exit
  echo "This VPN config file already exists in the config dir.  Skip uploading and point the OpenVPN config to $FILE_NAME?"
  select yn in "Enter 1 to continue" "Enter 2 to cancel"; do
    case $yn in
      "Enter 1 to continue" ) ssh $SSH_TARGET "sed -i \"s/option config.*ovpn/option config '\/etc\/openvpn\/$FILE_NAME/\" /etc/config/openvpn;/etc/init.d/openvpn restart"; echo 'Config file edited!'; echo 'Restarting init.d service...'; break;;
      "Enter 2 to cancel" ) echo "Aborting..."; break;;
    esac
  done
  # ask user if they want to swap the VPN config to the file name
  # if yes, perform steps 3
  # else do nothing

else

  # step 1
  sed -i "s/auth-user-pass/auth-user-pass secret/" $FILE_PATH
  # step 2
  echo 'Transferring file...'
  scp $FILE_PATH $SSH_TARGET:/etc/openvpn/
  # step 3
  ssh $SSH_TARGET "sed -i \"s/option config.*ovpn/option config '\/etc\/openvpn\/$FILE_NAME/\" /etc/config/openvpn;/etc/init.d/openvpn restart"
  echo 'Config file edited!'
  echo 'Restarting init.d service...'

fi
