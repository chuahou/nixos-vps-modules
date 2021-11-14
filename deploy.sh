#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2021 Chua Hou
#
# Builds host $1, copies closure to $2 and activates it by switch or $3.

set -euo pipefail

nixos-rebuild build --flake .#$1
nix-copy-closure --to -v root@$2 $(realpath result)
ssh root@$2 $(realpath result)/bin/switch-to-configuration ${3:-switch}
