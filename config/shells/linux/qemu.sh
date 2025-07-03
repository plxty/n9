if [[ "${DEBUG:-}" == "" ]]; then
  set +x
fi

# In orbstack, host = macos, guest = linux

ARCH="$1"
ALT_ARCH="$ARCH"
shift 1

HOST_PREFIX=()
HOST_KERNEL_DIR="$PWD"
HOST_DATA_DIR="/var/lib/images"

GUEST_KERNEL_DIR="$HOST_KERNEL_DIR"
GUEST_DATA_DIR="$HOST_DATA_DIR"

QEMU_SUDO=
QEMU_ARGS=()

if [[ "$SSH_AUTH_SOCK" == "/opt/orbstack-guest/run/host-ssh-agent.sock" ]]; then
  HOST_PREFIX=(macctl run -p)
  HOST_KERNEL_DIR="/Users/$(whoami)/OrbStack/$(hostname)$GUEST_KERNEL_DIR"
  GUEST_DATA_DIR="/mnt/mac$HOST_DATA_DIR"
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
esac

if [[ "$("${HOST_PREFIX[@]}" uname -sm)" == "Darwin $ALT_ARCH" ]]; then
  # slirp seems conflict with the orbstack, it can't work after installed...
  # @see /Library/Preferences/SystemConfiguration/com.apple.vmnet.plist
  # vmnet-bridged,ifname=...
  QEMU_SUDO=sudo
  QEMU_ARGS+=(-accel hvf -netdev "vmnet-shared,id=net0")
else
  QEMU_ARGS+=(-netdev "user,id=net0,net=172.20.48.0/24,hostfwd=tcp::41322-:22,hostfwd=tcp::41380-:80,hostfwd=tcp::41390-:9090")
fi

if [[ ! -d "$GUEST_DATA_DIR" ]]; then
  "${HOST_PREFIX[@]}" sudo mkdir -p -m 777 "$HOST_DATA_DIR"
fi
cd "$GUEST_DATA_DIR"

image="debian-$ARCH".qcow2
if [[ ! -f "$image" ]]; then
  "${HOST_PREFIX[@]}" wget -O "$image" \
    "https://cdimage.debian.org/images/cloud/sid/daily/latest/debian-sid-nocloud-$ALT_ARCH-daily.qcow2"
  "${HOST_PREFIX[@]}" qemu-img resize "$image" 8G
fi

# 9pfs
"${HOST_PREFIX[@]}" mkdir -p share
echo "To enable 9pfs, you should run it yourself:"
echo '  mkdir /share'
echo '  echo "share /share 9p trans=virtio,version=9p2000.L 0 0" >> /etc/fstab'
if [[ -d "$HOST_KERNEL_DIR/debian/lib/modules" ]]; then
  QEMU_ARGS+=(-virtfs "local,path=$HOST_KERNEL_DIR/debian/lib/modules,mount_tag=modules,security_model=mapped-file")
  echo '  echo "modules /lib/modules 9p trans=virtio,version=9p2000.L 0 0" >> /etc/fstab'
fi
echo '  mount -a'

set -x

# sudo reason: https://gitlab.com/qemu-project/qemu/-/issues/1364
exec "${HOST_PREFIX[@]}" "$QEMU_SUDO" "qemu-system-$ARCH" \
  "${QEMU_ARGS[@]}" \
  -cpu max \
  -smp 4 \
  -m 4096 \
  -drive "file=$image,index=0,format=qcow2,media=disk" \
  -virtfs "local,path=$HOST_DATA_DIR/share,mount_tag=share,security_model=mapped-file" \
  -kernel "$HOST_KERNEL_DIR/arch/$ALT_ARCH/boot/Image" \
  -append "root=/dev/vda1" \
  -device virtio-net,netdev=net0 \
  -nographic \
  "$@"
