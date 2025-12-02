{
  n9.shell.d2l =
    { n9, pkgs, ... }:
    {
      environment.packages = with pkgs.python3Packages; [
        # TODO: Make d2l dependencies?
        torch
        torchvision
        pandas
        ipython
        matplotlib

        # just a simple d2l module...
        (buildPythonPackage rec {
          pname = "d2l";
          src = n9.sources.d2l;
          version = src.rev;
        })
      ];
    };
}
