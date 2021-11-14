# SPDX-License-Identifier: MIT
# Copyright (c) 2021 Chua Hou
#
# NextCloud setup module.

{ config, lib, ... }:

let
  cfg = config.services.nextcloud-easy;
in {
  options.services.nextcloud-easy = {
    enable = lib.mkOption {
      type = with lib.types; bool;
      description = "Whether to enable NextCloud";
      default = false;
    };
    domain = lib.mkOption {
      type = with lib.types; uniq string;
      description = "Domain name for NextCloud";
      example = "nc.chuahou.dev";
    };
    email = lib.mkOption {
      type = with lib.types; uniq string;
      description = "Email to use for ACME";
      example = "human+github@chuahou.dev";
    };
    adminpassFile = lib.mkOption {
      type = with lib.types; uniq string;
      description = "Admin password file for NextCloud to use";
      default = "/var/nextcloud-admin-pass";
    };
    database = {
      user = lib.mkOption {
        type = with lib.types; uniq string;
        description = "Database user for NextCloud to use";
        default = "nextcloud";
      };
      name = lib.mkOption {
        type = with lib.types; uniq string;
        description = "Database name for NextCloud to use";
        default = "nextcloud";
      };
      passFile = lib.mkOption {
        type = with lib.types; uniq string;
        description = "Database password file for NextCloud to use";
        default = "/var/nextcloud-db-pass";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 80 443 ];

    security.acme = {
      acceptTerms = true;
      inherit (cfg) email;
    };

    services.nginx = {
      enable = true;
      recommendedOptimisation = true;
      recommendedGzipSettings  = true;
      recommendedProxySettings = true;
      recommendedTlsSettings   = true;
      virtualHosts.${cfg.domain} = {
        forceSSL = true;
        enableACME = true;
      };
    };

    services.nextcloud = {
      enable = true;
      hostName = cfg.domain;
      https = true;
      autoUpdateApps.enable = true;
      config = {
        dbtype = "pgsql";
        dbhost = "/run/postgresql";
        dbpassFile = cfg.database.passFile;
        dbuser = cfg.database.user;
        dbname = cfg.database.name;
        adminuser = "admin";
        inherit (cfg) adminpassFile;
      };
    };

    services.postgresql = {
      enable = true;
      ensureDatabases = [ cfg.database.name ];
      ensureUsers = [
        {
          name = cfg.database.user;
          ensurePermissions."DATABASE ${cfg.database.name}" = "ALL PRIVILEGES";
        }
      ];
    };

    # Make sure postgresql starts before nextcloud.
    systemd.services.nextcloud-setup = rec {
      requires = [ "postgresql.service" ];
      after    = requires;
    };
  };
}
