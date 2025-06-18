ARCH="$1"
ALT_ARCH=
KERNEL_DIR="$PWD"
DATA_DIR="/var/lib/images"
MAPPING_DIR="$DATA_DIR"
PREFIX=()
QEMU_ARGS=()
shift 1

if [[ "$SSH_AUTH_SOCK" == "/opt/orbstack-guest/run/host-ssh-agent.sock" ]]; then
  PREFIX=(macctl run -p)
  KERNEL_DIR="/Users/$(whoami)/OrbStack/$(hostname)$KERNEL_DIR"
  MAPPING_DIR="/mnt/mac$DATA_DIR"
fi

case "$ARCH" in
  "aarch64")
    ALT_ARCH="arm64"
    QEMU_ARGS+=(-machine virt)
  ;;
  "x86_64")
    ALT_ARCH="x86"
    QEMU_ARGS+=(-machine q35)
  ;;
  *)
    ALT_ARCH="$ARCH"
  ;;
esac

if [[ "$("${PREFIX[@]}" uname -sm)" == "Darwin $ALT_ARCH" ]]; then
  QEMU_ARGS+=(-accel hvf)
fi

if [[ ! -d "$MAPPING_DIR" ]]; then
  "${PREFIX[@]}" sudo mkdir -p -m 777 "$DATA_DIR"
fi
cd "$MAPPING_DIR"

image="alpine-$ARCH".qcow2
if [[ ! -f "$image" ]]; then
  "${PREFIX[@]}" wget -O "$image" \
    "https://mirrors.tuna.tsinghua.edu.cn/alpine/v3.22/releases/cloud/nocloud_alpine-3.22.0-$ARCH-uefi-cloudinit-r0.qcow2"
  "${PREFIX[@]}" qemu-img resize "$image" 8G
fi

# https://cloudinit.readthedocs.io/en/latest/howto/launch_qemu.html
seed=seed.img
if [[ ! -f "$seed" ]]; then
  touch network-config meta-data
  cat >user-data <<EOF
#cloud-config
password: alpine
chpasswd:
  expire: False
ssh_pwauth: True
bootcmd:
- echo "share /share 9p trans=virtio,version=9p2000.L 0 0" >> /etc/fstab
- mount -m 777 -t 9p -o trans=virtio,version=9p2000.L share /share
runcmd:
- sed -i 's#https\?://dl-cdn.alpinelinux.org/alpine#https://mirrors.tuna.tsinghua.edu.cn/alpine#g' /etc/apk/repositories
- apk del cloud-init chrony
EOF
  genisoimage -output "$seed" -volid cidata -rational-rock -joliet \
    user-data meta-data network-config
  rm -f user-data meta-data network-config
fi

# 9pfs
"${PREFIX[@]}" mkdir -p share

exec "${PREFIX[@]}" "qemu-system-$ARCH" \
  "${QEMU_ARGS[@]}" \
  -cpu max \
  -smp 4 \
  -m 4096 \
  -drive "file=$image,index=0,format=qcow2,media=disk" \
  -drive "file=$seed,index=1,media=cdrom" \
  -virtfs "local,path=$DATA_DIR/share,mount_tag=share,security_model=mapped-file" \
  -kernel "$KERNEL_DIR/arch/$ALT_ARCH/boot/Image" \
  -append "root=/dev/vda2" \
  -netdev user,id=net0,net=172.20.48.0/24,hostfwd=tcp::41322-:22,hostfwd=tcp::41380-:80,hostfwd=tcp::41390-:9090 \
  -device virtio-net,netdev=net0 \
  -nographic \
  "$@"
