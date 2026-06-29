SPK_NAME = ocserv
SPK_VERS = 1.5.0
SPK_REV  = 1
SPK_ICON = src/ocserv.png

DEPENDS = cross/ocserv cross/radcli

MAINTAINER   = SynoCommunity
DESCRIPTION  = OpenConnect VPN server \(ocserv\) implements the AnyConnect SSL VPN protocol \
               and is compatible with Cisco AnyConnect SSL VPN clients on all major platforms.
DISPLAY_NAME = OpenConnect VPN
CHANGELOG    = "1. Initial release of ocserv 1.5.0 for DSM 7."
HOMEPAGE     = https://ocserv.gitlab.io/www/
LICENSE      = GPLv2+

STARTABLE            = yes
SERVICE_USER         = root
SERVICE_SETUP        = src/service-setup.sh
SERVICE_PORT         = 4433
SERVICE_PORT_PROTOCOL = https
SERVICE_PORT_TITLE   = OpenConnect VPN

FWPORTS              = src/ocserv.sc
WIZARDS_TEMPLATES_DIR = src/wizard_templates

POST_STRIP_TARGET = ocserv_extra_install

SPK_COMMANDS  = bin/ocserv
SPK_COMMANDS += bin/ocpasswd
SPK_COMMANDS += bin/occtl

include ../../mk/spksrc.spk.mk

.PHONY: ocserv_extra_install

ocserv_extra_install:
	@install -m 755 -d $(STAGING_DIR)/etc
	@install -m 755 -d $(STAGING_DIR)/var
	@install -m 640 src/ocserv.conf.tpl          $(STAGING_DIR)/etc/ocserv.conf.tpl
	@install -m 640 src/radiusclient.conf.tpl     $(STAGING_DIR)/etc/radiusclient.conf.tpl
	@install -m 644 src/environment-variables     $(STAGING_DIR)/var/environment-variables
