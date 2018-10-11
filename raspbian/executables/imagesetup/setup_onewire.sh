#!/bin/bash
WIRE_e=$(systemctl is-enabled owserver 2>&1 | tail -n 1)&> /dev/null
echo ""
echo "1WIRE: Server for 1-Wire System. (currently $WIRE_e)"
select owserver in "Enable" "Disable" "Skip"; do
    case $owserver in
        Enable ) sudo systemctl enable owserver; sudo systemctl enable owhttpd; sudo systemctl restart owserver; sudo systemctl restart owhttpd; break;;
        Disable ) sudo systemctl disable owserver; sudo systemctl disable owhttpd; break;;
        Skip) echo "Skipping"; break;;
        *) echo "Skipping"; break;;
    esac
done
WIRE_e=$(systemctl is-enabled owserver 2>&1 | tail -n 1)&> /dev/null
echo ""
echo "1WIRE Service is $WIRE_e. Config file is /etc/owfs.conf"
