#!/usr/bin/env bash
set -euo pipefail

# Finder
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write com.apple.finder CreateDesktop -bool false

# Keyboard
defaults write NSGlobalDomain InitialKeyRepeat -int 30
defaults write NSGlobalDomain KeyRepeat -int 5

# Screenshots
screenshots_dir="${HOME}/Desktop"
mkdir -p "$screenshots_dir"
defaults write com.apple.screencapture location -string "$screenshots_dir"
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture disable-shadow -bool false

# Dock
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock orientation -string "left"
defaults write com.apple.dock tilesize -int 33
defaults write com.apple.dock largesize -int 128
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock mineffect -string "scale"
defaults write com.apple.dock minimize-to-application -bool false
defaults write com.apple.dock mru-spaces -bool true

killall Finder >/dev/null 2>&1 || true
killall Dock >/dev/null 2>&1 || true
killall SystemUIServer >/dev/null 2>&1 || true
