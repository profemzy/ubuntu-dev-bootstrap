# Changelog

All notable changes to this project are documented in this file.

## [v2.0.0] - 2026-04-10

### Added
- **Bootstrap installer** (`install.sh`) - Single curl-accessible entry point for one-line installation
- **Installation profiles** - Built-in profiles for different developer needs:
  - `minimal`: Shell tools, mise, stow (base layer)
  - `frontend`: minimal + Node.js, dotfiles
  - `devops`: minimal + Docker, kubectl, helm, terraform, cloud CLIs
  - `full`: Complete toolkit (default)
- **Custom dotfiles URL** - Users can provide their own dotfiles repository via `--dotfiles-url`
- **Non-interactive mode** - `--non-interactive` flag for CI/CD and automated provisioning
- **Test suite** - bats-core tests for bootstrap, profiles, dotfiles, and idempotence verification
- **MIT License**

### Changed
- **Repository renamed** from `popos-supplements` to `ubuntu-dev-bootstrap`
- **Target systems** expanded from Pop!_OS 24.04 to Ubuntu 24.04+ (vanilla Ubuntu, Pop!_OS, future versions)
- **kubectl version handling** - Uses v1/stable channel for always-latest stable version (no hardcoding)
- **Dotfiles clone** - HTTPS by default instead of SSH for public accessibility
- **README.md** - Complete rewrite for Ubuntu branding, profile documentation, curl quick-start
- **Branding** - All references updated from Pop!_OS to Ubuntu 24.04+

### Breaking Changes
- **SSH dotfiles clone removed** - Default dotfiles now use HTTPS. Users with private dotfiles must use `--dotfiles-url` with proper authentication configured
- **Repository URL changed** - Existing clones should switch to `ubuntu-dev-bootstrap`
- **Flag changes** - New flags added (--profile, --dotfiles-url, --non-interactive)

### Migration Notes
For users with existing `popos-supplements` clones:
1. Clone the new repository: `git clone https://github.com/profemzy/ubuntu-dev-bootstrap.git`
2. If using private dotfiles, configure HTTPS authentication or use `--dotfiles-url`
3. All previous functionality preserved; new profile system defaults to `full` (equivalent to previous behavior)

## [v0.1.0] - 2026-03-13

### Added
- First tagged release for the Pop!_OS supplement bootstrap workflow.
- Runtime `PATH` bootstrapping across installer scripts so tools installed earlier in the run are available to later steps immediately.
- Safer dotfiles setup that backs up an existing `~/.zshrc` and ensures `~/.zprofile` loads `~/.profile` for login shells.
- Stronger GitHub CLI apt repository setup with validation that the downloaded keyring is not empty before the source is added.

### Changed
- Improved top-level idempotence checks so reruns correctly skip shell tools, dotfiles, DevOps tooling, and completed setup steps.
- Improved default-shell detection to check the user's configured shell in account data instead of the current shell process.
- Improved JetBrainsMono Nerd Font detection for shell-tools install and summary output.

### Fixed
- Fixed `fzf` GitHub release asset selection so the installer downloads the correct archive name.
- Fixed partial shell-tools and DevOps failures to return a non-zero exit code instead of appearing successful.

### Notes
- The default shell step still requires a manual `chsh -s /usr/bin/zsh` because it needs an interactive password prompt.
- This release targets Pop!_OS 24.04 workstation bootstrap and rehydration.
