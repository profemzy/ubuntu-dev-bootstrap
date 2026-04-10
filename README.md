# Ubuntu Developer Bootstrap

Automated setup for a fresh Ubuntu 24.04+ development environment. Install a complete development toolkit in minutes via a single curl command.

## Overview

This repository contains automated setup scripts to configure an Ubuntu system with development tools, DevOps utilities, and personalized configurations. All scripts are **idempotent** and safe to run multiple times.

**Target Systems:**
- Ubuntu 24.04 LTS (Noble Numbat)
- Ubuntu 26.04 LTS and future versions
- Pop!_OS 24.04+ (Ubuntu derivative)

## Quick Start

### One-Line Installation

```bash
curl -sSL https://raw.githubusercontent.com/profemzy/ubuntu-dev-bootstrap/master/install.sh | bash
```

This will prompt you to select a profile and optionally provide custom dotfiles. For automated/CI environments:

```bash
curl -sSL https://raw.githubusercontent.com/profemzy/ubuntu-dev-bootstrap/master/install.sh | bash -s -- --profile devops --non-interactive
```

### Preview Installation

See what would be installed without making changes:

```bash
curl -sSL https://raw.githubusercontent.com/profemzy/ubuntu-dev-bootstrap/master/install.sh | bash -s -- --dry-run
```

## Installation Profiles

Built-in profiles for different developer needs:

| Profile | Description | Components |
|---------|-------------|------------|
| `minimal` | Base layer | zsh, shelltools (starship, zoxide, fzf, fonts), mise, stow |
| `frontend` | Web development | minimal + Node.js, dotfiles |
| `devops` | Infrastructure | minimal + Docker, kubectl, helm, terraform, cloud CLIs, k9s, argocd, flux |
| `full` | Complete toolkit | frontend + devops + Ruby, Rust, Go, uv, fastfetch, Zed config |

**Default profile:** `full`

### Examples

#### Bootstrap entrypoint (`install.sh`)

```bash
# Install with the default full profile
./install.sh

# Install DevOps profile non-interactively
./install.sh --profile devops --non-interactive

# Preview a minimal install with custom dotfiles
./install.sh --profile minimal --dotfiles https://github.com/yourname/dotfiles.git --dry-run
```

#### Local orchestrator (`install-all.sh`)

```bash
# Install DevOps profile
./install-all.sh --profile devops

# Install minimal profile with custom dotfiles
./install-all.sh --profile minimal --dotfiles-url https://github.com/yourname/dotfiles.git

# Preview frontend profile
./install-all.sh --profile frontend --dry-run

# Skip specific components beyond profile
./install-all.sh --profile full --skip docker,ruby
```

## Command Line Options

### `install.sh` (bootstrap entrypoint)

```bash
./install.sh [OPTIONS]

OPTIONS:
    -p, --profile PROFILE     Installation profile (minimal, frontend, devops, full)
    -d, --dotfiles URL        Custom dotfiles repository URL (HTTPS)
    -n, --non-interactive     Skip all prompts, use defaults
    --dry-run                 Preview what would be installed
    -v, --verbose             Show detailed output
    -h, --help                Show help message
```

### `install-all.sh` (local orchestrator)

```bash
./install-all.sh [OPTIONS]

OPTIONS:
    -p, --profile PROFILE     Installation profile (minimal, frontend, devops, full)
    -d, --dotfiles-url URL    Custom dotfiles repository URL (HTTPS)
    -n, --non-interactive     Skip all prompts, use defaults
    -s, --skip COMP           Skip component(s). Can be used multiple times
    --dry-run                 Preview what would be installed
    -v, --verbose             Show detailed output
    -h, --help                Show help message

AVAILABLE COMPONENTS (for --skip):
    zsh         Zsh shell
    shelltools  Shell tools (starship, zoxide, fzf, nerd fonts)
    fastfetch   Fastfetch system info tool
    uv          Python uv package manager
    rust        Rust programming language
    golang      Go programming language
    mise        mise version manager
    nodejs      Node.js runtime
    ruby        Ruby runtime
    docker      Docker CE with compose plugin
    stow        GNU stow
    dotfiles    Dotfiles configuration
    devops      DevOps tools (kubectl, helm, terraform, cloud CLIs, etc.)
    zed         Configure Zed to allow emulated GPUs
    shell       Set Zsh as default shell
```

## What's Included

### Shell & Tools
- **Zsh** - Z shell with modern features
- **starship** - Cross-shell prompt
- **zoxide** - Smart directory jumper
- **fzf** - Fuzzy finder
- **nerd fonts** - JetBrains Mono Nerd Font

### Version Management
- **mise** - Fast, polyglot version manager (replaces asdf)

### Development Languages
- **Node.js** (v25) - JavaScript/TypeScript runtime (prefix-pinned)
- **Ruby** (v3.4) - Ruby programming language (prefix-pinned)
- **Rust** - Via rustup
- **Go** - Latest from official source
- **uv** - Python package manager

### Container Runtime
- **Docker CE** - Container runtime with docker-compose plugin
- **docker-buildx** - Multi-platform build support

### DevOps Tools

**Kubernetes:**
- **kubectl** - Kubernetes CLI (latest stable from v1/stable channel)
- **kubectx** - Context switcher
- **kubens** - Namespace switcher
- **helm** - Package manager
- **k9s** - Terminal UI
- **stern** - Multi-pod log tailing

**GitOps:**
- **argocd** - GitOps continuous delivery
- **flux** - Flux GitOps operator

**Infrastructure:**
- **terraform** - Infrastructure as Code
- **ansible** - Configuration management

**Cloud CLIs:**
- **aws-cli** (v2) - Amazon Web Services
- **gcloud** - Google Cloud Platform
- **azure-cli** - Microsoft Azure
- **gh** - GitHub CLI

**Utilities:**
- **yq** - YAML/XML/TOML processor
- **httpie** - User-friendly HTTP client

### Dotfiles
Pre-configured dotfiles from [profemzy/dotfiles](https://github.com/profemzy/dotfiles):
- Neovim configuration
- Starship prompt
- Zsh configuration

Use your own dotfiles by providing a URL:
```bash
./install.sh --dotfiles https://github.com/yourname/dotfiles.git
```

## Post-Installation Setup

After installation, configure authentication for cloud services:

### AWS CLI
```bash
aws configure
# Enter Access Key ID, Secret Access Key, region, output format
```

### Google Cloud CLI
```bash
gcloud init
# Follow interactive setup to authenticate and select project
```

### Azure CLI
```bash
az login
# Opens browser for authentication
az account list  # List subscriptions
az account set --subscription <id>  # Select subscription
```

### GitHub CLI
```bash
gh auth login
# Follow interactive setup
gh repo list  # Verify access
```

### Kubernetes
```bash
kubectl config view              # View current config
kubectl config get-contexts      # List contexts
kubectx                         # Switch contexts
kubens                          # Switch namespaces
k9s                             # Launch TUI
```

### ArgoCD
```bash
argocd login <server>           # Login to ArgoCD
argocd app list                 # List applications
```

### Flux
```bash
flux check --pre                # Check prerequisites
flux bootstrap github           # Bootstrap on cluster
```

**Important:** Log out and log back in for shell and Docker group changes to take effect.

## Version Management with mise

mise manages language versions per-project or globally.

### Common Commands

```bash
# Install versions
mise install                    # Install all from config
mise install node@25            # Install latest Node.js 25.x
mise install ruby@3.4           # Install Ruby 3.4.x

# Set versions
mise use -g node@25             # Set globally
mise use node@18                # Set for current project

# View versions
mise current                    # Active versions
mise ls                         # All installed
mise ls node                    # Node versions only

# Upgrade
mise upgrade                    # Upgrade all
mise upgrade node               # Upgrade Node.js only
```

## Docker

After installation:
```bash
# Verify
docker run hello-world

# Use compose
docker compose up -d
docker compose down
```

## Individual Scripts

Install components separately:

```bash
./install-zsh.sh              # Zsh shell
./install-shell-tools.sh      # starship, zoxide, fzf, fonts
./install-mise.sh             # mise version manager
./install-nodejs.sh           # Node.js via mise
./install-ruby.sh             # Ruby via mise
./install-docker.sh           # Docker CE + compose
./install-stow.sh             # GNU stow
./install-dotfiles.sh         # Clone and apply dotfiles
./install-devops-tools.sh     # All DevOps tooling
./set-shell.sh                # Set Zsh as default
```

## Troubleshooting

### mise: "missing: ruby@3.4" or "missing: node@..."

```bash
mise install ruby@3.4
# or
mise install  # Install all from config
```

### Docker: "permission denied"

Log out and log back in for docker group membership:
```bash
groups  # Should include 'docker'
```

### Dotfiles: Clone fails

For HTTPS authentication with private repos, use a credential helper or personal access token:
```bash
git config --global credential.helper store
```

### kubectl: "connection refused"

Ensure valid kubeconfig:
```bash
kubectl config view
kubectl config get-contexts
```

## Testing

Test suite using bats-core:

```bash
# Install bats-core
git clone https://github.com/bats-core/bats-core.git /tmp/bats-core
cd /tmp/bats-core && ./install.sh ~/.local

# Run tests
cd ubuntu-dev-bootstrap
bats tests/
```

## File Structure

```
ubuntu-dev-bootstrap/
├── install.sh              # Bootstrap entry point (curl one-liner)
├── install-all.sh          # Main orchestrator with profiles
├── install-zsh.sh          # Zsh installation
├── install-shell-tools.sh  # starship, zoxide, fzf, fonts
├── install-mise.sh         # mise version manager
├── install-nodejs.sh       # Node.js via mise
├── install-ruby.sh         # Ruby via mise
├── install-docker.sh       # Docker CE + compose
├── install-stow.sh         # GNU stow
├── install-dotfiles.sh     # Dotfiles clone and apply
├── install-devops-tools.sh # DevOps tooling
├── install-fastfetch.sh    # Fastfetch
├── install-uv.sh           # Python uv
├── install-rust.sh         # Rust via rustup
├── install-golang.sh       # Go
├── configure-zed.sh        # Zed GPU config
├── set-shell.sh            # Set default shell
├── tests/                  # Test suite
│   ├── test_bootstrap.bats
│   ├── test_profiles.bats
│   ├── test_dotfiles.bats
│   └── test_idempotence.bats
├── README.md
├── CHANGELOG.md
└── LICENSE
```

## Version Information

All tools install latest stable versions:

| Tool | Source | Version |
|------|--------|---------|
| kubectl | k8s v1/stable channel | Latest stable |
| Node.js | mise | 25.x.x (prefix-pinned) |
| Ruby | mise | 3.4.x (prefix-pinned) |
| Docker CE | Official repo | Latest stable |
| helm | helm.sh | Latest |
| terraform | HashiCorp repo | Latest |
| k9s | GitHub releases | Latest |
| aws-cli | awscli.amazonaws.com | v2 latest |
| gcloud | cloud.google.com | Latest |
| azure-cli | packages.microsoft.com | Latest |

## Installation Sources

| Tool | Documentation |
|------|---------------|
| Docker | [docs.docker.com](https://docs.docker.com/engine/install/ubuntu/) |
| kubectl | [kubernetes.io](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/) |
| Terraform | [hashicorp.com](https://developer.hashicorp.com/terraform/cli/install/apt) |
| AWS CLI | [aws.amazon.com](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) |
| gcloud | [cloud.google.com](https://cloud.google.com/sdk/docs/install) |
| Azure CLI | [microsoft.com](https://learn.microsoft.com/cli/azure/install-azure-cli-linux) |
| GitHub CLI | [github.com](https://github.com/cli/cli/blob/trunk/docs/install_linux.md) |
| Helm | [helm.sh](https://helm.sh/docs/intro/install/) |
| mise | [mise.jdx.dev](https://mise.jdx.dev/installing-mise.html) |

## License

MIT License - see [LICENSE](LICENSE) file.

## Contributing

Personal setup repository - feel free to fork and adapt for your own use!