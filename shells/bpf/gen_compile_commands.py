import json
import os
import sys
import subprocess

try:
    with open("compile_single.json", "r") as fin:
        data = json.loads(fin.read()[:-2])  # remove trailing , and lf
except FileNotFoundError:
    exit(0)

# vmlinux.h
cargo_metadata = subprocess.check_output(["cargo", "metadata"]).decode("utf-8")
cargo_metadata = json.loads(cargo_metadata)
vmlinux_inc = next(
    filter(lambda pkg: pkg["name"] == "vmlinux", cargo_metadata["packages"])
)
vmlinux_inc = os.path.dirname(str(vmlinux_inc["manifest_path"]))
vmlinux_inc = f"-I{vmlinux_inc}/include/{sys.argv[1]}"

# libbpf
libbpf_inc = (
    subprocess.check_output(["pkg-config", "--cflags", "libbpf"])
    .decode("ascii")
    .strip()
)

# workaround
data["directory"] = os.getcwd()
data["arguments"][0] = "clang"
data["arguments"].append(vmlinux_inc)
data["arguments"].append(libbpf_inc)

# writeback
with open("compile_commands.json", "w") as fout:
    fout.write(json.dumps([data], indent=2))
os.unlink("compile_single.json")
