{ pkgs, ... }:

let
  texlive = pkgs.texliveMedium.withPackages (
    pkgs: with pkgs; [
      xifthen
      ifmtarg
      titlesec
      enumitem
      xecjk
    ]
  );
in
pkgs.mkShell {
  name = "tex";

  packages = [ texlive ];
}
