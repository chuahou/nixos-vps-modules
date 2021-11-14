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

  in rec {
    nixosModules = builtins.foldl' (x: y: x // y) {} imported;
    allModules = builtins.attrValues nixosModules;

    deployScript = pkgs.writeShellScriptBin "deploy.sh"
      (builtins.readFile ./deploy.sh);
  };
}
