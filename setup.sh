#!/usr/bin/bash

# Store current directory
export CGWIRE=$PWD

# Set environment variables from .env file
export $(grep -v '^#' .env | xargs)

# Ensure system packages
sudo apt -y -qq install docker-compose docker
sudo apt -y -qq install python3 python3-pip
sudo apt -y -qq install git nginx ffmpeg

# Start custom verisons of Redis and Postgres w/ Docker
sudo docker-compose -f files/docker-compose.yaml up -d

# Ensure Zou user
sudo useradd --home /opt/zou zou
sudo mkdir -p /opt/zou

# Create a virtual environemnt in target
sudo pip3 install virtualenv
sudo virtualenv -q /opt/zou/zouenv

# Install Zou globally to get access to the CLI tools
sudo pip3 install -q zou gazu 

# Create Zou controlled folders
sudo mkdir -p /opt/zou/tmp
sudo mkdir -p /opt/zou/logs
sudo mkdir -p /opt/zou/backups
sudo mkdir -p /opt/zou/indexes
sudo mkdir -p /opt/zou/previews
sudo chown -R zou:www-data /opt/zou

# Enable and reload system services
sudo systemctl enable nginx
sudo systemctl restart nginx

# Add project bin to $PATH
if [ -d "./bin" ] && [[ ":$PATH:" != *":./bin:"* ]]; then
    PATH="${PATH:+"$PATH:"}./bin"
    chmod ug+x bin/*
fi

