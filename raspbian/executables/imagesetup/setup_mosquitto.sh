#!/bin/bash
MOSQUITTO_e=$(systemctl is-enabled mosquitto 2>&1 | tail -n 1)&> /dev/null
echo ""
echo "MOSQUITTO: Broker for network communication protocol MQTT."
echo "You can use it with the corresponding smarthomeNG plugin to exchange item values between multiple smarthome instances or between different devices. (currently $MOSQUITTO_e)"
select mosquitto in "Enable" "Disable" "Skip"; do
    case $mosquitto in
        Enable ) sudo systemctl enable mosquitto; sudo systemctl restart mosquitto; break;;
        Disable ) sudo systemctl disable mosquitto; break;;
        Skip) echo "Skipping"; break;;
        *) echo "Skipping"; break;;
    esac
done
MOSQUITTO_e=$(systemctl is-enabled mosquitto 2>&1 | tail -n 1)&> /dev/null
echo ""
echo "MOSQUITTO Service is $MOSQUITTO_e. Config file is /etc/mosquitto/mosquitto.conf"
