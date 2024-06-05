#!/bin/bash
PATH=$PATH:/usr/lib/knxd:/opt/susvd:/opt/:/opt/setup:/home/smarthome/.local/bin:/home/smarthome/node_modules/.bin:/root/node_modules/.bin:/usr/local/smarthome/venvs/:/usr/local/smarthome/venvs/py_310/bin:/usr/local/smarthome/venvs/py_311/bin:/usr/local/smarthome/tools/
export MAKEFLAGS="-j 4"

# Color Tweaks
 export LS_OPTIONS='-lh -F --color=auto'

 alias e='grep --text "FATAL\|ERROR\|WARNING\|CRITICAL\|FAIL\|fatal\|error\|warn\|fail\|Fail"'
 eval "`dircolors`"
 alias ls='ls $LS_OPTIONS'
 alias la='ls -A'
 alias errorgrep='grep --text "FATAL\|ERROR\|WARNING\|CRITICAL\|FAIL\|fatal\|error\|warn\|fail\|Fail" -i --color=auto'
 alias cli='rlwrap telnet 127.0.0.1 2323'
 alias ..='cd ..'
 alias cleanexim="exim -bp|grep frozen | awk '{print $3}' | xargs exim -Mrm && sudo /usr/sbin/exim_tidydb -t 1d /var/spool/exim retry > /dev/null && sudo rm -rf /var/spool/exim/db/retry*"
 alias cleanbash='/usr/local/bin/cleanbash.sh'

# Uses Colorize Script in /usr/local/bin
 ctail() { tail -f "$1" -n 400 | colorize yellow '.*[Ww][Aa][Rr][Nn].*' purple '.*[Ee][Rr][Rr][Oo][Rr].*' purple '.*[Ff][Aa][Ii][Ll].*' red '.*[Cc][Rr][Ii][Tt][Ii][Cc][Aa][Ll].*' red '.*[Ff][Aa][Tt][Aa][Ll].*' ;}
 ccat() { cat "$1" | colorize yellow '.*[Ww][Aa][Rr][Nn].*' purple '.*[Ee][Rr][Rr][Oo][Rr].*' purple '.*[Ff][Aa][Ii][Ll].*' red '.*[Cc][Rr][Ii][Tt][Ii][Cc][Aa][Ll].*' red '.*[Ff][Aa][Tt][Aa][Ll].*' ;}

 etail() { tail -f "$1" -n 400 | e | colorize yellow '.*[Ww][Aa][Rr][Nn].*' purple '.*[Ee][Rr][Rr][Oo][Rr].*' purple '.*[Ff][Aa][Ii][Ll].*' red '.*[Cc][Rr][Ii][Tt][Ii][Cc][Aa][Ll].*' red '.*[Ff][Aa][Tt][Aa][Ll].*' ;}
 ecat() { cat "$1" | e | colorize yellow '.*[Ww][Aa][Rr][Nn].*' purple '.*[Ee][Rr][Rr][Oo][Rr].*' purple '.*[Ff][Aa][Ii][Ll].*' red '.*[Cc][Rr][Ii][Tt][Ii][Cc][Aa][Ll].*' red '.*[Ff][Aa][Tt][Aa][Ll].*' ;}

 alias sh.log="tail -f -n 300 /usr/local/smarthome/var/log/smarthome-details.log | colorize green '.*INFO.*' yellow '.*WARNING.*' purple '.*ERROR.*' purple '.*FAIL.*'"
 alias sh.details="tail -f -n 300 /usr/local/smarthome/var/log/smarthome-details.log | colorize green '.*INFO.*' yellow '.*WARNING.*' purple '.*ERROR.*' purple '.*FAIL.*'"
 alias sh.error="tail -f -n 1000 /usr/local/smarthome/var/log/smarthome-warnings.log | colorize green '.*INFO.*' yellow '.*WARNING.*' purple '.*ERROR.*' purple '.*FAIL.*'"
 alias sh.warnings="tail -f -n 1000 /usr/local/smarthome/var/log/smarthome-warnings.log | colorize green '.*INFO.*' yellow '.*WARNING.*' purple '.*ERROR.*' purple '.*FAIL.*'"
 alias sh.debug="tail -f -n 300 /usr/local/smarthome/var/log/smarthome-develop.log | colorize green '.*INFO.*' yellow '.*WARNING.*' purple '.*ERROR.*' purple '.*FAIL.*'"
 alias sh.develop="tail -f -n 300 /usr/local/smarthome/var/log/smarthome-develop.log | colorize green '.*INFO.*' yellow '.*WARNING.*' purple '.*ERROR.*' purple '.*FAIL.*'"

 findsize() { find . -path /mnt -prune -o -type f -size +$1 -exec ls -lh {} \; 2>&1 | awk '{ print $9 ": " $5 }'; }
 adddate() {
     while IFS= read -r line; do
         echo "$(date) $line"
     done
 }
# Tweak Ignore Duplicate Entries in History
HISTCONTROL=ignoreboth

#apt-get history
function apt-history(){
      case "$1" in
        install)
              cat /var/log/dpkg.log | grep 'install '
              ;;
        upgrade|remove)
              cat /var/log/dpkg.log | grep $1
              ;;
        rollback)
              cat /var/log/dpkg.log | grep upgrade | \
                  grep "$2" -A10000000 | \
                  grep "$3" -B10000000 | \
                  awk '{print $4"="$5}'
              ;;
        *)
              cat /var/log/dpkg.log
              ;;
      esac
}

# Show up time
let upSeconds="$(/usr/bin/cut -d. -f1 /proc/uptime)"
let secs=$((${upSeconds}%60))
let mins=$((${upSeconds}/60%60))
let hours=$((${upSeconds}/3600%24))
let days=$((${upSeconds}/86400))
UPTIME=`printf "%d days, %02dh%02dm%02ds" "$days" "$hours" "$mins" "$secs"`

source /usr/local/smarthome/tools/act 310

echo "$(tput setaf 2)
SmartHome Raspi running for: ${UPTIME}
$(tput sgr0)"
FIRSTBOOT_e=$(systemctl is-enabled firstboot 2>&1 | tail -n 1) &> /dev/null

if [ -e /var/log/firstboot.log ] && [[ $FIRSTBOOT_e == "disabled" ]] ; then
  echo "$(tput setaf 2)Welcome to Smarthome Image 12.1.10 - At your first boot these changes were made:"
  echo "$(</var/log/firstboot.log)"
  echo "$(tput sgr0)"
  sudo mv /var/log/firstboot.log /var/log/firstboot_finished.log
  echo "It is recommended to run setup_all now to adjust services and configs."
fi
