{ lib, ... }:

let
  base =
    {
      config,
      n9,
      pkgs,
      pkgsCross,
      ...
    }:
    {
      # shell.static = true; # should it static?
      toolchain.rust.enable = true;
      toolchain.clang = {
        enable = true;
        unwrapped = true;
      };

      environment.variables = lib.mkMerge [
        {
          # bug: https://github.com/libbpf/bpftool/issues/152
          NIX_LDFLAGS = "$NIX_LDFLAGS -lzstd -lc";
        }

        # bug: https://github.com/rust-lang/rust/issues/89626#issuecomment-1642423512
        (lib.mkIf (config.shell.triplet == "aarch64-unknown-linux-musl") {
          NIX_CFLAGS_COMPILE = "$NIX_CFLAGS_COMPILE -mno-outline-atomics";
        })
      ];

      variant.shell.depsBuildBuild = with pkgs; [
        elfutils
        protobuf # for bytemap2-agent
        krb5
      ];

      # Hmmm using packages (nativeBuildInputs) will not work, the offset is
      # kind of confusing for me now...
      variant.shell.buildInputs = lib.mkMerge [
        (with pkgsCross; [
          elfutils
          libbpf # only for indexing
          openssl
        ])

        (lib.mkIf (!config.shell.static) (
          with pkgsCross;
          [
            zlib
            zstd
          ]
        ))

        (lib.mkIf config.shell.static (
          with pkgsCross;
          [
            # The glibc static is hard to link, we use musl to make our life easier.
            zlib.static
            pkgsStatic.zstd
          ]
        ))
      ];

      environment.make.targets = {
        build = "cargo build";

        # only for vexas, until https://github.com/orbstack/orbstack/issues/1504
        push = ''
          bin="$(tomlq -r '.package.name' Cargo.toml)"
          macctl push "target/${config.shell.triplet}/debug/$bin" /var/lib/images/share
        '';
      };
    };
in
{
  n9.shell.bpf = base;
}
