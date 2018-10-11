#!/bin/bash
SQUEEZE_e=$(systemctl is-enabled squeezelite 2>&1 | tail -n 1)&> /dev/null
echo ""
echo "SQUEEZELITE: Headless Player for Logitech Squeezebox. (currently $SQUEEZE_e)"
select squeezelite in "Enable" "Disable" "Skip"; do
    case $squeezelite in
        Enable ) sudo systemctl enable squeezelite; sudo systemctl restart squeezelite; break;;
        Disable ) sudo systemctl disable squeezelite; break;;
        Skip) echo "Skipping"; break;;
        *) echo "Skipping"; break;;
    esac
done
SQUEEZE_e=$(systemctl is-enabled squeezelite 2>&1 | tail -n 1)&> /dev/null
echo ""
echo "SQUEEZELITE Service is $SQUEEZE_e. Config file is /usr/local/bin/squeezelite.sh"
