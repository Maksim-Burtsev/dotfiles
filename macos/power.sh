#!/usr/bin/env bash
set -euo pipefail

# Питание и экран блокировки — отдельно от defaults.sh, потому что здесь не
# `defaults write`, а pmset (просит sudo) и sysadminctl (просит пароль
# пользователя). Скрипт интерактивный, поэтому у него свой флаг install.sh --power.

# Mac mini всегда от сети, батареи нет, но -a покрывает все источники питания.
# displaysleep — когда гаснет экран, sleep — когда засыпает сама система.
# sleep 0: the system never sleeps, so the Remote Control server
# (claude/dev.mburtsev.claude-remote-control.plist) stays reachable from the phone.
# autorestart 1: after a power loss the Mac boots by itself; FileVault still waits for the
# password, and after that login the Batcave LaunchAgent (~/open-source/batcave) starts again.
sudo pmset -a displaysleep 30 sleep 0 autorestart 1

# No unattended macOS update installs: an update reboots the machine at night, and
# after a reboot FileVault waits for the password, so the phone loses the Mac.
# Updates still download; install them from System Settings when it suits.
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates -bool false

# Пробуждение без пароля: после сна сразу возвращаемся ровно туда, где заснули.
# `defaults write com.apple.screensaver askForPassword` начиная с Ventura
# игнорируется — настройку читает только sysadminctl (это тот же тумблер, что
# System Settings -> Lock Screen -> "Require password after screen saver begins").
# FileVault не затрагивается: он спрашивает пароль при загрузке, а не при выходе из сна.
# `-password -` заставляет sysadminctl спросить пароль в терминале, а не брать его из аргумента.
sysadminctl -screenLock off -password -

echo
echo "Готово. Текущие значения:"
pmset -g custom | grep -E '(displaysleep|[^y]sleep|autorestart)'
sysadminctl -screenLock status
