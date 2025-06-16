# Build-from-scratch:

{
  # gcc
  n9.shell.scratch = { };

  # clang
  n9.shell."scratch.clang" = {
    gcc.enable = false;
    clang.enable = true;
  };

  # rust
  n9.shell."scratch.rust" = {
    gcc.enable = false;
    clang.enable = true;
    rust.enable = true;
  };
}
