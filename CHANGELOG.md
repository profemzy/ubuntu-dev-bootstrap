# Changelog

All notable changes to this project are documented in this file.

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
