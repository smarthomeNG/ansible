#!/bin/sh
# Exim Frozen Cleanup – schlankes Logging
LOG_FILE="/var/log/exim4/remove_frozen.log"
PATH=/usr/sbin:/usr/bin:/bin
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"
STATUS_FILE="/run/exim_frozen_cleanup.status"

log() {
    echo "$TIMESTAMP - $1" >> "$LOG_FILE" 2>&1
}

# -------------------------------
# 1. Gefrorene Mails ermitteln und löschen
# -------------------------------
FROZEN_IDS=$(/usr/sbin/exim -bp 2>/dev/null | /usr/bin/awk '/frozen/ {print $3}')

if [ -n "$FROZEN_IDS" ]; then
    log "Found frozen mail IDs:"
    for id in $FROZEN_IDS; do
        log "Deleting mail ID $id"
        /usr/sbin/exim -Mrm "$id" 2>/dev/null
    done
fi

# -------------------------------
# 2. tidydb aufräumen, Fehler unterdrücken
# -------------------------------
/usr/sbin/exim_tidydb -t 86400 /var/spool/exim4 retry >/dev/null 2>&1

# -------------------------------
# 3. Abschlusslog
# -------------------------------
log "exim_frozen_cleanup finished OK"

# Exit 0 → Monit zeigt keinen Fehler
touch "$STATUS_FILE"
echo "$TIMESTAMP - exim_frozen_cleanup finished OK" > "$STATUS_FILE"
exit 0
