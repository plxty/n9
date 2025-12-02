{ config, lib, ... }:

let
  cfg = config.environment.variables;
in
{
  options.environment.variables = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = { };
  };

  config.variant = {
    # For NixOS, effects to:
    nixos.environment.sessionVariables = cfg // {
      NIX_CRATES_INDEX = "sparse+https://mirrors.ustc.edu.cn/crates.io-index/";
      REPO_URL = "https://mirrors.tuna.tsinghua.edu.cn/git/git-repo";
    };
    # TODO: nix-darwin
    # Only the shell can have the ability to expand variables, like $NIX_LDFLAGS.
    shell.shellHooks = lib.mkBefore (
      [
        # @see nixpkgs/pkgs/build-support/cc-wrapper/setup-hooks.sh
        ''
          export -n \
            AR AR_FOR_BUILD \
            AS AS_FOR_BUILD \
            CC CC_FOR_BUILD \
            CXX CXX_FOR_BUILD \
            LD LD_FOR_BUILD \
            NM NM_FOR_BUILD \
            OBJCOPY OBJCOPY_FOR_BUILD \
            OBJDUMP OBJDUMP_FOR_BUILD \
            PKG_CONFIG PKG_CONFIG_FOR_BUILD \
            RANLIB RANLIB_FOR_BUILD \
            READELF READELF_FOR_BUILD \
            SIZE SIZE_FOR_BUILD \
            STRINGS STRINGS_FOR_BUILD \
            STRIP STRIP_FOR_BUILD
        ''
      ]
      ++ lib.mapAttrsToList (k: v: ''export ${k}="${v}"'') cfg
    );
  };
}
