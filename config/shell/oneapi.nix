{ lib, ... }:

let
  # TODO: Automatically install? FIXME: Avoid hardcode username...
  # https://www.intel.com/content/www/us/en/developer/tools/oneapi/base-toolkit-download.html?packages=oneapi-toolkit&oneapi-toolkit-os=linux&oneapi-lin=offline
  sdk = "/home/byte/.local/share/oneapi";
  compiler_version = "2025.3";
in
{
  n9.shell.oneapi =
    { pkgs, ... }:
    let
      # Exclude some NixOS specified things, just don't want to dig out a new stdenv.
      # This is a bash wrapper, so `exec -a` won't work as it changes the bash...
      compiler_wrapper = pkgs.writers.writeBash "icx" { } ''
        cc="$1"
        shift
        args=()
        for a in "$@"; do
          case "$a" in
          "-resource-dir="*)
            continue ;;
          esac
          args+=("$a")
        done
        exec "$cc" "''${args[@]}"
      '';
    in
    {
      # This is a "mono" environment for mainly most of the oneAPI things.
      # Mostly for code viewing now:
      # * https://github.com/uxlfoundation/oneCCL
      # * https://github.com/intel/compute-runtime
      variant.shell.shellHooks = [
        ''
          # TODO: Priority?
          wrapper="$(dirname "$(which icx)")"
          source "${sdk}/setvars.sh"
          export PATH="$wrapper:$PATH"

          # Honor the cmake prefix:
          export CMAKE_PREFIX_PATH="$CMAKE_PREFIX_PATH:$NIXPKGS_CMAKE_PREFIX_PATH"
        ''
      ];

      environment.variables = {
        # To forcibly use exec in wrapper:
        NIX_CC_USE_RESPONSE_FILE = "0";
      };

      # Naive wrapper for replacing with clang:
      # Diff from `icpx -E -xc++ -v -` should be close enough to keep consistency.
      variant.shell.depsBuildBuild = [
        (pkgs.runCommand "icx" { } ''
          set -xeu
          mkdir -p "$out/bin"
          declare -A compilers=([clang]='icx' [clang++]='icpx')
          for cc in "''${!compilers[@]}"; do
            old="$(grep -Eo 'compiler=.+' "${pkgs.clang}/bin/$cc" | awk -F= '{print $2}')"
            new="bin/''${compilers[$cc]}"
            ${lib.getExe pkgs.gnused} "s!exec $old!exec ${compiler_wrapper} ${sdk}/compiler/${compiler_version}/$new!g" \
              "${pkgs.clang}/bin/$cc" > "$out/$new"
            chmod +x "$out/$new"
          done
        '')
      ];
      variant.shell.packages = with pkgs; [
        # intel-compute-runtime
        level-zero
      ];
    };
}
