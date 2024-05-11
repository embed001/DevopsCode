FROM bitnami/minideb:bullseye
RUN install_packages curl ca-certificates

RUN curl -O -L "https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64" && \
mv cosign-linux-amd64 /usr/local/bin/cosign && \
chmod +x /usr/local/bin/cosign