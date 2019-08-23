#!/bin/bash
install_nodered () {
  NODERED_e=$(systemctl is-enabled nodered 2>&1 | tail -n 1)&> /dev/null
  if [[ $(echo $NODERED_e | grep "Failed") ]]; then
    NODERED_e="not installed"
  fi
  echo ""
  echo "NODERED: a programming tool for wiring together hardware devices, APIs and online services in new and interesting ways. (currently $NODERED_e)"
  if [[ $NODERED_e == "not installed" ]]; then
    select nodered_install in "Install" "Skip"; do
        case $nodered_install in
            Install ) cd /etc/ansible; ansible-playbook playbooks/nodered_Raspi3.yml; break;;
            Skip) echo "Skipping"; break;;
            *) echo "Skipping"; break;;
        esac
    done
  fi
  NODERED_e=$(systemctl is-enabled nodered 2>&1 | tail -n 1)&> /dev/null
  if [[ $(echo $NODERED_e | grep "Failed") ]]; then
    NODERED_e="not installed"
  fi
  if [[ ! $NODERED_e == "not installed" ]]; then
    echo ""
    echo "Do you want to enable Node-Red?"
    select homebridge in "Enable" "Disable" "Skip"; do
        case $homebridge in
            Enable ) sudo systemctl enable nodered; break;;
            Disable ) sudo systemctl disable nodered; break;;
            Skip) echo "Skipping"; break;;
            *) echo "Skipping"; break;;
        esac
    done
  fi
  NODERED_e=$(systemctl is-enabled nodered 2>&1 | tail -n 1)&> /dev/null
  if [[ $(echo $NODERED_e | grep "Failed") ]]; then
    NODERED_e="not installed"
  fi
  echo ""
  echo "NODE-RED Service is $NODERED_e."
}

raspi=$(grep "Revision" /proc/cpuinfo | awk -F': ' '{print $2}')
raspiversion=0
case $raspi in
    a02082 ) raspiversion=3;;
    a22082 ) raspiversion=3;;
    a01041 ) raspiversion=3;;
esac
if [[ $raspiversion == "3" ]]; then
  echo ""
  echo "It looks like you have a Raspberry Pi Version 3. Installing Node-Red"
  install_nodered

else
  echo ""
  echo "You need a Rasperry Pi 3 or better. Not installing Homebridge"
fi
