#!/bin/bash
adddate() {
    while IFS= read -r line; do
        echo "$(date) $line"
    done
}

export LC_ALL=C

backup_owner="mysql"
log_file="/var/log/mysql/mariabackup.log"
number_of_args="${#}"
processors="$(nproc --all)"

shopt -s nullglob
incremental_dirs=( ./restore/incremental-*/ )
full_dirs=( ./restore/full-*/ )
shopt -u nullglob

full_backup_dir="${full_dirs[0]}"

printf "Starting SQL Restore\n" | adddate > $log_file 2>&1

# Use this to echo to standard error
error () {
    printf "%s: %s\n" "$(basename "${BASH_SOURCE}")" "${1}" | adddate >> $log_file 2>&1
	printf "%s: %s\n" "$(basename "${BASH_SOURCE}")" "${1}"
    exit 1
}

trap 'error "An unexpected error occurred.  Try checking the \"${log_file}\" file for more information."' ERR | adddate >> $log_file 2>&1

sanity_check () {
    # Check user running the script
    if [ "${USER}" != "${backup_owner}" ] && [ "${USER}" != "root" ]; then
        error "Script can only be run as the \"${backup_owner}\" user"
    fi
	
    # Check whether any arguments were passed
    if [ "${number_of_args}" -lt 1 ] || [[ ! "${@}" =~ ".xbstream" ]]; then
        error "Script requires at least one \".xbstream\" file as an argument."
		error "Example command: mysql_restore.sh /var/backups/mysql/$(date +%Y%m%d)/*.xbstream"
    fi

}

do_extraction () {
	files=$(ls ${@} 2> /dev/null | wc -l);
	if [ "$files" == "0" ] || [[ ! "${@}" =~ ".xbstream" ]]; then
		printf "\nThe files or folder %s do not exist! Canceling.\n" "${@}"
		printf "\nThe files/folders %s do not exist! Canceling.\n" "${@}" | adddate >> $log_file 2>&1
		exit
	else
		for file in "${@}"; do
			base_filename="$(basename "${file%.xbstream}")"
			restore_dir="./restore/${base_filename}"
			printf "\n\nRestore dir %s\n\n" "${restore_dir}"

			if [[ -d "${restore_dir}" ]]; then
				printf "\nDirectory %s already exists. Skipping extraction of %s\n" "${restore_dir}" "${file}"
				printf "\nDirectory %s already exists. Skipping extraction of %s\n" "${restore_dir}" "${file}" | adddate >> $log_file 2>&1
			else
				printf "\nExtracting file %s\n" "${file}" | adddate >> $log_file 2>&1
				printf "\nExtracting file %s\n" "${file}"

				# Extract the directory structure from the backup file
				mkdir --verbose -p "${restore_dir}" | adddate >> $log_file 2>&1
				xbstream -x -C "${restore_dir}" < "${file}" | adddate >> $log_file 2>&1
				
				mariabackup_args=(
					"--parallel=${processors}"
				)
				printf "Restoring file %s\n" "${file}" | adddate >> $log_file 2>&1
				printf "Restoring file %s\n" "${file}"
				mariabackup "${mariabackup_args[@]}" --target-dir="${restore_dir}" 2>> $log_file
				find "${restore_dir}" -name "*.xbcrypt" -exec rm {} \;
				find "${restore_dir}" -name "*.qp" -exec rm {} \;

				printf "\n\nFinished work on %s\n\n" "${file}" | adddate >> $log_file 2>&1
			fi

		done > "${log_file}" 2>&1
	fi
}

prepare_backup () {
    # Apply the logs to each of the backups
    printf "Initial prep of full backup %s\n" "${full_backup_dir}"
	printf "Initial prep of full backup %s\n" "${full_backup_dir}" | adddate >> $log_file 2>&1
	datadir=$(mariabackup |egrep  "datadir\s*/" |  awk '/datadir/{sub("datadir[[:blank:]]","");print}')
	ln -s /var/lib/mysql/backup-my.cnf ${full_backup_dir} 2> /dev/null
    mariabackup --prepare --apply-log-only --target-dir="${full_backup_dir}" 2>> $log_file

    for increment in "${incremental_dirs[@]}"; do
        printf "Applying incremental backup %s to %s\n" "${increment}" "${full_backup_dir}"
		printf "Applying incremental backup %s to %s\n" "${increment}" "${full_backup_dir}" | adddate >> $log_file 2>&1
        mariabackup --prepare --apply-log-only --incremental-dir="${increment}" --target-dir="${full_backup_dir}" 2>> $log_file
    done

    printf "Applying final logs to full backup %s\n" "${full_backup_dir}" | adddate >> $log_file 2>&1
	printf "Applying final logs to full backup %s\n" "${full_backup_dir}"
    mariabackup --prepare --target-dir="${full_backup_dir}" 2>> $log_file
}

sanity_check "$@" && do_extraction "$@" && prepare_backup "$@"

ok_count="$(grep -c 'completed OK' "${log_file}")"

if (( ${ok_count} == ${#full_dirs[@]} + ${#incremental_dirs[@]} + 1 )); then
    cat << EOF
Backup looks to be fully prepared.  Please check the log file
to verify before continuing.

If everything looks correct, you can apply the restored files.

First, stop MySQL 

        sudo systemctl stop mysql
		
Move or remove the contents of the MySQL data directory. Use one of the two commands:

        sudo mv /var/lib/mysql/ /tmp/
        sudo rm /var/lib/mysql/ -R

Then, recreate the data directory and copy the backup files, adjust permission and restart service:

        sudo mkdir /var/lib/mysql
        sudo mariabackup --copy-back --target-dir=${PWD}/$(basename "${full_backup_dir}")
        sudo chown -R mysql:mysql /var/lib/mysql
        sudo find /var/lib/mysql -type d -exec chmod 750 {} \\;
        sudo systemctl start mysql
		sudo mysql_upgrade --force
		sudo rm ${PWD}/restore -R
EOF
else
    error "It looks like something went wrong. OK count is ${ok_count}."
	error "You might need to delete the restore directory before retry. Check the \"${log_file}\" file for more information."
fi