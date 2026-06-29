#!/bin/sh
# Wizard script — collects user input and writes /tmp/wizard.conf
# The values are read by service_postinst() in service-setup.sh.

wizard_vpn_port="${wizard_vpn_port:-443}"
wizard_server_cert="${wizard_server_cert:-}"
wizard_server_key="${wizard_server_key:-}"
wizard_ca_cert="${wizard_ca_cert:-}"

cat > /tmp/wizard.conf <<EOF
wizard_vpn_port="${wizard_vpn_port}"
wizard_server_cert="${wizard_server_cert}"
wizard_server_key="${wizard_server_key}"
wizard_ca_cert="${wizard_ca_cert}"
EOF
