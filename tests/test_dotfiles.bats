#!/usr/bin/env bats

# Test suite for dotfiles handling (install-dotfiles.sh)
# These tests verify URL parameter handling and HTTPS cloning

load 'test_helper'

@test "dotfiles: unknown option fails" {
    run ./install-dotfiles.sh --help
    [ "$status" -ne 0 ]
}

@test "dotfiles: default URL is used for clone" {
    setup_isolated_env
    make_stub stow 'exit 0'
    make_stub git '
if [ "$1" = "clone" ]; then
    mkdir -p "$3/.git" "$3/zshrc" "$3/nvim" "$3/starship"
    exit 0
fi
exit 0'

    run ./install-dotfiles.sh

    [ "$status" -eq 0 ]
    assert_call_logged "git clone https://github.com/profemzy/dotfiles.git $HOME/dotfiles"
}

@test "dotfiles: custom URL is used for clone" {
    setup_isolated_env
    make_stub stow 'exit 0'
    make_stub git '
if [ "$1" = "clone" ]; then
    mkdir -p "$3/.git" "$3/zshrc" "$3/nvim" "$3/starship"
    exit 0
fi
exit 0'

    run ./install-dotfiles.sh --dotfiles-url https://example.com/test.git

    [ "$status" -eq 0 ]
    assert_call_logged "git clone https://example.com/test.git $HOME/dotfiles"
}

@test "dotfiles: script validates URL parameter format" {
    run ./install-dotfiles.sh --dotfiles-url
    [ "$status" -eq 1 ]
    [[ "$output" =~ "requires a URL" ]]
}

@test "dotfiles: existing repo with matching remote skips clone" {
    setup_isolated_env
    mkdir -p "$HOME/dotfiles/.git" "$HOME/dotfiles/zshrc" "$HOME/dotfiles/nvim" "$HOME/dotfiles/starship"
    make_stub stow 'exit 0'
    make_stub git '
if [ "$1" = "-C" ] && [ "$3" = "remote" ] && [ "$4" = "get-url" ]; then
    echo "https://github.com/profemzy/dotfiles.git"
    exit 0
fi
if [ "$1" = "clone" ]; then
    exit 99
fi
exit 0'

    run ./install-dotfiles.sh

    [ "$status" -eq 0 ]
    [[ "$output" =~ "already exists with correct remote. Skipping clone" ]]
    ! assert_call_logged "git clone"
}

@test "dotfiles: existing repo with different remote updates remote URL" {
    setup_isolated_env
    mkdir -p "$HOME/dotfiles/.git" "$HOME/dotfiles/zshrc" "$HOME/dotfiles/nvim" "$HOME/dotfiles/starship"
    make_stub stow 'exit 0'
    make_stub git '
if [ "$1" = "-C" ] && [ "$3" = "remote" ] && [ "$4" = "get-url" ]; then
    echo "https://example.com/old.git"
    exit 0
fi
exit 0'

    run ./install-dotfiles.sh --dotfiles-url https://example.com/new.git

    [ "$status" -eq 0 ]
    assert_call_logged "git -C $HOME/dotfiles remote set-url origin https://example.com/new.git"
}

@test "dotfiles: reports helpful error on clone failure" {
    setup_isolated_env
    make_stub stow 'exit 0'
    make_stub git '
if [ "$1" = "clone" ]; then
    exit 1
fi
exit 0'

    run ./install-dotfiles.sh

    [ "$status" -eq 1 ]
    [[ "$output" =~ "Failed to clone the dotfiles repository" ]]
    [[ "$output" =~ "If using a private repository" ]]
}
