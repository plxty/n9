let
  base =
    {
      config,
      lib,
      pkgs,
      pkgsCross,
      ...
    }:
    {
      # Keep gcc enabled for simplicity...
      rust = {
        enable = true;
        static = true;
      };
      clang = {
        enable = true;
        unwrapped = true;
      };

      shellHooks = [
        # bug: https://github.com/libbpf/bpftool/issues/152
        ''export NIX_LDFLAGS="$NIX_LDFLAGS -lzstd -lc"''

        # bug: https://github.com/rust-lang/rust/issues/89626#issuecomment-1642423512
        (lib.optionalString (
          config.triplet == "aarch64-unknown-linux-musl"
        ) ''export NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE -mno-outline-atomics"'')
      ];

      depsBuildBuild = with pkgs; [
        # need for build-dependencies:
        elfutils
      ];

      # Hmmm using packages (nativeBuildInputs) will not work, the offset is
      # kind of confusing for me now...
      buildInputs = with pkgsCross; [
        # The glic static is hard to link, we use musl to make our life easier.
        zlib.static
        pkgsStatic.zstd

        # bug: https://github.com/NixOS/nixpkgs/issues/373516
        (elfutils.overrideAttrs rec {
          version = "0.193";
          src = fetchurl {
            url = "https://sourceware.org/elfutils/ftp/${version}/elfutils-${version}.tar.bz2";
            hash = "sha256-eFf0S2JPTY1CHfhRqq57FALP5rzdLYBJ8V/AfT3edjU=";
          };

          preCheck = ''
            # Workaround lack of rpath linking:
            #   ./dwarf_srclang_check: error while loading shared libraries:
            #     libelf.so.1: cannot open shared object file: No such file or directory
            # Remove once https://sourceware.org/PR32929 is fixed.
            export LD_LIBRARY_PATH="$PWD/libelf:$LD_LIBRARY_PATH"
          '';
        })

        # only for indexing
        libbpf
      ];

      make = {
        build = "exec cargo build";

        # only for vexas:
        push = ''
          bin="$(tomlq -r '.package.name' Cargo.toml)"
          exec macctl push "target/${config.triplet}/debug/$bin" /var/lib/images/share
        '';
      };
    };
in
{
  n9.shell."bpf.arm64".imports = [
    base
    { triplet = "aarch64-unknown-linux-musl"; }
  ];

  n9.shell."bpf.x86_64".imports = [
    base
    { triplet = "x86_64-unknown-linux-musl"; }
  ];
}
