# ocserv — Synology Package

Synology Package Center (SPK) package for [ocserv](https://ocserv.gitlab.io/www/) — an
OpenConnect VPN server compatible with Cisco AnyConnect SSL VPN clients.

## How it works

1. **Binary build** — GitHub Actions uses the [spksrc](https://github.com/SynoCommunity/spksrc)
   Docker toolchain to compile ocserv once per architecture.
2. **Packaging** — the compiled binaries are bundled with service scripts and a
   configuration wizard into a standard Synology `.spk` archive by `tools/build-spk.sh`.
3. **Release** — pushing a version tag triggers the full pipeline and publishes SPK
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
3. Follow the wizard (VPN port, TLS certificate paths).

## Post-install usage

```sh
# Add a VPN user
/var/packages/ocserv/target/bin/ocpasswd \
    -c /var/packages/ocserv/var/lib/ocpasswd <username>

# Reload config without dropping connections
kill -HUP $(cat /var/packages/ocserv/var/run/ocserv.pid)
```

## File layout on the NAS

```
/var/packages/ocserv/
  target/                       # installed binaries (managed by Package Center)
    bin/  ocserv  ocpasswd  occtl
    lib/  *.so.*
    etc/  ocserv.conf.tpl
  var/
    etc/ocserv.conf             # active config — edit here
    lib/ocpasswd                # user password file
    log/ocserv.log
    run/ocserv.pid
```

## Repository structure

```
.
├── cross/ocserv/               # spksrc Makefile used by CI to compile binaries
│   ├── Makefile
│   └── digests
├── package/                    # SPK packaging metadata
│   ├── INFO                    # package metadata template
│   ├── conf/
│   │   ├── privilege           # service runs as root
│   │   └── resource            # DSM firewall / symlink config
│   ├── etc/
│   │   └── ocserv.conf.tpl     # default configuration template
│   ├── scripts/
│   │   ├── installer           # pre/post-install hooks
│   │   └── start-stop-status   # daemon management
│   └── ui/wizard/
│       └── install_uifile      # Package Center install wizard
├── tools/
│   └── build-spk.sh            # assembles the .spk from pre-built bins
├── icons/                      # place PACKAGE_ICON_72.png / _256.png here
└── .github/workflows/
    └── build.yml               # CI: build → package → release
```

## Building locally

```sh
# 1. Clone spksrc and build binaries for x86_64
git clone https://github.com/SynoCommunity/spksrc.git /tmp/spksrc
cp -r cross/ocserv /tmp/spksrc/cross/
cd /tmp/spksrc
docker run --rm -v "$(pwd):/spksrc" -w /spksrc \
    ghcr.io/synocommunity/spksrc:latest \
    make -C cross/ocserv ARCH=x64 TCVERSION=7.2

# 2. Extract binaries
mkdir -p bins/x86_64/{bin,lib}
cp /tmp/spksrc/cross/ocserv/work*/install/usr/bin/{ocserv,ocpasswd,occtl} bins/x86_64/bin/
cp -a /tmp/spksrc/cross/ocserv/work*/install/usr/lib/*.so* bins/x86_64/lib/ 2>/dev/null || true

# 3. Build SPK
chmod +x tools/build-spk.sh
./tools/build-spk.sh --arch x86_64 --version 1.2.3 --rev 1 --bindir bins/x86_64
# Output: dist/ocserv_1.2.3-1_x86_64.spk
```

## Notes

- ocserv needs the TUN kernel module. Synology DSM ships `tun.ko`; confirm
  `/dev/net/tun` exists on your model.
- Port **443** conflicts with DSM HTTPS. The wizard defaults to **4433**.
  Change DSM HTTPS in **Control Panel → Network → DSM Settings** if you need 443.
- TLS certificates are required. Use the Synology Let's Encrypt integration
  or generate your own with `openssl req -x509 ...`.
