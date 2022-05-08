#! /bin/bash

adddate() {
    while IFS= read -r line; do
        echo "$(date) $line"
    done
}
PATH=/sbin:/usr/sbin:/bin:/usr/bin

DESC="Squeezebox client"
NAME=squeezelite
SL_DOWNLOAD_URL="http://ralph_irving.users.sourceforge.net/pico/squeezelite-armv6hf-noffmpeg"
LOG=/var/log/$NAME.log
DAEMON=/usr/bin/squeezelite
PIDFILE=/var/run/${NAME}.pid
SCRIPTNAME=/etc/init.d/${NAME}

SL_MAC_ADDRESS=$(cat /sys/class/net/eth0/address)

SL_NAME="Squeezelite"
ALSABUFFER=320
PERIODS=4
BIT=16
MMAP=0
SL_ALSA_PARAMS="$ALSABUFFER:$PERIODS:$BIT:$MMAP"
STREAMINGBUFFERIN=2048
STREAMINGBUFFEROUT=2048
STREAMINGBUFFER="$STREAMINGBUFFERIN:$STREAMINGBUFFEROUT"
MAXSAMPLERATE=48000
PRIORITY=90
SL_ADDITIONAL_OPTIONS="-b ${STREAMINGBUFFER} -r ${MAXSAMPLERATE} -p ${PRIORITY}"

SL_SOUNDCARD="plughw:CARD=ALSA,DEV=1"
SB_SERVER_CLI_PORT="9090"

#SB_SERVER_IP="IP ADDRESS"
SL_USER="smarthome"
#SL_ADDITIONAL_OPTIONS="-z"

    DAEMON_START_ARGS=""
    # set the user which will be used to start squeezelite
    if [ ! -z "$SL_USER" ]; then
       DAEMON_START_ARGS="${DAEMON_START_ARGS} --chuid ${SL_USER}"
    fi

    DAEMON_ARGS=""

    # add souncard setting if set
    if [ ! -z "$SL_SOUNDCARD" ]; then
       DAEMON_ARGS="${DAEMON_ARGS} -o ${SL_SOUNDCARD}"
    fi

    # add squeezelite name if set
    if [ ! -z "$SL_NAME" ]; then
       DAEMON_ARGS="${DAEMON_ARGS} -n ${SL_NAME}"
    fi

    # add mac address if set
    if [ ! -z "$SL_MAC_ADDRESS" ]; then
       DAEMON_ARGS="${DAEMON_ARGS} -m ${SL_MAC_ADDRESS}"
    fi

    # add squeezebox server ip address if set
    if [ ! -z "$SB_SERVER_IP" ]; then
       DAEMON_ARGS="${DAEMON_ARGS} -s ${SB_SERVER_IP}"
    fi

    # set ALSA parameters if set
    if [ ! -z "$SL_ALSA_PARAMS" ]; then
       DAEMON_ARGS="${DAEMON_ARGS} -a ${SL_ALSA_PARAMS}"
    fi

    # add logging if set
    if [ ! -z "$SL_LOGFILE" ]; then
       if [ -f ${SL_LOGFILE} ]; then
          rm ${SL_LOGFILE}
       fi
       DAEMON_ARGS="${DAEMON_ARGS} -f ${SL_LOGFILE}"
    fi

    # add log level setting if set
    if [ ! -z "$SL_LOGLEVEL" ]; then
       DAEMON_ARGS="${DAEMON_ARGS} -d ${SL_LOGLEVEL}"
    fi

    # add additional options if set
    if [ ! -z "$SL_ADDITIONAL_OPTIONS" ]; then
       DAEMON_ARGS="${DAEMON_ARGS} ${SL_ADDITIONAL_OPTIONS}"
    fi

    echo "Starting: $DAEMON $DAEMON_ARGS with pidfile: $PIDFILE"
    echo "Starting: $DAEMON $DAEMON_ARGS with pidfile: $PIDFILE" | adddate >> $LOG
    $DAEMON $DAEMON_ARGS
