FROM golang:1.21.1-alpine3.18 AS builder
COPY . /build
WORKDIR /build
RUN go build -o /webhook .

FROM golang:1.16.4-alpine
COPY --from=builder /webhook /usr/bin/webhook

RUN apk update && \
    chmod 0770 /usr/bin/webhook && \
    mkdir -p /source && \
    addgroup -g 1000 -S sre && \
    adduser -u 1000 -S sre -G sre && \
    chown -Rv sre:sre /source && \
    chmod 0775 /source

USER sre
WORKDIR /source

ENTRYPOINT [ "/usr/bin/webhook" ]
