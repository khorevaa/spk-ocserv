#!/bin/sh
# CGI backend for ocserv admin UI

PKG_VAR="/var/packages/ocserv/var"
PKG_ETC="${PKG_VAR}/etc"
OCPASSWD_FILE="${PKG_ETC}/ocpasswd"
CFG_FILE="${PKG_ETC}/ocserv.conf"
LOG_FILE="/var/log/ocserv.log"
OCCTL="${SYNOPKG_PKGDEST:-/var/packages/ocserv/target}/bin/occtl"

json_ok()  { printf 'Content-Type: application/json\r\n\r\n{"ok":true}\n'; }
json_err() { printf 'Content-Type: application/json\r\n\r\n{"error":"%s"}\n' "$1"; }
json_raw() { printf 'Content-Type: application/json\r\n\r\n%s\n' "$1"; }

read_post() {
    if [ "${REQUEST_METHOD}" = "POST" ]; then
        read -r QUERY_STRING
    fi
}

urldecode() {
    printf '%b' "$(printf '%s' "$1" | sed 's/+/ /g; s/%/\\x/g')"
}

get_param() {
    echo "$QUERY_STRING" | tr '&' '\n' | grep "^$1=" | head -1 | cut -d= -f2- | \
    { read v; urldecode "$v"; }
}

# Extract ACTION from GET query string (QUERY_STRING has both GET+POST merged)
GET_QS="${QUERY_STRING:-}"
# Override if POST: read body
read_post

ACTION=$(echo "${GET_QS}" | tr '&' '\n' | grep '^action=' | head -1 | cut -d= -f2-)

case "${ACTION}" in

status)
    running=false
    if pgrep -x ocserv > /dev/null 2>&1; then running=true; fi

    port=""
    auth=""
    network=""
    dns=""
    if [ -f "${CFG_FILE}" ]; then
        port=$(grep -m1 '^tcp-port' "${CFG_FILE}" | awk '{print $NF}')
        auth=$(grep -m1 '^auth =' "${CFG_FILE}" | sed 's/^auth = *//')
        network=$(grep -m1 '^ipv4-network' "${CFG_FILE}" | awk '{print $NF}')
        dns=$(grep '^dns =' "${CFG_FILE}" | awk '{print $NF}' | tr '\n' ',' | sed 's/,$//')
    fi

    sessions="[]"
    if ${running} && [ -x "${OCCTL}" ]; then
        raw=$(${OCCTL} --no-pager -j show users 2>/dev/null)
        if [ -n "${raw}" ]; then sessions="${raw}"; fi
    fi

    json_raw "{
  \"running\":${running},
  \"config\":\"${CFG_FILE}\",
  \"port\":\"${port}\",
  \"auth\":\"${auth}\",
  \"network\":\"${network}\",
  \"dns\":\"${dns}\",
  \"sessions\":${sessions}
}"
    ;;

users)
    if [ ! -f "${OCPASSWD_FILE}" ]; then
        json_raw '{"users":[]}'
        exit 0
    fi
    users=$(awk -F: '{print "\"" $1 "\""}' "${OCPASSWD_FILE}" | tr '\n' ',' | sed 's/,$//')
    json_raw "{\"users\":[${users}]}"
    ;;

log)
    if [ -f "${LOG_FILE}" ]; then
        log=$(tail -40 "${LOG_FILE}" | sed 's/\\/\\\\/g; s/"/\\"/g' | \
              awk '{printf "%s\\n", $0}')
    else
        log="Log file not found: ${LOG_FILE}"
    fi
    printf 'Content-Type: application/json\r\n\r\n{"log":"%s"}\n' "${log}"
    ;;

adduser)
    user=$(get_param user)
    pass=$(get_param pass)
    if [ -z "${user}" ] || [ -z "${pass}" ]; then
        json_err "user and pass required"
        exit 0
    fi
    # Validate: alphanumeric + _ - . only
    if ! echo "${user}" | grep -qE '^[a-zA-Z0-9._-]+$'; then
        json_err "invalid username"
        exit 0
    fi
    ocpasswd_bin="${SYNOPKG_PKGDEST:-/var/packages/ocserv/target}/bin/ocpasswd"
    err=$(printf '%s\n%s\n' "${pass}" "${pass}" | \
          "${ocpasswd_bin}" -c "${OCPASSWD_FILE}" "${user}" 2>&1)
    if [ $? -eq 0 ]; then json_ok; else json_err "${err}"; fi
    ;;

deluser)
    user=$(get_param user)
    if [ -z "${user}" ]; then json_err "user required"; exit 0; fi
    if ! echo "${user}" | grep -qE '^[a-zA-Z0-9._-]+$'; then
        json_err "invalid username"
        exit 0
    fi
    ocpasswd_bin="${SYNOPKG_PKGDEST:-/var/packages/ocserv/target}/bin/ocpasswd"
    err=$("${ocpasswd_bin}" -c "${OCPASSWD_FILE}" -d "${user}" 2>&1)
    if [ $? -eq 0 ]; then json_ok; else json_err "${err}"; fi
    ;;

disconnect)
    user=$(get_param user)
    if [ -z "${user}" ]; then json_err "user required"; exit 0; fi
    if ! echo "${user}" | grep -qE '^[a-zA-Z0-9._-]+$'; then
        json_err "invalid username"
        exit 0
    fi
    if [ ! -x "${OCCTL}" ]; then json_err "occtl not found"; exit 0; fi
    err=$(${OCCTL} disconnect user "${user}" 2>&1)
    if [ $? -eq 0 ]; then json_ok; else json_err "${err}"; fi
    ;;

*)
    printf 'Content-Type: application/json\r\n\r\n{"error":"unknown action"}\n'
    ;;

esac
