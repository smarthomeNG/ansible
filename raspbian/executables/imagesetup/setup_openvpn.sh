#!/bin/bash
RSA_FOLDER=/etc/ssl/easy-rsa
KEY_FOLDER=/etc/ssl/ca

source /opt/setup/setup_certs.sh

openvpn_config () {
    if sudo [ -d "$RSA_FOLDER/pki" ]; then
      echo "There is already a keys directory in $RSA_FOLDER. Do you want to create new certificates nevertheless?"
      echo "Important information: You can use the same certficates for openvpn, nginx reverse proxy and freeradius!"
      echo ""
      options=("Create new keys" "Show directory content" "Skip")
      select openvpn_keys in "${options[@]}"; do
          case $openvpn_keys in
              "Create new keys" ) create_servercerts; break;;
              "Show directory content" ) sudo sh -c "ls $RSA_FOLDER/pki/*"; echo ""; echo "Choose again: 1=Create new keys, 3=Skip" ;;
              "Skip" ) echo "Skipping"; break;;
              *) echo "Skipping"; break;;
          esac
      done
    else
        create_servercerts
    fi
    create_clientcerts
    echo "Finished openvpn certificate setup."
    echo "Copy certificates and relevant conf file to your client and import the conf file to your favourite OpenVPN client (Tunnelblick, OpenVPN, etc.)"
    echo "When connecting, use smarthome as user and password. Use your private keypassword if prompted."
}

VPN_e=$(systemctl is-enabled openvpn@server.service 2>&1 | tail -n 1)&> /dev/null
echo ""
echo "OPENVPN: Connect to your Pi from outside securely (currently $VPN_e)"
select openvpn in "Enable" "Disable" "Skip"; do
    case $openvpn in
        Enable ) sudo systemctl enable openvpn@server.service; break;;
        Disable ) sudo systemctl disable openvpn@server.service; break;;
        Skip) echo "Skipping"; break;;
        *) echo "Skipping"; break;;
    esac
done
VPN_e=$(systemctl is-enabled openvpn@server.service 2>&1 | tail -n 1)&> /dev/null
echo ""
echo "OPENVPN Service is $VPN_e. Config file is /etc/openvpn/server.conf"
if [[ $VPN_e == "enabled" ]]; then
    openvpn_config
    sudo systemctl restart openvpn@server.service
fi
