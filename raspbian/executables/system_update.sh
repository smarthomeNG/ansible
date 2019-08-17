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

echo "Do you want to update SmartVISU 2.9?"
sv="Skip"
select sv in "Update" "Skip"; do
    case $sv in
        "Update" ) break;;
        "Skip" ) break;;
        *) echo "Skipping"; break;;
    esac
done
if [ $sv = "Update" ]; then
  echo 'Updating smartVISU2.9 Develop'
  cd /var/www/html/smartVISU2.9
  sudo git pull origin develop
  sudo touch /var/www/html/smartVISU2.9/config.ini
  sudo chown smarthome:www-data /var/www/html/smartVISU2.9 -R
  sudo chmod 0775 /var/www/html/smartVISU2.9 -R
  sudo chmod 0660 /var/www/html/smartVISU2.9/config.ini
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
  sudo pip3 install --upgrade pip
  sudo pip3 freeze --local | sed '/scipy.*/d' | sed '/zwave.*/d' | sed -rn 's/^([^=# \t\\][^ \t=]*)=.*/echo; echo Processing \1 ...; pip3 install -U \1/p' |sh
  #sudo pip3 freeze --local | sed -rn 's/^([^=# \t\\][^ \t=]*)=.*/echo; echo Processing \1 ...; pip3 install -U \1/p' |sh
  echo "Reverting modules to SmarthomeNG requirements"
  #sudo sed -i 's/pyatv==0.3.9/#pyatv==0.3.9/g' /usr/local/smarthome/requirements/all.txt 2>&1
  sudo pip3 install --upgrade -r /usr/local/smarthome/requirements/all.txt
fi
echo "Finished Updating"
