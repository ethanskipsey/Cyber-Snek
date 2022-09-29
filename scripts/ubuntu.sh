#!/bin/bash

# Ubuntu Security Script
# Ethan Skipsey, Samuel Thompson

if [[ $EUID -ne 0 ]]
then
  echo "You must be root to run this script."
  exit 1
fi

# Lock Out Root User
passwd -l root

# Remove Guest Account
echo 'allow-guest=false' >> /etc/lightdm/lightdm.conf

# Delete Unauthorised Files
for suffix in mp3 txt wav wma aac mp4 mov avi gif jpg png bmp img exe msi bat
do
  find /home -name *.$suffix -delete
done

# Write Running Processes to a File on the Desktop
ps -ef | cut -c 50- > processes.txt

# Write Users and Groups to a File on the Desktop
cat /etc/passwd | grep home | cut -d ':' -f 1 > users.txt
cat /etc/group | grep 'adm\|su' >> users.txt
cat /etc/shadow | awk -F: '($2==""){print $1}' >> users.txt

# Update Repositories
version=$(lsb_release -a | grep Codename: | cut -d ':' -f 2 | awk '{$1=$1};1')
echo 'deb http://au.archive.ubuntu.com/ubuntu/ '$version' main' > /etc/apt/sources.list
echo 'deb http://au.archive.ubuntu.com/ubuntu/ '$version'-updates main' > /etc/apt/sources.list
echo 'deb http://au.archive.ubuntu.com/ubuntu/ '$version'-security main' > /etc/apt/sources.list
echo 'deb-src http://au.archive.ubuntu.com/ubuntu/ '$version' main' >> /etc/apt/sources.list
echo 'deb-src http://au.archive.ubuntu.com/ubuntu/ '$version'-updates main' >> /etc/apt/sources.list
echo 'deb-src http://au.archive.ubuntu.com/ubuntu/ '$version'-security main' >> /etc/apt/sources.list

# Updates
apt -y update
apt -y upgrade
apt -y dist-upgrade

# Firewall
apt -y install ufw
ufw enable

# Secure Shadow File
chmod 640 /etc/shadow

# Secure Network Configuration
sed -i '/rp_filter/ c\net/ipv4/conf/all/rp_filter = 1' /etc/sysctl.conf
sed -i '/accept_redirects/ c\net/ipv4/conf/all/accept_redirects = 0' /etc/sysctl.conf
sed -i '/send_redirects/ c\net/ipv4/conf/all/send_redirects = 0' /etc/sysctl.conf

# Configure Password Aging Controls
sed -i '/^PASS_MAX_DAYS/ c\PASS_MAX_DAYS   90' /etc/login.defs
sed -i '/^PASS_MIN_DAYS/ c\PASS_MIN_DAYS   10'  /etc/login.defs
sed -i '/^PASS_WARN_AGE/ c\PASS_WARN_AGE   7' /etc/login.defs

# Password Authentication
sed -i '1 s/^/auth optional pam_tally.so deny=5 unlock_time=900 onerr=fail audit even_deny_root_account silent\n/' /etc/pam.d/common-auth

# Force Strong Passwords
apt -y install libpam-cracklib
sed -i '1 s/^/password requisite pam_cracklib.so retry=3 minlen=8 difok=3 reject_username minclass=3 maxrepeat=2 dcredit=1 ucredit=1 lcredit=1 ocredit=1\n/' /etc/pam.d/common-password

# MySQL
echo -n "MySQL [Y/n] "
read option
if [[ $option =~ ^[Yy]$ ]]
then
  apt -y install mysql-server
  # Disable remote access
  sed -i '/bind-address/ c\bind-address = 127.0.0.1' /etc/mysql/my.cnf
  systemctl restart mysql
else
  apt -y purge mysql*
fi

# OpenSSH Server
echo -n "OpenSSH Server [Y/n] "
read option
if [[ $option =~ ^[Yy]$ ]]
then
  apt -y install openssh-server
  # Disable Root Login
  sed -i '/^PermitRootLogin/ c\PermitRootLogin no' /etc/ssh/sshd_config
  # Allow Through Firewall
  ufw allow ssh
  systemctl restart ssh
else
  apt -y purge openssh-server*
fi

# VSFTPD
echo -n "VSFTP [Y/n] "
read option
if [[ $option =~ ^[Yy]$ ]]
then
  apt -y install vsftpd
  # Disable anonymous uploads
  sed -i '/^anon_upload_enable/ c\anon_upload_enable no' /etc/vsftpd.conf
  sed -i '/^anonymous_enable/ c\anonymous_enable=NO' /etc/vsftpd.conf
  # FTP user directories use chroot
  sed -i '/^chroot_local_user/ c\chroot_local_user=YES' /etc/vsftpd.conf
  systemctl restart vsftpd
else
  apt -y purge vsftpd*
fi

# Bastille
echo -n "Bastille [Y/n] "
read option
if [[ $option =~ ^[Yy]$ ]]
then
  apt-get install bastille
  bastille -x
fi

# Malware/Hacking Tools
for program in netcat nmap zenmap ptunnel wireshark john burpsuite metasploit aircrack-ng sqlmap autopsy setoolkit lynis wpscan hydra skipfish maltego nessus beef apktool snort nikto yersinia stmpd rsync
do 
  apt -y purge $program*
done