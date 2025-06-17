{ lib, pkgs, ... }:

{
  n9.shell."bpf.arm64".imports = [
    (
      { config, pkgsCross, ... }:
      {
        triplet = "aarch64-unknown-linux-gnu";

        rust = {
          enable = true;
          static = true;
        };
        clang = {
          enable = true;
          unwrapped = true;
        };

        depsBuildBuild = with pkgs; [
          # pkgsCross.buildPackages.pkg-config # should it?
          pkg-config
          python3
        ];

        packages = with pkgsCross; [
          elfutils
          libbpf
        ];

        make = lib.mkIf (config.rust.enable && pkgs.stdenv.isDarwin) {
          # In container, add -MJ to clang to generate compile command snippet.
          # For the scripts to work, use "-MJcompile_single.json"
          check = "exec cargo check";

          build = ''
            image=libbpf-rs-builder
            if [[ "$(docker images -q "$image")" == "" ]]; then
              docker build \
                --build-arg CONFIG_TARGET=${config.target} \
                --build-arg CONFIG_TRIPLET=${config.triplet} \
                -t "$image" -f ${./Dockerfile} .
            fi

            proj="$(realpath .)"
            docker run --rm -it \
              -v "$proj:$proj" \
              -v $HOME/.cargo/git:/usr/local/cargo/git \
              -v $HOME/.cargo/registry:/usr/local/cargo/registry \
              "$image" bash -c "cd \"$proj\" && cargo build $@"

            exec python3 ${./gen_compile_commands.py} ${lib.elemAt (lib.splitString "-" config.target) 0}
          '';
        };
      }
    )
  ];
}
