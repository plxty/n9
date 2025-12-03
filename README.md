# N9.*

```nix
{ stdenv, gnumake, ... }:

stdenv.mkDerivation {
  # n-ix, yes, the n9 :O
  pname = "n";
  version = "ix";
}
```

NixOS (partial-non-secrets) configurations of mine. Break it!

_WARNING: Plenty of harmful codes, for reference only..._

# ()ctothorp

```bash
# to enter
direnv allow
# or
nix develop '.#burn'

# switch local
burn

# or remote
burn evil
```

# Imports

```nix
{
  inputs.n9.url = "github:plxty/n9";
  outputs =
    { n9, ... }: {
      colmenaHive = n9.mkHosts
        (import "${n9}/modules/module-list.nix")
        (import "${n9}/config/hosts-list.nix");
      devShells = n9.mkEnvs
        (import "${n9}/modules/module-list.nix")
        (import "${n9}/config/envs-list.nix");
    };
}
```

Append your own private hosts there :)

# Hierarchy

Relationship: n9 <-> variant <-> nixos/nix-darwin/..., most of compat works are done in `variant`.

```nix
{
  n9.${variant}.${name} = { pkgs, ...}: {
    hardware.configuration = ./hardware-configuration.nix;

    users.${userName} = {
      environment.packages = with pkgs; [
        helix
        neovim
      ];

      # for home-manager extension:
      variant.home-manager = {
        home.file.".config/...".text = "...";
      };

      # can reference a system configuration here:
      variant.${variant}.users.users.${userName} = {
        home = "...";
      };
    };

    # for system extension:
    variant.${variant} = {
      boot.initrd.availableKernelModules = [ "usbhid" ];
    };
  };
}
```

Where

* `variant`: one of `nixos`, `nix-darwin`, `home-manager` (for standalone) and `shell`
* `name`: to match your hostnamectl if non-`shell`
* `userName`: to match your whoami

The style of configuration is free, anything that just works is acceptable huh.

For modules, it's highly recommend to use what variant provides firstly, then the actual options from nixos or else, for example, using `environment.packages` is preferred than using `variant.nixos.environment.systemPackages` directly.

Many modules may not have corresponding variant, long way to go :/

# Asterisk

The n9 currently can't be burned if the directory `asterisk` is missing, you can build it as

```
asterisk/<name>/<userName>/id_ed25519
asterisk/<name>/<userName>/passwd
asterisk/<name>/some_system_secrets
```

to make it in fire.
