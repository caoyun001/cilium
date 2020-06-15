#!/bin/bash

# Copyright 2017-2020 Authors of Cilium
# SPDX-License-Identifier: Apache-2.0

set -o xtrace
set -o errexit
set -o pipefail
set -o nounset

packages=(
  libelf1
  libmnl0
  bash-completion
  iptables
  kmod
  ca-certificates
)

apt-get update

ln -fs /usr/share/zoneinfo/UTC /etc/localtime

apt-get install -y --no-install-recommends "${packages[@]}"

apt-get purge --auto-remove
apt-get clean
rm -rf /var/lib/apt/lists/*
