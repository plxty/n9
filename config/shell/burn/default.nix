{
  n9.shell.burn =
    {
      n9,
      pkgs,
      inputs,
      ...
    }:
    {
      environment.packages = with pkgs; [
        # Colmena:
        (n9.patch inputs.colmena.packages.${stdenv.system}.colmena "colmena-taste")

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
