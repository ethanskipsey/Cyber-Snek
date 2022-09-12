#!/bin/bash

# Debian Security Script
# Ethan Skipsey

if [[ $EUID -ne 0 ]]
then
	echo "You must be root to run this script."
	exit 1
fi

# Delete Unauthorised Files
for suffix in mp3 txt wav wma aac mp4 mov avi gif jpg png bmp img exe msi bat sh
do
  find /home -name *.$suffix -delete
done

# Write Users and Groups to a File on the Desktop
cat /etc/passwd | grep home | cut -d ';' -f 1 > users.txt
cat /etc/group | grep 'adm\su' >> users.txt

# Update Repositories List
echo -e 'deb http://deb.debian.org/debian/ buster main' > /etc/apt/sources.list
echo -e 'deb-src http://deb.debian.org/debian/ buster main' >> /etc/apt/sources.list
echo -e 'deb http://deb.debian.org/debian/ buster-updates main' >> /etc/apt/sources.list
echo -e 'deb-src http://deb.debian.org/debian/ buster-updates main' >> /etc/apt/sources.list
echo -e 'deb http://security.debian.org/debian-security buster/updates main' >> /etc/apt/sources.list
echo -e 'deb-src http://security.debian.org/debian-security buster/updates main' >> /etc/apt/sources.list

# Update And Upgrade Packages
apt -y update
apt -y upgrade 
apt -y dist-upgrade

# Firewall
apt install ufw
ufw enable 

# Configure Password Aging Control
sed -i '/^PASS_MAX_DAYS/ c\PASS_MAX_DAYS   30' /etc/login.defs
sed -i '/^PASS_MIN_DAYS/ c\PASS_MIN_DAYS   10'  /etc/login.defs
sed -i '/^PASS_WARN_AGE/ c\PASS_WARN_AGE   7' /etc/login.defs

# Configure Password Authentification
sed -i '1 i auth required pam_tally.so deny=5 unlock_time=900 onerr=fail audit even_deny_root_account silent' /etc/pam.d/common-auth

# Force Strong Passwords
apt -y install libpam-pwquality
sed -i '/password   requisite   pam_pwquality.so retry=3/ c\password   requisite   pam_pwquality.so retry=3 minlen=12 maxrepeat=3 ucredit=1 lcredit=1 dcredit=1 ocredit=1 difok=4 reject_username enforce_for_root'

# Configure Permissions for /etc/shadow
chmod 640 /etc/shadow

# RKHunter
apt -y install rkhunter 
rkhunter --update
rkhunter --check

# MySQL
echo -n "MySQL [Y/n] "
read option
if [[ $option =~ ^[Yy]$ ]]
then
  apt -y install mysql-server
  # Disable Remote Access
  sed -i '/bind-address/ c\bind-address = 127.0.0.1' /etc/mysql/my.cnf
  systemctl restart mysql
else
  apt -y purge mysql*
fi

# OpenSSH
echo -n 'OpenSSH [Y/n] '
read option
if [[ $option =~ ^[Yy]$ ]]
then
  apt -y install openssh-server
  # Disable Root Login
  sed -i '/^PermitRootLogin/ c\PermitRootLogin no' /etc/ssh/sshd_config
  # Disable X11 Forwarding
  sed -i '/X11Forwarding/ c\X11Fowarding no' /etc/ssh/sshd_config
  systemctl restart ssh
else
  apt -y purge openssh-server*
fi

# VSFTPD
echo -n 'VSFTP [Y/n] '
read option
if [[ $option =~ ^[Yy]$ ]]
then
  apt -y install vsftpd
  # Disable Anonymous Uploads
  sed -i '/^anon_upload_enable/ c\anon_upload_enable no' /etc/vsftpd.conf
  sed -i '/^anonymous_enable/ c\anonymous_enable=NO' /etc/vsftpd.conf
  # FTP User Directories Use Chroot
  sed -i '/^chroot_local_user/ c\chroot_local_user=YES' /etc/vsftpd.conf
  systemctl restart vsftpd
else
  apt -y purge vsftpd*
fi

# PureFTP
echo -n 'PureFTP [Y/n] '
read option
if [[ $option =~ ^[Yy]$ ]]
then
	apt -y install pure-ftpd
else
	apt -y purge pure-ftpd*
fi

# Apache

# Malware/Hacking Tools
for program in netcat nmap zenmap ptunnel wireshark john burpsuite metasploit aircrack-ng sqlmap autopsy setoolkit lynis wpscan hydra skipfish maltego nessus beef apktool snort nikto yersinia 
do 
  apt -y purge $program*
done

