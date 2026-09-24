# 开发进度

## 当前工作

**M9 分阶段强化已完成（本轮）**：新增纯数据链长档位表 `game/ChainTiers.ts`（`ChainTierDef { id, name, minChain, maxChain, multiplier }` + 4 档 2-3 ×1.0 / 4-5 ×1.25 / 6-7 ×1.6 / 8+ ×2.1 + `NoLimit` 哨兵 + `tierOf/multiplierOf/nameOf/isStrictlyIncreasing/describeAll`，最高档用 9999 表示无上限）；`game/Effects.ts` `EffectRule` 新增 `scaled: boolean`（`makeRule` 第 7 参数，默认 true），`resolveEffects()` 先取 `ChainTiers.multiplierOf(chainLength)` 再对 `scaled` 规则乘倍率（解析器内无任何 `kind ===` 分支）；`game/BlockDefs.ts` 四种可放置方块按档位补齐「阶段解锁」额外效果（物：破甲 6+ / 全体溅射 8+；法：全体法术 6+ / 自身增伤 8+；状：破甲 4+ / 增伤 8+；治：净化 4+ / 护盾 8+），魔力条目显式 `scaled=false` 恒为 1+3n；`game/Tests.ts` 新增 13f 段（42 条断言：档位区间落点、严格单调与区间连续、物伤 链长 2/4/6/8 = 10/20/35/59、魔力不被倍率影响 = 13/25、各档解锁阈值、效果条数随链长单调不减）；`tests/Entry.ts` 视图交互段的硬编码伤害断言改为按 `ChainTiers.multiplierOf(4)` 推导。构建 game **17/17** + tests 1/1 + init.ts 1/1 无诊断；自检 passed（逻辑 **336**（+42）/ 交互 27 / 运行时 46 / 主循环 94，0 失败）；`init.ts` 连续 2 次 `running=true`、`stopEntry()` 后 `running=false`。**M9 无残留项；下一步 M10（屏幕管理 + 开始界面 + 关卡选择）。**

**M8 关卡与敌人技能数据化已完成（前序回合）**：新增纯数据关卡注册表 `game/Levels.ts`（`EnemySkillDef { id, name, damage, effects, preparesNext, cooldownActions }` / `WaveDef { name, isElite, hp, attack, armor, actionTurns, actionSeconds, skills }` / `LevelDef`，含 `makeSkill/makeWave/blockSpec` + `buildDefaultLevel` + 6 个手工关卡 + `Levels.Default/List/EndlessBase/get/waveOf/skillOf/fallbackSkill`）；`game/Combat.ts` 构造改 `(board, level?)`，`enemyAct()` 去掉 `wave.isElite` 硬编码，改为按 `wave.skills` 轮转（`pickSkill` + 冷却）并经同一执行器 `applySpecs` 下发 `BoardBlock`，`EnemyAction` 改 `Attack/Prepare/Release`，新增 `isPreparing`/`lastSkillName`/`lastNewLocks`/`lastEnemyAction` 只读接口；`game/Game.ts` `enemyAct()` 按行动类别分道播报（预告「蓄力—下次释放」/ 释放带封锁计数 / 普攻）；`game/Tests.ts` 改 `EnemyAction.Prepare/Release` + `isPreparing` 并新增 M8 断言（默认关卡数值逐项等于 `Config.Waves`、第 3 关第 2 波先预告后释放、轮转覆盖、越界关卡/技能回退）。构建 game **16/16**（新增 Levels.ts）+ tests 1/1 + init.ts 1/1 无诊断；自检 passed（逻辑 **294**（+14）/ 交互 27 / 运行时 46 / 主循环 94，0 失败）；`init.ts` 连续 3 次 `running=true`、`stopEntry()` 后 `running=false`。**M8 无残留项。**

**前序规划/复核回合（历史记录）**：规划回合确认关卡制改造（M8–M13）范围与 4 个新界面；复核回合以代码复核确认计划与用户诉求一致且无事实偏差（`Combat.enemyAct()` 的 `wave.isElite` 硬编码、`EffectRule` 6 字段、`Settings` 仅 3 字段、`.agent/skills/` 不存在均已核实），并补记 `BlockDef.placeable` 与 skill frontmatter 约束。

**M6 排版统一与极端宽高比验收已完成**：新增 `game/UiLayout.ts` 排版审计 API 并接入 `game/Tests.ts` 第 13d 段——`visibleHalfExtent/insideSafeBox/hudLayoutRects/boardLayoutRect` 对 12 种窗口（5120×1440 … 600×1040、含 0×0 未就绪）断言最小可见区 ≥ 安全区 960×1080，并对 17 个 HUD/面板元素 + 棋盘逐个断言不越界，另加 3 条相邻性断言（棋盘↔提示行、对敌飘字上浮终点↔技能按钮下沿、我方飘字下沿↔提示行）。审计首次即暴露一处真实越界：`Config.NoticeEnemyY = 190` 时对敌飘字上浮终点 265.5 已升进技能按钮区（下沿 264），已下移到 **176**（终点 251，余量 12.5）。构建 game 15/15 + tests 1/1 + init.ts 1/1 无诊断；自检 passed（逻辑 **280** / 交互 27 / 运行时 46 / 主循环 94，0 失败）。**剩余：配色统一观感 + 真人手感与特效节奏确认（需用户实机）。**

**M5 已验收（用户实机反馈「动效均可」，精英蓄力→重击、封锁格角标、到期自动解除均正常）**。以下为本轮实施记录：

**M5（精英蓄力重击 + 封锁块）实现与自动化验证已完成**：封锁走统一执行器（`EffectKind.BoardBlock` → `Board.blockCells`），新增封锁计时 `Config.LockDurationActions=2`；`Board.expireLocks()` 在每次敌人行动时递减，到期格腾空后交回 `refillRestore()` 标准补充（C1/C2/C3 依旧成立，无特例逻辑）；`Combat.enemyAct()` 先推进计时再出手（新下发的封锁不会被同时扣减），`Combat.lastExpiredLocks` 暴露恢复数，`Game.enemyAct()` 播报「封锁自动解除 N 格」并刷新视图。构建 14/14 + 1/1 + 1/1 无诊断；自检 passed（逻辑 235 / 交互 27 / 运行时 46 / 主循环 94）。**剩余：实机视觉/手感验收（精英蓄力→重击、封锁变暗与到期恢复）。**

**本轮追加（用户诉求「封锁格看不到剩余时间」）**：`game/ui/BlockWidget.ts` 右上角新增剩余次数角标（深色底盘 `drawDot` + `Label`，默认隐藏；`setLockTurns(turns)` 更新数字，`lockTurns<=1` 转暖红 255,156,120）；`BoardView.refreshFromBoard()` 用 `board.lockTurnsAt(flat)` 驱动角标，新增公开访问器 `lockTurnsLabelAt(flat)`；`tests/Entry.ts` 运行时段新增角标断言并输正面证据行「M5 封锁角标：封锁 2 格，剩余次数「2」→「1」→到期恢复后「」」。同时修复一处**自检夹具缺陷**：`blockCells(2)` 选出的两格可能彼此相邻，而旧夹具固定取左邻格当作起手点 → 起手点本身就是封锁格，`chainLength` 断言偶发 `failed`（游戏逻辑无误：`canFollow/appendCell` 对封锁格直接 early-return）；现改为动态挑一个非封锁的上下左右邻格。连续两轮新鲜运行均 `passed`；另用临时探针抓帧 2 张供人眼确认角标观感（探针已删除）。

**M4 已完成**（实时模式 + 设置持久化）；M6 手感项大部分已完成，并已修复用户两次反馈的「实机看不到动效 / 血条纯白 / 缺技能动画」根因（描边传 `undefined` 导致白色填充覆盖整条、爆点误画进高亮图层），新增技能扫光 + 按钮亮光动画。本轮证据：构建 3 目标无诊断、自检 passed（196+19+21+94）、`previewGame` 抓帧 2 张；**视觉判读待用户实机复验**（本会话无 analyze_image）。之后进入 M5（精英蓄力重击 + 封锁块）。

**本轮追加（用户最新诉求）**：方块**掉落动画**已实现（塌落与补充时方块从旧格中心滑到新格中心，0.18s 缓出，到位后精确归位）；构建 14/14 + 1/1 + 1/1 无诊断，自检 passed（196+19+**28**+94）；**下坠手感需用户实机目视确认**。

当前游戏具备：拖拽连线→统一执行器结算→棋盘维护与兑底；回合制/实时双时间源与行动比例条；设置面板（模式/难度/提示）并持久化到 `settings.txt`；技能按钮按魔力置灰；失败结算与重开；消除时方块爆点闪光、血条缓动过渡；飘字按车道分开且同车道串行，伤害与受伤不再叠在同一位置。

## 步骤进度

| ID | 状态 | 最新结果 | 下一步 |
| --- | --- | --- | --- |
| M1 工程骨架 + 通用控件/注册表 + 棋盘渲染 | done | 构建无诊断；自检 passed；运行存活；首帧视觉确认 | — |
| M2 消除结算与棋盘维护 | done | 200/200 次随机操作可执行、无死局；用户人工验收通过 | — |
| M3 战斗核心 + 效果执行器 + 回合制 MVP（含魔力/技能/棋盘兑底、HUD/主循环） | done | 四段自检 passed（178+19+17+85）；`init.ts` 运行存活；用户人工验收（拖拽手感/失败结算/重开）通过 | — |
| M4 实时模式与设置持久化 | done | 新增 `game/Settings.ts`（key=value 存档，同步 `Content.load/save`）、HUD 设置面板（模式/难度/提示 + 存档状态）、`Combat` 实时倒计时（`setRealtime/advanceTime/secondsLeft`）；构建 14/14 + 1/1 + 1/1 无诊断；自检 passed（逻辑 196 + 交互 19 + 运行时 17 + 主循环 94）；运行存活 | 进入 M5 |
| M5 精英技能与封锁块 | done | 【已验收】数据层 + 执行侧 + 封锁到期自动恢复 + 封锁格剩余次数角标全部落地；构建 14/14 + 1/1 + 1/1 无诊断；自检连续两轮 passed（逻辑 235 / 交互 27 / 运行时 46 / 主循环 94，0 失败）；夹具缺陷已修；**用户 2026-01-01 实机反馈「动效均可」** | — |
| M6 手感与视觉打磨（含连通块上限调参） | in_progress | 已做：消除爆点闪光 + 短暂隐藏、血条缓动、进度条描边、飘字三车道 + 队列、受击反馈（血条闪红/抖动 + 全屏红闪）、玩家生命标签、敌方行动比例条、描边改全透明填充、爆点图层分离、技能扫光 + 按钮亮光、方块掉落动画、`game/UiLayout.ts`（Palette/HudLayout/SafeBox/zoomFor）统一字号与配色常量；**本轮新增：排版审计 API（`hudLayoutRects`/`boardLayoutRect`/`insideSafeBox`/`visibleHalfExtent`）+ 自检 13d 段（12 种窗口安全区、17 个 HUD 元素与棋盘越界、3 条相邻性），并修掉审计发现的「对敌飘字升进技能按钮」越界（NoticeEnemyY 190→176）**；待做：真人手感与特效节奏确认 | 请用户实机复验后继续微调 |
| M7 扩展性验收（仅改注册表新增方块/效果） | pending | 已归入 M13，不单独执行 | 由 M13 覆盖 |
| M8 关卡与敌人技能数据化（`game/Levels.ts` + `Combat` 去 `isElite` 硬编码） | done | 【本轮完成】`game/Levels.ts`（6 手工关卡 + 默认兼容关卡 + `skillOf`/`fallbackSkill` + `EnemySkillDef.damage`）；`Combat.enemyAct()` 数据化技能轮转（`Attack/Prepare/Release` + 冷却 + 执行器下发 `BoardBlock`，无 kind 分支）；`Game` Prepare/Release 分道播报；`Tests.ts` M8 断言。构建 16/16 + 1/1 + 1/1 无诊断；自检 passed（逻辑 294 / 交互 27 / 运行时 46 / 主循环 94）；`init.ts` 运行存活 | 进入 M9 |
| M9 分阶段强化（`game/ChainTiers.ts` + `EffectRule.scaled` + 档位阈值 4/6/8） | done | 【本轮完成】4 档纯数据表（接触/连击/共鸣/超载 ×1.0/1.25/1.6/2.1，`isStrictlyIncreasing()` 锁定严格单调与区间连续）；`EffectRule.scaled` 落地，`resolveEffects` 只查表取倍率（魔力 `scaled=false` 不受影响）；四类方块按档补齐阶段解锁效果（阈值 4/6/8）。构建 17/17 + 1/1 + 1/1 无诊断；自检 passed（逻辑 **336**（+42）/ 交互 27 / 运行时 46 / 主循环 94，0 失败）；`init.ts` 运行存活 | 进入 M10 |
| M10 屏幕管理 + 开始界面 + 关卡选择（含敌方技能预览） | pending | 未开始 | 依赖 M8/M9（均已满足）；视觉需 `analyze_image` 或用户实机 |
| M11 技能池扩充 + 3 装备槽 + 技能配置界面 | pending | 未开始 | 依赖 M10 |
| M12 方块功能配置界面 + 启用/禁用（`BlockDefs.activeIndices`） | pending | 未开始 | 依赖 M10 |
| M13 通用模板与工程 skill 固化 + 扩展性验收 | pending | 未开始 | 依赖 M9、M12 |

## 修改记录

| 日期 | 范围 | 内容 |
| --- | --- | --- |
| 2026-01-01 | `.agent/plan`（仅文档） | 规划回合与架构修订（方块→通用控件 + 注册表纯数据 + 效果三元组）。 |
| 2026-01-01 | 源码（M1/M2） | 新增 `Config`/`Effects`/`BlockDefs`/`ui/Widget`/`ui/BlockWidget`/`Board`/`BoardView`/`Tests`/`tests/Entry`；修正 C2 约束。 |
| 2026-01-01 | 源码（需求追加） | 链长下限 3→2；新增魔力（`ManaGain`）、技能注册表 `Skills.ts`、`Combat.ts`（技能/棋盘兑底）与棋盘新能力。 |
| 2026-01-01 | 源码（储备约束简化） | 删除 C2b 与 `ReserveGroupMin`/`IdealRefillRetries`；仅保留“存在 ≥ MinChainLength 可连线区域”一条硬约束。 |
| 2026-01-01 | 源码（M3 交互层） | 新增 `ui/Controls.ts`、`Hud.ts`、`Game.ts`；`Combat.ts` 新增波次/关卡推进；`init.ts` 改为只做自适应 + 启动 `Game`。 |
| 2026-01-01 | 源码（运行问题处理） | 修复 `init.ts` 的 `Node.scale` 编译错误；缩放改为宽高取最小 + 无摄像机降级 + 尺寸无效防护；隐藏面板按钮不再遮挡棋盘触控；`Game` 新增 `submitChain()` 与主循环自检。 |
| 2026-01-01 | 源码（M4 + M6 部分） | 新增 `game/Settings.ts`（存档用同步 `Content.load/save` —— `*Async` 必须在协程中调用，否则 assert 失败）；`Hud` 新增设置面板与底部提示行；`Combat` 新增 `setRealtime/advanceTime/secondsLeft/enemyIntervalSeconds`；`Game` 接入设置、实时倒计时与模式/难度/提示的公开切换接口；`BoardView` 新增消除爆点反馈与输入锁；`ui/Controls` 血条缓动 + 描边。 |
| 2026-01-01 | 源码（M6 手感 + 用户反馈修复） | `Hud.ts` 飘字改三车道 + 每车道 FIFO 队列（`NoticeLane`）、新增 `hitPlayer/hitEnemy`（血条 flash/shake + `hitLayer` 全屏红闪 z=-1）、左侧「玩家生命」标签、敌方行动比例条 `timerBar`；`Game.ts` 新增 `reportChain()` 分道播报并按 HP 前后差触发受击反馈、`setTimerInfo` 传剩余比例；`BoardView` 新增独立 `flashLayer` + `endFlash()` + `trackTo/appendToward` 修复滑动漏格与旧外观残留；`ui/Widget` 新增 `shake`，`ui/Controls` 新版 `flash`。 |
| 2026-01-01 | 源码（渲染根因修复 + 技能动画 + 自检增强） | `ui/Controls.ts` 血条描边改显式 `Color(0,0,0,0)` 填充（修「血条纯白」）、`ButtonWidget` 新增 `glow()` 与按下缩放；`BoardView.ts` 爆点改画 `flashLayer`、新增 `pulseLayer`(z=12) 与 `skillCast(cells)`/`isCasting`；`Game.ts` `handleSkill` 接通 `hud.glowSkill` + `view.skillCast(diffBlocks())`（新增 `captureBlocks/diffBlocks`）；`tests/Entry.ts` 运行时观测段新增 4 条动画起停断言（17→21 项）。 |
| 2026-01-01 | 源码（掉落动画） | `game/Board.ts` `collapse()` 记录成对塌落轨迹 `lastMoves` 与腾空格子 `lastSpawns`（新增只读 `collapseMoves`/`collapseSpawns`）；`game/BoardView.ts` 新增 `fallCells/fallOffsets/fallTimer`、`animateFall()`、`advanceFall()`、`finishFall()`、`isFalling`、`fallOffset()`，`update(dt)` 中驱动，`press()` 抢操作时立即归位；`game/Game.ts` `handleChain` 在 `flashCleared` 后插入 `view.animateFall(board.collapseMoves, board.collapseSpawns)`；`tests/Entry.ts` 新增 6 条断言（轨迹成对/腾空格子/动画起停/中途位移>1/结束后精确归位）。 |
| 2026-01-01 | 源码（M5 封锁到期） | `game/Board.ts` 新增 `lockTimers`/`lockedCount()`/`lockTurnsAt()`/`lastExpiredLocks`/`expireLocks()`（到期格腾空后调 `refillRestore()`），`resetCells()` 同步清空计时且 `reset()` 改为 `resetCells()` + `fill()`（换波/重开必定清除封锁），`blockCells()` 锁格时写入 `Config.LockDurationActions`；`game/Config.ts` 新增 `LockDurationActions = 2`；`game/Combat.ts` 新增 `expiredLockCount`/`lastExpiredLocks`，`enemyAct()` 首行推进计时；`game/Game.ts` 新增「封锁自动解除 N 格」播报；`game/Tests.ts` 新增 13c 段（14 条断言）；`tests/Entry.ts` 运行时段新增封锁到期与视图同步解除断言（+13 条）。 |
| 2026-01-01 | 源码 + 自检（M5 封锁角标） | `game/ui/BlockWidget.ts` 新增右上角剩余次数角标 `badge`（`Label` + `drawSelf()` 中的深色底盘 `drawDot`，`applyBadge()` 控制显隐与颜色，`badgeText` getter）；`game/BoardView.ts` `refreshFromBoard()` 调 `setLockTurns()` 并新增 `lockTurnsLabelAt(flat)`；`tests/Entry.ts` 运行时段新增 2 条角标断言（邻格起手链长、角标文本）与正面证据行，并修复**相邻封锁格导致的夹具缺陷**（改为动态挑非封锁邻格），检查项 44 → 46。 || 2026-01-01 | `.agent/plan`（仅文档） | 规划回合：确认关卡制改造（M8–M13）与四项新界面范围；PLAN.md 新增本轮目标、7 条已确认决策、5 节技术方案（屏幕流程与调度 / 分阶段强化 / 关卡与敌人技能数据化 / 技能池与装备槽 / 方块启停 / 通用模板与 skill）、M8–M13 实施步骤（M7 归入 M13）、风险 R12–R17、文件结构新行；PROGRESS.md 同步当前工作与步骤表。本轮无源码改动。 |
| 2026-01-01 | `.agent/plan`（仅文档，复核） | 复核回合：以代码复核确认关卡制计划（M8–M13）与用户诉求一致且无事实偏差（`Combat.enemyAct()` 的 `wave.isElite` 硬编码、`EffectRule` 6 字段、`Settings` 仅 3 字段、`.agent/skills/` 不存在均已核实）；补充 `BlockDef.placeable` 与 skill frontmatter 两处精度；范围无变化。 |
| 2026-01-01 | 源码（M8 关卡与敌人技能数据化） | 新增 `game/Levels.ts`（`EnemySkillDef`（含 `damage`）/`WaveDef`/`LevelDef` + `makeSkill/makeWave/blockSpec` + `buildDefaultLevel` + 6 手工关卡 + `Levels.Default/List/EndlessBase/get/waveOf/skillOf/fallbackSkill`）；`game/Combat.ts` 构造改 `(board, level?)`、`EnemyAction` 改 `Attack/Prepare/Release`、新增 `prepared/cooldowns/skillCursor/lastSkill/newLocks` 与 `pickSkill()`，`enemyAct()` 改为数据驱动轮转并经 `applySpecs` 下发技能效果（移除 `wave.isElite` 硬编码）；`game/Game.ts` `enemyAct()` 按 `lastEnemyAction` 分道播报；`game/Tests.ts` `EnemyAction.Charge/Heavy`→`Prepare/Release`、`isCharged`→`isPreparing` 并新增 M8 断言段。 |
| 2026-01-01 | 源码（M9 分阶段强化） | 新增 `game/ChainTiers.ts`（4 档纯数据 + `NoLimit`/`tierOf`/`multiplierOf`/`nameOf`/`isStrictlyIncreasing`/`describeAll`）；`game/Effects.ts` `EffectRule` 加 `scaled` 字段与 `makeRule` 第 7 参数，`resolveEffects()` 按档位倍率展开（无 kind 分支）；`game/BlockDefs.ts` 四类方块补齐档位解锁效果、魔力条目 `scaled=false`；`game/Tests.ts` 新增 13f 段 42 条断言；`tests/Entry.ts` 交互段伤害期望改为 `ChainTiers.multiplierOf(4)` 推导。 |

## 验证证据

| 类型 | 证据 | 结论 |
| --- | --- | --- |
| 自动化（M6 排版审计，本轮） | `.agent/test-results/m3.txt` 首行 `passed`（runTime=2876.65）：逻辑 **280**（+45）/ 交互 27 / 运行时 46 / 主循环 94，0 失败；报告含「M6 排版：12 种窗口下最小可见区 960×1080 ≥ 安全区 960×1080，HUD/面板 17 个元素与棋盘均在安全区内；棋盘底边 -484，提示行上沿 -489，对敌飘字上浮终点 251（技能按钮下沿 264）」 | 达成 |
| 构建（本轮） | `build paths=['game','tests','init.ts']`：game **15/15**（新增 UiLayout.ts）、tests 1/1、init.ts 1/1，逐文件 `messages` 无诊断 | 达成 |
| 源码实现（M1–M4） | `init.ts` → `Game` → `Board`/`BoardView`/`Combat`/`Hud`/`Settings`；`Hud` → `ui/Controls` → `ui/Widget`；执行器按 `kind`/`target` 查表 | 达成 |
| 构建 | `build paths=['game','tests','init.ts']`：14/14 + 1/1 + 1/1 文件通过，逐文件 `messages` 无诊断 | 达成 |
| 运行存活 | `init.ts` 连续 3 次观察 `running=true`，停止后 `running=false`（M1/M2/M3/M4 各一次） | 达成 |
| 自动化（逻辑） | `.agent/test-results/m3.txt` 首行 `passed`：196 项 0 失败（链长 2、魔力、技能、棋盘兑底、波次/失败/重开、设置往返、难度缩放、实时/回合时间源对比） | 达成 |
| 自动化（视图交互） | 同文件 passed（19 项） | 达成 |
| 运行时链路观测 | 同文件 passed（17 项）：40/40 次真实触点注入、魔力/伤害结算、无解棋盘被动重排 | 达成 |
| 主循环自检 | 同文件 passed（**94 项**）：`Game.submitChain()` 40 次全路径 + `toggleMode/cycleDifficulty/toggleHint` 运行时切换；难度切到休闲后敌人上限 40→32（可见于报告状态行） | 达成 |
| 视觉 | `.agent/vision/1790142557-958700532.png` + `analyze_image`：7×7 棋盘完整、上方 HUD 分层清晰、两个技能按钮标签可读、右上角「设置」按钮存在、底部提示行完整 | 达成（部分） |
| 自动化（本轮重跑） | `.agent/test-results/m3.txt` 首行 `passed`：逻辑 196 / 交互 19 / **运行时 21** / 主循环 94 项，0 失败（`runTime=4612.23`）；`stopEntry()` 后 `success=true running=false` | 达成 |
| 构建（本轮修复后） | `build paths=['game','tests','init.ts']`：game 14/14、tests 1/1、init.ts 1/1，逐文件 `messages` 无诊断 | 达成 |
| 抓帧（本轮） | `previewGame({entry='init.ts', captureAtSeconds={0.5,2.5}})` → `.agent/vision/1790146343-445096667.png`、`1790146345-157393825.png`（1280×960）：真实入口渲染循环存活 | 达成（仅存活，未判读） |
| 自动化（掉落动画，本轮） | `.agent/test-results/m3.txt` 首行 `passed`：逻辑 196 / 交互 19 / **运行时 28** / 主循环 94，0 失败；其中「中途相对格中心位移 >1」「结束后偏移 <0.01」直接证明方块确实在移动且精确到位 | 达成 |
| 自动化（M5 封锁到期，本轮） | `.agent/test-results/m3.txt` 首行 `passed`（runTime=12281.40）：逻辑 **235** / 交互 **27** / 运行时 **41** / 主循环 94，0 失败；报告含「封锁经 2 次敌人行动后自动恢复」行；逻辑段断言封锁计时递减、未到期不解除、到期后 `lockedCount()=0` 且满格/可执行/满足 C1，运行时段断言视图 `isLockedAt` 到期后全部归零 | 达成 |
| 自动化（M5 封锁角标 + 夹具修复，本轮） | `.agent/test-results/m3.txt` 连续两轮新鲜报告（`runTime=636.48` / `637.04`）首行均 `passed`：逻辑 235 / 交互 27 / 运行时 **46** / 主循环 94，0 失败；正面证据行「M5 封锁角标：封锁 2 格，剩余次数「2」→「1」→到期恢复后「」；到期后视图锁定格 0 个」 | 达成 |
| 抓帧（角标观感，本轮） | 临时探针 `tests/PreviewLock.ts`（100% 程序化绘制棋盘 + 封锁 2 格）→ `.agent/vision/1790209390-61343960.png`（0.6s，角标「2」）、`1790209392-922238346.png`（1.8s，剩最后一次转暖色「1」），1010×700；探针与生成 Lua 已删除 | 仅产出图，**未判读**（本会话无 analyze_image） |
| 构建（M8，本轮） | `build paths=['game','tests','init.ts']`：game **16/16**（新增 Levels.ts）、tests 1/1、init.ts 1/1，逐文件 `messages` 无诊断 | 达成 |
| 自动化（M8 逻辑，本轮） | `.agent/test-results/m3.txt` 首行 `passed`（runTime=23333.78）：逻辑 **294**（+14）/ 交互 27 / 运行时 46 / 主循环 94，0 失败；报告含「M8 关卡：6 个手工关卡，每关 3 波；默认关卡数值等于 Config.Waves；第 3 关第 2 波「封锁击」先预告后释放，轮转覆盖 1 条技能」 | 达成 |
| 运行存活（M8，本轮） | `init.ts` 连续 3 次观察 `running=true`，`stopEntry()` 后 `success=true running=false` | 达成 |
| 构建（M9，本轮） | `build paths=['game','tests','init.ts']`：game **17/17**（新增 ChainTiers.ts）、tests 1/1、init.ts 1/1，逐文件 `messages` 无诊断 | 达成 |
| 自动化（M9 逻辑，本轮） | `.agent/test-results/m3.txt` 首行 `passed`（新鲜运行 runTime=29573.70，与旧报告 29366.47 不同）：逻辑 **336**（+42）/ 交互 27 / 运行时 46 / 主循环 94，0 失败；报告含「M9 分阶段强化：2-3 接触×1 / 4-5 连击×1.25 / 6-7 共鸣×1.6 / 8+ 超载×2.1；物伤 链长2/4/6/8 = 10/20/35/59；魔力不受倍率影响（链长4 = 13，链长8 = 25）」 | 达成 |
| 运行存活（M9，本轮） | `init.ts` 连续 2 次观察 `running=true`，`stopEntry()` 后 `success=true running=false` | 达成 |
| 残留未验 | **血条颜色差异是否可见、消除爆点/技能扫光/按钮亮光动效是否可见**（本轮修的就是这些，但本会话无 analyze_image，抓帧 PNG 未判读）、三车道飘字/受击闪红抖动/玩家生命标签/敌方行动比例条观感与节奏、实时模式真人手感、设置面板点击流程 | `not_run`，建议用户实机确认 |

## 阻塞问题

无。非阻塞待办：①本轮关卡制改造进行中（M8、M9 已完成；M10–M13 待实施），计划已定稿且无待确认问题；②M6 调参：重力合流可造出超过放宽上限（7）的同色块并长期存在（200 次操作中越界 13~181 次波动，**无死局**）；②实时模式节奏参数（波 1/2/3 = 5/4/3 秒）需真人手感验证。

## 进度日志

- 2026-01-01：规划回合 + 架构修订；M1/M2/M3 实施与验收（含 C2 修正、链长 2、魔力/技能、运行问题修复）。
- 2026-01-01：用户确认运行正常、拖拽手感良好、失败结算与重开已实现。
- 2026-01-01：M4 实施与验收（设置面板 + 存档 + 实时时间源）；顺带完成 M6 部分手感项（消除爆点、血条缓动、描边、飘字位置）；自检 196+19+17+94 全通过。
- 2026-01-01：M6 手感推进 + 用户反馈修复（飘字三车道 + 队列、受击闪红/抖动/全屏红闪、玩家生命标签、敌方行动比例条、滑动漏格与旧外观残留修复）；构建 14/14 + 1/1 + 1/1 无诊断；自检重跑 196+19+17+94 0 失败。
- 2026-01-01：渲染根因修复（描边改全透明填充、爆点图层分离）+ 技能扫光/按钮亮光与按下反馈 + 自检新增动画起停断言；构建 14/14 + 1/1 + 1/1 无诊断；自检 passed 196+19+21+94；`previewGame` 抓帧 2 张（0.5s/2.5s）待用户视觉复验。
- 2026-01-01：方块掉落动画（用户最新诉求）：`Board.collapse()` 记录塌落轨迹 + `BoardView.animateFall/advanceFall` 播放下滑（0.18s 缓出）+ `Game.handleChain` 接线；构建 3 目标无诊断；自检 passed 196+19+28+94（新增 6 条断言，含「中途位移 >1」「结束后归位 <0.01」）。
- 2026-01-01：M9 分阶段强化（本轮）：`game/ChainTiers.ts` 四档纯数据表 + `EffectRule.scaled` + 解析器按档位倍率展开（魔力不受影响）+ 方块阶段解锁效果（阈值 4/6/8）+ `Tests.ts` 13f 段 42 条断言 + `tests/Entry.ts` 伤害期望改按档位推导；构建 3 目标无诊断；自检 passed 336+27+46+94，0 失败；`init.ts` 运行存活。
- 2026-01-01：M5 实现 + 封锁到期自动恢复：`Board.lockTimers/expireLocks()`（到期走 `refillRestore()`）、`Config.LockDurationActions=2`、`Combat.enemyAct()` 推进计时、`Game` 「封锁自动解除」播报；构建 14/14 + 1/1 + 1/1 无诊断；自检 passed 逻辑 235 / 交互 27 / 运行时 41 / 主循环 94；视觉验收 not_run。
- 2026-01-01：M6 排版统一与极端宽高比验收：新增 `game/UiLayout.ts` 审计 API（`visibleHalfExtent`/`insideSafeBox`/`hudLayoutRects`/`boardLayoutRect`）+ `game/Tests.ts` 13d 段 45 条断言；审计揭露 `NoticeEnemyY=190` 时对敌飘字上浮终点 265.5 提前升进技能按钮区（下沿 264），改为 176（终点 251）；构建 15/15 + 1/1 + 1/1 无诊断，自检 passed 280/27/46/94。
- 2026-01-01：M5 封锁角标（用户诉求「封锁格看不到剩余时间」）：`BlockWidget` 右上角数字角标（深色底盘 + 剩余敌方行动次数，最后一次转暖红）、`BoardView.lockTurnsLabelAt()`、`tests/Entry.ts` 角标断言与正面证据行；顺带修复「相邻封锁格 → 夹具起手点即封锁格」的偶发 `failed`（游戏逻辑无误）；构建 3 目标无诊断，自检连续两轮 passed（235 / 27 / 46 / 94），并抓帧 2 张（临时探针已删）；角标观感待用户目视确认。
- 2026-01-01：规划回合（关卡制改造）：确认 4 个新界面、6 关 + 无尽挑战、分阶段强化四档、3 技能装备槽、方块图鉴 + 启停、敌方技能预览，并把新增方块/效果的流程固化为工程 skill；计划写入 PLAN.md 的 M8–M13 与风险 R12–R17，本轮无源码改动、无构建与自检证据。
- 2026-01-01：复核回合（关卡制改造）：用户重申同一诉求，逐条对照 PLAN.md 确认无遗漏；用代码复核 `Combat.enemyAct()`（`wave.isElite` 硬编码待 M8 移除）、`Effects.EffectRule`（6 字段待 M9 增 `scaled`）、`Settings`（现 3 字段待 M10–M12 扩展）、`.agent/skills/`（不存在待 M13 新建）；依据 skill-creator 补充 skill 的路径/命名/frontmatter 约束，并补记 `BlockDef.placeable`。范围无变化，本轮无源码改动。
- 2026-01-01：M8 关卡与敌人技能数据化完成：新增 `game/Levels.ts`（6 手工关卡 + 默认兼容关卡 + `EnemySkillDef.damage`）、`Combat.enemyAct()` 数据驱动技能轮转（`Attack/Prepare/Release` + 冷却 + 执行器下发 `BoardBlock`，移除 `wave.isElite` 硬编码）、`Game` 分道播报、`Tests.ts` M8 断言；构建 16/16 + 1/1 + 1/1 无诊断，自检 passed（逻辑 294 / 交互 27 / 运行时 46 / 主循环 94，0 失败），`init.ts` 运行存活。下一步 M9。
