#!/bin/bash
sql_backupconfig () {
    echo "Should the automatic sql backup be enabled or disabled?"
    backup_conf1="Skip"
    select backup_conf1 in "Enable" "Disable" "Skip"; do
        case $backup_conf1 in
            Enable ) sudo sed -i 's/RUNBACKUPS=[a-zA-Z0-9]*/RUNBACKUPS=True/1' /etc/cron.hourly/mysql_backup 2>&1; break;;
            Disable) sudo sed -i 's/RUNBACKUPS=[a-zA-Z0-9]*/RUNBACKUPS=False/1' /etc/cron.hourly/mysql_backup 2>&1; break;;
            Skip) echo "Skipping"; break;;
            *) echo "Skipping"; break;;
        esac
    done
    if [ $backup_conf1 == "Enable" ]; then
        unset backup_keep
        while ! [[ "$backup_keep" =~ ^[0-9]+$ ]]; do
            echo "MySQL Backup is enabled."
            read -p "Please define the number of backups that should be kept in the folder: " backup_keep
        done
        sudo sed -i 's/'MAXKEEP=[0-9]*'/'MAXKEEP="$backup_keep"'/1' /etc/cron.hourly/mysql_backup
        echo "MySQL Backup will keep the latest ${backup_keep} backups."
    fi
}

SQL_e=$(systemctl is-enabled mysql 2>&1 | tail -n 1)&> /dev/null
echo ""
echo "MYSQL: Database alternative to sqlite. Recommended to use in conjunction with the database plugin (currently $SQL_e)"
select mysql in "Enable" "Disable" "Skip"; do
    case $mysql in
        Enable ) sudo systemctl enable mysql; break;;
        Disable ) sudo systemctl disable mysql; sudo sed -i 's/RUNBACKUPS=[a-zA-Z0-9]*/RUNBACKUPS=False/1' /etc/cron.hourly/mysql_backup 2>&1; break;;
        Skip) echo "Skipping"; break;;
        *) echo "Skipping"; break;;
    esac
done
SQL_e=$(systemctl is-enabled mysql 2>&1 | tail -n 1)&> /dev/null
echo ""
echo "MYSQL Service is $SQL_e. Config file is /etc/mysql/debian.cnf"
if [ $SQL_e == "enabled" ]; then
    echo ""
    echo "An automatic backup of your database will be created every hour in the folder /var/backups/mysql."
    echo "A maxmimum number of the 5 most recent backups is kept."
    sql_backupconfig
    sudo systemctl restart mysql;
fi
