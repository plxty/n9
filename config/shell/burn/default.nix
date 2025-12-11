{
  n9.shell.burn =
    { pkgs, ... }:
    {
      environment.packages = with pkgs; [
        # Colmena:
        colmena

        # RDepends:
        getent # upload-keys
        (pkgs.writers.writeBashBin "niv" ''
          # Specify our own sources, don't want to patch it :/
          exec ${niv}/bin/niv -s lib/sources.json "$@"
        '')
        procps # pkill

        # Real stuff:
        (pkgs.writers.writeBashBin "burn" ''exec ${./burn.sh} "$@"'')
      ];
    };
}
