{ lib, pkgs, ... }:

let
  image = "linux-kernel-builder";

  shellHooks = [
    ''export MAKEFLAGS="-j$(nproc --ignore 3)"''

    # Force a path mapping for clangd, to avoid some unwanted symbol link:
    # TODO: It can be a simple config now.
    ''
      if [[ ! -f .helix/languages.toml ]]; then
        mkdir -p .helix
        {
          echo "[language-server.clangd]"
          echo 'command = "clangd"'
          echo "args = [\"--path-mappings\", \"''${DIRSTACK[1]}=$(realpath .)\"]"
        } > .helix/languages.toml
      fi
    ''

    (lib.mkIf pkgs.stdenv.isDarwin ''
      if [[ "$(docker images -q ${image})" == "" ]]; then
        docker build -t ${image} -f ${./Dockerfile} .
      fi
    '')
  ];

  # TODO: Other platform...
  make = {
    # Make my own version of some config:
    defconfig =
      ''
        ${pkgs.gnumake}/bin/make defconfig "$@"
        ./scripts/config \
          -d COMPAT \
          -e ISO9660_FS -e JOLIET -e ZISOFS \
          -e 9P_FS_POSIX_ACL \
          -d DEBUG_INFO_REDUCED -e DEBUG_INFO_BTF -d DEBUG_INFO_BTF_MODULES -d SCHED_CLASS_EXT 
      ''
      # Mock resolve_btfids to prevent from linux building, TODO: respect O=?
      + lib.optionalString pkgs.stdenv.isDarwin ''
        ln -s ${pkgs.writers.writeBash "resolve_btfids" ''
          proj="$(realpath .)"
          exec docker run --rm -it -v "$proj:$proj" ${image} \
            bash -c "cd \"$proj\" && /usr/src/linux-headers-*-arm64/tools/bpf/resolve_btfids/resolve_btfids $@"
        ''} tools/bpf/resolve_btfids/resolve_btfids
      '';

    # TODO: make compile_commands.json
    compdb = ''exec ./scripts/clang-tools/gen_compile_commands.py "$@"'';

    qemu = lib.readFile ./qemu.sh;
  };

  clang = {
    gcc.enable = false;
    clang = {
      enable = true;
      unwrapped = true;
      # arguments = lib.mkIf pkgs.stdenv.isDarwin [
      #   "-Wno-macro-redefined"
      # ];
    };
    shellHooks = shellHooks ++ [ ''export LLVM="1"'' ];
    inherit make depsBuildBuild;
  };

  depsBuildBuild =
    with pkgs;
    [
      flex
      bison
      ncurses
      openssl
      cdrkit
    ]
    ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
      elfutils
      pahole
    ]
    ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
      (pkgs.stdenv.mkDerivation {
        # Headers that are missing in macOS, we make a little hacks.
        name = "glibc-supplement-headers";
        src = lib.fileset.toSource {
          root = ./.;
          fileset = ./.;
        };
        installPhase = ''
          runHook preInstall
          mkdir -p $out/include
          cp -a $src/*.h $out/include/
          runHook postInstall
        '';
      })

      # Mocked pahole, TODO: merge the docker part with bpf/default.nix?
      # TODO: Docker will introdue a '0x0d' (cr), making linux warning.
      (pkgs.writers.writeBashBin "pahole" ''
        proj="$(realpath .)"
        exec docker run --rm -it -v "$proj:$proj" ${image} bash -c "cd \"$proj\" && pahole $@"
      '')

      # It doesn't work...
      # (linuxHeaders.overrideAttrs (prev: {
      #   meta.platforms = prev.meta.platforms ++ [ pkgs.system ];
      # }))
    ];
in
{
  n9.shell.linux = {
    make =
      lib.traceIf pkgs.stdenv.hostPlatform.isDarwin
        "for darwin it's better to use the \"linux.clang\" shell, gcc version is broken"
        make;
    inherit shellHooks depsBuildBuild;
  };

  # For macOS please use the clang one :)
  n9.shell."linux.clang" = clang;

  n9.shell."linux.arm64" = {
    triplet = "aarch64-unknown-linux-gnu";
    shellHooks = shellHooks ++ [ "export ARCH=arm64" ];
    inherit make depsBuildBuild;
  };

  # For different config, it seems the nix will select the most suitable argument,
  # dynamically, with `config._module.args` as other options.
  n9.shell."linux.riscv" = {
    triplet = "riscv64-unknown-linux-gnu";
    shellHooks = shellHooks ++ [ "export ARCH=riscv" ];
    inherit make;
  };

  # Just fancy.
  n9.shell.rust-for-linux = lib.mkMerge [
    { rust.enable = true; }
    clang
  ];
}
