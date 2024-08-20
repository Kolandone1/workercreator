# Download the script and place it in the $PREFIX/bin directory
curl -o $PREFIX/bin/koland https://raw.githubusercontent.com/Kolandone1/workercreator/main/kol.py

# Make the script executable
chmod +x $PREFIX/bin/koland

# Add a shebang line to the top of your Python script to ensure it runs with Python
sed -i '1i#!/usr/bin/env python' $PREFIX/bin/koland

# Refresh environment
source $PREFIX/etc/profile

echo "Installation complete. You can now run the script using the 'koland' command."
