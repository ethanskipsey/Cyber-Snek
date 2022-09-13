#!/bin/bash

# Ubuntu Security Script
# Ethan Skipsey, Samuel Thompson

if [[ $EUID -ne 0 ]]
then 
	echo 'You must be root to run this script.'
	exit 1
fi 

# Lock Out Root User
passwd -l root

# Disable Guest Account
echo 'allow-guest=false' >> /etc/lightdm/lightdm.conf

# Write Users to a File on the Desktop
cat /etc/passwd | 
cat /etc/shadow | awk -F: '($2==""){print $1}'

