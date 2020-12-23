#!/bin/bash
RSA_FOLDER=etc/ssl/easy-rsa
KEY_FOLDER=etc/ssl/ca/

backupfolder='home/smarthome/backup'

addate() {
    while IFS= read -r line; do
        echo "$(date) $line"
    done
}

restore_all() {
  if [ -f /$backupfolder/image_backup_encrypted.tar ]; then
      echo "Decrypting tar file.. please provide the correct password."
      sudo openssl enc -d -iter -in /$backupfolder/image_backup_encrypted.tar -out /$backupfolder/image_backup.tar
      echo ""
      echo "Decryption done. Extracting all config files to the correct folders. Please be patient."
      cd /
      sudo tar xvf $backupfolder/image_backup.tar | addate >> /$backupfolder/restore_log.txt 2>&1;
      newhost=$(cat /etc/hostname)
      sudo hostnamectl set-hostname ${newhost} | addate >> /$backupfolder/restore_log.txt 2>&1;
      echo "All files extracted and hostname set."
      echo ""
      echo "Generating locales and setting standard language now (is active after logout and login)"
      sudo locale-gen
      currentlang=$(cat /$backupfolder/locales.txt | tail -n1)
      sudo update-locale LANG=$currentlang
      echo ""
      echo "Activating services now..."
      while read p; do
        echo "Enabling "$p
        sudo systemctl enable $(echo $p) 2>&1
        echo ""
      done </$backupfolder/enabled.txt
      echo "Deactivating services now..."
      while read p; do
        echo "Disabling "$p
        sudo systemctl disable $(echo $p) 2>&1
        echo ""
      done </$backupfolder/disabled.txt
      echo ""
      echo "Finished. You can ignore any (error) message during enable/disable procedure."
      echo "Please reboot now."
  else
      echo ""
	  echo "File not found. Please copy your image_backup_encrypted.tar file to the folder /$backupfolder."
      echo "File not found. Please copy your image_backup_encrypted.tar file to the folder /$backupfolder." | addate >> /$backupfolder/restore_log.txt 2>&1
      echo ""
      select backupall in "Retry" "Skip"; do
          case $backupall in
              Retry) echo "Looking for file.."; echo ""; restore_all; break;;
              Skip) echo "Skipping"; break;;
              *) echo "Skipping"; break;;
          esac
      done
  fi
}

restore_influx() {
  if [ -f /$backupfolder/influxdb_backup.tar ]; then
      echo "Restore of influxdb is running."
      echo ""
      sudo echo "DROP DATABASE smarthome" > /$backupfolder/dropinflux.txt
      sudo influx < /$backupfolder/dropinflux.txt | addate >> /$backupfolder/restore_log.txt 2>&1
      cd /
      sudo tar xvf $backupfolder/influxdb_backup.tar | addate >> /$backupfolder/restore_log.txt 2>&1
      sudo influxd restore -portable -db smarthome /$backupfolder/influxdb | addate >> /$backupfolder/restore_log.txt 2>&1
      sudo rm /$backupfolder/influxdb -R | addate >> /$backupfolder/restore_log.txt 2>&1
      echo "Restored influxdb database and deleted /$backupfolder/influxdb folder. Compressed backup still exists in /$backupfolder."
  else
      echo ""
	  echo "File not found. Please copy your influxdb_backup.tar file to the folder /$backupfolder."
      echo "File not found. Please copy your influxdb_backup.tar file to the folder /$backupfolder." | addate >> /$backupfolder/restore_log.txt 2>&1
      echo ""
      select backup in "Retry" "Skip"; do
          case $backup in
              Retry) echo "Looking for file.."; echo ""; restore_influx; break;;
              Skip) echo "Skipping"; break;;
              *) echo "Skipping"; break;;
          esac
      done
  fi
}

restore_mysql() {
  sudo systemctl stop monit
  sudo systemctl stop mysql
  unset backup_files
  files=0
  while [ "$files" != "0" ] || [[ ! "${backup_files}" =~ ".xbstream" ]]; do
	  read -p "Please define the folder that should be restored. Don't forget to add a '*.xbstream' at the end: " backup_files;
	  files=$(ls ${backup_files} 2> /dev/null | wc -l);
  done
  echo "Rebuilding backup files to folder '${PWD}/restore'. Please follow further steps later to restore the database completely"
  sudo /opt/mysql_restore ${backup_files}
}

if [ -n "/$backupfolder" ]; then
	touch /$backupfolder/restore_log.txt >/dev/null 2>&1
	truncate -s 0 /$backupfolder/restore_log.txt >/dev/null 2>&1
	echo ""
	echo "Do you want to restore your previously saved configuration?"
	echo "BE AWARE: Any current config files for packages, smartvisu and smarthome will be overwritten by the backup files!"
	echo ""
	echo "Please copy the relevant files and folders to /$backupfolder."
	backup="Skip"
	select backup in "Restore" "Skip"; do
		case $backup in
			Restore) echo "Starting restore."; restore_all; break;;
			Skip) echo "Skipping"; break;;
			*) echo "Skipping"; break;;
		esac
	done

	if [[ $backup == "Restore" ]]; then
		echo ""
		echo "Restore finished."
	fi
	echo ""
	echo "Do you want to restore your influxdb database? The current influxdb database will be erased!"
	echo "If yes, you need to place the influxdb_backup.tar file in the /$backupfolder folder now."
	select influx in "Restore" "Skip"; do
		case $influx in
			Restore ) restore_influx; break;;
			Skip) echo "Skipping"; break;;
			*) echo "Skipping"; break;;
		esac
	done

	echo ""
	echo "Do you want to restore your mysql database?"
	echo "If yes, you need to place the mysql backup folder in the /$backupfolder folder now."
  echo "WARNING: Current /var/lib/mysql folder will be deleted!!"
	select mysql in "Restore" "Skip"; do
		case $mysql in
			Restore ) restore_mysql; break;;
			Skip) echo "Skipping"; break;;
			*) echo "Skipping"; break;;
		esac
	done
	echo ""
	echo "Everything finished. You might want to check the file /$backupfolder/restore_log.txt for errors."
	echo "You should reboot your system now and hope for the best. Good bye!"

else
	echo "The backup files don't seem to be in /$backupfolder!"
fi
