#!/usr/bin/env python3

import subprocess
import os
import sys
import shutil
import logging
from typing import List, Set, Optional


# linker, wrapped
BINARY_LD_PATH_TEMPLATE = """#!/usr/bin/env bash
BASH_DIRECTORY="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
export LD_LIBRARY_PATH="$BASH_DIRECTORY:$LD_LIBRARY_PATH"
exec "$BASH_DIRECTORY/%s" "$BASH_DIRECTORY/%s" "$@"
"""

# linker, wrapped
BINARY_PATCHELF_TEMPLATE = """#!/usr/bin/env bash
BASH_DIRECTORY="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
exec "$BASH_DIRECTORY/%s" "$BASH_DIRECTORY/%s" "$@"
"""


def resolve(required: List[str]) -> (Set[str], Optional[str]):
    """required -> dependencies, linker"""
    dependencies = set()
    linker = None

    while len(required) != 0:
        # TODO: Invoke ld from elf, instead of system-wide ldd:
        elf = required.pop()
        output = subprocess.check_output(["ldd", elf]).decode("ascii")

        for relation in output.splitlines():
            resolved = None
            parts = relation.strip().split()

            match (parts[0], parts[1]):
                case ("linux-vdso.so.1", _) | ("statically", _):
                    continue
                case (_, "=>"):
                    resolved = parts[2]
                case (_, _):
                    if "ld-linux-" in parts[0]:
                        linker = os.path.basename(parts[0])
                    resolved = parts[0]

            if resolved in dependencies:
                continue

            dependencies.add(resolved)
            required.append(resolved)
            logging.info("adding dependency: %s", resolved)

    return dependencies, linker


def copy(source: str, target: str, dry_run: bool):
    target_dir = os.path.dirname(target)
    if not os.path.exists(target_dir):
        if dry_run:
            logging.info("will makedirs(%s)", target_dir)
        else:
            os.makedirs(target_dir, exist_ok=True)

    if os.path.exists(target):
        if dry_run:
            logging.info("will unlink(%s)", target)
        else:
            os.unlink(target)

    if dry_run:
        logging.info("will copy(%s, %s)", source, target)
    else:
        shutil.copy(source, target, follow_symlinks=True)
        # adding write perm for later patchelf:
        os.chmod(target, 0o777)


def patch(target: str, patchelf: bool, dry_run: bool):
    if not patchelf:
        # For LD_LIBRARY_PATH way, no need to make patched ELFs:
        return

    if dry_run:
        logging.info("will patchelf(%s)", target)
    else:
        subprocess.check_call(["patchelf", "--set-rpath", "$ORIGIN", target])


def make_wrapper(target: str, content: str, dry_run: bool):
    if dry_run:
        logging.info("will write %s, content: %s", target, content)
    else:
        with open(target, "w") as writer:
            writer.write(content)
            subprocess.check_call(["chmod", "+x", target])


def main(argv: List[str]):
    positions = list()
    dry_run = True
    patchelf = False

    for i, flag in enumerate(argv):
        if not flag.startswith("-"):
            positions.append(flag)
            continue
        elif flag == "-n":
            dry_run = False
        elif flag == "-p":
            patchelf = True
        elif flag == "--":
            positions += argv[i + 1]
            break
        else:
            logging.error("unknown flag %s", flag)

    source, target_dir, *extra_required = positions
    dependencies, linker = resolve([source] + extra_required)
    if linker is None:
        logging.error("source %s has no linker detected", source)
        return False

    # copy dependencies (plus extra):
    for dep in list(dependencies) + extra_required:
        target = f"{target_dir}/{os.path.basename(dep)}"
        copy(dep, target, dry_run)
        if not os.path.basename(dep) == linker:
            patch(target, patchelf, dry_run)

    # copy renamed binary:
    binary = os.path.basename(source)
    wrapped = f".{binary}-wrapped"
    target = f"{target_dir}/{wrapped}"
    copy(source, target, dry_run)

    # make a wrapper to binary:
    patch(target, patchelf, dry_run)
    target = f"{target_dir}/{binary}"
    template = BINARY_PATCHELF_TEMPLATE if patchelf else BINARY_LD_PATH_TEMPLATE
    make_wrapper(target, template % (linker, wrapped), dry_run)

    return True


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    exit(0 if main(sys.argv[1:]) else 1)
