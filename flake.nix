{
  inputs.nixpkgs.url = "nixpkgs/nixos-21.05";

  outputs = inputs@{ self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    inherit (pkgs) lib;

    modules = let dir = ./modules; in builtins.map (file: dir + "/${file}")
      (builtins.attrNames (builtins.readDir dir));
    imported = builtins.map (file: {
      "${lib.removeSuffix ".nix" "${builtins.baseNameOf file}"}" = import file;
    }) modules;

  in {
    nixosModules = builtins.foldl' (x: y: x // y) {} imported;
    allModules = builtins.attrValues self.nixosModules;

    deployScript = pkgs.writeShellScriptBin "deploy.sh"
      (builtins.readFile ./deploy.sh);

    # Initial DigitalOcean image, with thanks to
    # https://git.sr.ht/~rj/digitalocean-image.
    doImage = (pkgs.nixos (self.nixosModules.vps-common {
      inherit pkgs;
      inherit (pkgs) lib;
      config.vps-common = true;
    } // {
      imports = [
        "${nixpkgs}/nixos/modules/virtualisation/digital-ocean-image.nix"
      ];
      config.virtualisation.digitalOceanImage.compressionMethod = "bzip2";
    })).digitalOceanImage;
  };
}
