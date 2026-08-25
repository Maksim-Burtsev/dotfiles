#!/usr/bin/env bash
set -euo pipefail

# Питание и экран блокировки — отдельно от defaults.sh, потому что здесь не
# `defaults write`, а pmset (просит sudo) и sysadminctl (просит пароль
# пользователя). Скрипт интерактивный, поэтому у него свой флаг install.sh --power.

# Mac mini всегда от сети, батареи нет, но -a покрывает все источники питания.
# displaysleep — когда гаснет экран, sleep — когда засыпает сама система.
sudo pmset -a displaysleep 15 sleep 60

# Пробуждение без пароля: после сна сразу возвращаемся ровно туда, где заснули.
# `defaults write com.apple.screensaver askForPassword` начиная с Ventura
# игнорируется — настройку читает только sysadminctl (это тот же тумблер, что
# System Settings -> Lock Screen -> "Require password after screen saver begins").
# FileVault не затрагивается: он спрашивает пароль при загрузке, а не при выходе из сна.
# `-password -` заставляет sysadminctl спросить пароль в терминале, а не брать его из аргумента.
sysadminctl -screenLock off -password -

echo
echo "Готово. Текущие значения:"
pmset -g custom | grep -E '(displaysleep|[^y]sleep)'
sysadminctl -screenLock status
