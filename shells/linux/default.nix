{ lib, pkgs, ... }:

let
  shellHooks = [ ''export MAKEFLAGS="-j$(nproc --ignore 3)"'' ];

  make = {
    # Make my own version of some config:
    defconfig = ''
      ${pkgs.gnumake}/bin/make defconfig "$@"
      exec ./scripts/config -u COMPAT_VDSO
    '';

    compdb = ''exec ./scripts/clang-tools/gen_compile_commands.py "$@"'';
  };

  clang = {
    gcc.enable = false;
    clang = {
      enable = true;
      unwrapped = true;
    };
    shellHooks = shellHooks ++ [ ''export LLVM="1"'' ];
    inherit make depsBuildBuild;
  };

  depsBuildBuild = with pkgs; [
    flex
    bison
    ncurses
    (
      if pkgs.stdenv.hostPlatform.isDarwin then
        pkgs.stdenv.mkDerivation {
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
        }
      else
        elfutils
    )
    openssl
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
