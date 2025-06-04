#!/usr/bin/env bash

export SDM_RELAY_TOKEN=${sdm_relay_token}
export TARGET_USER=${target_user}
export SDM_HOME="/home/$TARGET_USER/.sdm"

# Just in case no access through SDM, add my SSH key
# echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDbSETVxvXNe2G4SAPnuwKlg8HZHjsBNRYJpLCE3zgm2KLdnFF7SC5RXRLghi5Nkqzz3TCSTrWW39ZL/KrDp8NiclCgIZYXIViL5E5eYYIT5y2GAe4bcttULGxM+18Bk4pq1XubTRdPw66an4LBHyS8Wj/T/Ao/Pdzft0htif+1zLZusSro4nm5cw/wuPo7nylkaqDnDM+LHcOP8M9Xajbw53UhJ5hXS6Vv8VwaPRhuKxIMZsUF9f290ylzeEOcd9rZOkVSfBmF3Le/Yw/It5kZB2K2YnpUlp0PdXATr4kYIwB+FnX7/MX289QUHdsZOlkg1cdwaogfudlMRczd9G7T arpi" >> /home/$TARGET_USER/.ssh/authorized_keys
# chmod 600 /home/$TARGET_USER/.ssh/authorized_keys
# chown $TARGET_USER:$TARGET_USER /home/$TARGET_USER/.ssh/authorized_keys

# Inial package installation & upgrade
apt-get update -y | logger -t sdminstall
apt-get upgrade -y | logger -t sdminstall
apt-get install -y unzip | logger -t sdminstall

# Download and install sdm
curl -J -O -L https://app.strongdm.com/releases/cli/linux && unzip sdmcli* && rm sdmcli*
systemctl disable ufw.service
systemctl stop ufw.service
sudo ./sdm install --relay --token=$SDM_RELAY_TOKEN --user=$TARGET_USER| logger -t sdminstall

# Just in case services are not started
systemctl enable sdm.service
systemctl start sdm.service

# Log the relay token and installation success
echo "sdm relay token: $SDM_RELAY_TOKEN" | logger -t sdminstall
echo "sdm installation completed successfully" | logger -t sdminstall
echo "sdm relay token: $SDM_RELAY_TOKEN"
echo "sdm installation completed successfully"