# Plan: Transform popos-supplements into ubuntu-dev-bootstrap

> Source PRD: GitHub Issue #1 - https://github.com/profemzy/popos-supplements/issues/1

## Architectural decisions

Durable decisions that apply across all phases:

- **Entry Points**:
  - Primary: `install.sh` for curl one-liner (`curl -sSL ... | bash`)
  - Secondary: `install-all.sh` for manual/custom runs with flags

- **Profile Definitions**:
  - `minimal`: zsh, shelltools (starship, zoxide, fzf, fonts), stow, mise
  - `frontend`: minimal + nodejs, dotfiles
  - `devops`: minimal + docker, kubectl, helm, terraform, cloud CLIs (aws, gcloud, az), k9s, argocd, flux, stern, yq, httpie, ansible
  - `full`: frontend + devops + ruby, rust, golang, uv, fastfetch, zed config

- **Component Registry**: 15 components in `AVAILABLE_COMPONENTS` string
  - zsh, shelltools, fastfetch, uv, rust, golang, mise, nodejs, ruby, docker, stow, dotfiles, devops, zed, shell

- **Installation Patterns**:
  - Idempotent `command_exists()` checks before installing
  - Continue-on-failure with `FAILED_PACKAGES` tracking
  - End-of-run failure summary report
  - Trap-based cleanup on exit
  - Standardized logging: `log_info`, `log_success`, `log_error`, `log_warning`

- **Dotfiles Handling**:
  - Stow-based symlink application
  - HTTPS clone (not SSH)
  - URL parameterization via `--dotfiles <url>` or interactive prompt
  - Default: `https://github.com/profemzy/dotfiles.git`

- **Flag Interface**:
  - `--profile <name>`: Select installation profile
  - `--dotfiles <url>`: Custom dotfiles repository
  - `--non-interactive`: Skip all prompts, use defaults
  - `--dry-run`: Preview without changes
  - `--skip <comp>`: Skip specific components
  - `--verbose`: Detailed output

- **Ubuntu Version Detection**: `lsb_release -cs` for dynamic codename

---

## Phase 1: Bootstrap Entry Point

**User stories**: 1, 9, 10, 14, 18

- US1: Single curl command for complete setup
- US9: `--non-interactive` mode for CI/CD
- US10: Works on cloud VMs
- US14: `--dry-run` preview mode
- US18: Temp directory with cleanup

### What to build

Create `install.sh` as the single curl-accessible entry point. This bootstrap script:

1. Downloads the repository to `/tmp/ubuntu-dev-bootstrap-<timestamp>`
2. Parses command-line flags (`--profile`, `--dotfiles`, `--non-interactive`, `--dry-run`)
3. In interactive mode, prompts user for profile selection and dotfiles URL
4. Delegates to `install-all.sh` with resolved parameters
5. Cleans up temporary directory after completion
6. Reports installation summary and next steps

The bootstrap does NOT perform installation logic itself—it orchestrates and delegates. This keeps the actual installation scripts testable and reusable.

### Acceptance criteria

- [ ] `curl -sSL https://raw.githubusercontent.com/profemzy/ubuntu-dev-bootstrap/main/install.sh | bash` works on fresh Ubuntu 24.04
- [ ] Repository downloaded to `/tmp/ubuntu-dev-bootstrap-<timestamp>`
- [ ] Interactive prompts for profile (1-4) and dotfiles URL
- [ ] `--non-interactive` skips prompts, uses defaults (full profile, default dotfiles)
- [ ] `--dry-run` shows what would happen without executing
- [ ] Temporary directory cleaned up after successful run
- [ ] Failure summary reported at end
- [ ] Exit code reflects installation success/failure

---

## Phase 2: Profile System

**User stories**: 2, 3, 4, 5, 15

- US2: DevOps profile with kubectl, helm, terraform, cloud CLIs
- US3: Frontend profile with Node.js and shell enhancements
- US4: Minimal profile with shell tools and mise only
- US5: Full profile with complete toolkit
- US15: `--skip` for component-level customization

### What to build

Modify `install-all.sh` to implement profile-based component filtering:

1. Define profile-to-component mappings at script start
2. Add `--profile` flag parsing (accepts: minimal, frontend, devops, full)
3. Filter `AVAILABLE_COMPONENTS` based on selected profile before installation loop
4. Merge `--skip` exclusions with profile filtering
5. Display which components will be installed based on profile
6. Preserve existing idempotent checks and failure handling

Each profile is a preset component set. The `--skip` flag further subtracts from that set. No component addition beyond profile scope (use `--skip` to customize down, not up).

### Acceptance criteria

- [ ] `--profile minimal` installs: zsh, shelltools, stow, mise
- [ ] `--profile frontend` installs: minimal + nodejs, dotfiles
- [ ] `--profile devops` installs: minimal + docker + all devops components
- [ ] `--profile full` installs: frontend + devops + ruby, rust, golang, uv, fastfetch, zed
- [ ] Invalid profile name shows error with valid options
- [ ] `--skip nodejs --profile frontend` correctly excludes nodejs
- [ ] Profile selection shown in installation header output
- [ ] Default profile when unspecified: `full`

---

## Phase 3: Dotfiles Customization

**User stories**: 7, 8

- US7: Provide custom dotfiles URL during installation
- US8: Use default dotfiles when not specified

### What to build

Modify `install-dotfiles.sh` to accept dotfiles URL as parameter:

1. Accept `--dotfiles-url` parameter or environment variable
2. Default to `https://github.com/profemzy/dotfiles.git` (HTTPS, not SSH)
3. Remove hardcoded SSH URL (`git@github.com:profemzy/dotfiles.git`)
4. Validate URL format before cloning
5. Handle clone failures gracefully with clear error message
6. Preserve stow-based symlink application logic

The bootstrap (`install.sh`) passes the URL from user prompt or `--dotfiles` flag to `install-all.sh`, which passes it to `install-dotfiles.sh`.

### Acceptance criteria

- [ ] Default clone URL: `https://github.com/profemzy/dotfiles.git`
- [ ] Custom URL via `--dotfiles https://example.com/my-dotfiles.git` works
- [ ] Clone failure shows clear error suggesting SSH key setup
- [ ] Stow application unchanged (symlinks created correctly)
- [ ] Existing `.zshrc`, nvim config backed up before stow (current behavior preserved)
- [ ] Idempotent: skips clone if directory exists and is valid git repo

---

## Phase 4: Version Modernization

**User stories**: 11, 13

- US11: Re-running skips installed components (existing idempotent behavior)
- US13: Works on Ubuntu 26.04+ without version-specific modifications

### What to build

Remove all hardcoded version references and implement dynamic latest-version fetching:

**Files to modify:**

1. `install-devops-tools.sh`:
   - kubectl: Change `v1.31` to `v1/stable` channel
   - stern: Already fetches latest via GitHub API (unchanged)
   - k9s: Already downloads latest .deb (unchanged)
   - argocd: Already downloads latest binary (unchanged)
   - terraform: Already uses HashiCorp repo (gets latest)
   - helm: Already uses get-helm-3 script (gets latest)

2. `install-nodejs.sh` and `install-ruby.sh`:
   - Change mise install to use `@latest` syntax
   - Prefix-pinning remains for minor version stability

3. `install-all.sh`:
   - Remove any hardcoded Ubuntu version references
   - Use `lsb_release -cs` dynamically for repository setup

4. Version display in summary section:
   - Ensure all version commands work (some currently fail silently)

The goal is forward compatibility: if Ubuntu 26.04 releases, the tool works without code changes.

### Acceptance criteria

- [ ] kubectl installed from `v1/stable` channel (latest stable k8s)
- [ ] Node.js installed via mise with `@latest` prefix-pinning
- [ ] Ruby installed via mise with `@latest` prefix-pinning
- [ ] All apt repository setup uses dynamic `lsb_release -cs`
- [ ] No hardcoded `noble`, `jammy`, or version numbers in any script
- [ ] Version detection commands in summary section work reliably
- [ ] Idempotent re-run skips already-installed components (existing behavior verified)

---

## Phase 5: Testing & Documentation

**User stories**: 17, 16, 20, 6

- US17: Automated tests for core modules
- US16: Clear post-installation authentication documentation
- US20: Repository renamed to `ubuntu-dev-bootstrap`
- US6: Team consistency through shared tool

### What to build

Create test suite and comprehensive documentation:

**Tests (`tests/` directory):**

1. `test_bootstrap.bats`: Bootstrap entry point behavior
   - Download and cleanup
   - Prompt handling
   - Flag parsing
   - Delegation to install-all.sh

2. `test_profiles.bats`: Profile component filtering
   - Each profile produces correct component set
   - `--skip` correctly excludes
   - Invalid profile error handling

3. `test_dotfiles.bats`: Dotfiles URL handling
   - HTTPS clone (not SSH)
   - Custom URL parameter
   - Default URL when unspecified
   - Clone failure handling

4. `test_idempotence.bats`: Idempotent behavior
   - Re-run skips installed components
   - Detection logic for each component
   - No side effects on subsequent runs

**Documentation updates:**

1. `README.md`:
   - Rebrand from Pop!_OS to Ubuntu 24.04+
   - Add curl one-liner quick start
   - Document all four profiles
   - Add customization section (--skip, --dotfiles)
   - Expand post-installation authentication guide
   - Update all command examples

2. `CHANGELOG.md`:
   - Document v2.0 changes (breaking changes, new features)
   - Migration notes for existing users

3. `LICENSE`:
   - Add MIT license if not present

**Repository rename:**
- Rename `popos-supplements` → `ubuntu-dev-bootstrap`
- Update all internal references and GitHub links

### Acceptance criteria

- [ ] Test suite runs in Docker container with bats-core
- [ ] All tests pass on fresh Ubuntu 24.04 container
- [ ] README reflects Ubuntu 24.04+ branding (not Pop!_OS specific)
- [ ] Curl one-liner documented as primary installation method
- [ ] Profile documentation with component lists
- [ ] Post-install auth guide covers: aws configure, gcloud init, az login, gh auth login, argocd login, flux check --pre
- [ ] CHANGELOG.md documents v2.0 breaking changes and features
- [ ] Repository renamed on GitHub

---

## Implementation Notes

### Phase Dependencies

- Phase 1 and 2 can run in parallel (bootstrap and profiles are independent)
- Phase 3 depends on Phase 1 (bootstrap passes dotfiles URL)
- Phase 4 can run in parallel with Phases 1-3
- Phase 5 should run after all other phases complete

### Breaking Changes

1. SSH dotfiles clone → HTTPS (users need to ensure dotfiles repo is publicly accessible or use custom URL)
2. Repository name change (existing clones need to switch)

### Preserved Behaviors

- Idempotent installation (skip what's installed)
- Continue-on-failure with end report
- `--dry-run` preview mode
- `--verbose` output
- Stow-based dotfiles application
- All existing component scripts unchanged except version handling