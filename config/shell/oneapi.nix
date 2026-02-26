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
        ''
      ];

      # Naive wrapper for replacing with clang:
      variant.shell.depsBuildBuild = [
        (pkgs.runCommand "icx" { } ''
          set -xeu
          mkdir -p "$out/bin"
          declare -A compilers=([clang]='icx' [clang++]='icpx')
          for cc in "''${!compilers[@]}"; do
            old="$(grep -Eo 'compiler=.+' "${pkgs.clang}/bin/$cc" | awk -F= '{print $2}')"
            new="bin/''${compilers[$cc]}"
            ${lib.getExe pkgs.gnused} "s!$old!${sdk}/compiler/${compiler_version}/$new!g" \
              "${pkgs.clang}/bin/$cc" > "$out/$new"
            chmod +x "$out/$new"
          done
        '')
      ];
    };
}
