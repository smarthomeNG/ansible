#!/bin/bash
install_influxdb () {
  INFLUX_e=$(systemctl is-enabled influxdb 2>&1 | tail -n 1)&> /dev/null
  if [[ $(echo $INFLUX_e | grep "Failed") ]]; then
    INFLUX_e="not installed"
  fi
  echo ""
  echo "INFLUXDB: Time Series Database Monitoring plus Grafana to view graphs. (currently $INFLUX_e)"
  if [[ $INFLUX_e == "not installed" ]]; then
    unset influx_install
    select influx_install in "Install" "Skip"; do
        case $influx_install in
            Install ) cd /etc/ansible; ansible-playbook playbooks/influxdb_Raspi3.yml; break;;
            Skip) echo "Skipping"; break;;
            *) echo "Skipping"; break;;
        esac
    done
  fi
  INFLUX_e=$(systemctl is-enabled influxdb 2>&1 | tail -n 1)&> /dev/null
  if [[ $(echo $INFLUX_e | grep "Failed") ]]; then
    INFLUX_e="not installed"
  fi
  if [[ ! $INFLUX_e == "not installed" ]]; then
    echo ""
    echo "Do you want to enable InfluxDB?"
    unset influx
    select influx in "Enable" "Disable" "Skip"; do
        case $influx in
            Enable ) sudo systemctl enable influxdb; sudo systemctl restart influxdb; break;;
            Disable ) sudo systemctl disable influxdb; break;;
            Skip) echo "Skipping"; break;;
            *) echo "Skipping"; break;;
        esac
    done
  fi
  INFLUX_e=$(systemctl is-enabled influxdb 2>&1 | tail -n 1)&> /dev/null
  if [[ $(echo $INFLUX_e | grep "Failed") ]]; then
    INFLUX_e="not installed"
  fi
  echo ""
  echo "INFLUXDB Service is $INFLUX_e. Config file is /etc/influxdb/influxdb.conf"

  GRAFANA_e=$(systemctl is-enabled grafana-server 2>&1 | tail -n 1)&> /dev/null
  if [[ $(echo $GRAFANA_e | grep "Failed") ]]; then
    GRAFANA_e="not installed"
  fi
  echo ""
  echo "GRAFANA: Web Service to configure and show influxdb graphs as well as log files using loki. (currently $GRAFANA_e)"
  if [[ $GRAFANA_e == "not installed" ]]; then
    unset grafana_install
    select grafana_install in "Install" "Skip"; do
        case $grafana_install in
            Install ) cd /etc/ansible; ansible-playbook playbooks/grafana_Raspi3.yml; break;;
            Skip) echo "Skipping"; break;;
            *) echo "Skipping"; break;;
        esac
    done
  fi
  GRAFANA_e=$(systemctl is-enabled grafana-server 2>&1 | tail -n 1)&> /dev/null
  if [[ $(echo $GRAFANA_e | grep "Failed") ]]; then
    GRAFANA_e="not installed"
  fi
  if [[ ! $GRAFANA_e == "not installed" ]]; then
    echo ""
    echo "Do you want to enable Grafana?"
    unset influx
    select influx in "Enable" "Disable" "Skip"; do
        case $influx in
            Enable ) sudo systemctl enable grafana-server; sudo systemctl restart grafana-server; break;;
            Disable ) sudo systemctl disable grafana-server; break;;
            Skip) echo "Skipping"; break;;
            *) echo "Skipping"; break;;
        esac
    done
  fi
  GRAFANA_e=$(systemctl is-enabled grafana-server 2>&1 | tail -n 1)&> /dev/null
  if [[ $(echo $GRAFANA_e | grep "Failed") ]]; then
    GRAFANA_e="not installed"
  else
    echo ""
    echo "GRAFANA Service is $GRAFANA_e. Access it via http://IP/grafana using smarthome as user and password."
  fi
}
raspi=$(grep "Revision" /proc/cpuinfo | awk -F': ' '{print $2}')
raspiversion=0
case $raspi in
    a02082 ) raspiversion=3;;
    a22082 ) raspiversion=3;;
    a020a0 ) raspiversion=3;;
    a32082 ) raspiversion=3;;
    a020d3 ) raspiversion=3;;
    9020e0 ) raspiversion=3;;
    a02100 ) raspiversion=3;;
    a03111 ) raspiversion=4;;
    b03111 ) raspiversion=4;;
    b03112 ) raspiversion=4;;
    b03114 ) raspiversion=4;;
    b03115 ) raspiversion=4;;
    c03111 ) raspiversion=4;;
    c03112 ) raspiversion=4;;
    c03114 ) raspiversion=4;;
    c03115 ) raspiversion=4;;
    d03114 ) raspiversion=4;;
    d03115 ) raspiversion=4;;
esac
if [[ $raspiversion -ge "3" ]]; then
  echo ""
  echo "It looks like you have a Raspberry Pi Version 3 or higher. InfluxDB is installed."
  install_influxdb

else
  echo "You need a Rasperry Pi 3 or better. Not installing InfluxDB"
fi
