FROM golang:1.14 as builder

ARG GOARCH=amd64
ARG KANIKO_RELEASE="1.5.0"

WORKDIR /go/src/github.com/GoogleContainerTools
RUN echo $GOARCH > /goarch

RUN mkdir kaniko \
    && wget -O /tmp/kaniko.tar.gz https://github.com/GoogleContainerTools/kaniko/archive/refs/tags/v$KANIKO_RELEASE.tar.gz \
    && tar -xvf /tmp/kaniko.tar.gz -C ./kaniko --strip-components 1

WORKDIR /go/src/github.com/GoogleContainerTools/kaniko

RUN mkdir -p /kaniko/.docker
RUN make GOARCH=$(cat /goarch) && make GOARCH=$(cat /goarch) out/warmer

FROM debian:buster-slim AS certs

RUN \
  apt update && \
  apt install -y ca-certificates && \
  cat /etc/ssl/certs/* > /ca-certificates.crt

FROM alpine:3.13

ARG JQ_RELEASE="1.6"
ARG YQ_RELEASE="4.6.1"
ARG PUSHRM_RELEASE="1.7.0"

LABEL maintainer="woozymasta@gmail.com"

RUN apk add --update --no-cache \
    bash git tar xz gzip bzip2 curl coreutils openssl && \
    curl -sLo /usr/bin/jq \
      "https://github.com/stedolan/jq/releases/download/jq-$JQ_RELEASE/jq-linux64" && \
    curl -sLo /usr/bin/yq \
      "https://github.com/mikefarah/yq/releases/download/v$YQ_RELEASE/yq_linux_amd64" && \
    curl -sLo /usr/bin/pushrm \
      "https://github.com/christian-korneck/docker-pushrm/releases/download/v$PUSHRM_RELEASE/docker-pushrm_linux_amd64" && \
    chmod +x /usr/bin/jq /usr/bin/yq /usr/bin/pushrm

COPY --from=builder /go/src/github.com/GoogleContainerTools/kaniko/out/* /kaniko/
COPY --from=builder /go/src/github.com/GoogleContainerTools/kaniko/out/warmer /kaniko/warmer
COPY --from=builder /kaniko/.docker /kaniko/.docker
COPY --from=builder /go/src/github.com/GoogleContainerTools/kaniko/files/nsswitch.conf /etc/nsswitch.conf
COPY --from=certs /ca-certificates.crt /kaniko/ssl/certs/

ENV HOME /root
ENV USER root
ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/kaniko
ENV SSL_CERT_DIR=/kaniko/ssl/certs
ENV DOCKER_CONFIG /kaniko/.docker/

WORKDIR /workspace

ENTRYPOINT ["/kaniko/executor"]
