# Pop!_OS Supplement

Personal supplemental installation and configuration scripts for a fresh [Pop!_OS](https://pop.system76.com/) 24.04 installation.

## Overview

This repository contains automated setup scripts to configure a Pop!_OS system with development tools, DevOps utilities, and personalized configurations. All scripts are **idempotent** and safe to run multiple times.

## What's Included

### Core Tools
- **Zsh** - Z shell with modern features
- **mise** - Fast, polyglot version manager (replaces asdf)
- **stow** - Symlink farm manager for dotfiles

### Development Environments
- **Node.js** (v25) - JavaScript/TypeScript runtime (managed by mise, prefix-pinned)
- **Ruby** (v3.4) - Ruby programming language (managed by mise, prefix-pinned)

### Container Runtime
- **Docker CE** - Container runtime with docker-compose plugin
- **docker-buildx** - Multi-platform build support

### DevOps Tools

**Kubernetes:**
- **kubectl** - Kubernetes command-line tool
- **kubectx** - Fast Kubernetes context switcher
- **kubens** - Kubernetes namespace switcher
- **helm** - Kubernetes package manager
- **k9s** - Kubernetes TUI (Terminal UI)
- **stern** - Multi-pod log tailing for Kubernetes

**GitOps & CD:**
- **argocd** - GitOps continuous delivery
- **flux** - Flux GitOps operator

**Infrastructure as Code:**
- **terraform** - Infrastructure as Code tool
- **ansible** - Configuration management and automation

**Cloud CLIs:**
- **aws-cli** - Amazon Web Services CLI
- **gcloud** - Google Cloud Platform CLI
- **azure-cli** - Microsoft Azure CLI

**Developer Tools:**
- **github-cli** (gh) - GitHub CLI for workflow automation

**Utilities:**
- **yq** - YAML/XML/TOML processor
- **httpie** - User-friendly HTTP client

### Customizations

**Dotfiles** - Pre-configured from [profemzy/dotfiles](https://github.com/profemzy/dotfiles)
- Neovim configuration
- Starship prompt
- Zsh configuration

## Prerequisites

- **Pop!_OS 24.04** (fresh install recommended)
- **Internet connection** for downloading packages

## Quick Start

### Full Installation

Clone the repository and run the complete installation:

```bash
git clone <your-repo-url> ~/Projects/popos-supplements
cd ~/Projects/popos-supplements
chmod +x *.sh
./install-all.sh
```

The installation script is **idempotent** - it will only install components that are missing, so you can safely run it multiple times.

### Command Line Options

```bash
./install-all.sh [OPTIONS]

OPTIONS:
    -n, --dry-run        Show what would be installed without making changes
    -s, --skip COMP      Skip component(s). Can be used multiple times or comma-separated
    -v, --verbose        Show detailed output during installation
    -h, --help           Show this help message
```

### Examples

```bash
# Preview what would be installed
./install-all.sh --dry-run

# Skip Docker installation
./install-all.sh --skip docker

# Skip multiple components (comma-separated)
./install-all.sh -s docker,ruby,devops

# Skip multiple components (multiple flags)
./install-all.sh -s docker -s devops

# Verbose dry-run
./install-all.sh -n -v --skip docker
```

### Available Components for --skip

| Component | Description |
|-----------|-------------|
| `zsh` | Zsh shell |
| `mise` | mise version manager |
| `nodejs` | Node.js runtime |
| `ruby` | Ruby runtime |
| `docker` | Docker CE with compose |
| `stow` | GNU stow |
| `dotfiles` | Dotfiles configuration |
| `devops` | DevOps tools (kubectl, helm, terraform, etc.) |
| `shell` | Set Zsh as default shell |

After installation completes, **log out and log back in** for all changes to take effect.

### Individual Installations

You can also install components individually:

```bash
# Shell and utilities
./install-zsh.sh         # Zsh shell
./install-stow.sh        # GNU stow
./set-shell.sh           # Set Zsh as default

# Version manager (required for Node.js and Ruby)
./install-mise.sh        # Installs mise

# Development tools
./install-nodejs.sh      # Node.js (via mise)
./install-ruby.sh        # Ruby (via mise)

# Container runtime
./install-docker.sh      # Docker CE + compose

# DevOps tools
./install-devops-tools.sh  # kubectl, helm, terraform, k9s, cloud CLIs

# Dotfiles and configs
./install-dotfiles.sh    # Clone and apply dotfiles
```

All installation scripts are **idempotent** and can be run multiple times safely.

## Configuration Details

### Version Management with mise

mise is a fast, polyglot version manager (written in Rust) that replaces asdf. It manages different versions of programming languages and tools per-project or globally.

#### Common Commands

**Install versions:**
```bash
mise install                 # Install all tools from config
mise install node@25         # Install specific version
mise install node@latest     # Install latest version
```

**Set versions:**
```bash
mise use -g node@25          # Set globally (~/.config/mise/config.toml)
mise use node@18             # Set for current project (creates mise.toml)
```

**View versions:**
```bash
mise current                 # Show active versions in current directory
mise ls                      # List all installed versions
mise ls node                 # List installed node versions
```

**Update tools:**
```bash
mise upgrade                 # Upgrade all tools to latest versions
mise upgrade node            # Upgrade only node
```

### Docker Configuration

Docker is installed with:
- **Docker CE** - Container runtime
- **docker-compose plugin** - Multi-container orchestration (use `docker compose` not `docker-compose`)
- **docker-buildx** - Multi-platform builds

After installation, you need to **log out and log back in** for docker group membership to take effect.

```bash
# Verify installation
docker run hello-world

# Use docker compose
docker compose up -d
docker compose down
```

### DevOps Tools Setup

After installing the DevOps tools, you'll need to configure the cloud CLIs:

**AWS CLI:**
```bash
aws configure
# Enter your AWS Access Key ID, Secret Access Key, region, and output format
```

**Google Cloud CLI:**
```bash
gcloud init
# Follow the interactive setup to authenticate and select project
```

**Azure CLI:**
```bash
az login
# Opens browser for authentication
az account list  # List available subscriptions
az account set --subscription <subscription-id>
```

**GitHub CLI:**
```bash
gh auth login
# Follow the interactive setup to authenticate with GitHub
gh repo list     # List your repositories
gh pr list       # List pull requests
```

**Kubernetes:**
```bash
kubectl config view              # View current config
kubectl config get-contexts      # List available contexts
kubectx                          # Switch contexts easily
kubens                           # Switch namespaces easily
k9s                              # Launch Kubernetes TUI
stern <pod-name>                 # Tail logs from multiple pods
```

**ArgoCD:**
```bash
argocd login <server>            # Login to ArgoCD server
argocd app list                  # List applications
argocd app sync <app-name>       # Sync application
```

**Flux:**
```bash
flux check --pre                 # Check prerequisites
flux bootstrap github            # Bootstrap Flux on cluster
```

**Terraform:**
```bash
terraform init    # Initialize working directory
terraform plan    # Preview changes
terraform apply   # Apply changes
```

## Troubleshooting

### mise: "missing: ruby@3.4" or "missing: nodejs@..."

**Solution:** Install the missing tool version:
```bash
mise install ruby@3.4
# or
mise install  # Install all from config
```

**Check your configuration:**
```bash
mise doctor  # Verify mise setup
mise current # Show what versions are expected
mise ls      # Show what versions are installed
```

### Docker: "permission denied"

**Issue:** Cannot run docker commands without sudo after installation.

**Solution:** Log out and log back in for docker group membership to take effect. Then verify:
```bash
groups  # Should include 'docker'
docker run hello-world
```

### Dotfiles: SSH key error when cloning

**Issue:** `git clone git@github.com:...` fails with permission denied.

**Solution:** Set up SSH keys for GitHub:
```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
cat ~/.ssh/id_ed25519.pub  # Copy this to GitHub Settings > SSH Keys
ssh -T git@github.com      # Test connection
```

### kubectl: "The connection to the server was refused"

**Issue:** kubectl cannot connect to cluster.

**Solution:** Ensure you have a valid kubeconfig:
```bash
kubectl config view
kubectl config get-contexts
```

## File Structure

```
popos-supplements/
├── install-all.sh              # Master installation script (idempotent)
├── install-zsh.sh              # Install Zsh
├── install-mise.sh             # Install mise version manager
├── install-nodejs.sh           # Install Node.js via mise
├── install-ruby.sh             # Install Ruby via mise
├── install-docker.sh           # Install Docker CE + compose
├── install-stow.sh             # Install GNU stow
├── install-dotfiles.sh         # Clone and apply dotfiles
├── install-devops-tools.sh     # Install DevOps tooling
├── set-shell.sh                # Set Zsh as default shell
└── README.md                   # This file
```

## Version Information

### Development Tools
- **Node.js**: 25 (prefix-pinned, auto-updates to 25.x.x)
- **Ruby**: 3.4 (prefix-pinned, auto-updates to 3.4.x)
- **mise**: Latest from https://mise.run

### Container Runtime
- **Docker CE**: Latest stable from official Docker repository

### DevOps Tools
All DevOps tools are installed from official repositories or binary releases:
- **kubectl**: Latest stable (v1.31.x)
- **helm**: Latest stable (v3.x)
- **k9s**: Latest stable
- **terraform**: Latest stable (v1.14.x)
- **ansible**: Latest from apt
- **aws-cli**: v2 (latest)
- **gcloud**: Latest stable
- **azure-cli**: Latest stable
- **github-cli**: Latest stable

## Installation Sources

All installation methods verified December 2025:

| Tool | Source |
|------|--------|
| Docker | [docs.docker.com](https://docs.docker.com/engine/install/ubuntu/) |
| kubectl | [kubernetes.io](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/) |
| Terraform | [developer.hashicorp.com](https://developer.hashicorp.com/terraform/cli/install/apt) |
| AWS CLI | [docs.aws.amazon.com](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) |
| gcloud | [cloud.google.com](https://cloud.google.com/sdk/docs/install) |
| Azure CLI | [learn.microsoft.com](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-linux) |
| GitHub CLI | [github.com/cli/cli](https://github.com/cli/cli/blob/trunk/docs/install_linux.md) |
| Helm | [helm.sh](https://helm.sh/docs/intro/install/) |
| k9s | [k9scli.io](https://k9scli.io/topics/install/) |
| ArgoCD | [argo-cd.readthedocs.io](https://argo-cd.readthedocs.io/en/stable/cli_installation/) |
| Flux | [fluxcd.io](https://fluxcd.io/flux/installation/) |
| mise | [mise.jdx.dev](https://mise.jdx.dev/installing-mise.html) |

## License

This is a personal configuration repository. Use at your own discretion.

## Contributing

This is a personal setup repository, but feel free to fork and adapt for your own use!
