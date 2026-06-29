# ocserv — Synology SPK package

OpenConnect VPN server (ocserv) package for Synology NAS using the
[spksrc](https://github.com/SynoCommunity/spksrc) cross-compilation framework.

## Package summary

| Field       | Value |
|-------------|-------|
| ocserv      | 1.2.3 |
| DSM         | 7.x   |
| Architectures | x64, aarch64, armv8 (see notes) |
| License     | GPLv2+ |

## Dependencies (cross-compiled)

| Package  | Already in spksrc? |
|----------|--------------------|
| gnutls   | yes (`cross/gnutls`) |
| libev    | yes (`cross/libev`) |
| readline | yes (`cross/readline`) |
| zlib     | yes (`cross/zlib`) |

All other optional ocserv features (PAM, GSSAPI, RADIUS, libnl, protobuf-c,
MaxMindDB) are disabled at configure time to keep the dependency tree minimal.

## Build

### Prerequisites

Follow the spksrc [environment setup](https://docs.synocommunity.com/developer-guide/setup/)
(Docker or Debian VM/LXC).

### Steps

```sh
# 1. Clone spksrc into a sibling directory
git clone https://github.com/SynoCommunity/spksrc ../spksrc

# 2. Copy (or symlink) this package into the spksrc tree
cp -r cross/ocserv ../spksrc/cross/
cp -r spk/ocserv   ../spksrc/spk/

# 3. Fetch source and generate real digests
cd ../spksrc
make -C cross/ocserv digests

# 4. Build for a specific architecture and DSM version
make -C spk/ocserv ARCH=x64 TCVERSION=7.2

# The resulting .spk is in spk/ocserv/work*/
```

## Post-install usage

```sh
# Add a VPN user
/var/packages/ocserv/target/bin/ocpasswd \
    -c /var/packages/ocserv/var/lib/ocserv/ocpasswd <username>

# Reload configuration without dropping connections
kill -HUP $(cat /var/packages/ocserv/var/run/ocserv.pid)
```

## Directory layout inside NAS

```
/var/packages/ocserv/
  target/          ← compiled binaries (managed by Package Center)
  var/
    etc/ocserv.conf     ← active configuration (editable)
    lib/ocserv/ocpasswd ← user password file
    log/ocserv.log      ← log output
    run/ocserv.pid      ← PID file
```

## Notes

- ocserv requires a TUN/TAP kernel module.  Synology kernels ship with
  `tun.ko`; ensure `/dev/net/tun` exists.
- Port 443 is also used by DSM HTTPS.  Change either the VPN port or the
  DSM HTTPS port in **Control Panel → Network → DSM Settings**.
- A valid TLS certificate is required.  You can use Synology's Let's Encrypt
  integration or generate your own.

## Contributing

Please open an issue or PR against this repository, or upstream to
<https://github.com/SynoCommunity/spksrc> once the package is stable.
