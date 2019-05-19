#!/bin/bash
RSA_FOLDER=/etc/ssl/easy-rsa
KEY_FOLDER=/etc/ssl/ca/

source /opt/setup/setup_certs.sh

nginx_config () {
    domain=$(grep "EASYRSA_REQ_CN" $RSA_FOLDER/vars | cut -d'"' -f 2)
    echo ""
    echo "Changing nginx config based on domain $domain"
    sudo sed -i 's/'DOMAIN_HERE'/'${domain}'/g' /etc/nginx/conf.d/https.conf 2>&1
    sudo sed -i 's/'DOMAIN_HERE'/'${domain}'/g' /etc/nginx/sites-available/default 2>&1
    sudo sed -i 's/#ssl_certificate/ssl_certificate/g' /etc/nginx/conf.d/https.conf 2>&1
    sudo sed -i 's/#ssl_certificate_key/ssl_certificate_key/g' /etc/nginx/conf.d/https.conf 2>&1
    sudo sed -i 's/#ssl_trusted_certificate/ssl_trusted_certificate/g' /etc/nginx/conf.d/https.conf 2>&1
    sudo sed -i 's/#ssl_client_certificate/ssl_client_certificate/g' /etc/nginx/conf.d/https.conf 2>&1
    sudo sed -i 's/#ssl_crl/ssl_crl/g' /etc/nginx/conf.d/https.conf 2>&1
    sudo sed -i 's/#ssl_verify_client/ssl_verify_client/g' /etc/nginx/conf.d/https.conf 2>&1
    sudo sed -i 's/#ssl_dhparam/ssl_dhparam/g' /etc/nginx/conf.d/https.conf 2>&1
    unset pw
    echo ""
    echo "You have to put your private key password in the lua script to make reverse proxy work correctly."
    echo "Either do it manually by changing first line in /etc/nginx/scripts/hass_access.lua."
    read -p "Or provide the password here and let me insert it automatically (Hit enter to skip): " pw
    if [ $pw ]; then
        sudo sed -i 's/'\<SECRETKEY' 'from' 'OPENSSL\>'/'$pw'/g' /etc/nginx/scripts/hass_access.lua 2>&1
    fi
    IP=$(sudo ip addr list eth0 |grep 'inet ' |cut -d' ' -f6|cut -d/ -f1)
    echo ""
    echo ""
    echo "Creating Letsencrypt certificate"
    goencrypt=False
    if sudo [ -f /etc/letsencrypt/live/${domain}/fullchain.pem ]; then
        echo ""
        echo "An SSL certificate is already created in /etc/letsencrypt/live/${domain}."
        echo "Do you want to create a new one or keep the current?"
        select lets in "Create" "Keep" "Skip"; do
            case $lets in
                Create ) goencrypt=True; break;;
                Keep ) goencrypt=False; echo "Keeping current SSL fullchain."; break ;;
                Skip ) echo "Skipping"; break;;
                *) echo "Skipping"; break;;
            esac
        done
    else
        goencrypt=True
    fi
    if [ $goencrypt = True ]; then
        echo "IMPORTANT: You HAVE to forward port 80 to your Raspi on your router now before you advance."
        echo "Did you forward port 80 to this Raspberry Pi (IP: $IP)?"
        select port in "Yes" "No" "Skip"; do
            case $port in
                Yes ) echo "Going on with creating the SSL certificate"; break;;
                No ) echo "You need to create SSL certificates for this to work. Anyhow, skipping now."; break;;
                Skip ) echo "Skipping SSL certificate creation"; break;;
                *) echo "Skipping"; break;;
            esac
        done
        sudo mkdir -p /var/www/letsencrypt/.well-known/acme-challenge 2>&1
        echo ""
        echo "Please provide your mail address in the next step."
        sudo certbot certonly --rsa-key-size 4096 --webroot -w /var/www/letsencrypt -d ${domain}
        echo ""
        echo "Now change the port forwarding from 80 to 443 on your router! Restarting nginx now."


    fi

}

reverseproxy () {
    if sudo [ -d "$RSA_FOLDER/pki" ]; then
      echo "There is already a keys directory in $RSA_FOLDER. Do you want to start certificate creation from scratch nevertheless?"
      echo "Important information: You can use the same certficates for openvpn, nginx reverse proxy and freeradius!"
      echo ""
      options=("Create new keys" "Show directory content" "Skip")
      select openvpn_keys in "${options[@]}"; do
          case $openvpn_keys in
              "Create new keys" ) create_servercerts; break;;
              "Show directory content" ) sudo ls $RSA_FOLDER/pki; echo ""; echo "Choose again: 1=Create new keys, 3=Skip" ;;
              "Skip" ) echo "Skipping"; break;;
              *) echo "Skipping"; break;;
          esac
      done
    else
        create_servercerts
    fi
    create_clientcerts
    echo "Finished certificate setup."
    nginx_config
    echo ""
    echo "Copy certificates to your client."
    echo "If you also want to use OpenVPN, just import the copied conf file to your favourite OpenVPN client (Tunnelblick, OpenVPN, etc.)"
    echo "Start and enable openvpn (later in the setup process)"
}

NGINX_e=$(systemctl is-enabled nginx 2>&1 | tail -n 1)&> /dev/null
echo ""
echo "nginx: Webserver, necessary for SmartVisu, Backend, etc. (currently $NGINX_e)"
select nginx in "Enable" "Disable" "Skip"; do
    case $nginx in
        Enable ) sudo systemctl enable nginx; break;;
        Disable ) sudo systemctl disable nginx; break;;
        Skip) echo "Skipping"; break;;
        *) echo "Skipping"; break;;
    esac
done
NGINX_e=$(systemctl is-enabled nginx 2>&1 | tail -n 1)&> /dev/null
echo ""
echo "nginx Service is $NGINX_e."
if [ $NGINX_e = "enabled" ]; then
    echo " The server is setup the following way to easily access your websites:"
    echo "http://<YOURIP>/smartVISU -> smartVISU 2.8"
    echo "http://<YOURIP>/smartVISU2.9 -> smartVISU 2.9"
    echo "http://<YOURIP>/backend-> SmarthomeNG Backend (if plugin is enabled in smarthome config)"
    echo "http://<YOURIP>/phpmyadmin -> Admin Tool to manage SQL database. Login is root/smarthome"
    echo "http://<YOURIP>/shnet -> SmarthomeNG Network Plugin. Port is configured to 8888. Change in /etc/nginx/sites-available/default"
    echo "http://<YOURIP>/monit -> If you enable monit (later) you can see the status of your services"
    echo "http://<YOURIP>/monitgraph -> If you enable monit (later) you can see graphs of your computer resources per service"
    echo "http://<YOURIP>/grafana -> If you enable influxdb and grafana (later) you can use time series databases"
    echo ""
    echo ""
    IP=$(sudo ip addr list eth0 |grep 'inet ' |cut -d' ' -f6|cut -d/ -f1)
    echo "You can setup nginx as a Reverse Proxy to securely access the listed websites from outside your home network."
    echo "To work correctly you need to forward port 443 in your router to the internal IP of this Raspberry Pi ($IP)."
    echo "Furthermore you need to activate a Dynamic DNS service on your Router or other network device!"
    select reverse in "Enable" "Disable" "Skip"; do
        case $reverse in
            "Enable" ) reverseproxy; break;;
            "Disable" ) echo "Please disable Port Forwarding on your router to disable reverse proxy functionality"; break;;
            "Skip" ) echo "Skipping"; break;;
            *) echo "Skipping"; break;;
        esac
    done
    sudo systemctl restart nginx

    FAIL2BAN_e=$(systemctl is-enabled fail2ban 2>&1)&> /dev/null
    echo ""
    echo "fail2ban: bans IP addresses that tried to access nginx webserver unsuccessfully (currently $FAIL2BAN_e)"
    select fail in "Enable" "Disable" "Skip"; do
        case $fail in
            Enable ) sudo systemctl enable fail2ban; break;;
            Disable ) sudo systemctl disable fail2ban; break;;
            Skip) echo "Skipping"; break;;
            *) echo "Skipping"; break;;
        esac
    done
    FAIL2BAN_e=$(systemctl is-enabled fail2ban 2>&1)&> /dev/null
    echo ""
    echo "fail2ban Service is $FAIL2BAN_e."

fi
