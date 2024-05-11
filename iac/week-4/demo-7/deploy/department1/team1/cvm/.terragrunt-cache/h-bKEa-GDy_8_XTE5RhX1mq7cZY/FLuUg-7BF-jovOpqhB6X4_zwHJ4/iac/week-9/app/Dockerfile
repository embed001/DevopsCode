
FROM golang:1.19

ARG HEY_URL=https://hey-release.s3.us-east-2.amazonaws.com/hey_linux_amd64

RUN wget $HEY_URL -O hey && chmod +x hey && mv hey /usr/bin/hey

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY *.go ./
RUN CGO_ENABLED=0 GOOS=linux go build -o /week9-prometheus-app

EXPOSE 8080

CMD ["/week9-prometheus-app"]