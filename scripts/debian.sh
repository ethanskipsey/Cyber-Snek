#!/bin/bash

# Debian Security Script
# Ethan Skipsey, Samuel Thompson

if [[ $EUID -ne 0 ]]
then
	echo 'You must be root to run this script.'
	exit 1
fi

# Create A Root Password
passwd root

# Delete Unauthorised Files
for suffix in mp3 txt wav wma aac mp4 mov avi gif jpg png bmp img exe msi bat sh
do
  find /home -name *.$suffix -delete
done

# Write Running Processes to a File on the Desktop
ps -ef | cut -c 50- > processes.txt

# Write Users and Groups to a File on the Desktop
cat /etc/passwd | grep home | cut -d ':' -f 1 > users.txt
cat /etc/group | grep 'adm\|su' >> users.txt

# Update Repositories List
version=$(lsb_release -a | grep Codename: | cut -d ':' -f 2 | awk '{$1=$1};1')
echo 'deb http://deb.debian.org/debian '$version' main' > /etc/apt/sources.list
echo 'deb http://deb.debian.org/debian '$version'-updates main' >> /etc/apt/sources.list
echo 'deb http://deb.debian.org/debian-security/ '$version'-security main' >> /etc/apt/sources.list
echo 'deb-src http://deb.debian.org/debian '$version' main' >> /etc/apt/sources.list
echo 'deb-src http://deb.debian.org/debian '$version'-updates main' >> /etc/apt/sources.list
echo 'deb-src http://deb.debian.org/debian-security/ '$version'-security main' >> /etc/apt/sources.list

# Update And Upgrade Packages
apt -y update
apt -y upgrade 
apt -y dist-upgrade

# Firewall
apt -y install ufw
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

# Secure Network Configuration
sed -i '/rp_filter/ c\net/ipv4/conf/all/rp_filter = 1' /etc/sysctl.conf
sed -i '/accept_redirects/ c\net/ipv4/conf/all/accept_redirects = 0' /etc/sysctl.conf
sed -i '/send_redirects/ c\net/ipv4/conf/all/send_redirects = 0' /etc/sysctl.conf

# RKHunter
apt -y install rkhunter 
rkhunter --update
rkhunter --check

# Auditd
# apt -y install auditd
# auditctl -e 1

# MySQL
echo -n 'MySQL [Y/n]'
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
  # Allow SSH Through Firewall
  ufw allow ssh
  systemctl restart ssh
  systemctl restart sshd
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

# Pure-FTPd
echo -n 'Pure-FTPd [Y/n] '
read option
if [[ $option =~ ^[Yy]$ ]]
then
	apt -y install pure-ftpd
else
	apt -y purge pure-ftpd*
fi

# Apache

# Malware/Hacking Tools
for program in netcat nmap zenmap ptunnel wireshark john burpsuite metasploit aircrack-ng sqlmap autopsy setoolkit lynis wpscan hydra skipfish maltego nessus beef apktool snort nikto yersinia stmpd rsync
do 
  apt -y purge $program*
done