# SPDX-License-Identifier: MIT
# Copyright (c) 2021 Chua Hou
#
# Basic security configuration.

{ config, lib, ... }:

{
  options.secure = lib.mkOption {
    type = with lib.types; bool;
    description = "Whether to enable default security-related settings";
    default = true;
  };

  # Some options thanks to
  # https://christine.website/blog/paranoid-nixos-2021-07-18.
  config = lib.mkIf config.secure {
    networking.firewall.enable = true;
    nix.allowedUsers = [ "root" ];
    services.openssh = {
      passwordAuthentication = false;
      allowSFTP = false;
      challengeResponseAuthentication = false;
      extraConfig = ''
        X11Forwarding no
        AllowAgentForwarding no
        AllowStreamLocalForwarding no
        AuthenticationMethods publickey
      '';
    };
    services.fail2ban.enable = true;
    security.sudo.enable = false;
    security.auditd.enable = true;
    security.audit = {
      enable = true;
      rules = [ "-a exit,always -F arch=b64 -S execve" ];
    };
    environment.defaultPackages = lib.mkForce [];
  };
}
