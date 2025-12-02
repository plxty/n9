{
  config,
  lib,
  n9,
  pkgs,
  ...
}:

let
  cfg = config.environment.packages;

  # Keep most of my CLI stuff here, as default packages (system-wide):
  systemPackages =
    with pkgs;
    [
      # basic
      wget
      which
      coreutils
      findutils
      procps
      hostname
      less
      more
      ncurses
      gnutar
      xz
      gnugrep
      patch
      gawk
      gnused
      getent

      # enhancements
      ripgrep
      fd
      bat
      p7zip
      unrar
      jq
      yq
      nix-tree
      pstree
      binutils
      moreutils
      file
      dig
      binwalk
      bc
      ncdu
      smartmontools
      rsync
      socat
      lrzsz
      # python3 # conflict with jupyter
      jupyter # https://github.com/NixOS/nixpkgs/issues/255923
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      # basic
      util-linux

      # enhancements
      iproute2
      iputils
      tcpdump
      strace
      sysstat
      lm_sensors
      bpftrace
      config.variant.nixos.boot.kernelPackages.perf
    ];

  # TODO: Fill it?
  shellPackages = [ ];
in
{
  options.environment.packages = lib.mkOption {
    type = lib.types.listOf lib.types.package;
    default = [ ];
  };

  options.users = n9.mkAttrsOfSubmoduleOption (
    { config, ... }:
    let
      cfg = config.environment.packages;
    in
    {
      options.environment.packages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
      };

      config.variant.home-manager.home.packages = cfg;
    }
  );

  config.environment.packages = lib.mkMerge [
    (lib.mkIf (!config.variant.is.shell) systemPackages)
    (lib.mkIf config.variant.is.shell shellPackages)
  ];

  config.variant = rec {
    nixos.environment.systemPackages = cfg;
    nix-darwin = nixos;
    shell.packages = cfg;
  };
}
