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
- sed -i 's#https\?://dl-cdn.alpinelinux.org/alpine#https://mirrors.tuna.tsinghua.edu.cn/alpine#g' /etc/apk/repositories
- apk del cloud-init chrony
EOF
  genisoimage -output "$seed" -volid cidata -rational-rock -joliet \
    user-data meta-data network-config
  rm -f user-data meta-data network-config
fi

# 9pfs
mkdir -p snap

# TODO: Multiplaform?
exec qemu-system-aarch64 \
  -accel hvf \
  -machine virt \
  -cpu max \
  -smp 4 \
  -m 4096 \
  -drive "file=$image,index=0,format=qcow2,media=disk" \
  -drive "file=$seed,index=1,media=cdrom" \
  -virtfs local,path=./snap,mount_tag=snap,security_model=mapped-file \
  -kernel ./arch/arm64/boot/Image.gz \
  -append root=/dev/vda2 \
  -netdev user,id=net0,hostfwd=tcp::41322-:22,hostfwd=tcp::41380-:80,hostfwd=tcp::41390-:9090 \
  -device virtio-net,netdev=net0 \
  -nographic \
  "$@"
