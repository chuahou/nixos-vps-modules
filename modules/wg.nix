# SPDX-License-Identifier: MIT
# Copyright (c) 2021 Chua Hou
#
# WireGuard module for configurations I use.

{ config, lib, pkgs, ... }:

let
  cfg = config.networking.wg;
in {
  options.networking.wg = {
    enable = lib.mkOption {
      type = with lib.types; bool;
      description = "Whether to enable WireGuard";
      default = false;
    };
    port = lib.mkOption {
      type = with lib.types; uniq int;
      description = "Listening port for WireGuard";
      default = 33333;
    };
    interface = lib.mkOption {
      type = with lib.types; str;
      description = "Interface name";
      default = "wg";
    };
    ip = lib.mkOption {
      type = with lib.types; uniq str;
      description = "IP address of interface";
      example = "10.1.1.1";
    };
    subnet = lib.mkOption {
      type = with lib.types; uniq str;
      description = "Subnet of interface";
      default = "${cfg.ip}/24";
    };
    keyfile = lib.mkOption {
      type = with lib.types; uniq str;
      description = "Path to private key file (will be generated)";
      default = "/root/wg.private";
    };
    peers = lib.mkOption {
      type = with lib.types; listOf attrs;
      description = "WireGuard peers";
      default = [];
    };
    forwardInternet = {
      enable = lib.mkOption {
        type = with lib.types; bool;
        description = "Whether to forward packets through NAT";
        default = false;
      };
      interface = lib.mkOption {
        type = with lib.types; uniq str;
        description = "Interface to forward packets through NAT through";
        example = "ens3";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    networking = {
      firewall.allowedUDPPorts = [ cfg.port ];

      nat = lib.mkIf cfg.forwardInternet.enable {
        enable = true;
        externalInterface = cfg.forwardInternet.interface;
        internalInterfaces = [ cfg.interface ];
      };

      wireguard.interfaces.${cfg.interface} = {
        ips = [ cfg.subnet ];
        listenPort = cfg.port;

        privateKeyFile = cfg.keyfile;
        generatePrivateKeyFile = true;

        inherit (cfg) peers;

        postSetup = lib.mkIf cfg.forwardInternet.enable ''
          ${pkgs.iptables}/bin/iptables -A FORWARD -i ${cfg.interface} -j ACCEPT
          ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING \
              -o ${cfg.forwardInternet.interface} -j MASQUERADE
        '';
        postShutdown = lib.mkIf cfg.forwardInternet.enable ''
          ${pkgs.iptables}/bin/iptables -D FORWARD -i ${cfg.interface} -j ACCEPT
          ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING \
              -o ${cfg.forwardInternet.interface} -j MASQUERADE
        '';
      };
    };

    # Don't ban logins through WireGuard if fail2ban is enabled.
    services.fail2ban.ignoreIP = [ cfg.subnet ];
  };
}
