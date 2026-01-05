{
  config,
  lib,
  n9,
  pkgs,
  ...
}:

let
  cfg = config.environment.packages;

  # System-wide stuff, not using much, as the home-manager one provides with
  # better fish-completion support.
  systemPackages = with pkgs; [
    python3
  ];

  # Keep most of my CLI stuff here, as default packages (per-user):
  userPackages =
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
      # jupyter # https://github.com/NixOS/nixpkgs/issues/255923
      inferno
      flamelens
      b4
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
      (n9.patch perf "perf-taste") # Speed up perf + compressed debug info:
    ];

  # TODO: Fill it?
  shellPackages = [ ];
in
{
  options.environment.packages = lib.mkOption {
    type = lib.types.listOf lib.types.package;
    default = [ ];
  };

  options.users = n9.mkAttrsOfSubmoduleOption { } (
    { config, ... }:
    let
      cfg = config.environment.packages;
    in
    {
      options.environment.packages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
      };

      # Defaults:
      config.environment.packages = userPackages;

      # To home-manager:
      config.variant.home-manager.home.packages = cfg;
    }
  );

  # Defaults:
  config.environment.packages = lib.mkMerge [
    (lib.mkIf (!config.variant.is.shell) systemPackages)
    (lib.mkIf config.variant.is.shell shellPackages)
  ];

  # To system/shell:
  config.variant = rec {
    nixos.environment.systemPackages = cfg;
    nix-darwin = nixos;
    shell.packages = cfg;
  };
}
