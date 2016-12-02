#!/bin/bash

# List all installed packages
function installed {
    echo "|--- Installed packages ---|"
    echo "----------------------------------------------" >> /var/log/installed_packages.log
    date >> /var/log/installed_packages.log
    yum list installed >> /var/log/installed_packages.log
    echo "--> done"
   
}

# Update system
function update {
    echo "|--- Updating system ---|"
    echo "----------------------------------------------" >> /var/log/periodic_updates.log
    date >> /var/log/periodic_updates.log
    yum update -y >> /var/log/periodic updates.log
    echo "--> system updated"
}

# Add password to BIOS
function secure_bios {
    echo "|--- Add password to BIOS ---|"
    
}

# Disable USB mass storage
function disable_usb {
    echo "|--- Disabling usb ---|"
    echo "blacklist usb-storage" > /etc/modprobe.d/blacklist-usbstorage
    echo "--> usb disabled"
}

# Restrict root functions
function restrict_root {
    echo "|--- Restrict root ---|"
    # can't login directly as root user, must use su or sudo now
    echi "tty1" > /etc/securetty
    # restrict /root directory to root user
    chmod 700 /root
    echo "--> Root restricted"
    echo "to perform actions as root, login as root with su, or use sudo"
}


