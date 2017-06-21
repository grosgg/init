#!/bin/bash

# Ask for username
read -p 'Enter username: ' username

# Create user and make it a sudoer
adduser $username
usermod -aG sudo $username

# SSH keys
su $username -c "mkdir ~/.ssh && chmod 700 ~/.ssh && cd ~/.ssh && wget https://raw.githubusercontent.com/grosgg/init/master/authorized_keys"

# Disable password authentication
sed -i -e 's/PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
systemctl reload sshd

# Allow SSH and enable firewall
ufw allow OpenSSH
ufw enable
ufw status