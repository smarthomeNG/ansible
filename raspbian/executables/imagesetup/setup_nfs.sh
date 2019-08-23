#!/bin/bash
NFS_e=$(systemctl is-enabled nfs-server 2>&1 | tail -n 1)&> /dev/null
echo ""
echo "NFS: Similar to Samba but maybe preferrable (currently $NFS_e)"
select nfs in "Enable" "Disable" "Skip"; do
    case $nfs in
        Enable ) sudo systemctl enable nfs-server; break;;
        Disable ) sudo systemctl disable nfs-server; break;;
        Skip) echo "Skipping"; break;;
        *) echo "Skipping"; break;;
    esac
done
NFS_e=$(systemctl is-enabled nfs-server 2>&1 | tail -n 1)&> /dev/null
if [[ $NFS_e == "enabled" ]]; then
  ETH=`sudo dmesg | grep -Po '\K\b[[:alnum:]]+\b: renamed from eth' | cut -d ':' -f 1`
  if [ ! -z "$ETH" ]; then
      ETHIP=`sudo ip addr list $ETH |grep 'inet ' |cut -d' ' -f6|cut -d/ -f1|cut -d'.' -f1-3`
  else
      ETHIP=`sudo ip addr list eth0 |grep 'inet ' |cut -d' ' -f6|cut -d/ -f1|cut -d'.' -f1-3`
  fi
  if [ -z "$ETHIP" ]; then
    echo 'Could not figure out IP address'
  else
    sudo sed -i -e 's/\([0-9]\{1,3\}\.\)\{2\}[0-9]\{1,3\}\./'${ETHIP}'\./' /etc/exports 2>&1
  fi
fi
if [[ $EXIM4_e == "enabled" ]]; then
  sudo systemctl restart nfs-server;
fi
echo ""
echo "NFS Service is $NFS_e. Config file is /etc/exports"
