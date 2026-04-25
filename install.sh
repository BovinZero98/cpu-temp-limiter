#!/bin/bash

# Linux Temp Limiter Installer
# This script must be run with sudo

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)"
   exit 1
fi

echo "Checking dependencies..."
# Update apt if needed and install dependencies
apt-get update -qq
apt-get install -y python3 python3-gi gir1.2-gtk-3.0 gir1.2-ayatanaappindicator3-0.1

echo "Installing scripts to /usr/local/bin/..."
cp src/temp-limiter-daemon /usr/local/bin/
cp src/temp-limiter-ui /usr/local/bin/
chmod +x /usr/local/bin/temp-limiter-daemon
chmod +x /usr/local/bin/temp-limiter-ui

echo "Setting up configuration file..."
if [ ! -f /etc/temp-limiter.conf ]; then
    cp temp-limiter.conf /etc/temp-limiter.conf
fi

# Create group if it doesn't exist
if ! getent group temp-limiter > /dev/null; then
    groupadd temp-limiter
    echo "Created group: temp-limiter"
fi

# Set permissions for the config file
chown root:temp-limiter /etc/temp-limiter.conf
chmod 664 /etc/temp-limiter.conf

# Add the user who called sudo to the group
if [ -n "$SUDO_USER" ]; then
    usermod -aG temp-limiter "$SUDO_USER"
    echo "Added user $SUDO_USER to temp-limiter group"
else
    echo "Warning: Could not determine original user. You may need to manually add yourself to the 'temp-limiter' group."
fi

echo "Installing systemd service..."
cp temp-limiter.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable temp-limiter.service
systemctl start temp-limiter.service

echo "Installing icon..."
mkdir -p /usr/share/icons/hicolor/scalable/apps/
cp temp-limiter.svg /usr/share/icons/hicolor/scalable/apps/
gtk-update-icon-cache /usr/share/icons/hicolor/ || true

echo "Setting up autostart..."
AUTOSTART_DIR="/etc/xdg/autostart"
mkdir -p "$AUTOSTART_DIR"
cp temp-limiter-ui.desktop "$AUTOSTART_DIR/"

echo "-------------------------------------------------------"
echo "Installation complete!"
echo "The daemon is now running and will limit CPU temp."
echo "The UI will start automatically on next login."
echo "You can start it manually now by running: temp-limiter-ui"
echo "NOTE: You might need to log out and back in for group changes to take effect."
echo "-------------------------------------------------------"
