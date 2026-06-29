# ocserv — Synology SPK

Synology Package Center (SPK) package for [ocserv 1.5.0](https://ocserv.gitlab.io/www/) —
an OpenConnect VPN server compatible with Cisco AnyConnect SSL VPN clients.

Built with the [spksrc](https://github.com/SynoCommunity/spksrc) cross-compilation framework.
GitHub Actions compiles the binaries; the resulting `.spk` installs pre-built binaries on the NAS.

## Authentication methods

| Method | Description |
|--------|-------------|
| **Local** | Password file managed with `ocpasswd` |
| **RADIUS** | Per-user auth via any RFC 2865 RADIUS server (FreeRADIUS, etc.); RADIUS accounting is not supported on Synology NAS |

## Supported architectures

| DSM target | NAS models (examples) |
|------------|----------------------|
| x64-7.2    | DS918+, DS920+, DS923+ |
| aarch64-7.2 | DS223, DS423+        |
| armv8-7.2  | DS120j, DS220j        |

## Installing

1. Download the `.spk` matching your model from the [Releases](../../releases) page.
2. Open **Package Center → Manual Install** and upload the file.
3. Follow the wizard: VPN port, TLS certificate paths, authentication method.

## Post-install usage

```sh
# Add a local VPN user
/var/packages/ocserv/target/bin/ocpasswd \
    -c /var/packages/ocserv/var/lib/ocpasswd <username>

# Reload config without dropping sessions
kill -HUP $(cat /var/packages/ocserv/var/run/ocserv.pid)
```

### Switching to RADIUS after install

Edit `/var/packages/ocserv/var/etc/ocserv.conf`:
```
auth = "radius[config=/var/packages/ocserv/var/etc/radiusclient.conf,groupconfig=true]"
```

Edit `/var/packages/ocserv/var/etc/radius.servers`:
```
<host>:<auth_port>    <shared_secret>    [nas-id]
```

## Repository structure

```
.
├── cross/
│   ├── ocserv/            # spksrc recipe: ocserv 1.5.0 (infradead.org)
│   │   ├── Makefile
│   │   └── digests
│   └── radcli/            # spksrc recipe: radcli 1.5.2 (RADIUS client lib)
│       ├── Makefile
│       └── digests
├── spk/
│   └── ocserv/            # spksrc SPK package
│       ├── Makefile        # package metadata + service config
│       ├── PLIST           # file inventory
│       └── src/
│           ├── service-setup.sh          # lifecycle hooks (postinst, prestart)
│           ├── ocserv.conf.tpl           # default config template
│           ├── radiusclient.conf.tpl     # RADIUS client config template
│           ├── ocserv.sc                 # firewall port definition
│           ├── conf/
│           │   └── privilege             # DSM 7 service privilege
│           └── wizard_templates/
│               └── install_uifile        # Package Center install wizard
└── .github/workflows/
    └── build.yml           # CI: spksrc Docker build → SPK → GitHub Release
```

## Building locally

```sh
# 1. Clone spksrc
git clone https://github.com/SynoCommunity/spksrc.git /tmp/spksrc

# 2. Inject packages
cp -r cross/radcli /tmp/spksrc/cross/
cp -r cross/ocserv /tmp/spksrc/cross/
cp -r spk/ocserv   /tmp/spksrc/spk/

# 3. Build inside spksrc Docker
cd /tmp/spksrc
docker run --rm -v "$(pwd):/spksrc" -w /spksrc \
    ghcr.io/synocommunity/spksrc:latest \
    make -C spk/ocserv ARCH=x64 TCVERSION=7.2

# SPK output: /tmp/spksrc/packages/ocserv_x64-7.2_1.5.0-1.spk
```

## Notes

- ocserv requires the **TUN kernel module**. DSM ships `tun.ko`; confirm `/dev/net/tun`
  exists on your model before starting the package.
- Port **443** conflicts with DSM HTTPS. The wizard defaults to **4433**.
- TLS certificates are required. Use Synology's Let's Encrypt integration or generate
  your own with `openssl req -x509 ...`.
- RADIUS `groupconfig=true` maps the RADIUS **Class** attribute (25) to ocserv groups.
  Add `group-config` sections in `ocserv.conf` for per-group routing or ACL policies.
