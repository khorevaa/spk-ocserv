# ocserv configuration template
# Managed by the Synology ocserv package.
# Edit this file to customise your VPN settings.
# Full reference: https://ocserv.gitlab.io/www/manual.html

# ── Network ──────────────────────────────────────────────────────────────────
tcp-port = @@VPN_PORT@@
udp-port = @@VPN_PORT@@

# ── TLS certificates ─────────────────────────────────────────────────────────
# Paths to your server certificate, private key, and CA bundle.
# Generate a self-signed cert with:
#   openssl req -x509 -newkey rsa:4096 -keyout server-key.pem \
#               -out server-cert.pem -days 365 -nodes
server-cert = @@SERVER_CERT@@
server-key  = @@SERVER_KEY@@
ca-cert     = @@CA_CERT@@

# ── Authentication ────────────────────────────────────────────────────────────
# plain — password file managed with ocpasswd
auth = "plain[passwd=/var/packages/ocserv/var/lib/ocserv/ocpasswd]"

# ── Logging ───────────────────────────────────────────────────────────────────
syslog = false
log-level = 1

# ── Process / privilege ───────────────────────────────────────────────────────
run-as-user  = nobody
run-as-group = nogroup

# ── Client addressing ─────────────────────────────────────────────────────────
# VPN subnet assigned to connected clients
ipv4-network = 192.168.120.0/24
# DNS pushed to clients
dns = 8.8.8.8
dns = 8.8.4.4

# ── Routing ───────────────────────────────────────────────────────────────────
# Push a default route so all client traffic goes through the VPN.
route = default

# ── Session limits ────────────────────────────────────────────────────────────
max-clients  = 16
max-same-clients = 2
keepalive    = 32400
dpd          = 90
mobile-dpd   = 1800

# ── TUN device ────────────────────────────────────────────────────────────────
device = vpns

# ── Misc ──────────────────────────────────────────────────────────────────────
cisco-client-compat = true
dtls-legacy = true
