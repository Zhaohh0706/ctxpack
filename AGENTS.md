# AGENTS.md — ctxpack 协议

所有 CLI(Gemini / Claude / Codex / opencode)共用本手册。

## 开工(已由 hook 自动完成,但你要知道发生了什么)

SessionStart 时 `pack inject` 会把 HANDOFF、事实、占用表注入你的上下文。
如果上下文里出现 `[ctxpack]` 头,说明注入成功;没有就提醒用户运行
`scripts/install.sh`。

## 收工前必须做(hook 会强制检查)

1. **更新 `docs/agent/HANDOFF.md`**:只写结论——做了什么、卡在哪、下一步。不写过程叙事。
2. 改了 `docs/agent/STATUS.md` 里登记的 worktree 状态要同步。
3. 有值得跨会话保留的结论 → 按 FACTS 格式追加到 `docs/agent/FACTS.md`。

## 事实格式(FACTS.md)

每行一条,证据强制:

```
- <一句话结论> (<相对路径>@<commit前缀>)
```

commit 前缀取自该文件最后一次被修改的 commit。文件改了,事实自动标 STALE,
要么重新核实后更新 sha,要么删掉。

## 并行纪律

- 只在自己的 worktree/分支干活,主分支不直接写。
- 动手前在 `STATUS.md` 登记占用:`- ../proj-xxx: <cli> working on <task>`。
- 给别的 agent 留话写 `docs/agent/MAILBOX.jsonl`(append-only):
  `{"from":"gemini","msg":"research done -> see HANDOFF#passkey","ts":"..."}`,每条 <2KB。

## 红线

- 不往 HANDOFF 写"应该可以/大概没问题"——只写验证过的结论。
- STALE 事实不许当授权使用,先核实再引用。
