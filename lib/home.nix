{ self, nixpkgs, ... }: # <- Flake inputs

# Making a Home Manager things.
hostName: # <- Module arguments

{
  uid ? 1000,
  home ? "/home/${username}",
  groups ? [ ],
  packages ? [ ],
  modules ? [ ],
  secrets ? { },
}: # <- NixOS or HomeManager configurations (kind of)

let
  inherit (nixpkgs) lib;
  inherit (self.lib) utils;

  config = {
    imports = [
      (
        { pkgs, ... }:
        {
          home.packages =
            with pkgs;
            [
              ripgrep
              fd
              wget
              age
              p7zip
              jq
              yq
              bat
              cached-nix-shell

              strace
              sysstat
              lm_sensors
              bcc
              bpftrace
              binwalk
            ]
            ++ (map (utils.attrByIfStringPath pkgs) packages);

          services.ssh-agent.enable = true;
          programs.ssh = {
            enable = true;
            addKeysToAgent = "9h";
            forwardAgent = true;
          };
        }
      )

      ../home/shell/fish.nix
      ../home/editor/helix.nix
    ] ++ lib.flatten (builtins.map (m: m.__home__ or m) modules);

    home = {
      inherit username;
      homeDirectory = home;
      stateVersion = "25.05";
    };
  };
in
assert lib.assertMsg (username != "root") "can't manage root!";
{
  # TODO: Way to assert unique username?
  ${that.nixosConfigurations.passthru.hostName}.${username} = {
    modules = [
      {
        users.groups.${username}.gid = uid;

        users.users.${username} =
          {
            isNormalUser = true;
            inherit uid home;
            group = username;
            extraGroups = [ "wheel" ] ++ groups;
          }
          // (
            if (passwd == "!") then
              { hashedPassword = passwd; }
            else
              { hashedPasswordFile = "/run/keys/passwd-${username}"; }
          );

        home-manager.users.${username} = config;
      }
    ] ++ lib.flatten (builtins.map (m: if m ? __nixos__ then m.__nixos__ username else { }) modules);

    secrets =
      # Global:
      (lib.optionalAttrs (passwd != "!") {
        "passwd-${username}" = {
          keyFile = passwd;
        };
      })
      # Home:
      // builtins.mapAttrs (
        _: v:
        v
        // {
          user = username;
          group = username;
          destDir =
            if v ? destDir then
              assert lib.assertMsg (!(lib.strings.hasPrefix "/" v.destDir)) "must live within home!";
              "${home}/${v.destDir}"
            else
              "/var/run/user/${uid}/keys";
          uploadAt = "post-activation"; # After user and home created.
        }
      ) ((lib.fold (m: old: (m.__secrets__ or { }) // old) { } modules) // secrets);
  };
}
