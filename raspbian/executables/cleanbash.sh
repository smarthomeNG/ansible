#!/bin/bash
sudo echo '' > /var/log/auth.log
sudo echo '' > /var/log/boot.log
sudo echo '' > /var/log/cron.log
sudo echo '' > /var/log/user.log
sudo echo '' > /var/log/syslog
sudo rm /var/mail/smarthome > /dev/null 2>&1
sudo rm /var/mail/root > /dev/null 2>&1
sudo cat /dev/null > /root/.bash_history && history -c
sudo runuser -l smarthome -c "cat /dev/null > /home/smarthome/.bash_history && history -c"
sudo runuser -l pi -c "cat /dev/null > /home/pi/.bash_history && history -c"
