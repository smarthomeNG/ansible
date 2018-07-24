#!/bin/bash
sudo echo '' > /var/log/auth.log
sudo echo '' > /var/log/boot.log
sudo echo '' > /var/log/cron.log
sudo echo '' > /var/log/user.log
sudo echo '' > /var/log/syslog
sudo rm /var/mail/smarthome > /dev/null 2>&1
sudo rm /var/mail/root > /dev/null 2>&1
cat /dev/null > ~/.bash_history && history -c && exit
