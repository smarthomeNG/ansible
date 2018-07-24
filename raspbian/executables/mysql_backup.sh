#!/bin/sh
#
# Simple cron script to create backup of SQL databases

adddate() {
    while IFS= read -r line; do
        echo "$(date) $line"
    done
}

FOLDER='/var/backups/mysql/'`date +"%Y%m%d"`'/INC'
LOGFILE='/var/log/mysql/pyxtrabackup.log'
USER=root
PASSWORD=smarthome
if (command -v /usr/local/bin/pyxtrabackup-inc > /dev/null 2>&1 && pgrep -x mysqld > /dev/null 2>&1 && (! pgrep xtrabackup  > /dev/null 2>&1 || ! pgrep innobackupex > /dev/null 2>&1)); then
  echo "MySQL Backup running." | adddate >> $LOGFILE 2>&1
  if [ -d "$FOLDER" ]; then
          if test -n "$(find ${FOLDER} -maxdepth 1 -name 'base*' -print -quit)"; then
          echo "Creating incremental backup in existing folder $FOLDER" | adddate >> $LOGFILE 2>&1
          /usr/local/bin/pyxtrabackup-inc /var/backups/mysql/ --user=$USER --password=$PASSWORD --no-compress --incremental  >/dev/null 2>&1
          else
          echo "Creating full backup in existing folder $FOLDER" | adddate >> $LOGFILE 2>&1
          /usr/local/bin/pyxtrabackup-inc /var/backups/mysql/ --user=$USER --password=$PASSWORD --no-compress  >/dev/null 2>&1
          fi
  else
    echo "Creating new backup in newly created folder" | adddate >> $LOGFILE 2>&1
    /usr/local/bin/pyxtrabackup-inc /var/backups/mysql/ --user=$USER --password=$PASSWORD --no-compress  >/dev/null 2>&1
  fi
fi
