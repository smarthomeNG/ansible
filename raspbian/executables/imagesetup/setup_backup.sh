#!/bin/bash
RSA_FOLDER=etc/ssl/easy-rsa
KEY_FOLDER=etc/ssl/ca/
backupfolder='home/smarthome/backup'

adddate() {
    while IFS= read -r line; do
        echo "$(date) $line"
    done
}

adddate_copy() {
    while IFS= read -r line; do
        echo "$(date) Copy $line"
    done
}

cleanup() {
  IFS=
  full_list=$(systemctl list-units --full)
  touch $backupfolder/$1'_new.txt'
  truncate -s 0 $backupfolder/$1'_new.txt'
  while read p; do
      if [[ $p =~ '.service' ]]; then
        suffix='.service'
      elif [[ $p =~ '.socket' ]]; then
        suffix='.socket'
      fi
      p=$(echo $p | awk -F$suffix '{ print $1 }')
      new=$(echo $full_list | egrep $p$suffix | awk -F$suffix '{ print $1 }')

      if [[ $p =~ '@' ]]; then
        p=$(echo $p | awk -F'@' '{ print $1 }')
        new=$(echo $full_list | egrep $p'@(.*)'$suffix | awk -F$suffix '{ print $1 }')
      fi
      if [[ -n $new && $1 == 'enabled' ]]; then
        echo ${new}${suffix} >> $backupfolder/$1'_new.txt'
      elif [[ -z $new && $1 == 'disabled' ]]; then
        echo ${p}${suffix} >> $backupfolder/$1'_new.txt'
      fi

  done <$backupfolder/$1'.txt'
}

backup_all() {
  cd /
  sudo mkdir /$backupfolder >/dev/null 2>&1
  sudo chown smarthome:smarthome /$backupfolder >/dev/null 2>&1
  echo "Starting backup. Be patient."
  echo "Starting backup. Be patient." | adddate > $backupfolder/backup_log.txt 2>&1
  sudo tar vcpf $backupfolder/image_backup.tar $backupfolder/backup_log.txt | adddate_copy >> $backupfolder/backup_log.txt 2>&1
  logchecksize=$(du -sm /var/www/html/monitgraph/* | awk '$1 > 100')
  if [ -z "$logchecksize" ]; then
    sudo tar vprf $backupfolder/image_backup.tar var/www/html/monitgraph/ | adddate_copy >> $backupfolder/backup_log.txt 2>&1
  else
    echo ""
    echo "Your monitgraph logs are larger than 100MB. Backup will take some time"
    echo "Do you still want to backup the logs?"
    select logcheck in "Backup" "Skip"; do
        case $logcheck in
            Backup )
              sudo tar vprf $backupfolder/image_backup.tar var/www/html/monitgraph/ | adddate_copy >> $backupfolder/backup_log.txt 2>&1
              echo "Backed up monitgraph"
              break;;
            Skip ) echo "Skipping monitgraph"; break;;
            *) echo "Skipping monitgraph"; break;;
        esac
    done
  fi
  sudo tar vprf $backupfolder/image_backup.tar etc/exim4/ | adddate_copy > $backupfolder/backup_log.txt 2>&1
  sudo tar vprf $backupfolder/image_backup.tar etc/email-addresses | adddate_copy >> $backupfolder/backup_log.txt 2>&1
  sudo tar vprf $backupfolder/image_backup.tar etc/aliases | adddate_copy >> $backupfolder/backup_log.txt 2>&1
  sudo tar vprf $backupfolder/image_backup.tar etc/mailname | adddate_copy >> $backupfolder/backup_log.txt 2>&1

  echo "Backed up exim4"
  if [ -z "$RSA_FOLDER" ]; then
	sudo tar vprf $backupfolder/image_backup.tar $RSA_FOLDER | adddate_copy >> $backupfolder/backup_log.txt 2>&1
	sudo tar vprf $backupfolder/image_backup.tar $KEY_FOLDER | adddate_copy >> $backupfolder/backup_log.txt 2>&1
	echo "Backed up certifictes"
  fi
  if [ -z "etc/letsencryp" ]; then
	  sudo tar vprf $backupfolder/image_backup.tar etc/letsencrypt/ | adddate_copy >> $backupfolder/backup_log.txt 2>&1
	  sudo tar vprf $backupfolder/image_backup.tar var/www/letsencrypt/.well-known/ | adddate_copy >> $backupfolder/backup_log.txt 2>&1
	  sudo tar vprf $backupfolder/image_backup.tar var/www/letsencrypt | adddate_copy >> $backupfolder/backup_log.txt 2>&1
	  echo "Backed up letsencrypt"
  fi

  sudo tar vprf $backupfolder/image_backup.tar etc/fail2ban/ | adddate_copy >> $backupfolder/backup_log.txt 2>&1

  echo "Backed up fail2ban"
  sudo tar vprf $backupfolder/image_backup.tar etc/ufw/ | adddate_copy >> $backupfolder/backup_log.txt 2>&1

  echo "Backed up ufw"
  sudo tar vprf $backupfolder/image_backup.tar etc/apt/apt.conf.d/20auto-upgrades | adddate_copy >> $backupfolder/backup_log.txt 2>&1
  sudo tar vprf $backupfolder/image_backup.tar etc/hostname | adddate_copy >> $backupfolder/backup_log.txt 2>&1
  sudo tar vprf $backupfolder/image_backup.tar etc/hosts | adddate_copy >> $backupfolder/backup_log.txt 2>&1
  sudo tar vprf $backupfolder/image_backup.tar etc/dphys-swapfile | adddate_copy >> $backupfolder/backup_log.txt 2>&1

  echo "Backed up swap settings"
  if [ -z "home/smarthome/.homebridge" ]; then
	  sudo tar vprf $backupfolder/image_backup.tar home/smarthome/.homebridge | adddate_copy >> $backupfolder/backup_log.txt 2>&1
	  echo "Backed up homebridge"
  fi
  if [ -z "etc/influxdb/influxdb.conf" ]; then
	  sudo tar vprf $backupfolder/image_backup.tar etc/influxdb/influxdb.conf | adddate_copy >> $backupfolder/backup_log.txt 2>&1
	  echo "Backed up influxdb config"
  fi
  if [ -z "etc/grafana/" ]; then
	sudo tar vprf $backupfolder/image_backup.tar etc/grafana/ | adddate_copy >> $backupfolder/backup_log.txt 2>&1
	echo "Backed up grafana config"
  fi

  sudo tar vprf $backupfolder/image_backup.tar etc/knxd.* | adddate_copy >> $backupfolder/backup_log.txt 2>&1
  sudo tar vprf $backupfolder/image_backup.tar etc/default/eibd | adddate_copy >> $backupfolder/backup_log.txt 2>&1
  sudo tar vprf $backupfolder/image_backup.tar etc/init.d/eibd | adddate_copy >> $backupfolder/backup_log.txt 2>&1
  echo "Backed up knxd and eibd"

  sudo tar vprf $backupfolder/image_backup.tar etc/lirc/ | adddate_copy >> $backupfolder/backup_log.txt 2>&1
  echo "Backed up lirc"
  sudo tar vprf $backupfolder/image_backup.tar etc/logcheck/ | adddate_copy >> $backupfolder/backup_log.txt 2>&1
  sudo tar vprf $backupfolder/image_backup.tar etc/monit/ | adddate_copy >> $backupfolder/backup_log.txt 2>&1

  echo "Backed up logcheck and monit"
  sudo tar vprf $backupfolder/image_backup.tar etc/mosquitto/ | adddate_copy >> $backupfolder/backup_log.txt 2>&1

  echo "Backed up mosquitto"
  sudo tar vprf $backupfolder/image_backup.tar etc/exports | adddate_copy >> $backupfolder/backup_log.txt 2>&1

  echo "Backed up nfs"
  sudo tar vprf $backupfolder/image_backup.tar etc/freeradius/3.0/ | adddate_copy >> $backupfolder/backup_log.txt 2>&1

  echo "Backed up freeradius"
  sudo tar vprf $backupfolder/image_backup.tar etc/nginx/ | adddate_copy >> $backupfolder/backup_log.txt 2>&1

  echo "Backed up nginx"
  sudo tar vprf $backupfolder/image_backup.tar etc/owfs.conf | adddate_copy >> $backupfolder/backup_log.txt 2>&1

  echo "Backed up onewire settings"
  sudo tar vprf $backupfolder/image_backup.tar etc/openvpn/ | adddate_copy >> $backupfolder/backup_log.txt 2>&1

  echo "Backed up openvpn"
  sudo tar vprf $backupfolder/image_backup.tar etc/samba/ | adddate_copy >> $backupfolder/backup_log.txt 2>&1

  echo "Backed up samba"
  sudo tar vprf $backupfolder/image_backup.tar etc/mysql/ | adddate_copy >> $backupfolder/backup_log.txt 2>&1

  echo "Backed up mysql"
  sudo tar vprf $backupfolder/image_backup.tar usr/local/bin/squeezelite*.sh | adddate_copy >> $backupfolder/backup_log.txt 2>&1

  echo "Backed up squeezelite scripts"
  sudo tar vprf $backupfolder/image_backup.tar home/smarthome/.ssh/ | adddate_copy >> $backupfolder/backup_log.txt 2>&1
  sudo tar vprf $backupfolder/image_backup.tar root/.ssh/ | adddate_copy >> $backupfolder/backup_log.txt 2>&1
  sudo tar vprf $backupfolder/image_backup.tar etc/ssh/ | adddate_copy >> $backupfolder/backup_log.txt 2>&1

  echo "Backed up ssh"
  sudo tar vprf $backupfolder/image_backup.tar etc/watchdog.conf | adddate_copy >> $backupfolder/backup_log.txt 2>&1

  echo "Backed up watchdog. Backing up smartVISU folders... This might take longer."
  sudo tar vprf $backupfolder/image_backup.tar var/www/html/smart* | adddate_copy >> $backupfolder/backup_log.txt 2>&1
  echo "Backed up smartvisu folders. Backing up smarthomeNG folders... This might take longer."

  sudo tar vprf $backupfolder/image_backup.tar usr/local/smarthome/etc/ | adddate_copy >> $backupfolder/backup_log.txt 2>&1
  sudo tar vprf $backupfolder/image_backup.tar usr/local/smarthome/items/ | adddate_copy >> $backupfolder/backup_log.txt 2>&1
  sudo tar vprf $backupfolder/image_backup.tar usr/local/smarthome/logics/ | adddate_copy >> $backupfolder/backup_log.txt 2>&1
  sudo tar vprf $backupfolder/image_backup.tar usr/local/smarthome/var/cache/ | adddate_copy >> $backupfolder/backup_log.txt 2>&1
  sudo tar vprf $backupfolder/image_backup.tar usr/local/smarthome/var/db/ | adddate_copy >> $backupfolder/backup_log.txt 2>&1
  echo "Backed up smarthomeNG folders: etc, items, logics, cache, db"

  sudo tar vprf $backupfolder/image_backup.tar etc/dhcpcd.conf | adddate_copy >> $backupfolder/backup_log.txt 2>&1
  sudo tar vprf $backupfolder/image_backup.tar etc/wpa_supplicant/ | adddate_copy >> $backupfolder/backup_log.txt 2>&1
  sudo tar vprf $backupfolder/image_backup.tar var/lib/alsa/ | adddate_copy >> $backupfolder/backup_log.txt 2>&1
  sudo tar vprf $backupfolder/image_backup.tar etc/udev/rules.d/ | adddate_copy >> $backupfolder/backup_log.txt 2>&1
  sudo tar vprf $backupfolder/image_backup.tar etc/passwd | adddate_copy >> $backupfolder/backup_log.txt 2>&1
  sudo tar vprf $backupfolder/image_backup.tar etc/cron* | adddate_copy >> $backupfolder/backup_log.txt 2>&1
  sudo tar vprf $backupfolder/image_backup.tar etc/rsyslog.conf | adddate_copy >> $backupfolder/backup_log.txt 2>&1
  sudo tar vprf $backupfolder/image_backup.tar etc/rsyslog.d | adddate_copy >> $backupfolder/backup_log.txt 2>&1
  sudo tar vprf $backupfolder/image_backup.tar boot/config.txt | adddate_copy >> $backupfolder/backup_log.txt 2>&1
  if [ -z "var/lib/systemd/linger" ]; then
	sudo tar vprf $backupfolder/image_backup.tar var/lib/systemd/linger | adddate_copy >> $backupfolder/backup_log.txt 2>&1
  fi
  sudo tar vprf $backupfolder/image_backup.tar etc/default/keyboard | adddate_copy >> $backupfolder/backup_log.txt 2>&1
  sudo tar vprf $backupfolder/image_backup.tar etc/locale.gen | adddate_copy >> $backupfolder/backup_log.txt 2>&1
  currentlang=$(localectl status |grep LANG | awk -F'LANG=' '{ print $2 }')
  sudo echo $currentlang > /$backupfolder/locales.txt 2>&1
  sudo tar vprf $backupfolder/image_backup.tar $backupfolder/locales.txt | adddate_copy >> $backupfolder/backup_log.txt 2>&1
  echo "Backed up cronjobs, log configurations, boot options and other system settings"
  echo "Backing up service states... This might take longer."
  sudo systemctl list-unit-files | grep -E 'disabled|generated' | awk '{ print $1 }' | grep -E 'service|socket' > /$backupfolder/disabled.txt 2>&1
  sudo systemctl list-unit-files | grep -E 'enabled|generated' | awk '{ print $1 }' | grep -E 'service|socket' > /$backupfolder/enabled.txt 2>&1
  cleanup enabled 2>&1
  cleanup disabled 2>&1
  sudo mv /$backupfolder/enabled_new.txt /$backupfolder/enabled.txt 2>&1
  sudo mv /$backupfolder/disabled_new.txt /$backupfolder/disabled.txt 2>&1
  sudo tar vprf $backupfolder/image_backup.tar $backupfolder/enabled.txt | adddate_copy >> /$backupfolder/backup_log.txt 2>&1
  sudo tar vprf $backupfolder/image_backup.tar $backupfolder/disabled.txt | adddate_copy >> /$backupfolder/backup_log.txt 2>&1
  rm /$backupfolder/disabled.txt 2>&1
  rm /$backupfolder/enabled.txt 2>&1
  rm /$backupfolder/locales.txt 2>&1
  echo ""
  echo "Backup finished and saved as /$backupfolder/image_backup.tar."
  echo "Please check /$backupfolder/backup_log.txt for unexpected errors."
  echo ""
  echo "Encrypting tar file as there are certificates and other private information stored. This might take longer."
  echo "Please provide a password and remember that for the restore process!"
  sudo openssl enc -e -iter -out /$backupfolder/image_backup_encrypted.tar -in /$backupfolder/image_backup.tar
  echo ""
  echo "Encryption done. Please copy the file /$backupfolder/image_backup_encrypted.tar to a save place."
  echo "Deleting unencrypted file."
  sudo rm /$backupfolder/image_backup.tar
}

backup_mysql() {
  if [ ! -f "$backupfolder/backup_log.txt" ]; then
    sudo chown smarthome:users /$backupfolder -R
    echo "Running mariadb-backup now." | adddate > /$backupfolder/backup_log.txt 2>&1
  fi
  echo "Running mariadb-backup now. Check the file /etc/cron.hourly/mysql_backup for the target directory"
  echo "Running mariadb-backup now. Check the file /etc/cron.hourly/mysql_backup for the target directory" | adddate >> /$backupfolder/backup_log.txt 2>&1
  bkp=$(grep RUNBACKUPS= /etc/cron.hourly/mysql_backup | awk -F= '{ print $2 }')
  sudo sed -i 's/RUNBACKUPS=False/RUNBACKUPS=True/g' /etc/cron.hourly/mysql_backup 2>&1
  sudo /etc/cron.hourly/mysql_backup
  sudo sed -i 's/RUNBACKUPS=True/RUNBACKUPS='${bkp}'/g' /etc/cron.hourly/mysql_backup 2>&1
  echo "Backup finished. Please copy the relevant folder to your external backup disk."
  echo "Backup finished. Please copy the relevant to your external backup disk." | adddate >> /$backupfolder/backup_log.txt 2>&1

}

backup_influxdb() {
  echo ""
  echo "Backup of influxdb is running and stored to /$backupfolder/"; echo "";
  if [ ! -f "$backupfolder/backup_log.txt" ]; then
    sudo chown smarthome:users /$backupfolder -R
    echo "Backup of influxdb is running and stored to /$backupfolder/" | adddate > /$backupfolder/backup_log.txt 2>&1
  fi

	sudo /usr/bin/influxd backup -portable -database smarthome /$backupfolder/influxdb | adddate >> /$backupfolder/backup_log.txt 2>&1
	cd /
	if [ -z "$backupfolder/influxdb" ]; then
		sudo tar vprf $backupfolder/influxdb_backup.tar $backupfolder/influxdb | adddate_copy >> /$backupfolder/backup_log.txt 2>&1
		sudo rm /$backupfolder/influxdb -R | adddate >> /$backupfolder/backup_log.txt 2>&1
		echo ""
		echo "Backup finished. Please copy the file /$backupfolder/influxdb_backup.tar to your external backup disk."
		echo "Backup finished. Please copy the file /$backupfolder/influxdb_backup.tar to your external backup disk." | adddate >> /$backupfolder/backup_log.txt 2>&1
	else
		echo ""
		echo "No influxdb database found. Nothing backed up."
		echo "No influxdb database found. Nothing backed up." | adddate >> /$backupfolder/backup_log.txt 2>&1
	fi

}

backup_overwrite() {
  if [ -f /$backupfolder/backup_log.txt ]; then
	  echo "There seems to be an older backup existing. Previously created backups in $backupfolder will be overwritten. Are you sure?"
	  select overwrite in "Overwrite" "Skip"; do
		case $overwrite in
			Overwrite ) echo "Backup is running."; echo ""; sudo rm /$backupfolder/ -R; backup_all; break;;
			Skip) echo "Skipping"; break;;
			*) echo "Skipping"; break;;
		esac
	  done
  else
    backup_all
  fi

}

echo ""
echo "Do you want to backup your configuration?"
echo "In case you update your image you can easily restore your configuration by running setup_all on the new install."
echo ""
echo "Backup files are stored in /$backupfolder/. If you don't have enough space on your SD card or USB stick"
echo "you can mount an external drive and symlink the folder like sudo ln -s /mnt/usb /$backupfolder/"
select backup in "Backup" "Skip"; do
    case $backup in
        Backup ) echo "Checking for existing backups."; echo ""; backup_overwrite; break;;
        Skip) echo "Skipping"; break;;
        *) echo "Skipping"; break;;
    esac
done

echo ""
echo "Do you want to backup your influxdb database?"
select influx in "Backup" "Skip"; do
    case $influx in
        Backup ) backup_influxdb; break;;
        Skip) echo "Skipping"; break;;
        *) echo "Skipping"; break;;
    esac
done
echo ""
echo "Do you want to backup your mysql database?"
select mysql in "Backup" "Skip"; do
    case $mysql in
        Backup ) backup_mysql; break;;
        Skip) echo "Skipping"; break;;
        *) echo "Skipping"; break;;
    esac
done
sudo chown smarthome:users /$backupfolder -R
echo "Good bye!"
