#!/bin/bash

# Copyright 2017-2020 Authors of Cilium
# SPDX-License-Identifier: Apache-2.0

set -o xtrace
set -o errexit
set -o pipefail
set -o nounset

mkdir /src

cd /src

unset GOPATH

go mod init github.com/cilium/cilium/images/runtime
go get github.com/google/gops@v0.3.6

for arch in amd64 arm64 ; do
  mkdir -p "/out/linux/${arch}/bin"
  GOARCH="${arch}" go build -ldflags "-s -w" -o "/out/linux/${arch}/bin/gops" github.com/google/gops
done
