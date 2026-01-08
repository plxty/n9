{
  config,
  lib,
  n9,
  pkgs,
  inputs,
  ...
}:

let
  # TODO: including security.keys...
  cfg = config.deployment.file;

  libHm = import "${inputs.home-manager}/modules/lib/stdlib-extended.nix" lib;
  mkFileType =
    home:
    (import "${inputs.home-manager}/modules/lib/file-type.nix" {
      lib = libHm;
      homeDirectory = home;
      inherit pkgs;
    }).fileType;
in
{
  options.users = n9.mkAttrsOfSubmoduleOption { } (
    { options, config, ... }:
    let
      opt = options.deployment.file;

    in
    {
      # @see home-manager: home.file
      options.deployment.file = lib.mkOption {
        type = mkFileType config.home ''users."".deployment.file'' "{env}`HOME`" config.home;
        default = { };
      };

      config.variant.home-manager = {
        # doRename by ourselves:
        home.file = lib.mkAliasDefinitions opt;
      };
    }
  );

  options.deployment.file = lib.mkOption {
    type = mkFileType "/" ''deployment.file'' "/" "";
    default = { };
  };

  config.variant.shell.shellHooks = lib.mapAttrsToList (
    _: cfg:
    let
      source = cfg.source;
      target = "$PWD/${cfg.target}";
    in
    ''
      if [[ ! -L "${target}" || "$(readlink "${target}")" != "${source}" ]]; then
        mkdir -p "$(dirname "${target}")"
        ln -sfT "${source}" "${target}"
      fi
    ''
  ) (lib.filterAttrs (_: cfg: cfg.text != null) cfg);
}
