PKG_NAME = radcli
PKG_VERS = 1.5.2
PKG_EXT  = tar.gz
PKG_DIST_NAME = $(PKG_NAME)-$(PKG_VERS).$(PKG_EXT)
PKG_DIST_SITE = https://github.com/radcli/radcli/releases/download/$(PKG_VERS)
PKG_DIR       = $(PKG_NAME)-$(PKG_VERS)

DEPENDS =

HOMEPAGE = https://github.com/radcli/radcli
COMMENT  = FreeRADIUS-client compatible RADIUS client library.
LICENSE  = BSD/LGPLv2+

GNU_CONFIGURE = 1
CONFIGURE_ARGS  = --without-openssl
CONFIGURE_ARGS += --disable-tests

include ../../mk/spksrc.cross-cc.mk
