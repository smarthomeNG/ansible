#!/bin/sh

# Is system recently booted ?
# Is Fail2Ban startup time $n minutes fresh ?

RECENT_TIME_MIN="8" # Default time (in minutes) to consider the last boot or Fail2Ban startup time as not recent

F2B_STATUS_CMD="systemctl status fail2ban" # System command showing Fail2Ban current events, depends on the OS version
#F2B_STATUS_CMD="service fail2ban status"
#F2B_STATUS_CMD="systemctl status fail2ban.service"

is_boot_recent() # AKA: is the Uptime greater than This $min grace startup period?
{
	local recent_time="$1" # Recent period (in minutes) that we consider as recent

	if [ -z "$recent_time" ]; then
		recent_time="$RECENT_TIME_MIN"
	fi

	recent_time=$(($recent_time*60)) # Convert recent minutes to seconds like system uptime in is also seconds

	local uptime_secs="$(cut -f1 -d. /proc/uptime)" # Get system uptime without microseconds

	if [ $uptime_secs -gt $recent_time ] # If time since last boot is greater than period we consider as recent
	then return 1 # 1 for FALSE
	else return 0 # 0 for TRUE
	fi
}


is_f2b_recent()
{
	local recent_time="$1" # Recent period (in minutes) that we consider as recent

	if [ -z "$recent_time" ]; then
		recent_time="$RECENT_TIME_MIN"
	fi

	local started_time="$(LANG=en_US ${F2B_STATUS_CMD} | grep -Po '(?<=active \(running\) since ).+(?=; )')"

	if [ -z "$started_time" ]
	then return 1
	fi

	local started_secs=$(date -d "${started_time}" +'%s') # Get F2B starting time in seconds

	local now_secs=$(date -d "now" +'%s')

	started_secs=$(($started_secs+($recent_time*60)))

	if [ $started_secs -lt $now_secs ] # If time since started plus grace period is lower than now
	then return 1 # 1 for FALSE
	else return 0 # 0 for TRUE
	fi
}

grace_end=0

case "$1" in
"sys" | "boot")
	if is_boot_recent "$2"
	then grace_end=1
	fi
	;;
"f2b" | "fail2ban")
	if is_f2b_recent "$2"
	then grace_end=1
	fi
	;;
*)
	if is_boot_recent "$2" || is_f2b_recent "$2"
	then grace_end=1
	fi
	;;
esac

if [ $grace_end -gt 0 ]
then echo "YES"
else echo "NO"
fi

exit 0
