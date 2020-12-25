#!/bin/bash
x=1
while ! ip route | grep -oP 'default via .+ dev eth0' && [ $x -le 10 ]; do
  sudo echo "interface not up, will try again in 1 second" >> /var/log/firstboot.log;
  sudo sleep 1;
  x=$(( $x + 1 ));
done

ETHIP=`hostname -I| cut -d' ' -f1-1|cut -d'.' -f1-3`

if [ -f /etc/exports ]; then
  if [ -z "$ETHIP" ]; then
    RES='Could not figure out IP address'
  else
    RES='Exchanging IP addresses for NFS Service with IP range '$ETHIP
    sudo sed -i -e 's/\([0-9]\{1,3\}\.\)\{2\}[0-9]\{1,3\}\./'${ETHIP}'\./' /etc/exports
  fi
else
    RES='No NFS exports file found, doing nothing.'
fi
sudo touch /var/log/firstboot.log
sudo echo ${RES} >> /var/log/firstboot.log

if [ -f /etc/dhcpcd.conf ] && [ ! -z "$ETH" ]; then
    RES='Exchanging Network device name in dhcpcd config file '$ETH
    sudo sed -i -e 's/eth_replace/'${ETH}'/' /etc/dhcpcd.conf
else
    RES='Network device name did not have to be changed.'
fi
sudo echo ${RES} >> /var/log/firstboot.log

if [ -f /etc/monit/monitrc ]; then
  if [ ! -z "$ETHIP" ]; then
    RES='Exchanging Network range in monitrc config file '$ETHIP
    sudo sed -i -e 's/allow \([0-9]\{1,3\}\.\)\{2\}[0-9]\{1,3\}\./allow '${ETHIP}'\./' /etc/monit/monitrc  2>&1
  fi
else
    RES='No changes for monit because config file does not exist.'
fi
sudo echo ${RES} >> /var/log/firstboot.log

if [ -e /dev/snd/controlC0 ]; then
    SOUNDCARD=`amixer scontrols | cut -d "'" -f 2`
    RES='Changing volume for sound card '$SOUNDCARD
    amixer sset $SOUNDCARD 95%
else
    RES='No soundcard found.'
fi
sudo echo ${RES} >> /var/log/firstboot.log


FIRSTBOOT_e=$(systemctl is-enabled firstboot 2>&1 | tail -n 1) &> /dev/null
x=1
while [[ $FIRSTBOOT_e == "enabled" ]] && [ $x -le 10 ]; do
  sudo echo "Disabling firstboot Service" >> /var/log/firstboot.log;
  sudo systemctl disable firstboot
  sudo sleep 2;
  FIRSTBOOT_e=$(systemctl is-enabled firstboot 2>&1 | tail -n 1) &> /dev/null
  x=$(( $x + 1 ));
done

if [ -f /etc/ssh/ssh_host_dsa_key ]; then
    RES='Deleting existing SSH host keys.'
    rm /etc/ssh/ssh_host_*
    #rm /root/.ssh/authorized_keys
fi
sudo echo ${RES} >> /var/log/firstboot.log
sudo /usr/bin/ssh-keygen -t dsa -N "" -f /etc/ssh/ssh_host_dsa_key
sudo /usr/bin/ssh-keygen -t rsa -N "" -f /etc/ssh/ssh_host_rsa_key
sudo /usr/bin/ssh-keygen -t ecdsa -N "" -f /etc/ssh/ssh_host_ecdsa_key
sudo /usr/bin/ssh-keygen -t ed25519 -N "" -f /etc/ssh/ssh_host_ed25519_key
sudo cp /etc/ssh/ssh_host_rsa_key.pub /root/.ssh/authorized_keys 2>&1
sudo cp /etc/ssh/ssh_host_rsa_key.pub /home/smarthome/.ssh/authorized_keys 2>&1
sudo chown smarthome:users /home/smarthome/.ssh/ -R
sudo chmod 700 /root/.ssh/ -R
sudo chmod 700 /home/smarthome/.ssh/ -R
sudo chmod 600 /home/smarthome/.ssh/authorized_keys
sudo chmod 600 /root/.ssh/authorized_keys
sudo cp /etc/ssh/ssh_host_rsa_key /home/smarthome/smarthomeng.private
sudo chown smarthome:smarthome /home/smarthome/smarthomeng.private
RES='Created new SSH host keys. Copy /etc/ssh/ssh_host_rsa_key to your client and connect as smarthome or root!'
sudo echo ${RES} >> /var/log/firstboot.log
#sudo raspi-config nonint do_expand_rootfs
#sudo partprobe
#RES='Expanded SD disk to full capacity.'
#sudo echo ${RES}
#sudo echo ${RES} >> /var/log/firstboot.log
#sudo reboot
