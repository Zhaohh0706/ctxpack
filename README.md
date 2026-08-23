# ctxpack — 跨 CLI 上下文编译器

> 不是又一个 agent memory。是跨 CLI 的**上下文编译器**:每次 session 开始,
> 只注入现在仍为真、且和当前任务有关的东西。

## 它解决什么

你同时用 Gemini / Claude / Codex / opencode / Grok 干同一个项目:

- 每个 CLI 各吃各的窗口,换工具就要把昨天讲过的再讲一遍
- 写在 markdown 里的协议没人执行——模型一忙就跳过检索
- 记忆会腐烂:代码改了,旧结论还在被当真

ctxpack 用官方 **hook 机制强制注入**(不靠模型自觉),每条事实挂
`path@commit` 证据并对照 git 自动标 STALE,收工没写交接就 **block**。

## 快速开始

```bash
git clone https://github.com/Zhaohh0706/ctxpack.git && cd ctxpack
scripts/install.sh /path/to/your/project --with-claude
```

之后在该项目里打开 gemini / claude,session 开始即自动注入;
Codex 接线见 `.ctxpack/codex-snippet.json`(P2)。

## 组成

```
bin/pack            全部逻辑(单文件,零依赖 Python3)
  inject   --cli …  SessionStart:编译 ≤1200 token 上下文包
  closeout --cli …  Stop/AfterAgent:改码未写 HANDOFF 则 block
  facts-check       FACTS.md 新鲜度报告
  say/mail-read     跨 CLI 邮箱(<2KB/条,append-only)
  (inject 内置)    跨 CLI transcript 尾部:自动附带其他 CLI 最近发言
  doctor            健康检查(hook 接线/STALE/占用冲突/未读)
  log               观测日志(.ctxpack/events.jsonl)
docs/agent/         HANDOFF(短命)/ FACTS(带证据长寿)/ DECISIONS(pinned)/ STATUS / MAILBOX.jsonl
extension/          Gemini CLI extension 发行包(gemini extensions install 即用)
tests/run_tests.sh  18 项行为测试
```

## 设计红线

1. 不做存储引擎/向量库/swarm —— 存储已过剩,注入才是失败点
2. token 预算硬约束:超限丢弃并写进 `dropped[]`,绝不静默塞满;
   DECISIONS 是 pinned 约束,永不因预算被丢(Constraint Pinning)
3. 事实必须有出处(`path@commit`),过期自动降级,不许当授权
4. hook fail-open,所以注入失败必须在 systemMessage 里可见
5. 每次注入写一行 JSONL —— 没有观测就没有调优

详细研究:`docs/research/hook-matrix.md`(三家信封验证)、
`docs/research/prior-art.md`(与 ctx / captain-memo 的边界)。协议见 `AGENTS.md`。
