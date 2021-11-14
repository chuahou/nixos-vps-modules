# SPDX-License-Identifier: MIT
# Copyright (c) 2021 Chua Hou
#
# dnsmasq setup.

{ config, lib, pkgs, ... }:

{
  options.services.dnsmasq-easy = {
    enable = lib.mkEnableOption "dnsmasq with hosts-blocklists";
    addresses = lib.mkOption {
      type = with lib.types; listOf str;
      description = "Addresses for dnsmasq to listen on";
      default = [ "127.0.0.1" ];
    };
    servers = lib.mkOption {
      type = with lib.types; listOf str;
      description = "DNS servers for dnsmasq to forward requests to";
      default = [ "1.1.1.1" "8.8.8.8" "8.8.4.4" ];
    };
    cacheSize = lib.mkOption {
      type = with lib.types; int;
      description = "Cache size for dnsmasq to use";
      default = 10000;
    };
    ttl = lib.mkOption {
      type = with lib.types; int;
      description = "dnsmasq's local cache TTL";
      default = 300;
    };
    confFile = lib.mkOption {
      type = with lib.types; uniq str;
      description = "dnsmasq config file path";
    };
    interface = lib.mkOption {
      type = with lib.types; uniq str;
      description = "Interface to allow DNS on";
      example = "wg0";
    };
  };

  config =
  let
    cfg = config.services.dnsmasq-easy;
  in lib.mkIf cfg.enable {
    services.dnsmasq.enable = true;
    services.dnsmasq.extraConfig = ''
      domain-needed
      bogus-priv

      no-resolv
      ${lib.concatStringsSep "\n" (builtins.map (x: "server=${x}")
        cfg.servers)}

      listen-address=${lib.concatStringsSep "," cfg.addresses}
      bind-interfaces

      cache-size=${builtins.toString cfg.cacheSize}
      local-ttl=${builtins.toString cfg.ttl}

      conf-file=${cfg.confFile}
    '';

    networking.firewall.interfaces.${cfg.interface} = {
      allowedTCPPorts = [ 53 ];
      allowedUDPPorts = [ 53 ];
    };
  };
}
