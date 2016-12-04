#!/bin/bash

# simple function to display the date in a file
function display_date()
{
    echo "--------------------------------------" >> $1
    date >> $1
    echo "--------------------------------------" >> $1
}

# List all installed packages
function installed()
{
    echo "|--- Installed packages ---|"
    display_date /var/log/installed_packages.log
    yum list installed >> /var/log/installed_packages.log
    echo "--> done"
   
}

# Update system
function update()
{
    echo "|--- Updating system ---|"
    display_date /var/log/periodic_updates.log
    yum update -y >> /var/log/periodic updates.log
    echo "--> system updated"
}

# Disable USB mass storage
function disable_usb()
{
    echo "|--- Disabling usb ---|"
    echo "blacklist usb-storage" > /etc/modprobe.d/blacklist-usbstorage
    echo "--> usb disabled"
}

# Restrict root functions
function restrict_root()
{
    echo "|--- Restrict root ---|"
    # can't login directly as root user, must use su or sudo now
    echo "tty1" > /etc/securetty
    # disable ssh root login
    perl -npe 's/#PermitRootLogin no/PermitRootLogin no/g' -i /etc/ssh/sshd_config
    # restrict /root directory to root user
    chmod 700 /root
    echo "--> Root restricted"
    echo "to perform actions as root, login as root with su, or use sudo"
}

# Harden password policies
function password_policies()
{
    echo "|--- Update password policies ---|"
    echo "Passwords expire every 90 days"
    perl -npe 's/PASS_MAX_DAYS\s+99999/PASS_MAX_DAYS 90/' -i /etc/login.defs
    echo "Passwords can be changed twice a day"
    perl -npe 's/PASS_MIN_DAYS\s+0/PASS_MIN_DAYS 2/g' -i /etc/login.defs
    echo "Passwords minimal length is now 8"
    perl -npe 's/PASS_MIN_LEN\s+0/PASS_MIN_LEN 8/g' -i /etc/login.defs
    echo "Changing password encryption type to sha512"
    authconfig --passalgo=sha512 --update
    echo "--> done"
}

# Change umask to 077
function change_umask()
{
    echo "|--- Change umask ---|"
    perl -npe 's/umask\s+0\d2/umask 077/g' -i /etc/bashrc
    perl -npe 's/umask\s+0\d2/umask 077/g' -i /etc/csh.cshrc
    echo "--> done"
}

# Change PAM to harden auth through apps
function change_pam()
{
    echo "|--- Change PAM ---|"
    echo -e '#%PAM-1.0
# This file is auto-generated.
# User changes will be destroyed the next time authconfig is run.
auth        required      pam_env.so
auth        sufficient    pam_unix.so nullok try_first_pass
auth        requisite     pam_succeed_if.so uid >= 500 quiet
auth        required      pam_deny.so
auth        required      pam_tally2.so deny=3 onerr=fail unlock_time=60

account     required      pam_unix.so
account     sufficient    pam_succeed_if.so uid < 500 quiet
account     required      pam_permit.so
account     required      pam_tally2.so per_user

password    requisite     pam_cracklib.so try_first_pass retry=3 minlen=9 lcredit=-2 ucredit=-2 dcredit=-2 ocredit=-2
password    sufficient    pam_unix.so sha512 shadow nullok try_first_pass use_authtok remember=10
password    required      pam_deny.so

session     optional      pam_keyinit.so revoke
session     required      pam_limits.so
session     [success=1 default=ignore] pam_succeed_if.so service in crond quiet use_uid
session     required      pam_unix.si' > /etc/pam.d/system-auth
    echo "--> done"
}

# kick inactive users after 20 minutes
function kick_off()
{
    echo "|--- Kick inactive users after 20 min. ---|"
    echo "readonly TMOUT=1200" >> /etc/profile.d/os-security.sh
    echo "readonly HISTFILE" >> /etc/profile.d/os-security.sh
    chmod +x /etc/profile.d/os-security.sh
    echo "--> property added"
}

# Restrict the use of cron and at to root user
function restrict_cron_at()
{
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
 
# list files and directories with suid, sgid and sticky bit
function list_permissions()
{
    # setuid allow to use files as root but logged as normal user
    # list setuid files
    echo "|--- Listing setuid files ---|"
    display_date /var/log/suid.log
    find / -perm -4000 >> /var/log/suid.log
    # setgid is the same as stuid but for groups
    # list setgid files
    echo "|--- Listing setgid files ---|"
    display_date /var/log/sgid.log
    find / -perm -2000 >> /var/log/sgid.log
    # sticky bit : if there is a sticky bit on a runnable file, the file will stay in memory
    # if sticky bit is positioned on a directory it can secure write access to this directory
    # example : /tmp where everyone can write but we do't wan't other users to access our files.
    echo "|--- Listing sticky bit ---|"
    display_date /var/log/stickybit.log
    find / -perm -1000 >> /var/log/stickybit.log
    echo "--> done"

}

# List files others can use
function find_other_perm()
{
    echo "|--- Find Permissions to Others ---|"
    display_date /var/log/other_permissions.log
    find / -perm -o=rwx >> /var/log/other_permissions.log
    echo "--> done"
}

#TODO Capabilities
#TODO DAC, MAC, RBAC ??
#TODO SELINUX

#TODO faire des diffs avec les fichiers de log déjà présents pour voir ce qui a changé et enregistrer seulement ces diffs dans les fichiers de log

#TODO Installer ufw
#TODO changer le port ssh
#TODO vérifier que seul root puisse lancer le script
