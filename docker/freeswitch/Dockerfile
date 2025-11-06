FROM safarov/freeswitch:latest

# Ensure CA bundles are present for TLS-enabled modules such as mod_signalwire
RUN set -eux; \
    if command -v apt-get >/dev/null 2>&1; then \
        apt-get update; \
        apt-get install -y --no-install-recommends ca-certificates; \
        rm -rf /var/lib/apt/lists/*; \
    elif command -v apk >/dev/null 2>&1; then \
        apk add --no-cache ca-certificates; \
    else \
        echo "Unsupported base image: no known package manager found" >&2; \
        exit 1; \
    fi; \
    update-ca-certificates
