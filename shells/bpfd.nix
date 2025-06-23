{ pkgs, ... }:

let
  base =
    { config, pkgsCross, ... }:
    {
      golang.enable = true;

      depsBuildBuild = with pkgs; [
        (writers.writePython3Bin "protoc"
          {
            flakeIgnore = [
              "E401"
              "E111"
              "E501"
            ];
          }
          ''
            import os, sys
            new_argv = []
            for arg in sys.argv:
              path = arg.removeprefix("--go_out=plugins=grpc:")
              if len(path) != len(arg):
                new_argv.append(f"--go-grpc_out=require_unimplemented_servers=false:{path}")
                new_argv.append(f"--go_out={path}")
              else:
                new_argv.append(arg)
            os.execv("${protobuf}/bin/protoc", new_argv)
          ''
        )
        protoc-gen-go
        protoc-gen-go-grpc
      ];

      buildInputs = with pkgsCross; [
        pkgsStatic.libpcap
        pkgsStatic.libnl
      ];

      shellHooks = [
        # Seems like the pkgsStatic isn't play well in nix, we need to specify
        # every indirect dependencies of that static libaray we actually want.
        ''export NIX_LDFLAGS="$NIX_LDFLAGS -lnl-3 -lnl-genl-3"''
      ];

      make = {
        # @see build/build.sh and Makefile
        build = ''
          export BUILD_SLAM="1"
          export VERSION="$(git describe --tags --always --dirty | sed 's/^v//g')"
          export TAG="$VERSION"
          export ARCH="$GOARCH"
          export OS="$GOOS"
          export CC="${config.triplet}-gcc"

          mkdir -p "$(go env GOPATH)/src/code.byted.org/sys"
          ln -Tsf $PWD "$(go env GOPATH)/src/code.byted.org/sys/bpfd"

          for bin in bpfd bpfd-metrics; do
            BIN="$bin" bash ./build/build.sh
          done
        '';
      };
    };
in
{
  # Can now only be x86:
  n9.shell."bpfd.x86_64".imports = [
    base
    { triplet = "x86_64-unknown-linux-musl"; }
  ];
}
