#!/bin/sh

# Paths resolved from spksrc framework environment variables
VAR_DIR="${SYNOPKG_PKGVAR}"
ETC_DIR="${VAR_DIR}/etc"
LIB_DIR="${VAR_DIR}/lib"
LOG_DIR="${VAR_DIR}/log"

CFG_FILE="${ETC_DIR}/ocserv.conf"
RADIUS_CFG="${ETC_DIR}/radiusclient.conf"
RADIUS_SERVERS="${ETC_DIR}/radius.servers"
PASSWD_FILE="${LIB_DIR}/ocpasswd"

# ── Service command (used by the spksrc start/stop framework) ─────────────────
SERVICE_COMMAND="${SYNOPKG_PKGDEST}/bin/ocserv --config ${CFG_FILE} --foreground"
SVC_BACKGROUND=y
SVC_WRITE_PID=y

# ── Lifecycle hooks ───────────────────────────────────────────────────────────

service_postinst() {
    install -m 755 -d "${ETC_DIR}" "${LIB_DIR}" "${LOG_DIR}"

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
        sed -i "s|@@RADIUS_HOST@@|${wizard_radius_host:-127.0.0.1}|g"           "${RADIUS_CFG}"
        sed -i "s|@@RADIUS_AUTH_PORT@@|${wizard_radius_auth_port:-1812}|g"       "${RADIUS_CFG}"
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

service_prestart() {
    if [ ! -f "${CFG_FILE}" ]; then
        echo "Configuration file missing: ${CFG_FILE}" >&2
        return 1
    fi
}
