# HANDOFF

## Current

- 项目:ctxpack v0.3.0(跨 CLI 上下文编译器)。研究结论在 docs/research/。
- v0.3.0 新增:Antigravity CLI(agy)完整接入——PreInvocation 每轮注入 + Stop closeout,schema 经二进制内嵌文档+真机逆向验证(hook-matrix.md)。
- 真机已验证:agy -p 下注入生效(模型可见 [ctxpack] 内容);Stop 仅交互模式触发,待用户交互验证一次。
- 安装:scripts/install.sh <project> --with-claude --with-agy;agy 走用户级 ~/.ctxpack/pack + ~/.gemini/config/hooks.json。
- 下一步:Codex 接线(P2)、transcript 尾部注入(P3)、npm publish(需账号)。
