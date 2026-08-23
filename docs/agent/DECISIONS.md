# DECISIONS

<!-- 只记决定和理由,不记过程 -->

- 不做存储引擎/向量库/swarm;只做注入+freshness+closeout 薄层。理由:存储已过剩(claude-mem 91k★),注射才是失败点。
- token 预算硬约束:超限丢弃并记录 dropped[],绝不静默塞满。理由:claude-mem v3 污染教训。
- HANDOFF 与 FACTS 分开:前者短命(任务级),后者长寿(带 path@commit 证据)。
