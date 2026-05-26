#!/bin/sh
set -e

INETD_CONF="/etc/inetd.conf"
TMP_CONF="/tmp/inetd.conf"

GENERATED=0

# Normalize boolean values: yes, true, 1 -> 1; no, false, 0 -> 0
is_enabled() {
    case "${1:-0}" in
        yes|true|1) return 0 ;;
        no|false|0) return 1 ;;
        *) return 1 ;;
    esac
}

append_internal() {
    svc="$1"
    printf '%s\tstream\ttcp\tnowait\troot\tinternal\n' "$svc" >> "$TMP_CONF"
    printf '%s\tdgram\tudp\twait\troot\tinternal\n' "$svc" >> "$TMP_CONF"
}

if is_enabled "$INETD_ECHO" || \
   is_enabled "$INETD_DISCARD" || \
   is_enabled "$INETD_CHARGEN" || \
   is_enabled "$INETD_DAYTIME" || \
   is_enabled "$INETD_TIME"; then

    cp "$INETD_CONF" "$TMP_CONF"

    is_enabled "$INETD_ECHO"    && append_internal echo    && GENERATED=1
    is_enabled "$INETD_DISCARD" && append_internal discard && GENERATED=1
    is_enabled "$INETD_CHARGEN" && append_internal chargen && GENERATED=1
    is_enabled "$INETD_DAYTIME" && append_internal daytime && GENERATED=1
    is_enabled "$INETD_TIME"    && append_internal time    && GENERATED=1
fi

if [ "$GENERATED" = "1" ]; then
    exec /usr/sbin/inetd -i "$TMP_CONF"
else
    exec /usr/sbin/inetd -i "$INETD_CONF"
fi
