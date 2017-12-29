#!/bin/bash
echo 'Updating System Packages'
sudo apt-get update && apt-get dist-upgrade
echo 'Updating SmarthomeNG Master'
cd /usr/local/smarthome
sudo git pull
cd /usr/local/smarthome/plugins
sudo git pull origin master
sudo chown smarthome:smarthome /usr/local/smarthome -R
sudo chmod 0755 /usr/local/smarthome -R
echo 'Updating smartVISU2.8 Master'
cd /var/www/html/smartVISU
sudo git pull origin master
sudo chown smarthome:www-data /var/www/html/smartVISU -R
sudo chmod 0775 /var/www/html/smartVISU -R
sudo chmod 0660 /var/www/html/smartVISU/config.ini
echo 'Updating smartVISU2.9 Develop'
cd /var/www/html/smartVISU2.9
sudo git pull origin develop
sudo chown smarthome:www-data /var/www/html/smartVISU2.9 -R
sudo chmod 0775 /var/www/html/smartVISU2.9 -R
sudo chmod 0660 /var/www/html/smartVISU2.9/config.ini
