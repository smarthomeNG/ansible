#!/bin/sh
#
# Script to create full and incremental backups (for all databases on server) using innobackupex from Percona.
# http://www.percona.com/doc/percona-xtrabackup/innobackupex/innobackupex_script.html
#
# Every time it runs will generate an incremental backup except for the first time (full backup).
# FULLBACKUPLIFE variable will define your full backups schedule.
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
MYSQL=/usr/bin/mysql
MYSQLADMIN=/usr/bin/mysqladmin
FULLBACKUPLIFE=86400 # Lifetime of the latest full backup in seconds
KEEP=1 # Number of full backups (and its incrementals) to keep
SCRIPTNAME=$(basename "$0")
BACKUPDIR="/var/backups/mysql"
MYCNF="/etc/mysql/debian.cnf"
MYUSER="root"
MYPASSWD="smarthome"
LOGFILE="/var/log/mysql/backup.log"

# Grab start time
STARTED_AT=`date +%s`

#############################################################################
# Display usage message and exit
#############################################################################
usage() {
  cat <<EOF
Usage: $SCRIPTNAME [-d backdir] [-f config] [-g group] [-u username] [-p password] [-H host] [-P port] [-S socket]
  -d  Directory used to store database backup
  -f  Path to my.cnf database config file
  -g  Group to read from the config file
  -u  Username used when connecting to the database
  -p  Password used when connecting to the database
  -H  Host used when connecting to the database
  -P  Port number used when connecting to the database
  -S  Socket used when connecting to the database
  -h  Display basic help
EOF
  exit 0
}

# Parse parameters
while getopts ":d:f:g:u:p:H:P:S:h" opt; do
  case $opt in
    d )  BACKUPDIR=$OPTARG ;;
    f )  MYCNF=$OPTARG ;;
    g )  MYGROUP=$OPTARG ;;
    u )  MYUSER=$OPTARG ;;
    p )  MYPASSWD=$OPTARG ;;
    H )  MYHOST=$OPTARG ;;
    P )  MYPORT=$OPTARG ;;
    S )  MYSOCKET=$OPTARG ;;
    h )  usage ;;
    \?)  echo "Invalid option: -$OPTARG"
         echo "For help, type: $SCRIPTNAME -h"
         exit 1 ;;
    : )  echo "Option -$OPTARG requires an argument"
         echo "For help, type: $SCRIPTNAME -h"
         exit 1 ;;
  esac
done

# Check required parameters
if [ -z "$BACKUPDIR" ]; then
  echo "Backup directory is required"
  echo "For help, type: $SCRIPTNAME -h"
  exit 1
fi

if [ -z "$MYUSER" ]; then
  echo "Database username is required"
  echo "For help, type: $SCRIPTNAME -h"
  exit 1
fi

if [ -z "$MYCNF" ]; then MYCNF=/etc/mysql/my.cnf; fi
if [ ! -z "$MYGROUP" ]; then DEFGROUP="--defaults-group=$MYGROUP"; fi

# Concatenate parameters into innobackupex ones
USEROPTIONS="--user=$MYUSER"
if [ ! -z "$MYPASSWD" ]; then USEROPTIONS="$USEROPTIONS --password=$MYPASSWD"; fi
if [ ! -z "$MYHOST" ]; then USEROPTIONS="$USEROPTIONS --host=$MYHOST"; fi
if [ ! -z "$MYPORT" ]; then USEROPTIONS="$USEROPTIONS --port=$MYPORT"; fi
if [ ! -z "$MYSOCKET" ]; then USEROPTIONS="$USEROPTIONS --socket=$MYSOCKET"; fi

# Full and incremental backups directories
FULLBACKUPDIR=$BACKUPDIR/full
INCRBACKUPDIR=$BACKUPDIR/incr

#############################################################################
# Display error message and exit
#############################################################################
error() {
  echo "$1" 1>&2
  exit 1
}

# Check options before proceeding
if [ ! -x $INNOBACKUPEXFULL ]; then
  error "$INNOBACKUPEXFULL does not exist."
fi

if [ ! -d $BACKUPDIR ]; then
  error "Backup destination folder: $BACKUPDIR does not exist."
fi

if [ -z "`$MYSQLADMIN $USEROPTIONS status | grep 'Uptime'`" ] ; then
  error "HALTED: MySQL does not appear to be running."
fi

if ! `echo 'exit' | $MYSQL -s $USEROPTIONS` ; then
  error "HALTED: Supplied mysql username or password appears to be incorrect (not copied here for security, see script)."
fi

# Some info output
echo "----------------------------"
echo
echo "$SCRIPTNAME: MySQL backup script"
echo "started: `date`"
echo
echo "Started MySQL Backup"  | adddate >> $LOGFILE 2>&1
# Create full and incr backup directories if they not exist.
mkdir -p $FULLBACKUPDIR
mkdir -p $INCRBACKUPDIR

# Find latest full backup
LATEST_FULL=`find $FULLBACKUPDIR -mindepth 1 -maxdepth 1 -type d -printf "%P\n" | sort -nr | head -1`

# Get latest backup last modification time
LATEST_FULL_CREATED_AT=`stat -c %Y $FULLBACKUPDIR/$LATEST_FULL`

# Run an incremental backup if latest full is still valid. Otherwise, run a new full one.
if [ "$LATEST_FULL" -a `expr $LATEST_FULL_CREATED_AT + $FULLBACKUPLIFE + 5` -ge $STARTED_AT ] ; then
  # Create incremental backups dir if not exists.
  TMPINCRDIR=$INCRBACKUPDIR/$LATEST_FULL
  mkdir -p $TMPINCRDIR

  # Find latest incremental backup.
  LATEST_INCR=`find $TMPINCRDIR -mindepth 1 -maxdepth 1 -type d | sort -nr | head -1`

  # If this is the first incremental, use the full as base. Otherwise, use the latest incremental as base.
  if [ ! $LATEST_INCR ] ; then
    INCRBASEDIR=$FULLBACKUPDIR/$LATEST_FULL
  else
    INCRBASEDIR=$LATEST_INCR
  fi

  echo "Running new incremental backup using $INCRBASEDIR as base."
  echo "Running new incremental backup using $INCRBASEDIR as base."  | adddate >> $LOGFILE 2>&1
  $INNOBACKUPEXFULL --defaults-file=$MYCNF $DEFGROUP $USEROPTIONS --incremental $TMPINCRDIR --incremental-basedir $INCRBASEDIR > $TMPFILE 2>&1
else
  echo "Running new full backup."
  echo "Running new full backup."  | adddate >> $LOGFILE 2>&1
  $INNOBACKUPEXFULL --defaults-file=$MYCNF $DEFGROUP $USEROPTIONS $FULLBACKUPDIR > $TMPFILE 2>&1
fi

if [ -z "`tail -1 $TMPFILE | grep 'completed OK!'`" ] ; then
  echo "$INNOBACKUPEX failed:"; echo
  echo "---------- ERROR OUTPUT from $INNOBACKUPEX ----------"
  echo "---------- ERROR OUTPUT from $INNOBACKUPEX ----------"  | adddate >> $LOGFILE 2>&1
  cat $TMPFILE
  rm -f $TMPFILE
  exit 1
fi

THISBACKUP=`awk -- "/Backup created in directory/ { split( \\\$0, p, \"'\" ) ; print p[2] }" $TMPFILE`
rm -f $TMPFILE

echo "Databases backed up successfully to: $THISBACKUP"
echo "Databases backed up successfully to: $THISBACKUP"  | adddate >> $LOGFILE 2>&1
echo

echo "completed: `date`"
echo "Completed MySQL Backup"  | adddate >> $LOGFILE 2>&1
exit 0
