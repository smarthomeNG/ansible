#!/bin/bash
LIRC_e=$(systemctl is-enabled lircd 2>&1 | tail -n 1)&> /dev/null
echo ""
echo "LIRC: Integrate infrared receive/send. Extra IR hardware needed. (currently $LIRC_e)"
select lirc in "Enable" "Disable" "Skip"; do
    case $lirc in
        Enable ) sudo systemctl enable lircd; sudo systemctl restart lircd; break;;
        Disable ) sudo systemctl disable lircd; break;;
        Skip) echo "Skipping"; break;;
        *) echo "Skipping"; break;;
    esac
done
LIRC_e=$(systemctl is-enabled lircd 2>&1 | tail -n 1)&> /dev/null
echo ""
echo "LIRC Service is $LIRC_e. Config file is /etc/lirc/lirc_options.conf"
