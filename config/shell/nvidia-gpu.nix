{
  n9.shell.nvidia-gpu =
    { lib, pkgs, ... }:
    {
      development.linux.enable = true;

      environment.make = {
        targets."compile_commands.json" = ''
          # This will ignore something like osapi.c, the NVIDIA compiles common
          # part of the osapi itselves to an object, then link it to the modules.
          # "$KERNEL_SOURCES/source/scripts/clang-tools/gen_compile_commands.py" -d "$KERNEL_SOURCES/build" .

          # Required to use the wrapper, much safer than LD_PRELOAD.
          bear --force-wrapper -- make "$@"
        '';

        # Only specified flags we need, preventing selected toolchains:
        flags = lib.filter (
          flag:
          (lib.findFirst (p: lib.hasPrefix p flag) null [
            "ARCH="
            "TARGET_ARCH="
            "CROSS_COMPILE="
            "KBUILD_OUTPUT="
            "SYSSRC="
            "SYSOUT="
            "IGNORE_PREEMPT_RT_PRESENCE="
          ]) != null
        ) pkgs.linuxPackages.nvidia_x11_latest_open.makeFlags;
      };

      environment.variables = {
        KERNEL_SOURCES = "${pkgs.linux.dev}/lib/modules/${pkgs.linux.version}";
      };
    };
}
