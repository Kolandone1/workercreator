#!/bin/bash

# Update package list and install python
pkg update && pkg upgrade
pkg install -y python

# Install requests module if not already installed
pip install requests
pkg install git
# Clone your repository (replace with your actual repository URL)
git clone https://github.com/Kolandone1/workercreator.git

# Navigate to the script directory
cd workercreator

# Make the Python script executable
chmod +x kol.py

# Create an alias to run the script with the 'koland' command
echo "alias koland='python $(pwd)/kol.py'" >> ~/.bashrc

# Apply the changes to the current session
source ~/.bashrc

echo "Installation complete. You can now run the script using the 'koland' command."
