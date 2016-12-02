#!/bin/bash

# List all installed packages
function installed {
    echo "|--- Installed packages ---|"
    echo "----------------------------------------------" >> /var/log/installed_packages.log
    date >> /var/log/installed_packages.log
    echo "----------------------------------------------" >> /var/log/installed_packages.log
    yum list installed >> /var/log/installed_packages.log
    echo "--> done"
   
}

# Update system
function update {
    echo "|--- Updating system ---|"
    echo "----------------------------------------------" >> /var/log/periodic_updates.log
    date >> /var/log/periodic_updates.log
    echo "----------------------------------------------" >> /var/log/periodic_updates.log
    yum update -y >> /var/log/periodic updates.log
    echo "--> system updated"
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

# Harden password policies
function password_policies {
    echo "|--- Update password policies ---|"
    echo "Passwords expire every 90 days"
    perl -npe 's/PASS_MAX_DAYS\s+99999/PASS_MAX_DAYS 90/' -i /etc/login.defs
    echo "Passwords can be changed twice a day"
    perl -npe 's/PASS_MIN_DAYS\s+0/PASS_MIN_DAYS 2/g' -i /etc/login.defs
    echo "Passwords minimal length is now 8"
    perl -npe 's/PASS_MIN_LEN\s+0/PASS_MIN_LEN 8/g' -i /etc/login.defsi
    echo "Changing password encryption type to sha512"
    authconfig --passalgo=sha512 --update
    echo "--> done"
}

# Change umask to 077
function change_umask {
    echo "|--- Change umask ---|"
    perl -npe 's/umask\s+0\d2/umask 077/g' -i /etc/bashrc
    perl -npe 's/umask\s+0\d2/umask 077/g' -i /etc/csh.cshrc
    echo "--> done"
}

# Change PAM to harden auth through apps
function change_pam {
    
}

# kick inactive users after 20 minutes
function kick_off {
    echo "|--- Kick inactive users after 20 min. ---|"
    echo "readonly TMOUT=1200" >> /etc/profile.d/os-security.sh
    echo "readonly HISTFILE" >> /etc/profile.d/os-security.sh
    chmod +x /etc/profile.d/os-security.sh
    echo "--> property added"
}

# Restrict the use of cron and at to root user
function restrict_cron_at {
    echo "|--- Restrict cron and at ---|"
    echo "Lock cron"
    touch /etc/cron.allow
    chmod 600 /etc/cron.allow
    awk -F: '{print $1}' /etc/passwd | grep -v root > /etc/cron.deny
    echo "Lock AT"
    touch /etc/at.allow
    chmod 600 /etc/at.allow
    awk -F: '{print $1}' /etc/passwd | grep -v root > /etc/at.deny
    echo "--> done"
    echo "to allow users to do cron jobs, add then to /etc/cron.allow"
}


