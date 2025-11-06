FROM safarov/freeswitch:latest

# Ensure CA bundles are reachable from the Debian-style path expected by mod_signalwire
RUN set -eux; \
    TARGET=/etc/ssl/certs/ca-certificates.crt; \
    if [ -f "$TARGET" ]; then exit 0; fi; \
    mkdir -p "$(dirname "$TARGET")"; \
    for SRC in \
        /etc/ssl/certs/ca-bundle.crt \
        /etc/ssl/cert.pem \
        /etc/pki/tls/certs/ca-bundle.crt \
        /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem \
    ; do \
        if [ -f "$SRC" ]; then \
            ln -sf "$SRC" "$TARGET"; \
            exit 0; \
        fi; \
    done; \
    echo "Could not locate a CA bundle to link into $TARGET" >&2; \
    exit 1
