#!/bin/sh
### BEGIN INIT INFO
# Provides:          dbus
# Required-Start:    $local_fs $network $syslog
# Required-Stop:     $local_fs $network $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Set dbusvars
# Description:       <Enter a long description of the software>
#                    <...>
#                    <...>
### END INIT INFO
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/dbus/system_bus_socket
export DISPLAY=:0.0
su smarthome -c "/usr/bin/jackd -dalsa -dhw:CARD=USB_OG -r44000 -p2048 -n3 -I5 -O5 -P"
