{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.system;
in
{
  options.system = {
    locale.language = lib.mkOption {
      type = lib.types.str;
      default = "zh_CN.UTF-8";
    };

    locale.timeZone = lib.mkOption {
      type = lib.types.str;
      default = "Asia/Shanghai";
    };

    activation.post = lib.mkOption {
      type = lib.types.lines;
    };
  };

  config.system.activation.post = ''
    # https://github.com/luishfonseca/nixos-config/blob/main/modules/upgrade-diff.nix
    # https://github.com/nix-darwin/nix-darwin/blob/e04a388232d9a6ba56967ce5b53a8a6f713cdfcf/modules/system/activation-scripts.nix#L114
    ${pkgs.nvd}/bin/nvd --nix-bin-dir=${pkgs.nix}/bin diff /run/current-system "$systemConfig"
  '';

  config.variant = lib.mkMerge [
    rec {
      nixos = {
        time.timeZone = cfg.locale.timeZone;
        system.activationScripts.postActivation.text = cfg.activation.post;
      };
      nix-darwin = nixos;
    }

    {
      nixos = {
        i18n.defaultLocale = cfg.locale.language;
        system.activationScripts.postActivation.supportsDryActivation = true;
      };
    }
  ];
}
