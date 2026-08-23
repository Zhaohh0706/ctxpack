# ctxpack extension

每个 session 开始时自动注入带证据的上下文包;收工没写 HANDOFF 会被拦。

安装(本地开发):

```bash
gemini extensions install /path/to/ctxpack/extension
# 或开发模式热更新:
gemini extensions link /path/to/ctxpack/extension
```

发布:把本目录推到独立 GitHub repo,然后任何人

```bash
gemini extensions install https://github.com/<you>/ctxpack-extension
```

注意:extension 注入的是**当前工作区**的 `docs/agent/`,与项目级
`.gemini/settings.json` 方案二选一,不要重复注入。
