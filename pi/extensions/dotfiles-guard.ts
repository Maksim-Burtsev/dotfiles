// Порт claude/hooks/dotfiles-guard.sh на pi.
//
// Сам скрипт не дублируем: регэксп системных мутаторов и вся git-логика живут
// в нём одном, а это — адаптер, который кормит его CC-шным JSON и раскладывает
// ответ по событиям pi.
//
//   tool_result(bash) ← PostToolUse/Bash: команда поменяла машину → дописать
//                       напоминание прямо в результат команды.
//   agent_settled     ← Stop: репа грязная → вернуть агенту ход, а не дать
//                       закончить. Скрипт блокирует один раз за сессию сам,
//                       по маркеру, так что зацикливания не будет.
import { execFile } from "node:child_process";
import { randomUUID } from "node:crypto";
import { existsSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const GUARD = join(homedir(), "open-source", "dotfiles", "claude", "hooks", "dotfiles-guard.sh");

// Скрипт дедуплицирует блокировку по session_id. У pi своего id для этого нет,
// поэтому один на процесс — ровно то поведение, что нужно: одна блокировка за запуск.
const SESSION_ID = randomUUID();

function runGuard(mode: "post" | "stop", input: unknown): Promise<any | null> {
  return new Promise((resolve) => {
    const child = execFile("bash", [GUARD, mode], { timeout: 30_000 }, (err, stdout) => {
      if (err || !stdout.trim()) return resolve(null);
      try {
        resolve(JSON.parse(stdout));
      } catch {
        resolve(null);
      }
    });
    child.stdin?.end(JSON.stringify(input));
  });
}

export default function (pi: ExtensionAPI) {
  if (!existsSync(GUARD)) return;

  pi.on("tool_result", async (event) => {
    if (event.toolName !== "bash") return;
    const command = event.input?.command;
    if (typeof command !== "string" || !command) return;

    const out = await runGuard("post", { tool_input: { command } });
    const note = out?.hookSpecificOutput?.additionalContext;
    if (typeof note !== "string" || !note) return;

    return { content: [...event.content, { type: "text" as const, text: note }] };
  });

  pi.on("agent_settled", async () => {
    const out = await runGuard("stop", { stop_hook_active: false, session_id: SESSION_ID });
    if (out?.decision !== "block" || typeof out.reason !== "string") return;
    pi.sendUserMessage(out.reason);
  });
}
