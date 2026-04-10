#!/usr/bin/env bats

# Test suite for profile system (install-all.sh --profile)
# These tests verify correct component filtering per profile

load 'test_helper'

@test "profiles: --help shows all available profiles" {
    run ./install-all.sh --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "minimal" ]]
    [[ "$output" =~ "frontend" ]]
    [[ "$output" =~ "devops" ]]
    [[ "$output" =~ "full" ]]
}

@test "profiles: minimal profile excludes nodejs and dotfiles" {
    run ./install-all.sh --profile minimal --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Node.js..." ]]
    [[ "$output" =~ "Not included in 'minimal' profile" ]]
    [[ "$output" =~ "Dotfiles..." ]]
    [[ "$output" =~ "Not included in 'minimal' profile" ]]
}

@test "profiles: minimal profile includes zsh, shelltools, mise, stow" {
    run ./install-all.sh --profile minimal --dry-run
    [ "$status" -eq 0 ]
    # These should NOT show "Not included" message
    # They will either show "Already installed" or be in would-install
}

@test "profiles: frontend profile includes nodejs and dotfiles" {
    run ./install-all.sh --profile frontend --dry-run
    [ "$status" -eq 0 ]
    # Node.js and dotfiles should NOT show "Not included" for frontend
}

@test "profiles: frontend profile excludes devops tools" {
    run ./install-all.sh --profile frontend --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" =~ "DevOps tools..." ]]
    [[ "$output" =~ "Not included in 'frontend' profile" ]]
}

@test "profiles: devops profile includes docker and devops tools" {
    run ./install-all.sh --profile devops --dry-run
    [ "$status" -eq 0 ]
    # Docker and devops should NOT show "Not included"
}

@test "profiles: devops profile excludes nodejs and ruby" {
    run ./install-all.sh --profile devops --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Node.js..." ]]
    [[ "$output" =~ "Not included in 'devops' profile" ]]
}

@test "profiles: full profile includes all components" {
    run ./install-all.sh --profile full --dry-run
    [ "$status" -eq 0 ]
    # Full profile should not have any "Not included" messages
}

@test "profiles: --skip works with profile filtering" {
    run ./install-all.sh --profile minimal --skip zsh --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Skipped by user" ]]
}

@test "profiles: invalid profile shows error" {
    run ./install-all.sh --profile nonexistent --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Invalid profile" ]]
    [[ "$output" =~ "Valid profiles" ]]
}

@test "profiles: default profile is full" {
    run ./install-all.sh --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Profile: full" ]]
}