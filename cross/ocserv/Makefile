PKG_NAME = ocserv
PKG_VERS = 1.2.3
PKG_EXT = tar.xz
PKG_DIST_NAME = $(PKG_NAME)-$(PKG_VERS).$(PKG_EXT)
PKG_DIST_SITE = ftp://ftp.infradead.org/pub/ocserv
PKG_DIR = $(PKG_NAME)-$(PKG_VERS)

DEPENDS = cross/gnutls cross/libev cross/readline cross/zlib

HOMEPAGE = https://ocserv.gitlab.io/www/
COMMENT  = OpenConnect VPN server — compatible with Cisco AnyConnect SSL VPN clients.
LICENSE  = GPLv2+

GNU_CONFIGURE = 1

# Disable optional features that require additional cross-compiled libraries
# or are not practical in the Synology package environment.
CONFIGURE_ARGS  = --without-pam
CONFIGURE_ARGS += --without-gss
CONFIGURE_ARGS += --without-radius
CONFIGURE_ARGS += --without-libnl
CONFIGURE_ARGS += --without-protobuf-c
CONFIGURE_ARGS += --without-maxminddb
CONFIGURE_ARGS += --without-lz4
CONFIGURE_ARGS += --without-http-parser
CONFIGURE_ARGS += --disable-oidc-connect
# Prevent building man pages / docs (saves time, no groff cross-compile needed)
CONFIGURE_ARGS += --disable-doc

# ocserv uses /run for PID files and /var for persistent data; let post-install
# wiring in the SPK adjust the compiled-in defaults via configure flags.
CONFIGURE_ARGS += --sysconfdir=/var/packages/ocserv/etc
CONFIGURE_ARGS += --localstatedir=/var/packages/ocserv/var

# gnutls pkg-config must be found via cross sysroot
ADDITIONAL_CFLAGS  = -I$(STAGING_INSTALL_PREFIX)/include
ADDITIONAL_LDFLAGS = -L$(STAGING_INSTALL_PREFIX)/lib -Wl,-rpath-link,$(STAGING_INSTALL_PREFIX)/lib

include ../../mk/spksrc.cross-cc.mk
