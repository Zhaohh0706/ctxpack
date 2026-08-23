# Hook 注入矩阵(2026-08-23 逐家对照官方文档验证)

| CLI | 注入点 | 输出信封 | closeout 强制点 | 配置位置 |
|---|---|---|---|---|
| Gemini | `SessionStart` | `{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":str},"systemMessage":str}` | `AfterAgent` → `{"decision":"deny","reason"}` 强制重试 | `.gemini/settings.json` 项目级,v0.26+ 默认开启;extensions 可打包分发 |
| Claude Code | `SessionStart`(startup/resume/clear) | 同上同构 | `Stop` → `{"decision":"block","reason"}`(v2.1.163 起还支持 additionalContext) | `.claude/settings.json` 项目级 |
| Codex | `SessionStart` 等 ~9 事件 | additionalContext 模型可见(**已知 bug #16933:会在 transcript 可见渲染**) | `Stop` 可 block | `~/.codex/hooks.json` 或 config.toml |
| **Antigravity CLI (`agy`)** | `PreInvocation`(每次调模型前,**每轮重注入**) | `{"injectSteps":[{"ephemeralMessage":str}]}` | `Stop` → `{"decision":"continue","reason"}` | 全局 `~/.gemini/config/hooks.json` 或项目级 `.agents/hooks.json` |

## Antigravity CLI 实测笔记(2026-08-24,v1.1.17,逐条真机验证)

- 个人版 Gemini CLI 已于 2026-06-18 关停(IneligibleTierError),**agy 是唯一正道**,配置树复用 `~/.gemini/`。
- hooks schema 与 Gemini CLI **不同**:顶层键是 hook 名(非事件名),事件作为 hook spec 内的键;`.hooks` 若为数组会解析失败。
- 支持事件仅 5 个:`PreToolUse`/`PostToolUse`(grouped,带 matcher)、`PreInvocation`/`PostInvocation`/`Stop`(flat)。**没有 SessionStart/AfterAgent**。
- `PreInvocation` 每轮调模型前执行 → 天然实现 Constraint Pinning 的"每轮重注入"语义,比 SessionStart 更强。
- handler 经 `sh -c` 执行但环境 PATH 精简(git 需绝对路径兜底);`~` 会展开;工作目录 = hooks.json 所在目录 → 项目根要从 stdin 的 `workspacePaths` 读。
- `-p` print 模式触发 PreInvocation,**不触发 Stop**;Stop 在交互会话生效(changelog 印证:"lets Stop hooks run at all")。
- 探测方法备忘:`strings agy` 里有完整内嵌文档(skill: agy-customizations),schema 以此为准。

## 关键语义

- 三家 SessionStart 均**不阻塞**会话启动(advisory);阻塞能力在 BeforeTool/Stop/AfterAgent。
- hook 是 **fail-open**:超时/非零退出 = 会话继续。所以注入失败必须靠 systemMessage 喊出来。
- Gemini 对项目级 hook 有指纹机制防 git pull 投毒;Claude 曾有 SessionStart RCE(CVE-2025-59536)。hook 脚本必须进仓库可 review。
- Claude Stop 防死循环:连续 block 上限 8 次;我们另用 blocked_once 标记每会话只拦一次。
