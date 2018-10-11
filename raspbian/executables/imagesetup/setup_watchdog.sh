#!/bin/bash
WATCH_e=$(systemctl is-enabled watchdog 2>&1 | tail -n 1)&> /dev/null
echo ""
echo "WATCHDOG: Auto restart system on overload (currently $WATCH_e)"
select watchdog in "Enable" "Disable" "Skip"; do
    case $watchdog in
        Enable ) sudo systemctl enable watchdog; sudo systemctl restart watchdog; break;;
        Disable ) sudo systemctl disable watchdog; break;;
        Skip) echo "Skipping"; break;;
        *) echo "Skipping"; break;;
    esac
done
WATCH_e=$(systemctl is-enabled watchdog 2>&1 | tail -n 1)&> /dev/null
echo ""
echo "WATCHDOG Service is $WATCH_e. Config file is /etc/watchdog.conf. Be careful with it ;)"
