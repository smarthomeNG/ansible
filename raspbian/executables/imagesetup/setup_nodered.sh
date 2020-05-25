#!/bin/bash
NODERED_e=$(systemctl is-enabled nodered 2>&1 | tail -n 1)&> /dev/null
echo ""
echo "NODERED: visual programming tool for wiring up devices (currently $NODERED_e)"
select nodered in "Enable" "Disable" "Skip"; do
    case $nodered in
        Enable ) sudo systemctl enable nodered; sudo systemctl restart nodered; break;;
        Disable ) sudo systemctl disable nodered; break;;
        Skip) echo "Skipping"; break;;
        *) echo "Skipping"; break;;
    esac
done
NODERED_e=$(systemctl is-enabled nodered 2>&1 | tail -n 1)&> /dev/null
echo ""
echo "NODERED Service is $NODERED_e. Open your browser http://IP/nodered"
