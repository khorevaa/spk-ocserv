# ocserv — Synology Package

Synology Package Center (SPK) package for [ocserv 1.5.0](https://ocserv.gitlab.io/www/) —
an OpenConnect VPN server compatible with Cisco AnyConnect SSL VPN clients.

## Authentication methods

| Method | Description |
|--------|-------------|
| **Local** | Password file managed with `ocpasswd` |
| **RADIUS** | Per-user auth via any RFC 2865 RADIUS server (FreeRADIUS, etc.) with support for RADIUS Class attribute group assignment |

## How it works

1. **Binary build** — GitHub Actions clones the [spksrc](https://github.com/SynoCommunity/spksrc)
   Docker toolchain and compiles ocserv 1.5.0 + radcli from the official source tarballs
   at `https://www.infradead.org/ocserv/download/`.
2. **Packaging** — compiled binaries are bundled by `tools/build-spk.sh` into a
   standard Synology `.spk` archive (no compilation on the NAS).
3. **Release** — pushing a `v*` tag triggers the full pipeline and publishes SPK
   files as a GitHub Release.

## Supported architectures

| `.spk` file | Synology models (examples) |
|-------------|---------------------------|
| `*_x86_64`  | DS918+, DS920+, DS923+     |
| `*_aarch64` | DS223, DS423+              |
| `*_armv8`   | DS120j, DS220j             |

## Installing on your NAS

1. Download the `.spk` matching your model from the [Releases](../../releases) page.
2. Open **Package Center → Manual Install** and upload the file.
3. The setup wizard asks for:
   - VPN port (default: **4433**)
   - TLS certificate and key paths
   - Authentication method (local or RADIUS)
   - If RADIUS: server host, ports, shared secret, NAS identifier

## Post-install usage

```sh
# Add a local VPN user
/var/packages/ocserv/target/bin/ocpasswd \
    -c /var/packages/ocserv/var/lib/ocpasswd <username>

# Reload config without dropping active sessions
kill -HUP $(cat /var/packages/ocserv/var/run/ocserv.pid)
```

### Switching to RADIUS after install

Edit `/var/packages/ocserv/var/etc/ocserv.conf`:
```
auth = "radius[config=/var/packages/ocserv/var/etc/radiusclient.conf,groupconfig=true]"
```

Edit `/var/packages/ocserv/var/etc/radius.servers`:
```
<host>:<auth_port>:<acct_port>    <shared_secret>
```

## File layout on the NAS

```
/var/packages/ocserv/
  target/                             # installed binaries (Package Center)
    bin/  ocserv  ocpasswd  occtl
    lib/  *.so.*
    etc/  ocserv.conf.tpl  radiusclient.conf.tpl
  var/
    etc/
      ocserv.conf          # active config — edit here
      radiusclient.conf    # RADIUS client config
      radius.servers       # RADIUS server list + secrets
    lib/ocpasswd           # local user password file
    log/ocserv.log
    run/ocserv.pid
```

## Repository structure

```
.
├── cross/
│   ├── ocserv/            # spksrc recipe: ocserv 1.5.0 from infradead.org
│   │   ├── Makefile
│   │   └── digests
│   └── radcli/            # spksrc recipe: radcli 1.5.2 (RADIUS client lib)
│       ├── Makefile
│       └── digests
├── package/               # SPK packaging metadata
│   ├── INFO
│   ├── conf/  privilege  resource
│   ├── etc/   ocserv.conf.tpl  radiusclient.conf.tpl
│   ├── scripts/  installer  start-stop-status
│   └── ui/wizard/  install_uifile
├── tools/
│   └── build-spk.sh       # assembles .spk from pre-built bins
├── icons/                 # place ocserv_72.png / ocserv_256.png here
└── .github/workflows/
    └── build.yml          # CI: compile → package → release
```

## Building locally

```sh
# 1. Clone spksrc
git clone https://github.com/SynoCommunity/spksrc.git /tmp/spksrc

# 2. Inject our cross packages
cp -r cross/radcli /tmp/spksrc/cross/
cp -r cross/ocserv /tmp/spksrc/cross/

# 3. Build for x86_64 inside the spksrc Docker container
cd /tmp/spksrc
docker run --rm -v "$(pwd):/spksrc" -w /spksrc \
    ghcr.io/synocommunity/spksrc:latest \
    sh -c "make -C cross/radcli digests && \
           make -C cross/ocserv digests && \
           make -C cross/ocserv ARCH=x64 TCVERSION=7.2"

# 4. Collect binaries
mkdir -p bins/x86_64/{bin,lib}
IROOT="/tmp/spksrc/cross/ocserv/work-x64-7.2/install"
cp "${IROOT}/usr/bin/"{ocserv,ocpasswd,occtl} bins/x86_64/bin/
find "${IROOT}/usr/lib" -name '*.so*' -exec cp -a {} bins/x86_64/lib/ \;

# 5. Build SPK
chmod +x tools/build-spk.sh
./tools/build-spk.sh --arch x86_64 --version 1.5.0 --rev 1 --bindir bins/x86_64
# → dist/ocserv_1.5.0-1_x86_64.spk
```

## Notes

- ocserv requires the TUN kernel module. DSM ships `tun.ko`; confirm `/dev/net/tun`
  exists on your model before starting.
- Port **443** conflicts with DSM HTTPS. The installer defaults to **4433**.
  Change DSM HTTPS in **Control Panel → Network → DSM Settings** if you need 443.
- TLS certificates are required. Use Synology's Let's Encrypt integration or
  generate your own with `openssl req -x509 ...`.
- RADIUS `groupconfig=true` uses the RADIUS **Class** attribute (25) to assign
  users to ocserv groups. Configure `group-config` sections in `ocserv.conf`
  if you need per-group routing or ACL policies.
