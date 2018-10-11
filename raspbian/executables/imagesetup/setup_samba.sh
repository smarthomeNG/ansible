#!/bin/bash
SAMBA_e=$(systemctl is-enabled smbd 2>&1 | tail -n 1)&> /dev/null
echo ""
echo "Samba: Access your folders via Windows Explorer, Apple Finder, etc.. (currently $SAMBA_e)"
select samba in "Enable" "Disable" "Skip"; do
    case $samba in
        Enable ) sudo systemctl enable smbd; sudo systemctl restart smbd; break;;
        Disable ) sudo systemctl disable smbd; break;;
        Skip) echo "Skipping"; break;;
        *) echo "Skipping"; break;;
    esac
done
SAMBA_e=$(systemctl is-enabled smbd 2>&1 | tail -n 1)&> /dev/null
echo ""
echo "Samba Service is $SAMBA_e. Config file is /etc/samba/smb.conf"
