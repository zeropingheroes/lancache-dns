#!/bin/bash

# Exit if there is an error
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# If script is executed as an unprivileged user
# Execute it as superuser, preserving environment variables
if [ $EUID != 0 ]; then
    sudo -E "$0" "$@"
    exit $?
fi

# If there is an .env file use it
# to set the variables
if [ -f $SCRIPT_DIR/.env ]; then
    source $SCRIPT_DIR/.env
fi

# If an IP is not set, use the machine's first IP
if [ -z $LANCACHE_IP ]; then
   export LANCACHE_IP=$(hostname -I | cut -d' ' -f1)
fi

# Check all required variables are set
: "${LANCACHE_IP:?must be set}"

# Install required packages
/usr/bin/apt update -y
/usr/bin/apt install -y unbound

# Rename default unbound main config file
cd /etc/unbound && mv unbound.conf unbound.conf.example

# Install lancache unbound main config file
cp $SCRIPT_DIR/unbound.conf /etc/unbound/unbound.conf

# Prepare the upstreams config directory
mkdir -p /etc/unbound/upstreams-available

# Get domains from `uklans/cache-domains` GitHub repo
rm -rf /var/git/lancache-cache-domains
/usr/bin/git clone https://github.com/uklans/cache-domains.git /var/git/lancache-cache-domains

# Set the upstreams we want to create unbound config files from
declare -a UPSTREAMS=("blizzard" "origin" "riot" "steam" "windowsupdates")

# Loop through each upstream file in turn
for UPSTREAM in "${UPSTREAMS[@]}"
do
    UPSTREAM_CONFIG_FILE="/etc/unbound/upstreams-available/$UPSTREAM.conf"

    # Add the starting block to the config file
    echo "server:" > ${UPSTREAM_CONFIG_FILE}

    # Read the upstream file line by line
    while read -r LINE;
    do
        # Skip line if it is a comment
        if [[ ${LINE:0:1} == '#' ]]; then
            continue
        fi

        # Check if hostname is a wildcard
        if [[ $LINE == *"*"* ]]; then

            # Remove the asterix and the dot from the start of the hostname
            LINE=${LINE/#\*./}

            # Add a wildcard config line
            echo "local-zone: \"${LINE}.\" redirect" >> ${UPSTREAM_CONFIG_FILE}
        fi

        # Add a standard A record config line
        echo "local-data: \"${LINE}. A $LANCACHE_IP\"" >> ${UPSTREAM_CONFIG_FILE}

    done < /var/git/lancache-cache-domains/$UPSTREAM.txt
done

# Enable all upstreams
mkdir -p /etc/unbound/upstreams-enabled
ln -fs /etc/unbound/upstreams-available/* /etc/unbound/upstreams-enabled/

# Set the unbound service to start at boot
/bin/systemctl enable unbound

# Start the unbound service
/bin/systemctl restart unbound
