{
  n9.shell."bpf.x86_64".imports = [
    {
      # The glic static is hard to link, we use musl to make our life easier.
      triplet = "x86_64-unknown-linux-musl";

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
        # The zstd has no static version, therefore it's still dynamic linked.
        ''export NIX_LDFLAGS="$NIX_LDFLAGS -lzstd"''
      ];
    }

    (
      {
        config,
        lib,
        pkgs,
        pkgsCross,
        ...
      }:
      {
        depsBuildBuild = with pkgs; [
          pkg-config
          python3

          # need for build-dependencies:
          elfutils
        ];

        # Hmmm using packages (nativeBuildInputs) will not work, the offset is
        # kind of confusing for me now...
        buildInputs = lib.mkIf config.cross (
          with pkgsCross;
          [
            # dependencies
            zlib.static
            zstd

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
          ]
        );
      }
    )
  ];
}
