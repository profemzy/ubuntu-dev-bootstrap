#!/usr/bin/env bats

# Test suite for bootstrap installer (install.sh)
# These tests verify the curl-accessible entry point behavior

load 'test_helper'

@test "bootstrap: --help shows usage information" {
    run ./install.sh --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
    [[ "$output" =~ "Ubuntu Developer Bootstrap" ]]
    [[ "$output" =~ "--profile" ]]
    [[ "$output" =~ "--dotfiles" ]]
    [[ "$output" =~ "--non-interactive" ]]
}

@test "bootstrap: --dry-run shows preview without execution" {
    run ./install.sh --dry-run --non-interactive
    [ "$status" -eq 0 ]
    [[ "$output" =~ "DRY RUN" ]]
    [[ "$output" =~ "Profile: full" ]]
}

@test "bootstrap: invalid profile shows error" {
    run ./install.sh --profile invalid --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Invalid profile" ]]
}

@test "bootstrap: --profile minimal selects minimal profile" {
    run ./install.sh --profile minimal --dry-run --non-interactive
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Profile: minimal" ]]
}

@test "bootstrap: --profile devops selects devops profile" {
    run ./install.sh --profile devops --dry-run --non-interactive
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Profile: devops" ]]
}

@test "bootstrap: --profile frontend selects frontend profile" {
    run ./install.sh --profile frontend --dry-run --non-interactive
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Profile: frontend" ]]
}

@test "bootstrap: --dotfiles URL is accepted" {
    run ./install.sh --dry-run --non-interactive --dotfiles https://example.com/dotfiles.git
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Dotfiles: https://example.com/dotfiles.git" ]]
}

@test "bootstrap: default dotfiles URL is HTTPS" {
    run ./install.sh --dry-run --non-interactive
    [ "$status" -eq 0 ]
    [[ "$output" =~ "https://github.com/profemzy/dotfiles.git" ]]
}

@test "bootstrap: missing argument for --profile shows error" {
    run ./install.sh --profile
    [ "$status" -eq 1 ]
    [[ "$output" =~ "requires a profile name" ]]
}

@test "bootstrap: missing argument for --dotfiles shows error" {
    run ./install.sh --dotfiles
    [ "$status" -eq 1 ]
    [[ "$output" =~ "requires a URL" ]]
}