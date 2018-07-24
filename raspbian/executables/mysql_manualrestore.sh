#!/bin/sh
#
# Script to prepare and restore full and incremental backups created with innobackupex-runner.
#
# (C)2010 Owen Carter @ Mirabeau BV
# This script is provided as-is; no liability can be accepted for use.
# You are free to modify and reproduce so long as this attribution is preserved.
#
# (C)2013 Benoît LELEVÉ @ Exsellium (www.exsellium.com)
# Adding parameters in order to execute the script in a multiple MySQL instances environment
#
adddate() {
    while IFS= read -r line; do
        echo "$(date) $line"
    done
}

INNOBACKUPEX=innobackupex
INNOBACKUPEXFULL=/usr/local/xtrabackup/bin/$INNOBACKUPEX
TMPFILE="/tmp/innobackupex-runner.$$.tmp"
MEMORY=1024M # Amount of memory to use when preparing the backup
MYSQL=/usr/bin/mysql
MYSQLADMIN=/usr/bin/mysqladmin
FULLBACKUPLIFE=86400 # Lifetime of the latest full backup in seconds
KEEP=1 # Number of full backups (and its incrementals) to keep
SCRIPTNAME=$(basename "$0")
BACKUPDIR="/var/backups/mysql"
MYGROUP="root"
DATADIR="/var/lib/mysql"
LOGFILE="/var/log/mysql/backup.log"

#############################################################################
# Display usage message and exit
#############################################################################
usage() {
  cat <<EOF
Usage: $SCRIPTNAME [-d backdir] [-f config] [-g group] /absolute/path/to/backup/to/restore
  -d  Directory used to store database backup
  -f  Path to my.cnf database config file
  -g  Group to read from the config file
  -h  Display basic help
EOF
  exit 0
}

# Parse parameters
while getopts ":d:f:g:h" opt; do
  case $opt in
    d )  BACKUPDIR=$OPTARG ;;
    f )  MYCNF=$OPTARG ;;
    g )  MYGROUP=$OPTARG ;;
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

# Check required parameters
if [ -z "$BACKUPDIR" ]; then
  echo "Backup directory is required"
  echo "For help, type: $SCRIPTNAME -h"
  exit 1
fi

if [ -z "$MYCNF" ]; then MYCNF=/etc/mysql/my.cnf; fi
if [ ! -z "$MYGROUP" ]; then DEFGROUP="--defaults-group=$MYGROUP"; fi

# Full and incremental backup directories
FULLBACKUPDIR=$BACKUPDIR/full
INCRBACKUPDIR=$BACKUPDIR/incr

#############################################################################
# Display error message and exit
#############################################################################
error() {
  echo "$1" 1>&2
  exit 1
}

#############################################################################
# Check for errors in innobackupex output
#############################################################################
check_innobackupex_error() {
  if [ -z "`tail -1 $TMPFILE | grep 'completed OK!'`" ]; then
    echo "$INNOBACKUPEX failed:"; echo
    echo "---------- ERROR OUTPUT from $INNOBACKUPEX ----------"
    echo "$INNOBACKUPEX failed!" | adddate >> $LOGFILE 2>&1
    cat $TMPFILE
    rm -f $TMPFILE
    mv ${DATADIR}_bak $DATADIR
    echo "Moved backup directory back."
    exit 1
  fi
}

# Check options before proceeding
if [ ! -x $INNOBACKUPEXFULL ]; then
  error "$INNOBACKUPEXFULL does not exist."
fi

if [ ! -d $BACKUPDIR ]; then
  error "Backup destination folder: $BACKUPDIR does not exist."
fi

if [ ! -d $1 ]; then
  error "Backup to restore: $1 does not exist."
fi

# Some info output
echo "----------------------------"
echo
echo "$SCRIPTNAME: MySQL backup script"
echo "started: `date`"
echo
sudo systemctl stop mysql
mv $DATADIR ${DATADIR}_bak
echo "Stopped MySQL. Moved your data to ${DATADIR}_bak"

PARENT_DIR=`dirname $1`

if [ $PARENT_DIR = $FULLBACKUPDIR ]; then
  FULLBACKUP=$1

  echo "Restore `basename $FULLBACKUP`"
  echo "Restore `basename $FULLBACKUP`"  | adddate >> $LOGFILE 2>&1
  echo
else
  if [ `dirname $PARENT_DIR` = $INCRBACKUPDIR ]; then
    INCR=`basename $1`
    FULL=`basename $PARENT_DIR`
    FULLBACKUP=$FULLBACKUPDIR/$FULL

    if [ ! -d $FULLBACKUP ]; then
      error "Full backup: $FULLBACKUP does not exist."
    fi

    echo "Restore $FULL up to incremental $INCR"
    echo "Restore $FULL up to incremental $INCR" | adddate >> $LOGFILE 2>&1
    echo

    echo "Replay committed transactions on full backup"
    $INNOBACKUPEXFULL --defaults-file=$MYCNF $DEFGROUP --apply-log --redo-only --use-memory=$MEMORY $FULLBACKUP > $TMPFILE 2>&1
    check_innobackupex_error

    # Apply incrementals to base backup
    for i in `find $PARENT_DIR -mindepth 1 -maxdepth 1 -type d -printf "%P\n" | sort -n`; do
      if [ $INCR = $i ]; then
        echo "Applying last incremental $i to full ..."
        echo "Applying last incremental $i to full ..." | adddate >> $LOGFILE 2>&1
        $INNOBACKUPEXFULL --defaults-file=$MYCNF $DEFGROUP --apply-log --use-memory=$MEMORY $FULLBACKUP --incremental-dir=$PARENT_DIR/$i > $TMPFILE 2>&1
        check_innobackupex_error
        break # break. we are restoring up to this incremental.
      else
      echo "Applying $i to full ..."
      echo "Applying $i to full ..." | adddate >> $LOGFILE 2>&1
      $INNOBACKUPEXFULL --defaults-file=$MYCNF $DEFGROUP --apply-log --redo-only --use-memory=$MEMORY $FULLBACKUP --incremental-dir=$PARENT_DIR/$i > $TMPFILE 2>&1
      check_innobackupex_error
      fi
    done
  else
    error "unknown backup type"
  fi
fi

echo "Preparing ..."
echo "Preparing ..." | adddate >> $LOGFILE 2>&1
$INNOBACKUPEXFULL --defaults-file=$MYCNF $DEFGROUP --apply-log --use-memory=$MEMORY $FULLBACKUP > $TMPFILE 2>&1
check_innobackupex_error

echo
echo "Restoring ... $FULLBACKUP"
echo "Restoring ... $FULLBACKUP" | adddate >> $LOGFILE 2>&1
$INNOBACKUPEXFULL --defaults-file=$MYCNF $DEFGROUP --copy-back $FULLBACKUP > $TMPFILE 2>&1
check_innobackupex_error

chown -R mysql:mysql $DATADIR

rm -f $TMPFILE
echo "Backup restored successfully."
echo "Changed ownership of data directory, deleted bak directory and restarted mysql"
echo
echo "completed: `date`"
echo "completed mysql restore: `date`" | adddate >> $LOGFILE 2>&1
rm -r ${DATADIR}_bak
sudo systemctl start mysql
sudo systemctl status mysql
exit 0
