#!/bin/sh

# Paths
VAR_DIR="${SYNOPKG_PKGVAR}"
ETC_DIR="${VAR_DIR}/etc"
LIB_DIR="${VAR_DIR}/lib"
LOG_DIR="${VAR_DIR}/log"

CFG_FILE="${ETC_DIR}/ocserv.conf"
RADIUS_CFG="${ETC_DIR}/radiusclient.conf"
RADIUS_SERVERS="${ETC_DIR}/radius.servers"
PASSWD_FILE="${ETC_DIR}/ocpasswd"

INST_ETC="/var/packages/${SYNOPKG_PKGNAME}/etc"
INST_VARIABLES="${INST_ETC}/installer-variables"
ENV_VARIABLES="${SYNOPKG_PKGVAR}/environment-variables"

UI_DIR="${SYNOPKG_PKGDEST}/ui"
ADMIN_PORT=8880
HTTPD_PID="${VAR_DIR}/httpd.pid"

SVC_BACKGROUND=yes
SVC_WRITE_PID=yes

service_postinst ()
{
    install -m 755 -d "${ETC_DIR}" "${LIB_DIR}" "${LOG_DIR}"
    install -m 755 -d "${INST_ETC}"

    # Save wizard values for use in service_prestart
    if [ -n "${wizard_vpn_port}" ]; then
        echo "VPN_PORT=${wizard_vpn_port}" > "${INST_VARIABLES}"
    fi

    # Write ocserv.conf from template on first install
    if [ ! -f "${CFG_FILE}" ]; then
        cp "${SYNOPKG_PKGDEST}/etc/ocserv.conf.tpl" "${CFG_FILE}"

        AUTH_METHOD="${wizard_auth_method:-local}"
        sed -i "s|@@VPN_PORT@@|${wizard_vpn_port:-4433}|g"         "${CFG_FILE}"
        sed -i "s|@@SERVER_CERT@@|${wizard_server_cert:-}|g"        "${CFG_FILE}"
        sed -i "s|@@SERVER_KEY@@|${wizard_server_key:-}|g"          "${CFG_FILE}"
        sed -i "s|@@RADIUS_CONFIG@@|${RADIUS_CFG}|g"                "${CFG_FILE}"

        if [ "${AUTH_METHOD}" = "radius" ]; then
            sed -i "s|@@AUTH_LOCAL_COMMENT@@|#|g"  "${CFG_FILE}"
            sed -i "s|@@AUTH_RADIUS_COMMENT@@||g"  "${CFG_FILE}"
        else
            sed -i "s|@@AUTH_LOCAL_COMMENT@@||g"   "${CFG_FILE}"
            sed -i "s|@@AUTH_RADIUS_COMMENT@@|#|g" "${CFG_FILE}"
        fi
    fi

    # Write radiusclient.conf from template
    if [ ! -f "${RADIUS_CFG}" ]; then
        cp "${SYNOPKG_PKGDEST}/etc/radiusclient.conf.tpl" "${RADIUS_CFG}"
        sed -i "s|@@RADIUS_HOST@@|${wizard_radius_host:-127.0.0.1}|g"     "${RADIUS_CFG}"
        sed -i "s|@@RADIUS_AUTH_PORT@@|${wizard_radius_auth_port:-1812}|g" "${RADIUS_CFG}"
    fi

    # Write radius.servers: host:port <tab> secret [<tab> nas-id]
    if [ ! -f "${RADIUS_SERVERS}" ]; then
        if [ -n "${wizard_radius_host:-}" ]; then
            printf '%s:%s\t%s' \
                "${wizard_radius_host}" \
                "${wizard_radius_auth_port:-1812}" \
                "${wizard_radius_secret:-changeme}" > "${RADIUS_SERVERS}"
            [ -n "${wizard_radius_nas_id:-}" ] && \
                printf '\t%s' "${wizard_radius_nas_id}" >> "${RADIUS_SERVERS}"
            printf '\n' >> "${RADIUS_SERVERS}"
        else
            printf '# <host>:<auth_port>\t<secret>\n' > "${RADIUS_SERVERS}"
        fi
        chmod 640 "${RADIUS_SERVERS}"
    fi

    # Create empty local password file
    if [ ! -f "${PASSWD_FILE}" ]; then
        touch "${PASSWD_FILE}"
        chmod 640 "${PASSWD_FILE}"
    fi
}

export_variables_from_file ()
{
    if [ -n "$1" ] && [ -r "$1" ]; then
        while read -r _line; do
            if [ "$(echo "${_line}" | grep -v '^[[:space:]]*#')" != "" ]; then
                _key="$(echo "${_line}"   | cut -f1 -d=)"
                _value="$(echo "${_line}" | cut -f2- -d=)"
                export "${_key}=${_value}"
            fi
        done < "$1"
    fi
}

_start_httpd ()
{
    if command -v python3 > /dev/null 2>&1; then
        python3 -m http.server --cgi --directory "${UI_DIR}" "${ADMIN_PORT}" \
            > "${LOG_DIR}/httpd.log" 2>&1 &
        echo $! > "${HTTPD_PID}"
    fi
}

_stop_httpd ()
{
    if [ -f "${HTTPD_PID}" ]; then
        kill "$(cat "${HTTPD_PID}")" 2>/dev/null || true
        rm -f "${HTTPD_PID}"
    fi
}

service_prestart ()
{
    if [ ! -f "${CFG_FILE}" ]; then
        echo "Configuration file missing: ${CFG_FILE}" >&2
        return 1
    fi

    export_variables_from_file "${INST_VARIABLES}"
    export_variables_from_file "${ENV_VARIABLES}"

    _stop_httpd
    _start_httpd

    SERVICE_COMMAND="${SYNOPKG_PKGDEST}/bin/ocserv --config ${CFG_FILE} --foreground"
}

service_poststop ()
{
    _stop_httpd
}
