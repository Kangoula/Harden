#!/bin/bash

#TODO Pam 'Module unkown'
#TODO semanage not found
#TODO find no such file
#TODO ssh not changing port

# simple function to display the date in a file
display_date()
{
    echo "--------------------------------------" >> $1
    date +%Y%m%d-%H:%M >> $1
    echo "--------------------------------------" >> $1
}

# List all installed packages
installed()
{
    echo "Installed packages"
    display_date /var/log/installed_packages.log
    yum list installed >> /var/log/installed_packages.log
    echo "--> done"
   
}

repo_list()
{
    echo "Repositories List"
    display_date /var/log/repo_list.log
    yum repolist >> /var/log/repo_list.log
    echo "--> done"
}

# Update system
update()
{
    echo "Updating system"
    display_date /var/log/periodic_updates.log
    yum update -y >> /var/log/periodic_updates.log
    echo "--> done"
}

# Disable USB mass storage
disable_usb()
{
    echo "Disabling usb"
    echo "blacklist usb-storage" > /etc/modprobe.d/blacklist-usbstorage
    echo "--> done"
}

# Restrict root functions
restrict_root()
{
    echo "Restrict root"
    # can't login directly as root user, must use su or sudo now
    echo "tty1" > /etc/securetty
    # disable ssh root login
    echo "Disable Root SSH Login"
     's/#PermitRootLogin no/PermitRootLogin no/g' /etc/ssh/sshd_config
    # restrict /root directory to root user
    chmod 700 /root
    echo "--> done"
    echo "to perform actions as root, login as root with su, or use sudo"
}

# Harden password policies
password_policies()
{
    echo "Update password policies"
    echo "Passwords expire every 90 days"
    sed -i 's/PASS_MAX_DAYS\s+99999/PASS_MAX_DAYS 90/' /etc/login.defs
    echo "Passwords can be changed twice a day"
    sed -i 's/PASS_MIN_DAYS\s+0/PASS_MIN_DAYS 2/g' /etc/login.defs
    echo "Passwords minimal length is now 8"
    sed -i 's/PASS_MIN_LEN\s+0/PASS_MIN_LEN 8/g' /etc/login.defs
    echo "Changing password encryption type to sha512"
    authconfig --passalgo=sha512 --update
    echo "--> done"
}

# Change umask to 077
change_umask()
{
    echo "Change umask"
    sed -i 's/umask\s+0\d2/umask 077/g' /etc/bashrc
    sed -i 's/umask\s+0\d2/umask 077/g' /etc/csh.cshrc
    echo "--> done"
}

# Change PAM to harden auth through apps
change_pam()
{
    echo "Change PAM"
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
session     required      pam_unix.so' > /etc/pam.d/system-auth
    echo "--> done"
}

# kick inactive users after 20 minutes
kick_off()
{
    echo "Kick inactive users after 20 min."
    echo "readonly TMOUT=1200">> /etc/profile.d/os-security.sh
    echo "readonly HISTFILE" >> /etc/profile.d/os-security.sh
    chmod +x /etc/profile.d/os-security.sh
    echo "--> done"
}

# Restrict the use of cron and at to root user
restrict_cron_at()
{
    echo "Restrict cron and at"
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
list_permissions()
{
    # setuid allow to use files as root but logged as normal user
    # list setuid files
    echo "Listing setuid files"
    display_date /var/log/suid.log
    find / -perm -4000 >> /var/log/suid.log
    # setgid is the same as stuid but for groups
    # list setgid files
    echo "Listing setgid files"
    display_date /var/log/sgid.log
    find / -perm -2000 >> /var/log/sgid.log
    # sticky bit : if there is a sticky bit on a runnable file, the file will stay in memory
    # if sticky bit is positioned on a directory it can secure write access to this directory
    # example : /tmp where everyone can write but we do't wan't other users to access our files.
    echo "Listing sticky bit"
    display_date /var/log/stickybit.log
    find / -perm -1000 >> /var/log/stickybit.log
    echo "--> done"

}

# List files others can use
find_other_perm()
{
    echo "Find Permissions to Others"
    display_date /var/log/other_permissions.log
    find / -perm -o=rwx >> /var/log/other_permissions.log
    echo "--> done"
}

# check selinux status
check_selinux()
{
    echo "Check SELinux"
    display_date /var/log/selinux_status.log
    sestatus >> /var/log/selinux_status.log
    echo "--> done"
}

random_ssh_port()
{
    # randomize port between 9000 and 50000
    random_port=$((9000 + RANDOM % 50000))
    sed -i "s/Port 22/Port $random_port/g" /etc/ssh/sshd_config
    # tell SELinux about port change
    semanage -port -a -t ssh_port_t -p tcp $random_port
    systemctl restart sshd
    echo "--> done"
    echo "New SSH Port: $random_port"
}


main()
{
    if [ "$(id -u)" != "0" ]; then
        echo "This script must be run as root" 1>&2
        exit 1
    fi

    if [[ $# = 0 ]]; then
        echo "no args provided, using default config"
        # launching functions
        installed
        repo_list
        update
        disable_usb
        restrict_root
        password_policies
        change_umask
        change_pam
        kick_off
        restrict_cron_at
        list_permissions
        find_other_perm
        check_selinux
        random_ssh_port
    else
        # handle command line args
        key="$1"
        if [[ $key = "-f" ]]; then
            shift # pass argument 1
            # for each argument
            for arg in "$@"
            do
                case $arg in
                    installed)
                        installed
                        ;;
                    repo_list)
                        repo_list
                        ;;
                    update)
                        update
                        ;;
                    disable_usb)
                        disable_usb
                        ;;
                    restrict_root)
                        restrict_root
                        ;;
                    password_policies)
                        password_policies
                        ;;
                    change_umask)
                        change_umask
                        ;;
                    change_pam)
                        change_pam
                        ;;
                    kick_off)
                        kick_off
                        ;;
                    restrict_cron_at)
                        restrict_cron_at
                        ;;
                    list_permissions)
                        list_permissions
                        ;;
                    find_other_perm)
                        find_other_perm
                        ;;
                    check_selinux)
                        check_selinux
                        ;;
                    random_ssh_port)
                        random_ssh_port
                        ;;
                    *)
                        echo "unrecognized function: $arg"
                esac
            done
        else
            echo "error, unrecognized option: $key"
        fi
    fi
}

main $@
