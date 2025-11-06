FROM alpine:3.20 AS certs
RUN apk add --no-cache ca-certificates

FROM safarov/freeswitch:latest

# Provide a standard CA bundle path for modules that expect Debian-style locations
# Ensure we run as root for file operations even if upstream image sets a non-root default
USER 0
COPY --from=certs /etc/ssl /etc/ssl
COPY --from=certs /usr/share/ca-certificates /usr/share/ca-certificates
RUN update-ca-certificates || true
USER freeswitch
