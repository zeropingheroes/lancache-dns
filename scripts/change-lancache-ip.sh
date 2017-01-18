#!/bin/bash

PATH_UPSTREAMS_AVAILABLE="/etc/unbound/upstreams-available"

read -p "Enter NEW lancache IP address: " IP_ADDRESS_NEW

read -p "Enter OLD lancache IP address: " IP_ADDRESS_OLD

cd $PATH_UPSTREAMS_AVAILABLE

echo "Finding all instances of $IP_ADDRESS_OLD in config files in upstreams-available/ and replacing with $IP_ADDRESS_NEW"

sed -i "s/$IP_ADDRESS_OLD/$IP_ADDRESS_NEW/g" *

echo "Restarting unbound"

/bin/systemctl restart unbound
