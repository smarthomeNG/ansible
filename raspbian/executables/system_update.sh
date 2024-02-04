#!/bin/bash
echo "Updating System Packages"
sudo apt-get update
sudo apt-get dist-upgrade
echo "Fixing debian.cnf permissions"
sudo chown mysql:mysql /etc/mysql/debian.cnf
sudo chmod 0644 /etc/mysql/debian.cnf
echo "Do you want to update SmarthomeNG?"
echo "WARNING: Any changes to the source code/plugins you made manually are lost. Back them up now and proceed later."
sh="Skip"
select sh in "Update" "Skip"; do
    case $sh in
        "Update" ) break;;
        "Skip" ) break;;
        *) echo "Skipping"; break;;
    esac
done

if [ $sh = "Update" ]; then
  version=$(cd /usr/local/smarthome && git status |grep "[bB]ranch"|head -n1|awk -F' ' '{print $NF}')
  echo "Do you want to update to the latest Master or Develop version?"
  echo "Currently $version is installed."
  unset tree
  select tree in "Master" "Develop"; do
      case $tree in
          "Master" ) break;;
          "Develop" ) break;;
          *) echo "Skipping"; break;;
      esac
  done
  if [ $tree = "Develop" ]; then
    git config --global --add safe.directory /usr/local/smarthome
    git config --global --add safe.directory /usr/local/smarthome/plugins
    echo 'Updating SmarthomeNG to latest develop version'
    cd /usr/local/smarthome
    sudo git stash
    sudo git checkout develop
    sudo git pull origin develop
    cd /usr/local/smarthome/plugins
    sudo git stash
    sudo git checkout develop
    sudo git pull origin develop
  elif [ $tree = "Master" ]; then
    git config --global --add safe.directory /usr/local/smarthome
    git config --global --add safe.directory /usr/local/smarthome/plugins
    echo 'Updating SmarthomeNG to latest master version'
    cd /usr/local/smarthome
    sudo git stash
    sudo git checkout master
    sudo git pull origin master
    cd /usr/local/smarthome/plugins
    sudo git stash
    sudo git checkout master
    sudo git pull origin master
  fi
  sudo chown smarthome:smarthome /usr/local/smarthome -R
  sudo chmod 0755 /usr/local/smarthome -R
  sudo chmod +x /usr/local/smarthome/bin/smarthome.py
fi

echo "Do you want to update smartvisu?"
sv="Skip"
select sv in "Update" "Skip"; do
    case $sv in
        "Update" ) break;;
        "Skip" ) break;;
        *) echo "Skipping"; break;;
    esac
done

if [ $sv = "Update" ]; then
  git config --global --add safe.directory /var/www/html/smartvisu
  version=$(cd /var/www/html/smartvisu && git status |grep "[bB]ranch"|head -n1|awk -F' ' '{print $NF}')
  echo "Do you want to update to the latest Master or Develop version?"
  echo "WARNING: Any changes to the widgets, etc. you made manually are lost. Back them up now and proceed later."
  echo "Currently $version is installed."
  unset tree
  select tree in "Master" "Develop"; do
      case $tree in
          "Master" ) break;;
          "Develop" ) break;;
          *) echo "Skipping"; break;;
      esac
  done
  if [ $tree = "Develop" ]; then
    echo 'Updating smartvisu to latest develop version'
    cd /var/www/html/smartvisu
    sudo git stash
    sudo git checkout develop
    sudo git pull origin develop
  elif [ $tree = "Master" ]; then
    echo 'Updating smartvisu to latest master version'
    cd /var/www/html/smartvisu
    sudo git stash
    sudo git checkout master
    sudo git pull origin master
  fi
  sudo touch /var/www/html/smartvisu/config.ini
  sudo chown smarthome:www-data /var/www/html/smartvisu -R
  sudo ./setpermissions
  #sudo find . -type d -exec chmod g+rwsx {} + 2>&1
  #sudo find . -type f -exec chmod g+r {} + 2>&1
  #sudo find . -name *.ini -exec chmod g+rw {} + 2>&1
  #sudo find . -name *.var -exec chmod g+rw {} + 2>&1
  #sudo chmod 0775 /var/www/html/smartvisu -R
  #sudo chmod 0660 /var/www/html/smartvisu/config.ini
fi

echo "Do you want to update Python Modules?"
py="Skip"
select py in "Update" "Skip"; do
    case $py in
        "Update" ) break;;
        "Skip" ) break;;
        *) echo "Skipping"; break;;
    esac
done
if [ $py = "Update" ]; then
  echo "Updating SmarthomeNG requirements"
  sudo /usr/local/smarthome/tools/build_requirements.py
  echo "Updating all modules except zwave and those required by shng (will be updated in a separate step)"
  echo "Change to user smarthome"

  sudo runuser -l smarthome -c "pip3 install --user --upgrade pip"
  sudo runuser -l smarthome -c "pip3 freeze --local" | grep -v -f <(cat /usr/local/smarthome/requirements/base.txt /usr/local/smarthome/requirements/conf_all.txt | grep -Eo '^[^#=><]+' | sort -u) | sed '/zwave.*/d' | sed -rn 's/^([^=# \t\\][^ \t=]*)=.*/echo; echo Processing \1 ...; sudo runuser -l smarthome -c \"pip3 install --user -U \1\"/p' | sh
  echo "Updating modules for SmarthomeNG requirements"
  sudo runuser -l smarthome -c "pip3 install --user --upgrade -r /usr/local/smarthome/requirements/base.txt"
  sudo runuser -l smarthome -c "pip3 install --user --upgrade -r /usr/local/smarthome/requirements/conf_all.txt"
fi
echo "Finished Updating"
