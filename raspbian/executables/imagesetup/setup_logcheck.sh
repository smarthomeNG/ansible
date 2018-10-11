#!/bin/bash
mail_alias () {
  echo "You have setup the variables for mail like this:"
  sudo awk '/^#/ {f=0} /^if/ {f=1} !f;' /etc/exim4/passwd.client|grep -v -e '^$' | grep -v '#' | while IFS= read -r line ; do
      echo "$line"
  done
  echo ""
  echo "Do you want to change the configuration?"
  select rerun in "Change" "Keep"; do
      case $rerun in
          "Change" ) break;;
          "Keep" ) break;;
          *) echo "Skipping"; break;;
      esac
  done
  if [ $rerun = "Change" ]; then
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

enable_logcheck () {
    if [[ $EXIM4_e = "disabled" ]]; then
        echo ""
        echo "EXIM4 is currently disabled. Logcheck only makes sense if you send the logfile reports to your mail account."
        exim4
    fi

    logcheck_test1=$(grep '^#@reboot' /etc/cron.d/logcheck)
    if [[ $logcheck_test1 ]]; then
        echo "Logcheck doesn't run on reboots now. Do you want to enable logcheck on bootup?"
        select logcheck in "Enable" "Disable" "Skip"; do
            case $logcheck in
                Enable ) sudo sed -i 's/^#@reboot/@reboot/1' /etc/cron.d/logcheck; break;;
                Disable ) echo "Keeping logcheck disabled on reboot"; break;;
                Skip) echo "Skipping"; break;;
                *) echo "Skipping"; break;;
            esac
        done
    fi
    logcheck_test2=$(grep '^#10' /etc/cron.d/logcheck)
    if [[ $logcheck_test2 ]]; then
        echo "Logcheck doesn't run every hour. Do you want to enable it? You can change the behaviour anytime by editing the file /etc/cron.d/logcheck"
        select logcheck in "Enable" "Disable" "Skip"; do
            case $logcheck in
                Enable ) sudo sed -i 's/^#10/10/1' /etc/cron.d/logcheck; break;;
                Disable ) echo "Keeping hourly logcheck disabled."; break;;
                Skip) echo "Skipping"; break;;
                *) echo "Skipping"; break;;
            esac
        done
    fi
    logcheck_test1=$(grep '^#@reboot' /etc/cron.d/logcheck)
    logcheck_test2=$(grep '^#10' /etc/cron.d/logcheck)
    if [[ ! $logcheck_test1+$logcheck_test2 ]]; then
        echo "Actually logcheck is still deactivated. Let's keep it like that for now ;)"
    else
        sudo sed -i 's/^#MAILTO/MAILTO/1' /etc/cron.d/logcheck
        mail_alias 'logcheck'
    fi

}

disable_logcheck () {
    logcheck_test=$(grep '^#@reboot' /etc/cron.d/logcheck)
    if [[ ! $logcheck_test ]]; then
        sudo sed -i 's/^@reboot/#@reboot/1' /etc/cron.d/logcheck
        echo "Logcheck on reboot disabled"
    fi
    logcheck_test=$(grep '^#10' /etc/cron.d/logcheck)
    if [[ ! $logcheck_test ]]; then
        sudo sed -i 's/^10/#10/1' /etc/cron.d/logcheck
        echo "Hourly logcheck disabled"
    fi
    logcheck_test=$(grep '^#MAILTO=' /etc/cron.d/logcheck)
    if [[ ! $logcheck_test ]]; then
        sudo sed -i 's/^MAILTO/#MAILTO/1' /etc/cron.d/logcheck
    fi
}

logcheck_test1=$(grep '#@reboot' /etc/cron.d/logcheck)
logcheck_test2=$(grep '#10' /etc/cron.d/logcheck)
LOGCHECK_e="enabled"
if [[ $logcheck_test1 ]]; then
    if [[ $logcheck_test2 ]]; then
        LOGCHECK_e="disabled"
    fi
fi
echo ""
echo "LOGCHECK: Test your logfiles for errors every hour and send a mail automatically if there are problems (currently $LOGCHECK_e)"
select logcheck in "Enable" "Disable" "Skip"; do
    case $logcheck in
        Enable ) enable_logcheck; break;;
        Disable ) disable_logcheck; break;;
        Skip) echo "Skipping"; break;;
        *) echo "Skipping"; break;;
    esac
done
logcheck_test1=$(grep '#@reboot' /etc/cron.d/logcheck)
logcheck_test2=$(grep '#10' /etc/cron.d/logcheck)
LOGCHECK_e="enabled"
if [[ $logcheck_test1 ]]; then
    if [[ $logcheck_test2 ]]; then
        LOGCHECK_e="disabled"
    fi
fi
echo ""
echo "LOGCHECK Service is $LOGCHECK_e. Config file is /etc/logcheck/logcheck.logfiles"
