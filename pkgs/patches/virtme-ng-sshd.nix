diff --git a/virtme/commands/run.py b/virtme/commands/run.py
index fd522f3..adc3106 100644
--- a/virtme/commands/run.py
+++ b/virtme/commands/run.py
@@ -20,6 +20,7 @@ import sys
 import tempfile
 import termios
 from base64 import b64encode
+from glob import glob
 from pathlib import Path
 from shutil import which
 from time import sleep
@@ -1001,7 +1002,7 @@ def console_client(args):
     with open(console_script_path, "w", encoding="utf-8") as file:
         print(
             (
-                "#! /bin/bash\n"
+                "#!/usr/bin/env bash\n"
                 "main() {\n"
                 f"{stty}\n"
                 f'HOME=$(getent passwd "{user}" | cut -d: -f6)\n'
@@ -1113,6 +1114,14 @@ def ssh_server(args, arch, qemuargs, kernelargs):
         ]
     )
 
+    # Try to locate a (one) pubkey, for ssh server to use:
+    # TODO: Make a temporary key with ssh-keygen, use that key only?
+    for pubkey in glob(os.path.expanduser("~/.ssh/id_*.pub")):
+        with open(pubkey) as reader:
+            content = reader.readline().strip()
+        kernelargs.append(f"virtme_ssh_pubkey={content}")
+        break
+
     ssh_proxy = os.path.realpath(resources.find_script("virtme-ssh-proxy"))
     with open(SSH_CONF_FILE, "w", encoding="utf-8") as f:
         f.write(f"""Host {VIRTME_SSH_DESTINATION_NAME}*
@@ -1407,17 +1416,7 @@ def do_it() -> int:
         # Check if paths are accessible both on the host and the guest.
         if not os.path.exists(hostpath):
             arg_fail(f"error: cannot access {hostpath} on the host")
-        # Guest path must be defined inside one of the overlays
-        guest_path_ok = False
-        for d in args.overlay_rwdir:
-            if os.path.exists(guestpath) or is_subpath(guestpath, d):
-                guest_path_ok = True
-                break
-        if not guest_path_ok:
-            arg_fail(
-                f"error: cannot initialize {guestpath} inside the guest "
-                + "(path must be defined inside a valid overlay)"
-            )
+        # Overlay paths must be defined inside one of the rws, but not vice-versa?
 
         idx = mount_index
         mount_index += 1
diff --git a/virtme/guest/virtme-snapd-script b/virtme/guest/virtme-snapd-script
index 4cbd279..1464780 100755
--- a/virtme/guest/virtme-snapd-script
+++ b/virtme/guest/virtme-snapd-script
@@ -1,4 +1,4 @@
-#!/bin/bash
+#!/usr/bin/env bash
 #
 # Initialize a snap cgroup to emulate a systemd environment, tricking snapd
 # into recognizing our system as a valid one.
diff --git a/virtme/guest/virtme-sound-script b/virtme/guest/virtme-sound-script
index 11fde4e..ccd3860 100755
--- a/virtme/guest/virtme-sound-script
+++ b/virtme/guest/virtme-sound-script
@@ -1,4 +1,4 @@
-#!/bin/bash
+#!/usr/bin/env bash
 
 if [ -n "$(command -v pipewire)" ]; then
     # Start audio system services.
diff --git a/virtme/guest/virtme-sshd-script b/virtme/guest/virtme-sshd-script
index 097bc8a..249949d 100755
--- a/virtme/guest/virtme-sshd-script
+++ b/virtme/guest/virtme-sshd-script
@@ -1,4 +1,4 @@
-#!/bin/bash
+#!/usr/bin/env bash
 #
 # Initialize ssh server for remote connections (option `--server ssh`)
 
@@ -10,6 +10,10 @@ if [ -z "${virtme_ssh_channel}" ]; then
     echo "ssh: virtme_ssh_channel is not defined" >&2
     exit 1
 fi
+if [ -z "${virtme_ssh_pubkey}" ]; then
+    echo "ssh: virtme_ssh_pubkey is not defined" >&2
+    exit 1
+fi
 
 rm -f /var/run/nologin
 
@@ -37,7 +41,8 @@ cp "${SSH_CACHE}"/etc/ssh/* "${SSH_DIR}"/etc/ssh
 # Generate authorized_keys in the virtme-ng cache directory and add all
 # current user's public keys.
 SSH_AUTH_KEYS="${SSH_DIR}"/etc/ssh/authorized_keys
-cat "${SSH_HOME}"/.ssh/id_*.pub >> "${SSH_AUTH_KEYS}" 2> /dev/null
+# TODO: Supports multiple pubkeys? Seems unneccessary?
+echo "${virtme_ssh_pubkey}" >> "${SSH_AUTH_KEYS}"
 
 # fixup permissions
 chown -R root:root "${SSH_DIR}"/etc/ssh
@@ -62,6 +67,7 @@ AuthorizedKeysFile ${SSH_AUTH_KEYS}
 PubkeyAuthentication yes
 UsePAM yes
 PrintMotd no
+StrictModes no
 ${sftp_server}
 EOF
 
@@ -71,6 +77,7 @@ for key in "${SSH_DIR}"/etc/ssh/ssh_host_*_key; do
     ARGS+=(-h "${key}")
 done
 
+sshd="$(which sshd)"
 if [[ ${virtme_ssh_channel} == "vsock" ]]; then
     # Make sure vsock (module) is loaded and active, otherwise the '/dev/vsock' device
     # might not be available.
@@ -81,7 +88,7 @@ if [[ ${virtme_ssh_channel} == "vsock" ]]; then
     # 4294967295 == U32_MAX == -1
     declare -r VMADDR_CID_ANY=4294967295
     # TODO Use something like syslog or journal for the logging
-    setsid --fork -- systemd-socket-activate --accept --listen="vsock:${VMADDR_CID_ANY}:22" --inetd -- /usr/sbin/sshd -i "${ARGS[@]}" &> /dev/null < /dev/null
+    setsid --fork -- systemd-socket-activate --accept --listen="vsock:${VMADDR_CID_ANY}:22" --inetd -- "$sshd" -i "${ARGS[@]}" &> /dev/null < /dev/null
 else
-    /usr/sbin/sshd "${ARGS[@]}"
+    "$sshd" "${ARGS[@]}"
 fi
diff --git a/virtme/guest/virtme-udhcpc-script b/virtme/guest/virtme-udhcpc-script
index 5c72b6f..86ff0d9 100755
--- a/virtme/guest/virtme-udhcpc-script
+++ b/virtme/guest/virtme-udhcpc-script
@@ -1,4 +1,4 @@
-#!/bin/bash
+#!/usr/bin/env bash
 # virtme-udhcpc-script: A trivial udhcpc script
 # Copyright © 2014 Andy Lutomirski
 # Licensed under the GPLv2, which is available in the virtme distribution
diff --git a/virtme_ng/run.py b/virtme_ng/run.py
index 483b5f1..7b94f90 100644
--- a/virtme_ng/run.py
+++ b/virtme_ng/run.py
@@ -962,6 +962,10 @@ class KernelSource:
         self.virtme_param["rwdir"] = ""
         for item in args.rwdir:
             self.virtme_param["rwdir"] += f"--rwdir {item} "
+        # Map the current directory as rw as well, e.g. linux repo.
+        # For just this directory, we make it as rwdir, it should be fine :)
+        cwd = os.getcwd()
+        self.virtme_param["rwdir"] += f"--rwdir {cwd}={cwd} "
 
     def _get_virtme_overlay_rwdir(self, args):
         # Set default overlays if rootfs is mounted in read-only mode.
