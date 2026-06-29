#!/bin/sh

# Paths
PKG_DIR="${SYNOPKG_PKGDEST}"
VAR_DIR="${SYNOPKG_PKGVAR}"
ETC_DIR="${VAR_DIR}/etc"
LOG_DIR="${VAR_DIR}/log"
RUN_DIR="${VAR_DIR}/run"
LIB_DIR="${VAR_DIR}/lib/ocserv"

CFG_FILE="${ETC_DIR}/ocserv.conf"
PID_FILE="${RUN_DIR}/ocserv.pid"
LOG_FILE="${LOG_DIR}/ocserv.log"

# Main service command executed by the spksrc service wrapper
SERVICE_COMMAND="${PKG_DIR}/bin/ocserv --config ${CFG_FILE} --pid-file ${PID_FILE} --foreground"

service_postinst() {
    # Create runtime directories
    install -m 755 -d "${ETC_DIR}"
    install -m 755 -d "${LOG_DIR}"
    install -m 755 -d "${RUN_DIR}"
    install -m 700 -d "${LIB_DIR}"

    # Install default config from template on first install
    if [ ! -f "${CFG_FILE}" ]; then
        cp "${PKG_DIR}/etc/ocserv.conf.tpl" "${CFG_FILE}"

        # Substitute wizard-provided values (wizard writes them to /tmp/wizard.conf)
        if [ -f /tmp/wizard.conf ]; then
            . /tmp/wizard.conf
            sed -i "s|@@VPN_PORT@@|${wizard_vpn_port:-443}|g"    "${CFG_FILE}"
            sed -i "s|@@SERVER_CERT@@|${wizard_server_cert:-}|g"  "${CFG_FILE}"
            sed -i "s|@@SERVER_KEY@@|${wizard_server_key:-}|g"    "${CFG_FILE}"
            sed -i "s|@@CA_CERT@@|${wizard_ca_cert:-}|g"          "${CFG_FILE}"
        else
            # Sane defaults when wizard is skipped
            sed -i "s|@@VPN_PORT@@|443|g"    "${CFG_FILE}"
            sed -i "s|@@SERVER_CERT@@||g"    "${CFG_FILE}"
            sed -i "s|@@SERVER_KEY@@||g"     "${CFG_FILE}"
            sed -i "s|@@CA_CERT@@||g"        "${CFG_FILE}"
        fi
    fi

    # Create empty password file for plain-text authentication
    if [ ! -f "${LIB_DIR}/ocpasswd" ]; then
        touch "${LIB_DIR}/ocpasswd"
        chmod 640 "${LIB_DIR}/ocpasswd"
    fi
}

service_prestart() {
    if [ ! -f "${CFG_FILE}" ]; then
        echo "Configuration file not found: ${CFG_FILE}" >&2
        return 1
    fi
}
