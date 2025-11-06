FROM safarov/freeswitch:latest

# Ensure CA bundles are present for TLS-enabled modules such as mod_signalwire
RUN set -euo pipefail \
    && apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates \
    && update-ca-certificates \
    && rm -rf /var/lib/apt/lists/*
