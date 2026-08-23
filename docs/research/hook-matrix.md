# Hook 注入矩阵(2026-08-23 逐家对照官方文档验证)

| CLI | 注入点 | 输出信封 | closeout 强制点 | 配置位置 |
|---|---|---|---|---|
| Gemini | `SessionStart` | `{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":str},"systemMessage":str}` | `AfterAgent` → `{"decision":"deny","reason"}` 强制重试 | `.gemini/settings.json` 项目级,v0.26+ 默认开启;extensions 可打包分发 |
| Claude Code | `SessionStart`(startup/resume/clear) | 同上同构 | `Stop` → `{"decision":"block","reason"}`(v2.1.163 起还支持 additionalContext) | `.claude/settings.json` 项目级 |
| Codex | `SessionStart` 等 ~9 事件 | additionalContext 模型可见(**已知 bug #16933:会在 transcript 可见渲染**) | `Stop` 可 block | `~/.codex/hooks.json` 或 config.toml |

## 关键语义

- 三家 SessionStart 均**不阻塞**会话启动(advisory);阻塞能力在 BeforeTool/Stop/AfterAgent。
- hook 是 **fail-open**:超时/非零退出 = 会话继续。所以注入失败必须靠 systemMessage 喊出来。
- Gemini 对项目级 hook 有指纹机制防 git pull 投毒;Claude 曾有 SessionStart RCE(CVE-2025-59536)。hook 脚本必须进仓库可 review。
- Claude Stop 防死循环:连续 block 上限 8 次;我们另用 blocked_once 标记每会话只拦一次。
