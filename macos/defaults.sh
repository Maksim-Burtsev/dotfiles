#!/usr/bin/env bash
set -euo pipefail

# Appearance
# Графитовый акцент — единственное, что обесцвечивает «светофор» в углу окна.
defaults write NSGlobalDomain AppleAccentColor -int -1
defaults write NSGlobalDomain AppleHighlightColor -string "0.847059 0.847059 0.862745 Graphite"

# Menu bar
# Строка меню выезжает только когда курсор упирается в верх экрана, как Dock.
defaults write NSGlobalDomain _HIHideMenuBar -bool true

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
screenshots_dir="${HOME}/Pictures/Screenshots"
mkdir -p "$screenshots_dir"
defaults write com.apple.screencapture location -string "$screenshots_dir"
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture disable-shadow -bool false

# Cmd+Shift+S снимает выделенную область в файл вместо дефолтного Cmd+Shift+4.
# 30 — id хоткея "Save picture of selected area as a file".
# parameters = (ascii 's', keycode S, маска модификаторов): 1179648 = shift 131072 + cmd 1048576.
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 30 '
  <dict>
    <key>enabled</key><true/>
    <key>value</key>
    <dict>
      <key>parameters</key>
      <array>
        <integer>115</integer>
        <integer>1</integer>
        <integer>1179648</integer>
      </array>
      <key>type</key><string>standard</string>
    </dict>
  </dict>'

# Sound
# У звука затвора нет отдельного выключателя — он идёт в общем наборе звуков
# интерфейса ("Play user interface sound effects"), поэтому глушим набор целиком.
defaults write com.apple.systemsound "com.apple.sound.uiaudio.enabled" -int 0

# Dock
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock orientation -string "left"
defaults write com.apple.dock tilesize -int 33
defaults write com.apple.dock largesize -int 128
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock mineffect -string "scale"
defaults write com.apple.dock minimize-to-application -bool false
defaults write com.apple.dock mru-spaces -bool true

# Без этого перечитывания хоткей заработает только после перелогина.
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u

killall Finder >/dev/null 2>&1 || true
killall Dock >/dev/null 2>&1 || true
killall SystemUIServer >/dev/null 2>&1 || true
