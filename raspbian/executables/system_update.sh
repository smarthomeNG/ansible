#!/bin/bash
echo "Updating System Packages"
sudo apt-get update
sudo apt-get dist-upgrade
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
  sudo find . -type d -exec chmod g+rwsx {} + 2>&1
  sudo find . -type f -exec chmod g+r {} + 2>&1
  sudo find . -name *.ini -exec chmod g+rw {} + 2>&1
  sudo find . -name *.var -exec chmod g+rw {} + 2>&1
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
  echo "Updating all modules except scipy (as there are huge problems with the update)"
  echo "Change to user smarthome"

  sudo runuser -l smarthome -c "pip3 install --user --upgrade pip"
  sudo runuser -l smarthome -c "pip3 freeze --local" | sed '/scipy.*/d' | sed '/numpy.*/d' | sed '/zwave.*/d' | sed -rn 's/^([^=# \t\\][^ \t=]*)=.*/echo; echo Processing \1 ...; sudo runuser -l smarthome -c "pip3 install  --user -U \1"/p' |sh
  SCIPY_VERSION=$(sudo runuser -l smarthome -c "pip3 list"|grep scipy|awk '{print $2}')
  NUMPY_VERSION=$(sudo runuser -l smarthome -c "pip3 list"|grep numpy|awk '{print $2}')
  echo "Reverting modules to SmarthomeNG requirements"
  sudo sed -i 's/'scipy.*'/scipy>='${SCIPY_VERSION}',<='${SCIPY_VERSION}'/g' /usr/local/smarthome/requirements/conf_all.txt 2>&1
  sudo sed -i 's/'numpy.*'/numpy>='${NUMPY_VERSION}',<='${NUMPY_VERSION}'/g' /usr/local/smarthome/requirements/conf_all.txt 2>&1
  sudo runuser -l smarthome -c "pip3 install --user --upgrade -r /usr/local/smarthome/requirements/base.txt"
  sudo runuser -l smarthome -c "pip3 install --user --upgrade -r /usr/local/smarthome/requirements/conf_all.txt"
fi
echo "Finished Updating"
