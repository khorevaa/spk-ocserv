SPK_NAME = ocserv
SPK_VERS = 1.2.3
SPK_REV  = 1
SPK_ICON = src/ocserv.png

DEPENDS = cross/ocserv

MAINTAINER   = SynoCommunity
DESCRIPTION  = OpenConnect VPN server \(ocserv\) implements the AnyConnect SSL VPN protocol and is compatible with Cisco AnyConnect SSL VPN clients on all major platforms.
DISPLAY_NAME = OpenConnect VPN Server
CHANGELOG    = "1. Initial release of ocserv 1.2.3 for DSM 7."
HOMEPAGE     = https://ocserv.gitlab.io/www/
LICENSE      = GPLv2+

# Service configuration
STARTABLE       = yes
SERVICE_USER    = root
# SERVICE_COMMAND and pre/post hooks are defined in service-setup.sh
SERVICE_SETUP   = src/service-setup.sh
SERVICE_PORT    = 443
SERVICE_PORT_PROTOCOL = https
SERVICE_PORT_TITLE    = OpenConnect VPN

# Expose VPN port through Synology firewall helper
FWPORTS = src/ocserv.sc

# Installation wizard collects basic settings (port, CA paths)
WIZARDS_DIR = src/wizard/

# Custom install step to stage config template and scripts
POST_STRIP_TARGET = ocserv_extra_install

SPK_COMMANDS  = bin/ocserv
SPK_COMMANDS += bin/ocpasswd
SPK_COMMANDS += bin/occtl

include ../../mk/spksrc.spk.mk

.PHONY: ocserv_extra_install

ocserv_extra_install:
	install -m 755 -d $(STAGING_DIR)/etc
	install -m 755 -d $(STAGING_DIR)/var/log
	install -m 755 -d $(STAGING_DIR)/var/run
	install -m 755 -d $(STAGING_DIR)/var/lib/ocserv
	install -m 640 src/ocserv.conf.tpl $(STAGING_DIR)/etc/ocserv.conf.tpl
	install -m 644 src/ocserv.sc $(STAGING_DIR)/etc/ocserv.sc
