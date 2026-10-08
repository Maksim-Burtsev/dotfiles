#!/bin/bash
# Mac mini -> work laptop, every 15 minutes while `ssh work` answers:
# 1. the work part of the private compass (lines between the <!-- work --> and <!-- /work -->
#    comments) to the path the global CLAUDE.md imports on the laptop;
# 2. one-shot jobs queued in ~/.local/share/work-sync/once/*.sh, renamed to *.done after success.
set -u
ssh -o ConnectTimeout=5 -o BatchMode=yes work true 2>/dev/null || exit 0

compass="$HOME/open-source/batcave/config/compass.md"
if [[ -f "$compass" ]]; then
  {
    printf '# Компас: рабочая выжимка\n\nКопия с Mac mini, только работа; перезаписывается каждые 15 минут, правки здесь пропадут.\n\n'
    awk '/<!-- \/work -->/{p=0} p; /<!-- work -->/{p=1}' "$compass"
  } | ssh work 'mkdir -p ~/open-source/batcave/config && cat > ~/open-source/batcave/config/compass.md'
fi

for job in "$HOME"/.local/share/work-sync/once/*.sh; do
  [[ -f "$job" ]] || continue
  echo "$(date '+%F %T') run $job"
  bash "$job" && mv "$job" "$job.done"
done
