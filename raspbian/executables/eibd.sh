#! /bin/sh
### BEGIN INIT INFO
# Provides:             eibd
# Required-Start:       $remote_fs $syslog $network
# Required-Stop:        $remote_fs $syslog $network
# Default-Start:        2 3 4 5
# Default-Stop:
# Short-Description:    KNX/EIB eibd server
### END INIT INFO
set -e
export EIBD_BIN=/usr/local/bin/eibd
export EIBD_USER=eibd
export EIBD_OPTIONS="-d -D -T -R -i -u --no-tunnel-client-queuing --eibaddr=0.0.1 ipt:10.0.0.101"
test -x $EIBD_BIN || exit 0
umask 022
. /lib/lsb/init-functions
# Are we running from init?
run_by_init() {
    ([ "$previous" ] && [ "$runlevel" ]) || [ "$runlevel" = S ]
}
export PATH="/usr/local/bin:${PATH}"
case "$1" in
  start)
        log_daemon_msg "Starting eibd daemon" "eibd" || true
        route add 224.0.23.12 dev eth0 > /dev/null 2>&1 || true
        if start-stop-daemon --start --quiet --oknodo -c $EIBD_USER --exec $EIBD_BIN -- $EIBD_OPTIONS; then
            log_end_msg 0 || true
        else
            log_end_msg 1 || true
        fi
        ;;
  stop)
        log_daemon_msg "Stopping eibd daemon" "eibd" || true
		route delete 224.0.23.12 > /dev/null 2>&1 || true
        if start-stop-daemon --stop --quiet --oknodo --exec $EIBD_BIN; then
			log_end_msg 0 || true
        else
            log_end_msg 1 || true
        fi
        ;;

  restart)
        log_daemon_msg "Restarting eibd daemon" "eibd" || true
        start-stop-daemon --stop --quiet --oknodo --retry 30 --exec $EIBD_BIN
        if start-stop-daemon --start --quiet --oknodo --exec $EIBD_BIN -c $EIBD_USER --exec $EIBD_BIN -- $EIBD_OPTIONS; then
            log_end_msg 0 || true
        else
            log_end_msg 1 || true
        fi
        ;;

  status)
        status_of_proc $EIBD_BIN eibd && exit 0 || exit $?
        ;;

  *)
        log_action_msg "Usage: /etc/init.d/eibd {start|stop|restart|status}" || true
        exit 1
esac
exit 0
