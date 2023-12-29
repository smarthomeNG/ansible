#!/bin/bash
#
# Simple cron script to create backup of SQL databases
RUNBACKUPS=False
if [[ $RUNBACKUPS == False ]]; then
  exit 0
fi

adddate() {
    while IFS= read -r line; do
        echo "$(date) $line"
    done
}

export LC_ALL=C
log_file="/var/log/mysql/mariabackup.log"

if [[ $RUNBACKUPS == True ]] && (command -v /usr/bin/mariabackup > /dev/null 2>&1 && pgrep -x mariadbd > /dev/null 2>&1 && ! pgrep mariabackup  > /dev/null 2>&1); then
	days_of_backups=5  # Must be less than 7
	backup_owner="mysql"
	parent_dir="/var/backups/mysql"
	defaults_file="/etc/mysql/debian.cnf"
	todays_dir="${parent_dir}/$(date +%Y%m%d)"
	encryption_key_file="${parent_dir}/encryption_key"
	now="$(date +%m-%d-%Y_%H-%M-%S)"
	processors="$(nproc --all)"

  sanity_check () {
    # Check user running the script
    if [ "$(id --user --name)" != "$backup_owner" ]; then
        exec sudo -H -u ${backup_owner} $0 "$@"
    fi

  }
  sanity_check
  if [ ! -f "${log_file}" ]; then
      sudo touch $log_file
  fi

  sudo chmod 0644 /etc/mysql/debian.cnf
  sudo chown mysql:mysql /etc/mysql/debian.cnf
  sudo chmod 0664 /var/log/mysql/mariabackup.log
  sudo chown mysql:adm /var/log/mysql/mariabackup.log
  echo "MySQL Backup Initializing." | adddate >> $log_file 2>&1
	# Use this to echo to standard error
	error () {
		printf "%s: %s\n" "$(basename "${BASH_SOURCE}")" "${1}" | adddate >> $log_file 2>&1
		printf "%s: %s\n" "$(basename "${BASH_SOURCE}")" "${1}"
		exit 1
	}

	trap 'error "An unexpected error occurred."' ERR | adddate >> $log_file 2>&1
	echo "MySQL Backup running." | adddate >> $log_file 2>&1

	set_options () {
		# List the mariabackup arguments
		mariabackup_args=(
			"--defaults-file=${defaults_file}"
			"--target-dir=${parent_dir}"
			"--backup"
			"--extra-lsndir=${todays_dir}"
			"--stream=xbstream"
			"--parallel=${processors}"
			"--log=${log_file}"
		)

		backup_type="full"

		# Add option to read LSN (log sequence number) if a full backup has been
		# taken today.
		if grep -q -s "to_lsn" "${todays_dir}/xtrabackup_checkpoints"; then
			backup_type="incremental"
			lsn=$(awk '/to_lsn/ {print $3;}' "${todays_dir}/xtrabackup_checkpoints")
			mariabackup_args+=( "--incremental-lsn=${lsn}" )
		fi
		printf "Backup type: %s\n" "${backup_type}" | adddate >> $log_file 2>&1
		printf "Backup type: %s\n" "${backup_type}"
	}

	rotate_old () {
		# Remove the oldest backup in rotation
		day_dir_to_remove="${parent_dir}/$(date --date="${days_of_backups} days ago" +%Y%m%d)"

		if [ -d "${day_dir_to_remove}" ]; then
			rm -rf "${day_dir_to_remove}"
			echo "Deleted folder ${day_dir_to_remove}"  | adddate >> $log_file 2>&1
		fi
	}

	take_backup () {
		# Make sure today's backup directory is available and take the actual backup
		mkdir -p "${todays_dir}"
		cd /var/log/mysql/ && find "${todays_dir}" -type f -name "*.incomplete" -delete
    echo "Starting Backup"
		sudo mariabackup "${mariabackup_args[@]}" --target-dir="${todays_dir}" > "${todays_dir}/${backup_type}-${now}.xbstream.incomplete" 2>> $log_file

		sudo mv "${todays_dir}/${backup_type}-${now}.xbstream.incomplete" "${todays_dir}/${backup_type}-${now}.xbstream"
	}

	set_options && rotate_old && take_backup

	# Check success and print message
	if tail -1 "${log_file}" | grep -q "completed OK"; then
		printf "%s\n" "Backup successful!" | adddate >> $log_file 2>&1
		printf "Backup created at %s/%s-%s.xbstream\n" "${todays_dir}" "${backup_type}" "${now}" | adddate >> $log_file 2>&1
	else
		error "Backup failure! Check ${log_file} for more information" | adddate >> $log_file 2>&1
	fi
else
  echo "MySQL not running - nothing to backup."
  echo "MySQL not running - nothing to backup." | adddate >> $log_file 2>&1
fi
exit
