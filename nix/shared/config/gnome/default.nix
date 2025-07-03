{ this, ... }:

{
  imports = [
    (
      if this ? homeModule then
        ./home.nix
      else if this ? nixos then
        ./nixos.nix
      else
        { }
    )
  ];
}
