{
  options,
  config,
  lib,
  ...
}:
let
  cfg = config.n9.users;
in
{
  # To have our own namespace :) And to avoid potential inifinite recursion :(
  options.n9.users = options.home-manager.users;

  config = lib.mkIf (cfg != { }) {
    # https://discourse.nixos.org/t/users-users-name-packages-vs-home-manager-packages/22240/2
    home-manager.useUserPackages = true;
    home-manager.useGlobalPkgs = true;

    # We can access the "raw" definition values within options.definitions,
    # thus avoiding to have all the default configurations (like doRename).
    home-manager.users = lib.mkAliasDefinitions options.n9.users;
  };
}
