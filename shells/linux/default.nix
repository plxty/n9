{ lib, pkgs, ... }:

let
  shellHooks = [ ''export MAKEFLAGS="-j$(nproc --ignore 3)"'' ];

  # TODO: Other platform...
  make = {
    # Make my own version of some config:
    defconfig = ''
      ${pkgs.gnumake}/bin/make defconfig "$@"
      exec ./scripts/config \
        -d COMPAT \
        -e ISO9660_FS -e JOLIET -e ZISOFS \
        -e 9P_FS_POSIX_ACL
    '';

    compdb = ''exec ./scripts/clang-tools/gen_compile_commands.py "$@"'';

    qemu = ''
      image=alpine.qcow2.i
      if [[ ! -f "$image" ]]; then
        wget -O "$image" \
          'https://mirrors.tuna.tsinghua.edu.cn/alpine/v3.22/releases/cloud/nocloud_alpine-3.22.0-aarch64-uefi-cloudinit-r0.qcow2'
        qemu-img resize "$image" 8G
      fi

      # https://cloudinit.readthedocs.io/en/latest/howto/launch_qemu.html
      seed=seed.img.i
      if [[ ! -f "$seed" ]]; then
        touch network-config meta-data
        cat >user-data <<EOF
      #cloud-config
      password: alpine
      chpasswd:
        expire: False
      ssh_pwauth: True
      bootcmd:
      - echo "snap /snap 9p trans=virtio,version=9p2000.L 0 0" >> /etc/fstab
      - mount -m 777 -t 9p -o trans=virtio,version=9p2000.L snap /snap
      runcmd:
      - apk del cloud-init chrony
      EOF
        ${pkgs.cdrkit}/bin/genisoimage -output "$seed" -volid cidata -rational-rock -joliet \
          user-data meta-data network-config
        rm -f user-data meta-data network-config
      fi

      # 9pfs
      mkdir -p snap

      exec qemu-kvm \
        -machine virt \
        -cpu max \
        -smp 4 \
        -m 4096 \
        -drive "file=$image,index=0,format=qcow2,media=disk" \
        -drive "file=$seed,index=1,media=cdrom" \
        -virtfs local,path=./snap,mount_tag=snap,security_model=mapped-file \
        -kernel ./arch/arm64/boot/Image.gz \
        -append root=/dev/vda2 \
        -nographic \
        "$@"
    '';
  };

  clang = {
    gcc.enable = false;
    clang = {
      enable = true;
      unwrapped = true;
    };
    shellHooks = shellHooks ++ [ ''export LLVM="1"'' ];
    inherit make depsBuildBuild;
  };

  depsBuildBuild = with pkgs; [
    flex
    bison
    ncurses
    (
      if pkgs.stdenv.hostPlatform.isDarwin then
        pkgs.stdenv.mkDerivation {
          # Headers that are missing in macOS, we make a little hacks.
          name = "glibc-supplement-headers";
          src = lib.fileset.toSource {
            root = ./.;
            fileset = ./.;
          };
          installPhase = ''
            runHook preInstall
            mkdir -p $out/include
            cp -a $src/*.h $out/include/
            runHook postInstall
          '';
        }
      else
        elfutils
    )
    openssl
  ];
in
{
  n9.shell.linux = {
    make =
      lib.traceIf pkgs.stdenv.hostPlatform.isDarwin
        "for darwin it's better to use the \"linux.clang\" shell, gcc version is broken"
        make;
    inherit shellHooks depsBuildBuild;
  };

  # For macOS please use the clang one :)
  n9.shell."linux.clang" = clang;

  n9.shell."linux.arm64" = {
    triplet = "aarch64-unknown-linux-gnu";
    shellHooks = shellHooks ++ [ "export ARCH=arm64" ];
    inherit make depsBuildBuild;
  };

  # For different config, it seems the nix will select the most suitable argument,
  # dynamically, with `config._module.args` as other options.
  n9.shell."linux.riscv" = {
    triplet = "riscv64-unknown-linux-gnu";
    shellHooks = shellHooks ++ [ "export ARCH=riscv" ];
    inherit make;
  };

  # Just fancy.
  n9.shell.rust-for-linux = lib.mkMerge [
    { rust.enable = true; }
    clang
  ];
}
