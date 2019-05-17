#!/bin/bash
wlan_setup () {
  read -p "Please define the SSID: " ssid
  read -p "Please define the password. It will be saved as plaintext in the wpa-supplicant file: " password
  sudo wpa_passphrase ${ssid} ${password} >> /etc/wpa_supplicant/wpa_supplicant.conf 2>&1
  sudo sed -i '/#psk=/d' /etc/wpa_supplicant/wpa_supplicant.conf 2>&1
  echo "File /etc/wpa_supplicant/wpa_supplicant.conf is updated. Plain text password removed."
  sudo wpa_cli -i wlan0 reconfigure
  sudo systemctl enable wpa_supplicant
  sudo systemctl start wpa_supplicant
  sudo ifconfig wlan0 down
  echo "Please enable the WLAN adapter manually whenever you want by typing: sudo ifconfig wlan0 up"
}

echo ""
echo "Do you want to update your language setting or install new locales?"
select lang in "Update" "Skip"; do
    case $lang in
        Update ) sudo dpkg-reconfigure locales; break;;
        Skip) echo "Skipping"; break;;
        *) echo "Skipping"; break;;
    esac
done

echo ""
echo "Do you want to activate automatic system updates?"
echo "(apt-get update && upgrade once a day using unattendedupgrades Package)"
select unattended in "Activate" "Deactivate" "Skip"; do
    case $unattended in
        Activate ) sudo sed -i 's/"0"/"1"/g' /etc/apt/apt.conf.d/20auto-upgrades 2>&1; break;;
        Deactivate ) sudo sed -i 's/"1"/"0"/g' /etc/apt/apt.conf.d/20auto-upgrades 2>&1; break;;
        Skip) echo "Skipping"; break;;
        *) echo "Skipping"; break;;
    esac
done

echo ""
echo "Do you want to setup WLAN?"
select wlan in "Setup" "Skip"; do
    case $wlan in
        Setup ) wlan_setup; break;;
        Skip) echo "Skipping"; break;;
        *) echo "Skipping"; break;;
    esac
done

echo ""
echo "Do you want to change the hostname of your Raspi or keep SmarthomeNG?"
select name in "Change" "Skip"; do
    case $name in
        Change ) echo "Changing hostname..."; break;;
        Skip) echo "Skipping"; break;;
        *) echo "Skipping"; break;;
    esac
done
if [ $name = "Change" ]; then
  read -p "Please define your hostname (without any spaces): " newhost
  sudo hostnamectl set-hostname ${newhost}
  sudo sed -i 's/SmarthomeNG/'${newhost}'/g' /etc/hosts 2>&1
  echo "Changes hostname to $newhost"
fi

recommended=$(($(free -m|awk '$1=="Mem:"{print $2}')*2))
echo ""
echo "Do you want to change the Swap file on your Raspberry Pi?"
SWAP_e=$(systemctl is-enabled dphys-swapfile 2>&1 | tail -n 1)&> /dev/null
echo "Swap File is currently $SWAP_e."
echo "It is recommended to deactivate (set to 0) the Swapping in general"
echo "If you still want to use it (e.g. for compiling) you might want to set the swap to $recommended MB."
echo "That is around double the size of the phsyical RAM of your Pi."
read -p "Please define the size of your swap file in MB (0 or any non-number to deactivate): " swapsize
if [[ -n ${swapsize//[0-9]/} || $swapsize == 0 ]]; then
    echo "Swapping is disabled."
    sudo dphys-swapfile swapoff
    sudo systemctl disable dphys-swapfile
else
    sudo systemctl stop dphys-swapfile
    sudo sed -i 's/'CONF_SWAPSIZE=[[:space:]]*[[:digit:]]*'/'CONF_SWAPSIZE=''${swapsize}'/g' /etc/dphys-swapfile 2>&1
    sleep 3
    sudo dphys-swapfile swapon
    sudo systemctl start dphys-swapfile
    sudo systemctl enable dphys-swapfile
fi
SWAP_e=$(systemctl is-enabled dphys-swapfile 2>&1 | tail -n 1)&> /dev/null
echo "Swap File is $SWAP_e."