# Copyright 2020 Authors of Cilium
# SPDX-License-Identifier: Apache-2.0

ARG COMPILERS_IMAGE=docker.io/cilium/image-compilers:57f235db9a07e81c5b60c536498ecbf2501dd267@sha256:080245ac0d7d061e05613e6bf887dc3c8bb07392cd2ce265b8a4aaaad17f2125
ARG GOLANG_IMAGE=docker.io/library/golang:1.14.4@sha256:d39a459086c75920390c9b9d42bbc7c52fef1fe7666e7633a02508c607c889d4

FROM ${GOLANG_IMAGE} as golang-dist

FROM ${COMPILERS_IMAGE}
LABEL maintainer="maintainer@cilium.io"

COPY --from=golang-dist /usr/local/go /usr/local/go
RUN mkdir -p /go
ENV GOROOT /usr/local/go
ENV GOPATH /go
ENV PATH "${GOROOT}/bin:${GOPATH}/bin:${PATH}"

COPY build-go-deps.sh /tmp/build-go-deps.sh
RUN /tmp/build-go-deps.sh

WORKDIR /go/src/github.com/cilium/cilium
