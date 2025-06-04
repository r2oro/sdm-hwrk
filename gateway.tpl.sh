#!/usr/bin/env bash

SDM_RELAY_TOKEN=${sdm_relay_token}
TARGET_USER=${target_user}

SDM_CA="/etc/ssh/sdm_ca.pub"
SDM_USERS="/etc/ssh/sdm_users"
TARGET_USER_CONF=$SDM_USERS/$TARGET_USER
SSHD_CONFIG="/etc/ssh/sshd_config.d/100-strongdm.conf"

export SDM_HOME="/home/$TARGET_USER/.sdm"

# Inial package installation & upgrade
apt-get update -y | logger -t sdminstall
apt-get upgrade -y | logger -t sdminstall
apt-get install -y unzip | logger -t sdminstall

# Download and install sdm
echo "Downloading SDM Gateway" | logger -t sdminstall
curl -J -O -L https://app.strongdm.com/releases/cli/linux && unzip sdmcli* && rm sdmcli*
systemctl disable ufw.service
systemctl stop ufw.service
echo "Installing SDM Gateway" | logger -t sdminstall
./sdm install --relay --token=$SDM_RELAY_TOKEN --user=$TARGET_USER| logger -t sdminstall

# Just in case services are not started
systemctl enable sdm.service
systemctl start sdm.service

echo "Creating SSHCA as $SDM_CA" | logger -t sdminstall
echo "${sshca}" >  $SDM_CA
chmod 400 $SDM_CA
chown root:root $SDM_CA

echo "Reconfiguring SSHD" | logger -t sdminstall
echo "TrustedUserCAKeys $SDM_CA" >> $SSHD_CONFIG
echo "AuthorizedPrincipalsFile $SDM_USERS/%u" >> $SSHD_CONFIG
chmod 600 $SSHD_CONFIG 

echo "Enabling $TARGET_USER to login using SSH CA" | logger -t sdminstall
mkdir $SDM_USERS
chmod 711 $SDM_USERS # Ensure directory is accessible to $TARGET_USER (sshd switches to $TARGET_USER)
echo "strongdm" > $TARGET_USER_CONF
chmod 644 $TARGET_USER_CONF # Ensure file is accessible to $TARGET_USER (sshd switches to $TARGET_USER)

echo "Restarting SSHD" | logger -t sdminstall
systemctl restart sshd

# Log the relay token and installation success
echo "sdm installation completed successfully" | logger -t sdminstall
