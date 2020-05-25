#!/bin/sh
conf="$(/usr/bin/awk 'BEGIN{ORS=" "} $1=="nameserver" {print $2}' /etc/resolv.conf)"
[ "$conf" = "resolver ;" ] && exit 0
conf=$(echo $conf  | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b"  | tr '\n' ' ')
conf="resolver $conf;"
confpath=/etc/nginx/conf.d/resolvers.conf
if [ ! -e $confpath ] || [ "$conf" != "$(cat $confpath)" ]
then
    echo "$conf" > $confpath
    #service nginx reload >/dev/null
fi
exit 0
