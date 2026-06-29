PKG_NAME = ocserv
PKG_VERS = 1.5.0
PKG_EXT  = tar.xz
PKG_DIST_NAME = $(PKG_NAME)-$(PKG_VERS).$(PKG_EXT)
PKG_DIST_SITE = https://www.infradead.org/ocserv/download
PKG_DIR       = $(PKG_NAME)-$(PKG_VERS)

DEPENDS  = cross/gnutls cross/libev cross/readline cross/zlib
DEPENDS += cross/radcli

HOMEPAGE = https://ocserv.gitlab.io/www/
COMMENT  = OpenConnect VPN server compatible with Cisco AnyConnect SSL VPN clients.
LICENSE  = GPLv2+

GNU_CONFIGURE = 1

CONFIGURE_ARGS  = --without-pam
CONFIGURE_ARGS += --without-gss
CONFIGURE_ARGS += --without-libnl
CONFIGURE_ARGS += --without-protobuf-c
CONFIGURE_ARGS += --without-maxminddb
CONFIGURE_ARGS += --without-lz4
CONFIGURE_ARGS += --without-http-parser
CONFIGURE_ARGS += --disable-oidc-connect
CONFIGURE_ARGS += --disable-doc
# RADIUS enabled via radcli
CONFIGURE_ARGS += --with-radius

ADDITIONAL_CFLAGS  = -I$(STAGING_INSTALL_PREFIX)/include
ADDITIONAL_LDFLAGS = -L$(STAGING_INSTALL_PREFIX)/lib \
                     -Wl,-rpath-link,$(STAGING_INSTALL_PREFIX)/lib

include ../../mk/spksrc.cross-cc.mk
