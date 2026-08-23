# HANDOFF

## Current

- 项目:ctxpack v0.2.0(跨 CLI 上下文编译器)。研究结论在 docs/research/。
- 已完成:bin/pack 八个子命令(inject/closeout/facts-check/say/mail-read/doctor/log/version)、18 项测试全绿、Gemini+Claude 项目级 hook 接线、Gemini extension 发行脚手架(extension/)、npm 包脚手架(package.json)、同类项目对比(prior-art.md)。
- 真机验证:hook 在 gemini CLI 实际触发(systemMessage 可见);模型调用被账号层级阻塞(IneligibleTierError),见 todo a8e502。
- 下一步:用户修好任一家 CLI 登录后做最终真机注入确认;Codex hooks.json 全局接线(P2,需用户同意改 ~/.codx);ctx 式 transcript 尾部注入可作 P3 借鉴。
