#!/bin/bash
sudo echo '' > /var/log/auth.log
sudo echo '' > /var/log/boot.log
sudo echo '' > /var/log/cron.log
sudo echo '' > /var/log/user.log
sudo echo '' > /var/log/syslog
cat /dev/null > ~/.bash_history && history -c && exit