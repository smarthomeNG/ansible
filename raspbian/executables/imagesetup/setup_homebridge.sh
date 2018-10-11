#!/bin/bash
install_homebridge () {
  HOMEBRIDGE_e=$(systemctl is-enabled homebridge 2>&1 | tail -n 1)&> /dev/null
  if [[ $(echo $HOMEBRIDGE_e | grep "Failed") ]]; then
    HOMEBRIDGE_e="not installed"
  fi
  echo ""
  echo "HOMEBRIDGE: Implement your Raspi in your Apple HomeKit environment. (currently $HOMEBRIDGE_e)"
  if [[ $HOMEBRIDGE_e = "not installed" ]]; then
    select homebridge_install in "Install" "Skip"; do
        case $homebridge_install in
            Install ) cd /etc/ansible; ansible-playbook playbooks/homebridge_Raspi3.yml; break;;
            Skip) echo "Skipping"; break;;
            *) echo "Skipping"; break;;
        esac
    done
  fi
  HOMEBRIDGE_e=$(systemctl is-enabled homebridge 2>&1 | tail -n 1)&> /dev/null
  if [[ $(echo $HOMEBRIDGE_e | grep "Failed") ]]; then
    HOMEBRIDGE_e="not installed"
  fi
  if [[ ! $HOMEBRIDGE_e = "not installed" ]]; then
    echo ""
    echo "Do you want to enable Homebridge?"
    select homebridge in "Enable" "Disable" "Skip"; do
        case $homebridge in
            Enable ) sudo systemctl enable homebridge; break;;
            Disable ) sudo systemctl disable homebridge; break;;
            Skip) echo "Skipping"; break;;
            *) echo "Skipping"; break;;
        esac
    done
  fi
  HOMEBRIDGE_e=$(systemctl is-enabled homebridge 2>&1 | tail -n 1)&> /dev/null
  if [[ $(echo $HOMEBRIDGE_e | grep "Failed") ]]; then
    HOMEBRIDGE_e="not installed"
  fi
  echo ""
  echo "HOMEBRIDGE Service is $HOMEBRIDGE_e. Config file is /home/smarthome/.homebridge/config.json"
  if [[ $HOMEBRIDGE_e = "enabled" ]]; then
    echo "Find the PIN code below:"
    sudo systemctl status homebridge --no-pager
  fi
}

raspi=$(grep "Revision" /proc/cpuinfo | awk -F': ' '{print $2}')
raspiversion=0
case $raspi in
    a02082 ) raspiversion=3;;
    a22082 ) raspiversion=3;;
    a01041 ) raspiversion=3;;
esac
if [ $raspiversion = "3" ]; then
  echo ""
  echo "It looks like you have a Raspberry Pi Version 3. Installing Homebridge"
  install_homebridge

else
  echo ""
  echo "You need a Rasperry Pi 3 or better. Not installing Homebridge"
fi
