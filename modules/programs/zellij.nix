{
  lib,
  n9,
  pkgs,
  ...
}:

{
  options.users = n9.options.mkAttrsOfSubmoduleOption {
    config.variant.home-manager.programs.zellij = {
      enable = true;
      enableBashIntegration = false;
      enableFishIntegration = false;
      enableZshIntegration = false;

      settings = {
        simplified_ui = true;
        default_shell = lib.getExe pkgs.fish;
        scroll_buffer_size = 200000;
        session_serialization = false;
        show_startup_tips = false;
        show_release_notes = false;
      };
    };
  };
}
