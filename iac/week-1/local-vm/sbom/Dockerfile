FROM bitnami/minideb:bullseye
RUN install_packages curl ca-certificates

RUN curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin && grype db update