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
    [[ "$output" =~ "Zsh..." ]]
    [[ "$output" != *"Zsh..."$'\n'"[WARN] Not included in 'minimal' profile"* ]]
    [[ "$output" =~ "Shell tools (starship, zoxide, fzf, fonts)..." ]]
    [[ "$output" =~ "mise (version manager)..." ]]
    [[ "$output" =~ "stow..." ]]
}

@test "profiles: frontend profile includes nodejs and dotfiles" {
    run ./install-all.sh --profile frontend --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Node.js..." ]]
    [[ "$output" != *"Node.js..."$'\n'"[WARN] Not included in 'frontend' profile"* ]]
    [[ "$output" =~ "Dotfiles..." ]]
    [[ "$output" != *"Dotfiles..."$'\n'"[WARN] Not included in 'frontend' profile"* ]]
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
    [[ "$output" =~ "Docker CE..." ]]
    [[ "$output" != *"Docker CE..."$'\n'"[WARN] Not included in 'devops' profile"* ]]
    [[ "$output" =~ "DevOps tools..." ]]
    [[ "$output" != *"DevOps tools..."$'\n'"[WARN] Not included in 'devops' profile"* ]]
}

@test "profiles: devops profile excludes nodejs and ruby" {
    run ./install-all.sh --profile devops --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Node.js..." ]]
    [[ "$output" =~ "Not included in 'devops' profile" ]]
    [[ "$output" =~ "Ruby..." ]]
    [[ "$output" =~ "Not included in 'devops' profile" ]]
}

@test "profiles: full profile includes all components" {
    run ./install-all.sh --profile full --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" != *"Not included in 'full' profile"* ]]
}

@test "profiles: --skip works with profile filtering" {
    run ./install-all.sh --profile minimal --skip zsh --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Skipped by user (--skip zsh)" ]]
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
