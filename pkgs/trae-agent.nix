{
  fetchFromGitHub,
  python3Packages,
  unstableGitUpdater,
  ...
}:

python3Packages.buildPythonPackage {
  pname = "trae-agent";
  version = "0-unstable-2026-02-05";
  src = fetchFromGitHub {
    owner = "bytedance";
    repo = "trae-agent";
    rev = "e839e559ac61bdd0e057c375dd1dee391fee797d";
    sha256 = "sha256-rPMBfaDlVXNWfzt5lsQB3949rgJYezo+dNvgp1sdXPQ=";
  };
  pyproject = true;

  patches = [
    ./patches/trae-agent-tree-sitter.patch
  ];

  # https://github.com/bytedance/trae-agent/blob/main/pyproject.toml
  build-system = with python3Packages; [
    hatchling
  ];

  # Pin some versions, @see nixpkgs/pkgs/servers/home-assistant/default.nix
  dependencies = with python3Packages; [
    openai
    (anthropic.overridePythonAttrs rec {
      version = "0.60.0";
      src = fetchFromGitHub {
        owner = "anthropics";
        repo = "anthropic-sdk-python";
        tag = "v${version}";
        hash = "sha256-NwwZjpamBtRHYs/k+i2TfydTEzU2aB5+IxkONXlCqEk=";
      };
    })
    click
    google-genai
    jsonpath-ng
    pydantic
    python-dotenv
    rich
    typing-extensions
    ollama
    socksio
    tree-sitter-language-pack # alternatives tree-sitter-languages
    tree-sitter
    ruff
    (mcp.overridePythonAttrs rec {
      version = "1.12.2";
      src = fetchFromGitHub {
        owner = "modelcontextprotocol";
        repo = "python-sdk";
        tag = "v${version}";
        hash = "sha256-K3S+2Z4yuo8eAOo8gDhrI8OOfV6ADH4dAb1h8PqYntc=";
      };
    })
    asyncclick
    pyyaml
    textual
    pyinstaller

    # optionals
    datasets
    docker
    pexpect
    unidiff
  ];

  passthru.updateScript = unstableGitUpdater { hardcodeZeroVersion = true; };
}
