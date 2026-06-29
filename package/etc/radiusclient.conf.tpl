# radcli / radiusclient configuration for ocserv
# Written by the Synology ocserv package installer.
# Full radcli reference: https://github.com/radcli/radcli

# RADIUS authentication server
authserver    @@RADIUS_HOST@@:@@RADIUS_AUTH_PORT@@

# RADIUS accounting server (set to same host or leave as authserver)
acctserver    @@RADIUS_HOST@@:@@RADIUS_ACCT_PORT@@

# Shared secret (must match the secret configured on the RADIUS server)
servers       /var/packages/ocserv/var/etc/radius.servers

# Dictionary file — radcli 1.5+ has built-in RFC attributes, but a
# supplementary dictionary can be placed here for vendor-specific AVPs.
#dictionary    /var/packages/ocserv/target/etc/radcli/dictionary

# Connection timeout in seconds
radius_timeout     10

# Number of retries before giving up
radius_retries     3

# Deadtime in seconds before a failed server is retried
bindaddr      *
