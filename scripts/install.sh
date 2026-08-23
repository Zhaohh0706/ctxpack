#!/usr/bin/env bash
# ctxpack installer — wire hooks into Gemini/Claude (project) and Antigravity CLI (user-level).
# Usage: scripts/install.sh /path/to/project [--with-claude] [--with-agy]
set -euo pipefail

TARGET="${1:?usage: install.sh <project-dir> [--with-claude] [--with-agy]}"
WITH_CLAUDE=false WITH_AGY=false
for arg in "${@:2}"; do
  case "$arg" in
    --with-claude) WITH_CLAUDE=true ;;
    --with-agy)    WITH_AGY=true ;;
  esac
done
SRC="$(cd "$(dirname "$0")/.." && pwd)"

P="$(cd "$TARGET" && pwd)"
echo "==> installing ctxpack into $P"

mkdir -p "$P/.ctxpack" "$P/docs/agent"
cp "$SRC/bin/pack" "$P/.ctxpack/pack" && chmod +x "$P/.ctxpack/pack"

for f in AGENTS.md HANDOFF.md DECISIONS.md STATUS.md FACTS.md; do
  dest="$P/$f"; [ "$f" != "AGENTS.md" ] && dest="$P/docs/agent/$f"
  if [ ! -e "$dest" ]; then
    if [ -f "$SRC/templates/$f" ]; then cp "$SRC/templates/$f" "$dest";
    elif [ -f "$SRC/templates/$f.md" ]; then cp "$SRC/templates/$f.md" "$dest"; fi
    echo "    created $dest"
  fi
done
[ -e "$P/GEMINI.md" ] || ln -s AGENTS.md "$P/GEMINI.md"



python3 - "$P" "$WITH_CLAUDE" "$WITH_AGY" <<'PYEOF'
import json, os, shutil, sys

p, with_claude, with_agy = sys.argv[1], sys.argv[2] == "true", sys.argv[3] == "true"

def load(path):
    if os.path.exists(path):
        shutil.copy2(path, path + ".bak.ctxpack")
        with open(path) as f:
            return json.load(f)
    return {}

def save(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")

def push(hooks, event, entry):
    hooks.setdefault(event, [])
    if not any(any(h.get("command") == c["command"] for h in m.get("hooks", []))
               for m in hooks[event]):
        hooks[event].append(entry)

gem = load(os.path.join(p, ".gemini/settings.json"))
push(gem.setdefault("hooks", {}), "SessionStart", {
    "matcher": "*",
    "hooks": [{"name": "ctxpack-inject", "type": "command",
               "command": "$GEMINI_PROJECT_DIR/.ctxpack/pack inject --cli gemini"}]})
push(gem["hooks"], "AfterAgent", {
    "matcher": "*",
    "hooks": [{"name": "ctxpack-closeout", "type": "command",
               "command": "$GEMINI_PROJECT_DIR/.ctxpack/pack closeout --cli gemini"}]})
save(os.path.join(p, ".gemini/settings.json"), gem)
print("    wired .gemini/settings.json (SessionStart + AfterAgent)")

if with_claude:
    cl = load(os.path.join(p, ".claude/settings.json"))
    push(cl.setdefault("hooks", {}), "SessionStart", {
        "matcher": "startup|resume|clear",
        "hooks": [{"type": "command",
                   "command": "\"$CLAUDE_PROJECT_DIR\"/.ctxpack/pack inject --cli claude"}]})
    push(cl["hooks"], "Stop", {
        "hooks": [{"type": "command",
                   "command": "\"$CLAUDE_PROJECT_DIR\"/.ctxpack/pack closeout --cli claude"}]})
    save(os.path.join(p, ".claude/settings.json"), cl)
    print("    wired .claude/settings.json (SessionStart + Stop)")

if with_agy:
    hp = os.path.join(p, ".agents/hooks.json")
    agy = load(hp)
    def push_flat(name, event, command):
        h = agy.setdefault(name, {})
        lst = h.setdefault(event, [])
        if not any(c.get("command") == command for c in lst):
            lst.append({"type": "command", "command": command, "timeout": 15})
    push_flat("ctxpack-inject", "PreInvocation", "../.ctxpack/pack inject --cli agy")
    push_flat("ctxpack-closeout", "Stop", "../.ctxpack/pack closeout --cli agy")
    save(hp, agy)
    print("    wired .agents/hooks.json (PreInvocation + Stop, project-level)")

codex_hint = ("merge .ctxpack/codex-snippet.json into ~/.codex/hooks.json (manual, P2)")
open(os.path.join(p, ".ctxpack/codex-snippet.json"), "w").write(json.dumps({
    "SessionStart": [{"hooks": [{"type": "command",
        "command": "<project>/.ctxpack/pack inject --cli codex"}]}],
}, indent=2))
print(f"    {codex_hint}")
print("done")
PYEOF
