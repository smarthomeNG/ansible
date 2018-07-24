#!/bin/sh
adddate() {
    while IFS= read -r line; do
        echo "$(date) $line"
    done
}

INNOBACKUPEX=pyxtrabackup-restore
INNOBACKUPEXFULL=/usr/local/bin/$INNOBACKUPEX
SCRIPTNAME=$(basename "$0")
BACKUPDIR="/var/backups/mysql"
DATADIR="/var/lib/mysql"
LOGFILE='/var/log/mysql/pyxtrabackup.log'
PASSWORD=smarthome

usage() {
  cat <<EOF
Usage: $SCRIPTNAME [-d destination] [-f config] [-g group] /absolute/filename/to/backup/to/restore
  -d  Directory used to store database (usually /var/lib/mysql)
  -u  Database User
  -h  Display basic help
EOF
  exit 0
}

error() {
  echo "$1" 1>&2
  exit 1
}

# Parse parameters
while getopts ":d:u:h" opt; do
  case $opt in
    d )  DATADIR=$OPTARG ;;
    u )  USER=$OPTARG ;;
    h )  usage ;;
    \?)  echo "Invalid option: -$OPTARG"
         echo "For help, type: $SCRIPTNAME -h"
         exit 1 ;;
    : )  echo "Option -$OPTARG requires an argument"
         echo "For help, type: $SCRIPTNAME -h"
         exit 1 ;;
  esac
done

shift $(($OPTIND - 1))

# Check options before proceeding
if [ -z "$DATADIR" ]; then
  echo "Destination directory is required"
  echo "For help, type: $SCRIPTNAME -h"
  exit 1
fi

if [ ! -z "$USER" ]; then USER="root"; fi


if [ ! -x $INNOBACKUPEXFULL ]; then
  error "$INNOBACKUPEXFULL does not exist."
fi

if [ $# -eq 0 ]; then
  error "No backup file defined. Provide full path including incremental file name."
fi

if [ ! -e $1 ]; then
  error "Backup to restore: $1 does not exist."
fi

read -p"WARNING: are you sure you want to restore $1? (Enter yes or no) " response
if [ $response = "yes" ]; then
BASE=`ls $(dirname $1)/base*`
  echo "----------------------------"
  echo
  echo "$SCRIPTNAME: MySQL backup script"
  echo "started: `date`"
  echo
  echo "Restoring Base file: $BASE"
  echo "Restoring Incremental file: $1"
  echo "Restoring Incremental file: $1" | adddate >> $LOGFILE 2>&1
else
  exit;
fi

if [ $1 = $BASE ]; then
  error "Please provide an incremental file."
else
  pyxtrabackup-restore --base-archive=$BASE --incremental-archive=$1 --user=root --uncompressed-archives --restart
fi
