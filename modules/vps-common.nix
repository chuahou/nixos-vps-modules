# SPDX-License-Identifier: MIT
# Copyright (c) 2021 Chua Hou
#
# Common VPS options for creating images and after. Thanks to
# https://git.sr.ht/~rj/digitalocean-image.

{ config, lib, pkgs, modulesPath, ... }:

{
  options.vps-common = lib.mkOption {
    type = with lib.types; bool;
    description = "Whether to enable common VPS settings";
    default = true;
  };

  config = lib.mkIf config.vps-common {
    # Start headless without serial tty.
    systemd.services = {
      "serial-getty@ttyS0".enable = false;
      "serial-getty@hvc0".enable = false;
      "getty@tty1".enable = false;
      "autovt@".enable = false;
    };

    # Enable SSH.
    networking.firewall.allowedTCPPorts = [ 22 ];
    services.sshd.enable = true;

    # Enable Nix flakes.
    nix = {
      package = pkgs.nixUnstable;
      extraOptions = "experimental-features = nix-command flakes";
    };
  };
}
