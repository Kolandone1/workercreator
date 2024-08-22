#!/bin/bash

# Update and upgrade Termux packages
pkg update && pkg upgrade -y

# Install proot-distro to manage Linux distributions
pkg install proot-distro -y

# Install Ubuntu
proot-distro install ubuntu

# Login to Ubuntu and install packages
proot-distro login ubuntu -- apt update && \
    apt install nodejs -y && \
    apt-get install jq -y && \
    npm install -g wrangler && \
    exit

# Run the script from the provided URL
bash <(curl -fsSL https://raw.githubusercontent.com/Kolandone/Selector/main/Sel.sh)
