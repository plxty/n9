{
  lib,
  n9,
  inputs,
  ...
}:

{
  # To provide pkgs in modules argument:
  imports = [ "${inputs.nixpkgs}/nixos/modules/misc/nixpkgs.nix" ];

  options.users = n9.mkAttrsOfSubmoduleOption { } {
    config.deployment.file.".config/nixpkgs/config.nix".text = ''
      { allowUnfree = true; }
    '';
  };

  # OSes will use the overrided `pkgs` with those options set:
  config.nixpkgs = {
    # https://wiki.nixos.org/wiki/Overlays
    # It's generally not a good idea to place packages here, which may cause
    # rebuild for package who relies one of the package here as dependency...
    # Therefore, try keep the overlay as minimal as possible, @see packages.nix
    # Here for mainly new apps, or something that downstream host config uses.
    overlays = [
      # New toys:
      (
        final: prev:
        import ../.. {
          inherit (inputs) nixpkgs;
          pkgs = prev;
        }
      )

      # Hackish:
      (final: prev: {
        # Make fcitx5-rime or ibus-engines.rime works.
        # Overridding fcitx5 isn't simple as nixos uses `fcitx5-with-addons`.
        librime = n9.patch prev.librime "librime-temp-ascii";

        # Enforce the LUA version of librime-lua, same reason above:
        # @see pkgs/by-name/li/librime-lua/package.nix
        librime-lua = prev.librime-lua.overrideAttrs (prev': {
          propagatedBuildInputs = (lib.remove prev.lua prev'.propagatedBuildInputs) ++ [
            prev.lua5_4
          ];
        });
      })
    ];

    # Unfree is acceptable, what's the price?
    config.allowUnfree = true;
  };
}
