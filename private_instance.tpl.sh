#!/usr/bin/env bash
yum update -y | logger -t sdminstall

TARGET_USER=${target_user}

SDM_CA="/etc/ssh/sdm_ca.pub"
SDM_USERS="/etc/ssh/sdm_users"
TARGET_USER_CONF=$SDM_USERS/$TARGET_USER
SSHD_CONFIG="/etc/ssh/sshd_config"

echo "Creating SSHCA as $SDM_CA" | logger -t sdminstall
echo "${sshca}" >  $SDM_CA
chmod 400 $SDM_CA
chown root:root $SDM_CA

echo "Reconfiguring SSHD" | logger -t sdminstall
echo "TrustedUserCAKeys $SDM_CA" >> $SSHD_CONFIG
echo "AuthorizedPrincipalsFile $SDM_USERS/%u" >> $SSHD_CONFIG

echo "Enabling $TARGET_USER to login using SSH CA" | logger -t sdminstall
mkdir $SDM_USERS
chmod 711 $SDM_USERS # Ensure directory is accessible to $TARGET_USER (sshd switches to $TARGET_USER)
echo "strongdm" > $TARGET_USER_CONF
chmod 644 $TARGET_USER_CONF # Ensure file is accessible to $TARGET_USER (sshd switches to $TARGET_USER)

echo "Restarting SSHD" | logger -t sdminstall
systemctl restart sshd

echo "StrongDM target configuration done" | logger -t sdminstall
