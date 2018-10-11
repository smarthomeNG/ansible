#!/bin/bash
KNXD_e=$(systemctl is-enabled knxd 2>&1 | tail -n 1)&> /dev/null
KNXD_v=$(knxd --v  2>&1| head -n 1 | awk -F'knxd ' '{print $2}' | awk -F'-' '{print $1}' | awk -F':' '{print $1}')&> /dev/null
KNXD_n=$(ls -l /etc/deb-files/knxd_* | sort -k9,9 -V --ignore-case | tail -n1 | awk -F'\\_armhf' '{print $1}'  | awk -F'knxd_' '{print $2}' | awk -F'-' '{print $1}' | awk -F':' '{print $1}')&> /dev/null
echo "KNXD: KNX Bus Connection. (currently $KNXD_e)"
select knxd in "Enable" "Disable" "Skip"; do
    case $knxd in
        Enable ) sudo systemctl enable knxd; break;;
        Disable ) sudo systemctl disable knxd; break;;
        Skip ) echo "Skipping"; break;;
        *) echo "Skipping"; break;;
    esac
done
echo ""
if [ $KNXD_e = "enabled" ]; then
    KNXD_e=$(systemctl is-enabled knxd 2>&1 | tail -n 1)&> /dev/null
    echo ""
    echo "KNXD Service is $KNXD_e. Currently $KNXD_v is installed."
    first_v=${KNXD_v%%.*}; last_v=${KNXD_v##*.}; mid_v=${KNXD_v##$first_v.}; mid_v=${mid_v%%.$last_v}
    first_n=${KNXD_n%%.*}; last_n=${KNXD_n##*.}; mid_n=${KNXD_n##$first_n.}; mid_n=${mid_n%%.$last_n}
    update=False
    if [ "$first_n" -ge "$first_v" ]; then
        if [ "$first_n" -gt "$first_v" ]; then update=True; fi
        if [ "$mid_n" -ge "$mid_v" ]; then
            if [ "$mid_n" -gt "$mid_v" ]; then update=True; fi
            if [ "$last_n" -ge "$last_v" ]; then
                if [ "$last_n" -gt "$last_v" ]; then update=True; fi
            fi
        fi
    fi
    if [ $update = True ]; then
        echo "There is a newer version of knxd available: $KNXD_n. Do you want to upgrade?"
        echo "WARNING: Some IP routers/interfaces might have problems with the newer version!"
        select knxd_upgrade in "Upgrade" "Keep" "Skip"; do
            case $knxd_upgrade in
                Upgrade )
                  sudo sed -i 's/KNXD_OPTS="/#KNXD_OPTS="/g' /etc/knxd.conf 2>&1
                  sudo sed -i 's/##*/#/g' /etc/knxd.conf 2>&1
                  sudo sed -i 's/#KNXD_OPTS=\/etc\/knxd.ini/KNXD_OPTS=\/etc\/knxd.ini/g' /etc/knxd.conf 2>&1
                  sudo dpkg -i /etc/deb-files/knxd-tools_*$first_n.$mid_n.$last_n*.deb /etc/deb-files/knxd*dbgsym*$first_n.$mid_n.$last_n*.deb /etc/deb-files/knxd_*$first_n.$mid_n.$last_n*.deb
                  break;;
                Keep) echo "Skipping knxd Upgrade"; break;;
                Skip ) echo "Skipping knxd Upgrade"; break;;
                *) echo "Skipping knxd Upgrade"; break;;
            esac
        done
    fi
    if [ $mid_v -gt 12 ]; then
        echo "If you have problems with the current knxd version, you can downgrade to v0.12. Do you want to downgrade or keep the current version?"
        select knxd_upgrade in "Downgrade" "Keep" "Skip"; do
            case $knxd_upgrade in
                Downgrade )
                  sudo sed -i 's/#KNXD_OPTS="/KNXD_OPTS="/g' /etc/knxd.conf 2>&1
                  sudo sed -i 's/KNXD_OPTS=\/etc\/knxd.ini/#KNXD_OPTS=\/etc\/knxd.ini/g' /etc/knxd.conf 2>&1
                  sudo dpkg -i /etc/deb-files/knxd-tools_*0.12*.deb /etc/deb-files/knxd*dbgsym*0.12*.deb /etc/deb-files/knxd_*0.12*.deb
                  break;;
                Keep) echo "Skipping knxd Downgrade"; break;;
                Skip ) echo "Skipping knxd Downgrade"; break;;
                *) echo "Skipping knxd Downgrade"; break;;
            esac
        done
    fi
    KNXD_v=$(knxd --v  2>&1| head -n 1 | awk -F'knxd ' '{print $2}' | awk -F'-' '{print $1}' | awk -F':' '{print $1}')&> /dev/null
    first_v=${KNXD_v%%.*}; last_v=${KNXD_v##*.}; mid_v=${KNXD_v##$first_v.}; mid_v=${mid_v%%.$last_v}
    echo ""
    echo "If errors occured while down/upgrading you might want to try a reboot after changing the config files to your needs."
    if [ $mid_v -le 12 ]; then
        echo "Please change the config to your needs: /etc/knxd.conf. Please read https://github.com/knxd/knxd/wiki"
    else
        echo "Please change the config to your needs: /etc/knxd.ini. You find example configs in the /etc/ folder. Please read https://github.com/knxd/knxd/wiki"
    fi
else
  KNXD_e=$(systemctl is-enabled knxd 2>&1 | tail -n 1)&> /dev/null
  echo "KNXD Service is $KNXD_e. Currently $KNXD_v is installed."
  echo "If you want to downgrade, run sudo dpkg -i knxd_*12*.deb knxd-tools_*12*.deb in folder /etc/deb-files/"
fi
