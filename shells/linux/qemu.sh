if [[ "${DEBUG:-}" == "" ]]; then
  set +x
fi

ARCH="$1"
ALT_ARCH=
KERNEL_DIR="$PWD"
DATA_DIR="/var/lib/images"
MAPPING_DIR="$DATA_DIR"
PREFIX=()
PRIVILEGE_PREFIX=()
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
    # ALT_ARCH="x86" # FIXME: Broken
    QEMU_ARGS+=(-machine q35)
  ;;
  *)
    ALT_ARCH="$ARCH"
  ;;
esac

if [[ "$("${PREFIX[@]}" uname -sm)" == "Darwin $ALT_ARCH" ]]; then
  # slirp seems conflict with the orbstack, it can't work after installed...
  # @see /Library/Preferences/SystemConfiguration/com.apple.vmnet.plist
  # vmnet-bridged,ifname=...
  PRIVILEGE_PREFIX=(sudo)
  QEMU_ARGS+=(-accel hvf -netdev "vmnet-shared,id=net0")
else
  QEMU_ARGS+=(-netdev "user,id=net0,net=172.20.48.0/24,hostfwd=tcp::41322-:22,hostfwd=tcp::41380-:80,hostfwd=tcp::41390-:9090")
fi

if [[ ! -d "$MAPPING_DIR" ]]; then
  "${PREFIX[@]}" sudo mkdir -p -m 777 "$DATA_DIR"
fi
cd "$MAPPING_DIR"

image="debian-$ARCH".qcow2
if [[ ! -f "$image" ]]; then
  "${PREFIX[@]}" wget -O "$image" \
    "https://cdimage.debian.org/images/cloud/sid/daily/latest/debian-sid-nocloud-$ALT_ARCH-daily.qcow2"
  "${PREFIX[@]}" qemu-img resize "$image" 8G
fi

# 9pfs
"${PREFIX[@]}" mkdir -p share
echo "To enable 9pfs, you should run it yourself:"
echo '  echo "share /share 9p trans=virtio,version=9p2000.L 0 0" >> /etc/fstab'
echo '  mount -a'

set -x

# sudo reason: https://gitlab.com/qemu-project/qemu/-/issues/1364
exec "${PREFIX[@]}" "${PRIVILEGE_PREFIX[@]}" "qemu-system-$ARCH" \
  "${QEMU_ARGS[@]}" \
  -cpu max \
  -smp 4 \
  -m 4096 \
  -drive "file=$image,index=0,format=qcow2,media=disk" \
  -virtfs "local,path=$DATA_DIR/share,mount_tag=share,security_model=mapped-file" \
  -kernel "$KERNEL_DIR/arch/$ALT_ARCH/boot/Image" \
  -append "root=/dev/vda1" \
  -device virtio-net,netdev=net0 \
  -nographic \
  "$@"
