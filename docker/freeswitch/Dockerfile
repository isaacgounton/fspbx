FROM safarov/freeswitch:latest

# Ensure CA bundles are reachable from the Debian-style path expected by mod_signalwire
RUN set -eux; \
    TARGET=/etc/ssl/certs/ca-certificates.crt; \
    if [ -f "$TARGET" ]; then exit 0; fi; \
    install_ca() { \
        if command -v apt-get >/dev/null 2>&1; then \
            apt-get update; \
            apt-get install -y --no-install-recommends ca-certificates; \
            rm -rf /var/lib/apt/lists/*; \
        elif command -v apk >/dev/null 2>&1; then \
            apk add --no-cache ca-certificates; \
        elif command -v microdnf >/dev/null 2>&1; then \
            microdnf install -y ca-certificates; \
        elif command -v dnf >/dev/null 2>&1; then \
            dnf install -y ca-certificates; \
            dnf clean all; \
        elif command -v yum >/dev/null 2>&1; then \
            yum install -y ca-certificates; \
            yum clean all; \
        elif command -v zypper >/dev/null 2>&1; then \
            zypper refresh; \
            zypper install -y ca-certificates; \
            zypper clean; \
        else \
            return 1; \
        fi; \
        return 0; \
    }; \
    install_ca || true; \
    mkdir -p "$(dirname "$TARGET")"; \
    for SRC in \
        /etc/ssl/certs/ca-bundle.crt \
        /etc/ssl/cert.pem \
        /etc/pki/tls/certs/ca-bundle.crt \
        /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem \
        /etc/ssl/ca-bundle.pem \
    ; do \
        if [ -f "$SRC" ]; then \
            ln -sf "$SRC" "$TARGET"; \
            exit 0; \
        fi; \
    done; \
    if command -v update-ca-certificates >/dev/null 2>&1; then \
        update-ca-certificates; \
    elif command -v update-ca-trust >/dev/null 2>&1; then \
        update-ca-trust extract; \
    fi; \
    for SRC in \
        /etc/ssl/certs/ca-bundle.crt \
        /etc/ssl/cert.pem \
        /etc/pki/tls/certs/ca-bundle.crt \
        /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem \
        /etc/ssl/ca-bundle.pem \
    ; do \
        if [ -f "$SRC" ]; then \
            ln -sf "$SRC" "$TARGET"; \
            exit 0; \
        fi; \
    done; \
    echo "Could not locate a CA bundle to link into $TARGET" >&2; \
    exit 1
