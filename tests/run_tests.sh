#!/usr/bin/env bash
# ctxpack test suite — fixture repo based, no network.
set -u
PACK="$(cd "$(dirname "$0")/.." && pwd)/bin/pack"
TMP="$(mktemp -d)"
PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); echo "  ok: $1"; }
bad()  { FAIL=$((FAIL+1)); echo "FAIL: $1"; }

echo "== fixture =="
mkdir -p "$TMP"
export FIX="$TMP/fix"
mkdir -p "$FIX/docs/agent" "$FIX/src"
cd "$FIX"
git init -q . && git config user.email t@t && git config user.name t
echo "hello-v1" > src/a.txt
git add -A && git commit -qm init
SHA=$(git log -1 --format=%h -- src/a.txt)
cat > docs/agent/HANDOFF.md <<'EOF'
# HANDOFF
- working on login
EOF
cat > docs/agent/FACTS.md <<EOF
- 登录只允许 passkey+OAuth (src/a.txt@$SHA)
EOF
cat > docs/agent/DECISIONS.md <<'EOF'
# DECISIONS
- 登录只允许 passkey,禁密码
EOF
cat > docs/agent/STATUS.md <<'EOF'
- ../fix-codex: codex working on signup
EOF
git add -A && git commit -qm docs

echo "== T1 inject: gemini envelope shape =="
OUT=$(echo '{}' | "$PACK" inject --cli gemini)
echo "$OUT" | python3 -c '
import json,sys; d=json.load(sys.stdin)
o=d["hookSpecificOutput"]
assert o["hookEventName"]=="SessionStart"
assert "passkey" in o["additionalContext"]
assert "signup" in o["additionalContext"]          # occupancy parsed
assert d["systemMessage"].startswith("ctxpack:")
' && ok "envelope valid, handoff+occupancy injected" || bad "gemini envelope"

echo "== T2 freshness: fresh fact =="
echo "$OUT" | grep -q "STALE" && bad "fresh fact marked stale" || ok "fact fresh"

echo "== T3 freshness: stale detection =="
echo "hello-v2-changed" > src/a.txt && git add -A && git commit -qm touch-src
OUT2=$(echo '{}' | "$PACK" inject --cli gemini)
echo "$OUT2" | grep -q "STALE" && ok "stale detected after file changed" || bad "stale not detected"
"$PACK" facts-check | grep -q STALE && ok "facts-check shows stale" || bad "facts-check"

echo "== T4 budget: hard drop with visibility =="
for i in $(seq 1 40); do echo "- filler fact $i 很长很长很长很长很长 (src/a.txt@$SHA)" >> docs/agent/FACTS.md; done
OUT3=$(echo '{}' | "$PACK" inject --cli gemini --budget 300)
echo "$OUT3" | python3 -c '
import json,sys; d=json.load(sys.stdin)
assert d["systemMessage"], "missing systemMessage"
' && ok "budget respected, systemMessage present" || bad "budget"
git checkout -q docs/agent/FACTS.md && git commit -qm revert-facts

echo "== T5 closeout: dirty without handoff update => deny (gemini) =="
echo x >> src/new.py
C1=$(echo '{}' | "$PACK" closeout --cli gemini)
echo "$C1" | grep -q '"deny"' && ok "gemini AfterAgent denies" || bad "no deny"
echo "== T6 anti-loop: second call allows =="
C2=$(echo '{}' | "$PACK" closeout --cli gemini)
[ "$C2" = "{}" ] && ok "blocked_once prevents loop" || bad "loop not prevented"

echo "== T7 claude envelope: decision block =="
rm -f .ctxpack/blocked_once
C3=$(echo '{}' | "$PACK" closeout --cli claude)
echo "$C3" | grep -q '"block"' && ok "claude Stop blocks" || bad "claude no block"

echo "== T8 handoff updated => allow =="
rm -f .ctxpack/blocked_once
printf '\n- did stuff\n' >> docs/agent/HANDOFF.md
C4=$(echo '{}' | "$PACK" closeout --cli claude)
[ "$C4" = "{}" ] && ok "handoff update satisfies closeout" || bad "closeout still blocking"

echo "== T9 clean tree => allow =="
git add -A && git commit -qm wip
C5=$(echo '{}' | "$PACK" closeout --cli gemini)
[ "$C5" = "{}" ] && ok "clean tree passes" || bad "clean tree blocked"

echo "== T10 event log written =="
[ -s .ctxpack/events.jsonl ] && ok "events.jsonl exists" || bad "no event log"

echo "== T11 mailbox: say + inject shows unread =="
"$PACK" say --from gemini --msg "research done -> see HANDOFF" >/dev/null && ok "say delivered" || bad "say"
OUT4=$(echo '{}' | "$PACK" inject --cli claude)
echo "$OUT4" | grep -q "unread: 1" && ok "inject surfaces unread mail" || bad "no unread in pack"
echo "$OUT4" | grep -q "Pinned constraints" && ok "constraints pinned section present" || bad "pinned missing"

echo "== T12 mail-read clears unread =="
"$PACK" mail-read >/dev/null
echo '{}' | "$PACK" inject --cli claude | grep -q "unread: 1" && bad "mail-read did not clear" || ok "unread cleared after mail-read"

echo "== T13 say rejects oversized message =="
BIG=$(python3 -c "print('x'*3000)")
"$PACK" say --from a --msg "$BIG" >/dev/null 2>&1 && bad "oversize accepted" || ok "oversize rejected (<2KB rule)"

echo "== T14 pinned constraints survive tiny budget =="
echo '{}' | "$PACK" inject --cli claude --budget 100 | grep -q 'ctxpack v' && ok "tiny budget still emits (pinned survive)" || bad "pinning broken"

echo "== T15 doctor runs =="
"$PACK" doctor >/dev/null 2>&1; [ $? -le 1 ] && ok "doctor exits cleanly" || bad "doctor crashed"

echo
echo "RESULT: $PASS passed, $FAIL failed"
rm -rf "$TMP"
[ $FAIL -eq 0 ]