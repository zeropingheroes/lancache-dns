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

# Create unbound config files from templates
for UPSTREAM_CONFIG in $SCRIPT_DIR/upstreams-available/*.templ; do /usr/bin/envsubst '$LANCACHE_IP' < $UPSTREAM_CONFIG > ${UPSTREAM_CONFIG/.templ/}; done

# Move generated config files into place
mkdir -p /etc/unbound/upstreams-available
mv $SCRIPT_DIR/upstreams-available/*.conf /etc/unbound/upstreams-available/

# Enable all upstreams
mkdir -p /etc/unbound/upstreams-enabled
ln -fs /etc/unbound/upstreams-available/* /etc/unbound/upstreams-enabled/

# Set the unbound service to start at boot
/bin/systemctl enable unbound

# Start the unbound service
/bin/systemctl restart unbound
