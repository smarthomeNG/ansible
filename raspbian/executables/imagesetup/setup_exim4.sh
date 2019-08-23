#!/bin/bash
mail_alias () {
  echo "You have setup the variables for mail like this:"
  sudo awk '/^#/ {f=0} /^if/ {f=1} !f;' /etc/exim4/passwd.client|grep -v -e '^$' | grep -v '#' | while IFS= read -r line ; do
      echo "$line"
  done
  echo ""
  echo "Do you want to change the configuration?"
  rerun="Keep"
  select rerun in "Change" "Keep"; do
      case $rerun in
          "Change" ) break;;
          "Keep" ) break;;
          *) echo "Skipping"; break;;
      esac
  done
  if [[ $rerun == "Change" ]]; then
    mail_regex="^[a-z0-9!#\$%&'*+/=?^_\`{|}~-]+(\.[a-z0-9!#$%&'*+/=?^_\`{|}~-]+)*@([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z0-9]([a-z0-9-]*[a-z0-9])?\$"
    while ! [[ "$mail" =~ $mail_regex ]]; do
        read -p "Please define your email where $1 summary should be sent to (name@domain.tld): " mail
    done
    sudo sed -i 's/'$1:.*'/'$1:' '${mail}'/g' /etc/email-addresses 2>&1
    sudo sed -i 's/'root:.*'/'root:' '${mail}'/g' /etc/aliases 2>&1
    domain_regex="(^([a-zA-Z](([a-zA-Z0-9\-\_]){0,61}[a-zA-Z0-9\-\_])\.){1,6}[a-zA-Z]{2,}$)"
    while ! [[ "$domain" =~ $domain_regex ]]; do
        read -p "Please define your mail server (*.domain.tld): " domain
    done
    read -p "Please define the username for your mail login: " user
    read -p "Please define the password for your mail login: " password
    sudo echo $domain:$user:$password >> /tmp/passwd.client
    sudo mv /tmp/passwd.client /etc/exim4/
    echo "The mail information is saved in the file /etc/exim4/passwd.client."
  fi
}

EXIM4_e=$(systemctl is-enabled exim4 2>&1 | tail -n 1)&> /dev/null
if [[ $(echo $EXIM4_e | grep "Failed") ]]; then
  EXIM4_e="not installed"
fi
echo ""
echo "EXIM4: allows you to send mails from your Raspberry Pi. This is useful for monit and logcheck and the mail plugin of SmarthomeNG. (currently $EXIM4_e)"
if [[ $EXIM4_e == "not installed" ]]; then
  unset exim4_install
  select exim4_install in "Install" "Skip"; do
      case $exim4_install in
          Install ) sudo ansible-playbook /etc/ansible/playbooks/11_exim4.yml; break;;
          Skip) echo "Skipping"; break;;
          *) echo "Skipping"; break;;
      esac
  done
fi
echo "Do you want to enable the service automatically on startup?"
select exim4 in "Enable" "Disable" "Skip"; do
    case $exim4 in
        Enable ) sudo systemctl enable exim4; break;;
        Disable ) sudo systemctl disable exim4; break;;
        Skip) echo "Skipping"; break;;
        *) echo "Skipping"; break;;
    esac
done
EXIM4_e=$(systemctl is-enabled exim4 2>&1 | tail -n 1)&> /dev/null
echo ""
echo "EXIM4 Service is $EXIM4_e."
if [[ $EXIM4_e == "enabled" ]]; then
    echo "Do you want to run the exim4 configuration process now?"
    select exim4_conf in "Config" "Skip"; do
        case $exim4_conf in
            Config ) mail_alias; break;;
            Skip) echo "Skipping"; break;;
            *) echo "Skipping"; break;;
        esac
    done
    sudo systemctl restart exim4
    echo "You can (re)run the mail setup process by using sudo dpkg-reconfigure exim4-config"
fi
