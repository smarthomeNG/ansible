#!/bin/bash
MONIT_e=$(systemctl is-enabled monit 2>&1 | tail -n 1)&> /dev/null
echo ""
echo "MONIT: Monitor your services and automatically restart them on errors (currently $MONIT_e)"
select monit in "Enable" "Disable" "Skip"; do
    case $monit in
        Enable ) sudo systemctl enable monit; break;;
        Disable ) sudo systemctl disable monit; break;;
        Skip) echo "Skipping"; break;;
        *) echo "Skipping"; break;;
    esac
done
MONIT_e=$(systemctl is-enabled monit 2>&1 | tail -n 1)&> /dev/null
if [[ $MONIT_e == "enabled" ]]; then
  ETH=`sudo dmesg | grep -Po '\K\b[[:alnum:]]+\b: renamed from eth' | cut -d ':' -f 1`
  if [ ! -z "$ETH" ]; then
      ETHIP=`sudo ip addr list $ETH |grep 'inet ' |cut -d' ' -f6|cut -d/ -f1|cut -d'.' -f1-3`
  else
      ETHIP=`sudo ip addr list eth0 |grep 'inet ' |cut -d' ' -f6|cut -d/ -f1|cut -d'.' -f1-3`
  fi
  sudo sed -i -e 's/allow \([0-9]\{1,3\}\.\)\{2\}[0-9]\{1,3\}\./allow '${ETHIP}'\./' /etc/monit/monitrc  2>&1
  sudo sed -i -e 's/#\*/*/' /etc/cron.d/monitgraph 2>&1
  sudo systemctl restart monit
else
  sudo sed -i -e 's/^\*/#*/' /etc/cron.d/monitgraph 2>&1
fi
echo ""
echo "MONIT Service is $MONIT_e. Config file is /etc/monit/monitrc"
