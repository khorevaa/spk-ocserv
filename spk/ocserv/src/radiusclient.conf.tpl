# radcli / radiusclient configuration for ocserv
# Written by the Synology ocserv package installer.
# Full radcli reference: https://github.com/radcli/radcli

# RADIUS authentication server
authserver    @@RADIUS_HOST@@:@@RADIUS_AUTH_PORT@@

# Accounting is disabled — not supported on Synology NAS.

# Server list with shared secrets (host:port <tab> secret [<tab> nas-id])
servers       /var/packages/ocserv/var/etc/radius.servers

# Connection timeout and retries
radius_timeout  10
radius_retries  3

bindaddr  *
