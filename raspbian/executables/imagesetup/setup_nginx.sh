#!/bin/bash
RSA_FOLDER=/etc/ssl/easy-rsa
KEY_FOLDER=/etc/ssl/ca/

create_clientcerts() {
    unset client
    echo ""
    read -p "Please define the name of your client (string like MacBook, iPhone, etc.). Hit Enter to create no (more) client certificates. " client
    if [ $client ]; then
        echo ""
        echo "Please define whether your certificate should be password protected when importing or not."
        unset clientpass
        select clientpass in "Password" "NoPass"; do
            case $clientpass in
                "Password" ) password=''; echo "Setting a password for $client"; break;;
                "NoPass" ) password='nopass'; echo "Not setting a password for $client"; break;;
                *) password='nopass'; echo "Skipping"; break;;
            esac
        done
        sudo ./easyrsa build-client-full $client $password
        echo ""
        echo "Creating pkcs12 file with suffix pfx. You can rename that p12 if needed. It's recommended to set a password."
        sudo /usr/bin/openssl pkcs12 -export -out pki/$client.pfx -inkey pki/private/$client.key -in pki/issued/$client.crt -certfile pki/ca.crt
        sudo cp $RSA_FOLDER/pki/$client.pfx /home/smarthome/
        sudo cp /home/smarthome/openvpn_client_example.conf /home/smarthome/openvpn_$client.conf
        echo ""
        echo "Creating and setting up openvpn configuration file for your client $client in /home/smarthome."
        domain=$(sudo grep "Issuer: CN=" $RSA_FOLDER/pki/issued/server.crt | awk -F'Issuer: CN=' '{print $2}')
        sudo sed -i 's/'remote[[:space:]]*\<DOMAIN\>'/'remote' '${domain}'/g' /home/smarthome/openvpn_$client.conf 2>&1
        sudo sed -i 's/'pkcs12[[:space:]]*\<CLIENT\>'/'pkcs12' '${client}'/g' /home/smarthome/openvpn_$client.conf 2>&1
        create_clientcerts
    else
        echo ""
        echo "Creating client certificates finished. Copying all relevant server files for openvpn/nginx to $KEY_FOLDER"
        sudo mkdir $KEY_FOLDER/certs -p 2>&1
        sudo mkdir $KEY_FOLDER/private -p 2>&1
        sudo cp $RSA_FOLDER/pki/ca.crt $KEY_FOLDER/certs/
        sudo cp $RSA_FOLDER/pki/ca.pem $KEY_FOLDER/
        sudo cp $RSA_FOLDER/pki/private/ca.key $KEY_FOLDER/private/
        sudo cp $RSA_FOLDER/pki/crl.pem $KEY_FOLDER/private/ca.crl
        sudo cp $RSA_FOLDER/pki/private/server.key $KEY_FOLDER/private/
        sudo cp $RSA_FOLDER/pki/issued/server.crt $KEY_FOLDER/certs/
        sudo cp $RSA_FOLDER/pki/dh.pem $KEY_FOLDER/
        sudo cp $RSA_FOLDER/pki/ta.key $KEY_FOLDER/
        sudo chmod 600 $KEY_FOLDER -R
        sudo chmod 755 $KEY_FOLDER/private/ca.crl

        echo "Folder content of $KEY_FOLDER"
        sudo sh -c "ls $KEY_FOLDER/*"
        echo ""
        echo "Client certificates and ca.crt are copied to /home/smarthome. Make sure to transfer them securely to your clients."
        echo "They are saved as pkcs12 with suffix pfx. You can change the suffix to p12 if needed."
        echo "If you need seperate crt and key files have a look at the folder $RSA_FOLDER/pki"
        sudo cp $RSA_FOLDER/pki/ca.crt /home/smarthome
        sudo cp $RSA_FOLDER/pki/ta.key /home/smarthome
        sudo chown smarthome:smarthome /home/smarthome/* -R
        echo ""
        echo "Folder content of /home/smarthome: "
        ls /home/smarthome
    fi
}

create_servercerts () {
    cd $RSA_FOLDER/
    if [[ $(awk '/^#/ {f=0} /^if/ {f=1} !f;' $RSA_FOLDER/vars|grep -v -e '^$' | grep -v '#') ]]; then
        echo ""
        echo "You have setup the variables for key generation like this:"
        awk '/^#/ {f=0} /^if/ {f=1} !f;' $RSA_FOLDER/vars|grep -v -e '^$' | grep -v '#' | while IFS= read -r line ; do
            echo "$line"
        done
        unset rerun
        echo ""
        echo "Do you want to change the configuration? It has to include your correct DNS entry for the variable EASYRSA_REQ_CN!"
        select rerun in "Change" "Keep"; do
            case $rerun in
                "Change" ) break;;
                "Keep" ) break;;
                *) echo "Skipping"; break;;
            esac
        done
    else
        rerun="Change"
    fi
    if [ $rerun = "Change" ]; then
        echo "Setting up variables for OpenVPN. Please provide the relevant information..."
        sudo cp $RSA_FOLDER/vars.example $RSA_FOLDER/vars
        sudo sed -i 's/#set_var EASYRSA_BATCH[[:space:]]*\".*\"/set_var EASYRSA_BATCH\t\t"yes"/g' $RSA_FOLDER/vars 2>&1
        unset country
        while ! [[ "$country" =~ ^[a-zA-Z]{2} ]]; do
            read -p "Please define the countrycode of your server (2 letter code like AT, DE, CH): " country
        done
        sudo sed -i 's/'EASYRSA_REQ_COUNTRY[[:space:]]*\".*\"'/'EASYRSA_REQ_COUNTRY'\t'\"${country^^}\"'/g' $RSA_FOLDER/vars 2>&1
        sudo sed -i 's/#set_var EASYRSA_REQ_COUNTRY/set_var EASYRSA_REQ_COUNTRY/g' $RSA_FOLDER/vars 2>&1
        unset city
        while ! [[ "$city" =~ ^[a-zA-Z]+$ ]]; do
            read -p "Please define the city of your server (string): " city
        done
        sudo sed -i 's/'EASYRSA_REQ_CITY[[:space:]]*\".*\"'/'EASYRSA_REQ_CITY'\t'\"${city^}\"'/g' $RSA_FOLDER/vars 2>&1
        sudo sed -i 's/#set_var EASYRSA_REQ_CITY/set_var EASYRSA_REQ_CITY/g' $RSA_FOLDER/vars 2>&1
        unset mail
        mail_regex="^[a-z0-9!#\$%&'*+/=?^_\`{|}~-]+(\.[a-z0-9!#$%&'*+/=?^_\`{|}~-]+)*@([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z0-9]([a-z0-9-]*[a-z0-9])?\$"
        while ! [[ "$mail" =~ $mail_regex ]]; do
            read -p "Please define your email (name@domain.tld): " mail
        done
        sudo sed -i 's/'EASYRSA_REQ_EMAIL[[:space:]]*\".*\"'/'EASYRSA_REQ_EMAIL'\t'\"${mail}\"'/g' $RSA_FOLDER/vars 2>&1
        sudo sed -i 's/#set_var EASYRSA_REQ_EMAIL/set_var EASYRSA_REQ_EMAIL/g' $RSA_FOLDER/vars 2>&1
        unset domain
        domain_regex="(^([a-zA-Z](([a-zA-Z0-9\-]){0,61}[a-zA-Z])\.){1,2}[a-zA-Z]{2,}$)"
        while ! [[ "$domain" =~ $domain_regex ]]; do
            read -p "Please define your common=domain name (xxx.domain.tld): " domain
        done
        sudo sed -i 's/'EASYRSA_REQ_CN[[:space:]]*\".*\"'/'EASYRSA_REQ_CN'\t\t'\"${domain}\"'/g' $RSA_FOLDER/vars 2>&1
        sudo sed -i 's/#set_var EASYRSA_REQ_CN/set_var EASYRSA_REQ_CN/g' $RSA_FOLDER/vars 2>&1
        echo ""
        echo "You have setup the variables for key generation like this:"
        awk '/^#/ {f=0} /^if/ {f=1} !f;' $RSA_FOLDER/vars|grep -v -e '^$' | grep -v '#' | while IFS= read -r line ; do
            echo "$line"
        done
        unset rerun
        echo ""
        echo "Do you want to re-run the configuration?"
        select rerun in "Re-Run" "Move-on"; do
            case $rerun in
                "Re-Run" ) create_servercerts; break;;
                "Move-on" ) break;;
                *) echo "Skipping"; break;;
            esac
        done
    fi
    createnew=True
    if sudo [ -f $RSA_FOLDER/pki/issued/server.crt ]; then
        unset new
        echo ""
        echo "Server certificate already exists. Do you want to start from scratch and create new server certificates?"
        select new in "Create" "Skip"; do
            case $new in
                "Create" ) createnew=True; break;;
                "Skip" ) createnew=False; echo "Skipping"; break;;
                *) echo "Skipping"; break;;
            esac
        done
    fi
    if [ $createnew = True ]; then
        echo ""
        echo "Initializing server certification process. Later you have to provide a password to protect your certificates (export password)."
        if sudo [ -f $RSA_FOLDER/pki/dh.pem ]; then
            unset dh
            echo ""
            echo "Diffie Hellman file already exists. Do you want to create a new one (takes some time)?"
            select dh in "Create" "Keep" "Skip"; do
                case $dh in
                    "Create" ) echo "Going to create dh file.."; break;;
                    "Keep" ) echo "Backing up dh.pem"; sudo cp $RSA_FOLDER/pki/dh.pem /tmp/; break;;
                    "Skip" ) echo "Skipping dh.pem. You should create it manually afterwards: cd $RSA_FOLDER && sudo ./easyrsa gen-dh"; break;;
                    *) echo "Skipping"; break;;
                esac
            done
        else
            dh="Create"
        fi
        sudo ./easyrsa init-pki
        sudo touch $RSA_FOLDER/pki/index.txt.attr
        sudo ./easyrsa build-ca nopass
        sudo ./easyrsa gen-crl
        sudo ./easyrsa build-server-full server nopass
        sudo /usr/bin/openssl pkcs12 -export -out pki/server.pfx -inkey pki/private/server.key -in pki/issued/server.crt -certfile pki/ca.crt
        if [ $dh = "Create" ]; then
            sudo ./easyrsa gen-dh
            echo ""
            echo "Make sure the process was writing at least 5 lines with ... and +. Otherwise Ctrl-C and restart setup_nginx.sh."
            echo ""
        elif [ $dh = "Keep" ]; then
            sudo cp /tmp/dh.pem $RSA_FOLDER/pki/
        fi
        sudo cat $RSA_FOLDER/pki/ca.crt $RSA_FOLDER/pki/private/ca.key > /tmp/ca.pem
        sudo mv /tmp/ca.pem $RSA_FOLDER/pki/
        echo "Server certificates were generated: ca.crt, ca.key, ca.pem, ca.crl (for revoking certificates), dh.pem, server.crt, server.key."
        echo "Creating ta.key (for openvpn)."
        sudo /usr/sbin/openvpn --genkey --secret pki/ta.key
        echo "Creating a random file (for freeradius)."
        sudo openssl rand -out $RSA_FOLDER/pki/random 128
        echo ""
        echo "Now you have to create a certificate for each client."
    fi
    sudo sed -i 's/#set_var EASYRSA_BATCH[[:space:]]*\".*\"/set_var EASYRSA_BATCH\t\t"yes"/g' $RSA_FOLDER/vars 2>&1
}

nginx_config () {
    domain=$(grep "EASYRSA_REQ_CN" $RSA_FOLDER/vars | cut -d'"' -f 2)
    echo ""
    echo "Changing nginx config based on domain $domain"
    sudo sed -i 's/'DOMAIN_HERE'/'${domain}'/g' /etc/nginx/conf.d/https.conf 2>&1
    sudo sed -i 's/'DOMAIN_HERE'/'${domain}'/g' /etc/nginx/sites-available/default.conf 2>&1
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
    echo "nginx Service is $FAIL2BAN_e."

fi
