# HANDOFF

## Current

- ctxpack v0.4.0:新增跨 CLI transcript 尾部注入(P3 完成)——pack 自动读取同工作区其他 CLI(Claude/Codex)最近会话的最后发言,注入为 "Other agents' last words" 段。
- 真机验证:agy 中模型可见该段并正确概括 claude 尾部内容;23/23 测试全绿。
- 已知边界:agy -p 模式 workspacePaths 为空且 env 被清洗,自动化场景需 export CTXPACK_WORKSPACE=<项目>;交互模式无此问题。Stop closeout 仅交互模式触发。
- 下一步:npm publish(需用户账号)、Codex 接线验证、opencode/grok 的 transcript 读取器可按同一架构扩展。
