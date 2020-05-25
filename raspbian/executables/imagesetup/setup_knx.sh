#!/bin/bash
KNXD_e=$(systemctl is-enabled knxd 2>&1 | tail -n 1) &> /dev/null
EIBD_e=$(systemctl is-enabled eibd 2>&1 | tail -n 1) &> /dev/null
if [[ ! -e /usr/bin/knxd ]]; then
  KNXD_e='not installed'
fi
if [[ ! -e /usr/local/bin/eibd ]]; then
  EIBD_e='not installed'
fi

knxd_old() {
    sudo sed -i 's/#KNXD_OPTS="/KNXD_OPTS="/g' /etc/knxd.conf 2>&1
    sudo sed -i 's/KNXD_OPTS=\/etc\/knxd.ini/#KNXD_OPTS=\/etc\/knxd.ini/g' /etc/knxd.conf 2>&1
    sudo dpkg -i /etc/deb-files/knxd-tools_*0.12*.deb /etc/deb-files/knxd*dbgsym*0.12*.deb /etc/deb-files/knxd_*0.12*.deb
}

knxd_buster() {
  sudo sed -i 's/KNXD_OPTS="/#KNXD_OPTS="/g' /etc/knxd.conf 2>&1
  sudo sed -i 's/##*/#/g' /etc/knxd.conf 2>&1
  sudo sed -i 's/#KNXD_OPTS=\/etc\/knxd.ini/KNXD_OPTS=\/etc\/knxd.ini/g' /etc/knxd.conf 2>&1
  sudo apt-get -y install knxd
  sudo apt-get -y install knxd-dev
  sudo apt-get -y install knxd-tools
}

knxd_new() {
  first_v=${KNXD_v%%.*}; last_v=${KNXD_v##*.}; mid_v=${KNXD_v##$first_v.}; mid_v=${mid_v%%.$last_v}
  first_n=${KNXD_n%%.*}; last_n=${KNXD_n##*.}; mid_n=${KNXD_n##$first_n.}; mid_n=${mid_n%%.$last_n}
  sudo sed -i 's/KNXD_OPTS="/#KNXD_OPTS="/g' /etc/knxd.conf 2>&1
  sudo sed -i 's/##*/#/g' /etc/knxd.conf 2>&1
  sudo sed -i 's/#KNXD_OPTS=\/etc\/knxd.ini/KNXD_OPTS=\/etc\/knxd.ini/g' /etc/knxd.conf 2>&1
  sudo dpkg -i /etc/deb-files/knxd-tools_*$first_n.$mid_n.$last_n*.deb /etc/deb-files/knxd*dbgsym*$first_n.$mid_n.$last_n*.deb /etc/deb-files/knxd_*$first_n.$mid_n.$last_n*.deb
}
install_knxd() {
  echo ""
  KNXD_n=$(ls -l /etc/deb-files/knxd_* | sort -k9,9 -V --ignore-case | tail -n1 | awk -F'\\_armhf' '{print $1}'  | awk -F'knxd_' '{print $2}' | awk -F'-' '{print $1}' | awk -F':' '{print $1}') &> /dev/null
  KNXD_o=$(ls -l /etc/deb-files/knxd_* | sort -k9,9 -V --ignore-case | head -n1 | awk -F'\\_armhf' '{print $1}'  | awk -F'knxd_' '{print $2}' | awk -F'-' '{print $1}' | awk -F':' '{print $1}') &> /dev/null
  KNXD_buster=$(apt-cache madison knxd | head -n1 | awk -F"|" '{print $2}'  | tr -d '[:space:]' | sed 's/-1//') &> /dev/null
  if [[ ! -e /usr/bin/knxd ]]; then
      echo "Uninstalling eibd.."
      sudo systemctl stop eibd
      sudo dpkg -r eibd
      sudo dpkg -r pthsem
      echo "Installing knxd.. Which version do you want to install?"
      options=($KNXD_o $KNXD_n $KNXD_buster "Skip")
      select knxd_install in "${options[@]}"; do
          case $knxd_install in
              $KNXD_o ) echo "Installing old version $KNXD_o"; knxd_old; break;;
              $KNXD_n) echo "Installing new version $KNXD_n"; knxd_new; break;;
              $KNXD_buster) echo "Installing latest buster version $KNXD_buster"; knxd_buster; break;;
              Skip ) echo "Skipping knxd install"; break;;
              *) echo "Skipping knxd install"; break;;
          esac
      done
  else
      KNXD_v=$(knxd --v  2>&1| head -n 1 | awk -F'knxd ' '{print $2}' | awk -F'-' '{print $1}' | awk -F':' '{print $1}') &> /dev/null
      echo ""
      echo "KNXD Service is $KNXD_e. Currently $KNXD_v is installed."
      first_v=${KNXD_v%%.*}; last_v=${KNXD_v##*.}; mid_v=${KNXD_v##$first_v.}; mid_v=${mid_v%%.$last_v}
      first_n=${KNXD_buster%%.*}; last_n=${KNXD_buster##*.}; mid_n=${KNXD_buster##$first_n.}; mid_n=${mid_n%%.$last_n}
      update=False
      if [ "$first_n" -ge "$first_v" ]; then
          if [ "$first_n" -gt "$first_v" ]; then update=True; fi
          if [ "$mid_n" -ge "$mid_v" ]; then
              if [ "$mid_n" -gt "$mid_v" ]; then update=True; fi
              if [ "$last_n" -gt "$last_v" ]; then update=True; fi
          fi
      fi
      if [ $update = True ]; then
          echo "There is a newer version of knxd available: $KNXD_buster. Do you want to upgrade?"
          echo "WARNING: Some IP routers/interfaces might have problems with the newer version!"
          select knxd_upgrade in "Upgrade" "Keep" "Skip"; do
              case $knxd_upgrade in
                  Upgrade ) echo "Installing new version"; knxd_buster; break;;
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
                  Downgrade ) echo "Installing old version"; knxd_old; break;;
                  Keep) echo "Skipping knxd Downgrade"; break;;
                  Skip ) echo "Skipping knxd Downgrade"; break;;
                  *) echo "Skipping knxd Downgrade"; break;;
              esac
          done
      fi
  fi
  KNXD_v=$(knxd --v  2>&1| head -n 1 | awk -F'knxd ' '{print $2}' | awk -F'-' '{print $1}' | awk -F':' '{print $1}') &> /dev/null
  first_v=${KNXD_v%%.*}; last_v=${KNXD_v##*.}; mid_v=${KNXD_v##$first_v.}; mid_v=${mid_v%%.$last_v}
  echo ""
  echo "If errors occured while down/upgrading you might want to try a reboot after changing the config files to your needs."
  if [ $mid_v -le 12 ]; then
      echo "Please change the config to your needs: /etc/knxd.conf. Please read https://github.com/knxd/knxd/wiki"
  else
      echo "Please change the config to your needs: /etc/knxd.ini. You find example configs in the /etc/ folder. Please read https://github.com/knxd/knxd/wiki"
  fi

  sudo systemctl enable knxd &> /dev/null
  sudo systemctl disable eibd &> /dev/null
  sudo systemctl start knxd
  KNXD_e=$(systemctl is-enabled knxd 2>&1 | tail -n 1) &> /dev/null
  echo "knxd is now $KNXD_e, version is $KNXD_v."
}

install_eibd() {
  echo "Uninstalling knxd.."
  sudo systemctl stop knxd.service
  sudo systemctl stop knxd.socket
  sudo dpkg -r knxd-tools-dbgsym
  sudo dpkg -r knxd-tools
  sudo dpkg -r knxd-dbgsym
  sudo dpkg -r knxd
  echo "Installing eibd.. "
  sudo dpkg -i /etc/deb-files/pthsem_2.0.8-1_armhf.deb
  sudo dpkg -i /etc/deb-files/eibd_0.0.5-1_armhf.deb
  sudo ldconfig
  sudo update-rc.d eibd defaults
  sudo systemctl start eibd
  sudo systemctl enable eibd
  sudo systemctl disable knxd.service &> /dev/null
  sudo systemctl disable knxd.socket &> /dev/null
  EIBD_e=$(systemctl is-enabled eibd 2>&1 | tail -n 1) &> /dev/null
  echo "eibd is now $EIBD_e."
  echo "Please change the config to your needs: /etc/init.d/eibd"
}


echo ""
echo "KNXD/EIBD: KNX Bus Connection. (currently knxd: $KNXD_e, eibd: $EIBD_e)"
echo "It is recommended to use the latest version of knxd."
echo "However there might be problems so you can choose to use the old eibd service instead."
echo "What do you want to use?"
select knxd in "knxd" "eibd" "nothing" "Skip"; do
    case $knxd in
        knxd ) install_knxd; break;;
        eibd ) install_eibd; break;;
        nothing ) sudo systemctl disable knxd &> /dev/null; sudo systemctl disable eibd &> /dev/null; break;;
        Skip ) echo "Skipping"; break;;
        *) echo "Skipping"; break;;
    esac
done
