# 同类项目对比(2026-08-23)

## leonhartX/ctx(0★,MIT,bash+jq)

任务为中心的跨 agent 上下文共享:每个任务一个 Obsidian markdown,SessionStart
按 git 分支匹配注入 ~150 token 摘要;session transcript 登记到任务上实现
"读对方最后一条消息"。Claude Code + Codex,Gemini 非一等公民。

| 维度 | ctx | ctxpack |
|---|---|---|
| 单位 | 任务(task file) | 项目(docs/agent/ 五件套) |
| 注入内容 | 分支匹配的任务摘要 | handoff+pinned 约束+事实(freshness)+占用+mailbox |
| 新鲜度 | 无(git 只用来匹配分支) | **path@commit 对照,自动 STALE** |
| 预算 | 固定 ~150 token,无可见性 | 硬预算+dropped[] 可见 |
| 强制收工 | 靠人跑 `ctx save` | **hook block(deny/block + 防死循环)** |
| 观测 | 无 | events.jsonl + doctor |
| 形态 | shell 胶水+Obsidian vault | 单文件二进制+官方 extension |

结论:**验证了 SessionStart 注入路线可行**;它的"transcript 登记"思路值得
P3 借鉴(把别的 CLI 的 session 尾部消息带进 pack)。

## kalinbogatzevski/captain-memo(2★/431 commits,Apache-2.0,Bun/TS)

跨 AI 本地记忆层:Claude Code plugin + MCP,自动探测机器上的全部 agent 并接线;
索引各家已有记忆文件(CLAUDE.md、~/.codex、~/.cursor/rules…);混合检索,
本地 Ollama embedding。

| 维度 | captain-memo | ctxpack |
|---|---|---|
| 哲学 | 记得越多越好(RAG 召回) | 只注入仍为真且相关的(编译器) |
| 注入 | auto-injected context | hook 强制+预算硬约束 |
| 新鲜度 | 无(path@commit 概念缺失) | 核心循环 |
| 写安全/收工 | 无 | closeout block |

结论:偷它的 **auto-detect 安装体验**(`connect` 全自动);它走存储检索路线,
与本项目正交,未来可当我们的可选检索后端而非竞品。

## 定位总结

市场三块:自动抓取(claude-mem)、一键装记忆云(agentmemory/Iranti)、
任务上下文(ctx)。**"强制注入 × freshness × closeout 强制 × 跨厂商"四合一
无人做**,且 Gemini-first 是空白。ctxpack 卡的就是这个交叉点。
