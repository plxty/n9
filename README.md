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

# ()ctothorp

```bash
# to enter
direnv allow

# switch local
burn

# or remote
burn evil

# nixos-anywhere
fire iris
```

Checkout `config/hosts` directory for my own builds, with [colmena](https://github.com/zhaofengli/colmena).
