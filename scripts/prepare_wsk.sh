#!/bin/bash

# First check that wsk is installed, if not continue
if ! command -v wsk &> /dev/null
then
    echo "wsk could not be found. Proceeding with installation"
else
    echo "wsk is already installed. Setting apihost property"
    HOST="$(awk 'NR==2 {print $2}' ./ansible/hosts.ini | cut -d'=' -f2)"
    wsk -i property set --apihost ${HOST}:31001 --auth 23bc46b1-71f6-4ed5-8c54-816aa4f8c502:123zO3xZCLrMN6v2BKK1dXYFpXlPkccOFqm12CdAsMgRU4VrNZ9lyGVCGuMDGIwP
    exit
fi

# Determine the system architecture
ARCH=$(uname -m)

# Define the GitHub release URL based on the system architecture
if [ "$ARCH" == "aarch64" ]; then
    RELEASE_URL="https://github.com/apache/openwhisk-cli/releases/download/1.2.0/OpenWhisk_CLI-1.2.0-linux-arm64.tgz"
else
    RELEASE_URL="https://github.com/apache/openwhisk-cli/releases/download/1.2.0/OpenWhisk_CLI-1.2.0-linux-amd64.tgz"
fi

# Download the release
curl -LO $RELEASE_URL

# Extract the downloaded archive
tar -xzf OpenWhisk_CLI-1.2.0-*.tgz

# Clean up the downloaded archive
rm OpenWhisk_CLI-1.2.0-*.tgz

# Move the extracted binary to a desired location
mv wsk /usr/local/bin/


HOST="$(awk 'NR==2 {print $2}' ./ansible/hosts.ini | cut -d'=' -f2)"
wsk -i property set --apihost ${HOST}:31001 --auth 23bc46b1-71f6-4ed5-8c54-816aa4f8c502:123zO3xZCLrMN6v2BKK1dXYFpXlPkccOFqm12CdAsMgRU4VrNZ9lyGVCGuMDGIwP