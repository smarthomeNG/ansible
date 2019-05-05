#!/bin/bash
RSA_FOLDER=/etc/ssl/easy-rsa
KEY_FOLDER=/etc/ssl/ca/

create_clientcerts() {
    cd $RSA_FOLDER
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
        if [ $client == "Squeezebox"]; then
          sudo openssl pkcs8 -topk8 -inform PEM -outform PEM -nocrypt -in $RSA_FOLDER/pki/private/Squeezebox.key -out $RSA_FOLDER/pki/private/Squeezebox_PKCS8.pem
          sudo cp $RSA_FOLDER/pki/private/Squeezebox_PKCS8.pem /home/smarthome/
        fi
        sudo cp /home/smarthome/openvpn_client_example.conf /home/smarthome/openvpn_$client.conf
        echo ""
        echo "Creating and setting up openvpn configuration file for your client $client in /home/smarthome."
        domain=$(sudo grep "Issuer: CN=" $RSA_FOLDER/pki/issued/server.crt | awk -F'Issuer: CN=' '{print $2}')
        sudo sed -i 's/'remote[[:space:]]*\<DOMAIN\>'/'remote' '${domain}'/g' /home/smarthome/openvpn_$client.conf 2>&1
        sudo sed -i 's/'pkcs12[[:space:]]*\<CLIENT\>'/'pkcs12' '${client}'/g' /home/smarthome/openvpn_$client.conf 2>&1
        create_clientcerts
    else
        echo ""
        echo "Creating client certificates finished. Copying all relevant server files for openvpn to $KEY_FOLDER"
        sudo mkdir $KEY_FOLDER/certs -p &> /dev/null
        sudo mkdir $KEY_FOLDER/private -p &> /dev/null
        sudo cp $RSA_FOLDER/pki/ca.crt $KEY_FOLDER/certs/ &> /dev/null
        sudo cp $RSA_FOLDER/pki/ca.pem $KEY_FOLDER/ &> /dev/null
        sudo cp $RSA_FOLDER/pki/private/ca.key $KEY_FOLDER/private/ &> /dev/null
        sudo cp $RSA_FOLDER/pki/crl.pem $KEY_FOLDER/private/ca.crl &> /dev/null
        sudo cp $RSA_FOLDER/pki/private/server.key $KEY_FOLDER/private/ &> /dev/null
        sudo cp $RSA_FOLDER/pki/issued/server.crt $KEY_FOLDER/certs/ &> /dev/null
        sudo cp $RSA_FOLDER/pki/dh.pem $KEY_FOLDER/ &> /dev/null
        sudo cp $RSA_FOLDER/pki/ta.key $KEY_FOLDER/ &> /dev/null
        sudo chmod 0740 $KEY_FOLDER -R &> /dev/null
        sudo chmod 0755 $KEY_FOLDER/private/ca.crl &> /dev/null

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
        echo ""
    fi
}

create_servercerts () {
    cd $RSA_FOLDER
    mv pki pki_backup &>/dev/null
    echo "If you had a previous pki folder it got copied to pki_backup."
    test=$(awk '/^#/ {f=0} /^if/ {f=1} !f;' $RSA_FOLDER/vars|grep -v -e '^$' | grep -v '#') 2>&1
    if [[ $test ]]; then
        echo ""
        echo "You have setup the variables for key generation like this:"
        awk '/^#/ {f=0} /^if/ {f=1} !f;' $RSA_FOLDER/vars|grep -v -e '^$' | grep -v '#' | while IFS= read -r line ; do
            echo "$line"
        done
        unset rerun
        echo ""
        echo "Do you want to change the configuration?"
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
        if [ $dh = "Create" ]; then
            sudo ./easyrsa gen-dh
            echo ""
            echo "Make sure the process was writing at least 10 lines with ... and +. Otherwise Ctrl-C and restart setup_nginx.sh."
            echo ""
        elif [ $dh = "Keep" ]; then
            sudo mv /tmp/dh.pem $RSA_FOLDER/pki/
        fi
        sudo ./easyrsa build-ca nopass
        sudo ./easyrsa gen-crl
        unset serverpass
        unset password
        echo ""
        echo "Please define whether your server certificate should be password protected or not."
        echo "As the server key file will never leave your server it is easier to use the NoPass option."
        echo ""
        echo "If yes: Be aware that you have to put the password in mods-enabled/eap as private_key_password."
        select clientpass in "Password" "NoPass"; do
            case $serverpass in
                "Password" ) password=''; echo "Setting a password for server certificates"; break;;
                "NoPass" ) password='nopass'; echo "Not setting a password for certificates"; break;;
                *) password='nopass'; echo "Skipping"; break;;
            esac
        done
        sudo ./easyrsa build-server-full server $password
        sudo /usr/bin/openssl pkcs12 -export -out pki/server.pfx -inkey pki/private/server.key -in pki/issued/server.crt -certfile pki/ca.crt

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
