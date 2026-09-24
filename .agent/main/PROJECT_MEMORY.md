## Project Memory

### Project Facts

- Dora SSR 工程（TypeScript → Lua），游戏为「连线消除 + 战斗」：7×7 棋盘、四类方块（物/法/状/御）+ 不可放置「封锁」格、按住滑过相邻同色块形成连线（链长下限 2）、关卡制多波战斗 + 关底精英（第 3 波精英蓄力→重击并封锁棋盘）。
- 目标平台：PC 鼠标 + 移动触控（同一套节点手势插槽）；全程序化绘制（DrawNode + Label），无音频、无外部资源。UI 文本为简体中文。
- 入口 `init.ts`：设计高度 1080 的摄像机 zoom 自适应 + 单一 `schedule` 循环。

### Build And Run

- 构建：`build paths=['game','tests','init.ts']`；逐文件看 `messages`。若报 “TypeScript transpiler is not ready”，直接重试（服务未就绪，非代码错误）。仅改 `game/` 时可先 `build paths=['game']` 快速拿诊断（本轮 14/14 通过）。
- 运行时自检：`tests/Entry.ts` 为 Agent 自检入口，把报告写到项目根 `.agent/test-results/m3.txt`，首行为 passed/failed。
- Git：仓库无历史时由用户要求做了初始提交 `c744003`（init.ts/init.lua + `game/**` 与 `tests/**` 的 TS 源与生成 Lua，共 34 文件）。`.agent/**`（记忆/计划文档、test-results、vision 抓帧 PNG）有意未入库；无 `.gitignore`。仅支持单命令 Git（不支持 `git log --oneline`）。
  - 命令侧：`enterEntryAsync({fileName='tests/Entry.ts'})` → 轮询 `Content:exist(".agent/test-results/m3.txt")` 且内容变化 → `stopEntry()`。**轮询文件名必须是 `m3.txt`**（曾误用 `m4.txt` 导致 fresh=false/MISSING）。
  - **命令沙箱的 Content 只支持项目相对路径字符串**（`Content:exist(".agent/test-results/m3.txt")`）；用 `Path(projectDir, ...)` 拼绝对路径会报 `Content path must stay inside projectDir`。沙箱**无 mkdir/remove/写**（`Content:remove` 报 nil），所以目录与文件必须由 TS 入口自己在引擎内创建（`Content.save(Path(Content.searchPaths[0], ...))`），命令侧用「先读旧内容 → 轮询内容变化」判定新报告。
  - 报告带 `runTime=` 行，用于区分旧报告文件。
- 真实入口存活：`enterEntryAsync({fileName='init.ts'})` + 多次 `getEntryStatus().running` + `stopEntry()`。
- 视觉：`previewGame({entry='init.ts', captureAtSeconds={0.7}})` → 图片写入 `.agent/vision/`，再用 `analyze_image` 看。视觉预算有限（captureFrames/analysisRequests），且 analyze_image 的几何判断不可靠，需与代码几何核对。**本会话无 analyze_image 工具，视觉验证只能记 not_run。** 注意：掉落/扫光等需输入触发的动画，静态抓帧抓不到，抓帧只用于确认布局未坏与渲染循环存活。
- 引擎日志：`read_file @dora_full_logs.txt`（含 Lua 堆栈，是定位运行时 assert 的最快路径）。已读全 159 行：无运行时 Lua 报错，仅历史 `lualib_bundle not found`、`Content.saveAsync should be run in a thread`、`failed to load file: "settings.txt"`、TS100037 警告与 CodingAgent 网络错误。
- 注意：`edit_file` 批量条目中 `old_str` 为空代表“重写整个文件”，必须在每个条目显式给 `path`，否则会覆盖默认文件（曾因此误覆盖 `PROGRESS.md`/`PROJECT_MEMORY.md`）。批量条目中 `old_str` 与 `new_str` 相同会被拒绝（报 “saved 1/2 operations”），需确保两者不同。
- 陷阱：TSTL 生成的 Lua 中只有 false/nil 为假，**空字符串为真值**（`if (!text)` 与 JS 语义不同）→ 判定文本缺失必须写成 `text === undefined || text === ''`（否则构建报 TS100037）。
- 陷阱：`Content.saveAsync/loadAsync` 必须在协程/线程中调用（否则 `tolua_embedded/Initialization.lua` assert 失败，报 “Content.saveAsync should be run in a thread”）→ 项目统一用同步 `Content.load/save/exist`。
- 陷阱：`grep_files` 的 `path` 与 `globs` 叠加过滤，`path="game"` + `globs=["game/*.ts"]` 返回 0 结果；用 `path="."` + globs。
- 自检含“主循环自检”段：直接调用 `Game.submitChain(cells)` 驱动完整结算/HUD/波次路径，并运行时调用 `toggleMode/cycleDifficulty/toggleHint`；报告写入 `.agent/test-results/m3.txt`（一次性，覆盖旧文件）。

### Files And Architecture

- `init.ts`：入口（自适应 + 棋盘 + 状态标签 + 单一 schedule）；`scene.schedule` 里再校正一次 `updateViewSize()`（返回 true 只执行一次）。
- `game/Config.ts`：全局数值常量（模式/难度/波次/链长下限/魔力上限/棋盘重排惩罚/约束重试次数/`NoticeY=150`/`BoardCenterY=-120`/`CellSize=104`）；飘字分道常量 `NoticeEnemyX=-190, NoticeEnemyY=176`（原 190 会让对敌飘字上浮终点 265.5 升进技能按钮区（下沿 264），M6 排版审计后下移到 176，终点 251）、`NoticePlayerX=190, NoticePlayerY=-430`、`NoticeSystemX=0, NoticeSystemY=-120`，受击反馈常量 `HitFlashDuration=0.24`、`PlayerHitTintAlpha=90`；`EliteHeavyBlockCells=2`；`Waves` 三波（第 3 波 `isElite:true, hp120, attack14, heavyAttack24, armor10, actionTurns2, actionSeconds3`）。
- `game/Effects.ts`（313 行）：`EffectKind`/`EffectTarget` 枚举、`EffectSpec` 严格三元组、`EffectRule`+`makeRule`+`resolveEffects`、`formatEffects`；执行层：`ActorState`/`BoardOps`/`EffectContext`、目标解析表、`effectHandlers` 表与 `executeEffects`。**`BoardOps` 现为 `shuffle()` / `blastLargestGroup(): number` / `blockCells(count): number`；`effectHandlers` 已含 `[EffectKind.BoardBlock]`（调 `context.board.blockCells(spec.value)`）。`makeSpec` 不在此文件导出（只在 Skills.ts 内部）。**
- `game/BlockDefs.ts`：方块注册表（纯数据：id/颜色/glyph/效果规则/`placeable`，含 `manaGain` 与不可放置「封锁」def）；`placeableCount()/isPlaceable()/lockedIndex()`；新增类型只改此文件。
- `game/Skills.ts`：技能注册表（纯数据：id/名称/魔力消耗/效果列表）；初版重排（20）与引爆（35）；内部有 `makeSpec` 辅助。
- `game/Settings.ts`：设置存档（key=value 文本，同步 `Content.load/save`，`saved` 标记 + 失败回退内存态）。
- `game/Combat.ts`（约 257 行）：战斗状态（玩家/敌人 `ActorState`）、`applySpecs`、`useSkill(id)`、`availableSkills()`、`ensureBoardPlayable()`、实时秒级倒计时。**新增 `EnemyAction` 枚举（`Attack/Charge/Heavy`）、`charged`/`lastAction` 字段、`isCharged`/`lastEnemyAction` getter；`enemyAct()` 精英先蓄力（0 伤害）再重击（`heavyAttack × difficultyScale × stageEnemyScale` + `applySpecs([{kind:EffectKind.BoardBlock, value:Config.EliteHeavyBlockCells, target:EffectTarget.Board}])`）；`loadWave()` 复位蓄力状态。**
- `game/Board.ts`（约 634 行）：棋盘纯逻辑（生成、C1/C2 约束、连通统计、消除/塌落/补充、`isPlayable`/`reset`/`shuffle`/`largestGroupCells`/`blastLargestGroup`/`blockCells`、告警计数）；`collapse()` 记录 `collapseMoves`/`collapseSpawns`。**`largestGroupCells()` 已过滤 `BlockDefs.isPlaceable`；新增 `blockCells(count)`（从最大可放置连通块取格，逐格试锁 + `isPlayable()` 校验 + 失败回滚）。**
- `game/ui/Widget.ts`：`BaseWidget`（尺寸/锚点/visible/enabled/selected/redraw/触控钩子/`update(dt)`）+ `colorFromHex`；`readonly root` 公开；`shake(duration=0.24, amplitude=5)` + `advanceShake(dt)`。
- `game/ui/BlockWidget.ts`：通用方块控件（只读 `BlockDef`，无类型分支，`setDef`/`setLocked(on)`，locked 时填充 alpha=130）；`lighten(hex, ratio)`；选中白色 6px 描边。
- `game/ui/Controls.ts`：`PanelWidget`/`BarWidget`/`ButtonWidget`/`FloatTextWidget` 与 `makeLabel`（控件不注册 schedule）。`BarWidget` 有 `shownRatio` 缓动 + `flash(hex,duration)` + `advanceShake`；描边显式 `Color(0,0,0,0)`。`ButtonWidget` 按下缩放 + `glow()`。`FloatTextWidget` 向上飘 46/s、1.2s 淡出。
- `game/Hud.ts`：HUD 与结算面板（血条/魔力条/行动倒计时/技能按钮/关卡波次/飘字/设置面板）；三车道 FIFO 飘字；`hitPlayer/hitEnemy`；`glowSkill(id)`；布局常量见 Config。
- `game/Game.ts`（约 327 行）：主控制器（唯一 `schedule` 循环）；`handleChain` 顺序 = applyChain → flashCleared → animateFall → refreshFromBoard；`handleSkill` 快照 diff + 扫光。**`enemyAct()` 按 `combat.lastEnemyAction` 分支播报（蓄力预告 / 重击伤害+封锁提示 / 普通出手）并 `view.refreshFromBoard()`；`handleWaveCleared()` 增 `board.reset()` + `view.refreshFromBoard()` 清锁。**
- `game/BoardView.ts`（约 579 行）：棋盘视图与手势；`flashLayer`(z=10)/`highlight`(z=11)/`pulseLayer`(z=12)；`animateFall/advanceFall/finishFall/fallOffset`；`skillCast(cells)`。**`refreshFromBoard()` 现调 `widget.setLocked(!BlockDefs.isPlaceable(index))`；`canFollow()` 要求 from/to 均可放置且类型相同；`appendCell()` 拒绝封锁格。`widgets` 仍为 private，**已新增公开访问器 `isLockedAt(flat): boolean`（越界 false）**。**
- `game/UiLayout.ts`（M6）：排版/配色唯一来源 —— `Palette`（HUD 配色）、`HudLayout`（字号阶梓 FontStage/FontName/FontLabel/FontNotice/FontSmall/FontPanelTitle、顶部信息区 Y、`HintY=-505`、`NoticeRise=56`、面板尺寸、各 `*MaxChars` 估宽）、`SafeBox`（HalfWidth/Height = 480/540）、`zoomFor(w,h)`、`visibleHalfExtent(w,h)`、`insideSafeBox(rect)`、`hudLayoutRects()`（返回 17 个 HUD/面板矩形）、`boardLayoutRect()`（7×104 以 `BoardCenterY` 为中心）。新增 HUD 元素时必须同步补 `hudLayoutRects()`。
- `game/Tests.ts`（约 538 行，self-check 280 项）：`runTests()`（纯逻辑自检）+ 夹具 `findPlayableChain`/`walkChainFrom`；段：13b 执行器路径、13c M5 封锁/蓄力/到期（14 条）、**13d M6 排版审计（45 条：12 种窗口安全区、`hudLayoutRects()` 逐个不越界、棋盘↔提示行/对敌飘字↔技能按钮/我方飘字↔提示行 3 条相邻性）**；import 需带 `{ HudLayout, SafeBox, boardLayoutRect, hudLayoutRects, insideSafeBox, visibleHalfExtent } from 'game/UiLayout'`。（封锁格/blockCells/isPlayable/最大连通块过滤/引爆后满格/精英蓄力→重击/换关复位/BoardBlock 已注册）**。
- `tests/Entry.ts`（约 402 行）：运行时自检入口（逻辑 + 视图交互 + 运行时链路 + 坐标探针 + 诊断）；报告写 `.agent/test-results/m3.txt`；断言 `formatEffects(result.specs).indexOf('物理伤害 16') === 0`（改 `formatEffects` 文本会破坏该断言）。**已补：封锁格交互断言（起点/途经不可）与封锁到期后视图 `isLockedAt` 全归零断言。**

### Decisions

- 功能本质 = 效果列表 `[{执行效果 kind, 执行数值 value, 执行对象 target}]`；持续回合等时间性质不进三元组（放 Config）。
- 扩展方式：注册表 + 纯数据；控件与执行器核心不得出现按类型/按 kind 的分支（执行器只查表分发）。**封锁块同样走 `EffectKind.BoardBlock` + `EffectTarget.Board`，Combat/Game 不写特例分支。**
- 有尺寸节点的子节点局部原点在矩形左下角，棋盘命中换算直接 `floor(local/CellSize)`。
- 棋盘约束：C1（同色连通块 ≤ MaxGroupSize=5，可放宽到 7）、C2（必须存在 ≥ MinChainLength 的可连线区域，硬约束）、C3（始终 7×7 满格）。仅当 `Board.isPlayable()` 为 false 才重排棋盘并惩罚玩家。**封锁格视为阻挡，`isPlayable()` 必须仍为 true。**
- 链长下限 = **2**；链长 2 基准值：物伤 10 / 法伤 9 / 治疗 7 / 状态 1 层 / 魔力 7。
- 魔力与技能：“消除提供魔力”数据驱动；技能 = 扣魔力 + 把 `effects` 交给同一个执行器；上限 `MaxMana = 100`。
- 棋盘可执行性兑底：每次“消除→塌落→补充”后校验 `board.isPlayable()`，不可执行则 `board.reset()` + 玩家扣 `BoardResetPenalty = 8` 生命；技能释放后同样调用 `ensureBoardPlayable()`。
- 棋盘子节点不注册 schedule；仅 `init.ts` 根节点一个 schedule。
- 自适应：`zoom = min(View.size.width / 960, View.size.height / 1080)`；拿不到 2D 摄像机时降级为 `scene.scaleX/scaleY`。**`Node` 没有 `scale` 属性。**
- 回合制节奏（M3）：每次有效消除 = 1 回合；敌人行动间隔取当前波次 `actionTurns`（波 1/2 = 3、波 3 = 2）；三波清完进下一关（敌人数值 ×1.25、玩家回复 30% 最大生命）；玩家 HP ≤ 0 → 结算面板可重开本关。
- 实时模式（M4）：`Combat.setRealtime(on)` 切换秒级行动条，间隔波 1/2/3 = 5.0/4.0/3.0 秒；切换模式/难度后 `Game.restart()` 重开本关。
- 设置项：模式（回合制/实时）、难度（休闲 0.8 / 标准 1.0 / 困难 1.3）、底部提示开关；存档文件名 `settings.txt`。
- 存档：同步 `Content.load/save`；失败回退内存态并提示“设置未保存”。
- 消除反馈：`BoardView.flashCleared(cells)` 隐藏被消除格控件 + 白色淡出闪光（0.22s，画进 `flashLayer`）；爆点与路径高亮用两个独立 DrawNode，爆点期间可继续拖动；闪光结束 `endFlash()` → `refreshFromBoard()`。
- 飘字分道（已实施）：三车道 —— 对敌 `(-190, 190)` 黄、我方受伤/治疗 `(190, -430)` 红/绿、系统提示 `(0, -120)`；每车道一个 `FloatTextWidget` + FIFO 队列。
- 受击动效（已实施）：`BarWidget.flash(hex, duration)` + `BaseWidget.shake()`；玩家受击额外全屏红闪 overlay（`z=-1`）。
- **渲染层约定**：`drawPolygon` 的 `fillColor` 默认白色 → 只描边必须显式传 `Color(0,0,0,0)`；爆点/高亮/技能扫光分别用 `flashLayer`(z=10)/`highlight`(z=11)/`pulseLayer`(z=12)。
- 技能动画（已实施并经用户实机确认）：`ButtonWidget` 按下缩放 + `glow()`；`BoardView.skillCast(cells)` 左→右扫光波；`Hud.glowSkill(id)`；`Game.handleSkill` 用棋盘前后快照 diff 决定扫光格子。
- **掉落动画（已实施）**：`Board.collapse()` 记录成对塌落轨迹与腾空格；`BoardView.animateFall/advanceFall` 缓出滑落（0.18s），新补充块从棋盘上方落入；`Game.handleChain` 在 `flashCleared` 后、`refreshFromBoard` 前调用；`press()` 抢操作时 `finishFall()` 立即归位。
- **M5 精英机制（本轮实现）**：仅第 3 波精英；首次行动 = 蓄力（0 伤害 + 预告），下一次行动 = 重击（`heavyAttack × 难度缩放` + 经执行器封锁 `EliteHeavyBlockCells=2` 格）；换波/换关/重开时 `board.reset()` 清锁；封锁格不可作为连线起点或途经格，且不计入最大连通块候选。
- **M5 封锁到期（本轮实现）**：`Config.LockDurationActions = 2`（封锁格经过 2 次敌人行动后自动恢复）；`Board.lockTimers`（与 cells 等长、`resetCells()` 清零）、`lockedCount()`、`lockTurnsAt(flat)`、`lastExpiredLocks`、`expireLocks(): number`（递减计时，到期格置 -1 后走标准 `refillRestore()`，因此恢复后 C1/C2/C3 自动成立，无特例逻辑）；`reset()` = `resetCells() + fill()`；`Combat.enemyAct()` 首行 `expiredLockCount = board.expireLocks()`（先推进旧锁，新下发封锁不会同回合被扣）；`Game.enemyAct()` 在 `refreshFromBoard()` 前播报「封锁自动解除 N 格」。测试：`game/Tests.ts` 13c 段（14 条）+ `tests/Entry.ts` 运行时段（+13 条，含到期后视图 `isLockedAt` 全 false）。
- 颜色 API 结论：`Color(r,g,b,a)` 分量 0-255、`drawPolygon(verts, fillColor?, borderWidth?, borderColor?)` 均按现有用法正确；`rgba(r,g,b,a)` 的 a 为 0-1（不同函数）。

### Known Issues

- 重力合流（消除后同色块跨空隙合并）可能让连通块超过放宽上限，仅按告警计数上报（`Board.limitWarningCount`），不作为硬约束；可能造出 8 连并持续到本局结束（无死局）。M6 需调参或增加定向拆分修复。
- 拖动高亮的视觉确认尚未人工完成，已由确定性交互自检（`view.press/move/release`）覆盖。
- 实时模式节奏参数需真人验证；设置面板点击流程未做视觉确认。
- HUD 排版审计（M6 已加）：`game/Tests.ts` 13d 段对 12 种窗口（含 0×0 未就绪）断言可见区 ≥ 960×1080、17 个 HUD 元素 + 棋盘不越界、以及棋盘↔提示行/对敌飘字↔技能按钮/我方飘字↔提示行 3 条相邻性。**“playerBar 可见且不被飘字矩形覆盖”仍未加**（现仅靠矩形级审计）；新增 HUD 元素记得同步 `hudLayoutRects()`。
- 视觉分析工具（analyze_image）对元素几何位置的判断不可靠，需与代码几何核对后再下结论；本会话该工具不可用，视觉验证记 not_run。
- `BoardView.widgets` 为 private → 已加公开访问器 `isLockedAt(flat)`，视图侧封锁断言可用。
- **M5 仅剩视觉/真人验收**：实现与自动化验证已完成（`build paths=['game','tests','init.ts']` → 14/14 + 1/1 + 1/1 无诊断；`.agent/test-results/m3.txt` 首行 passed：逻辑 235 / 交互 27 / 运行时 41 / 主循环 94，0 失败，含「封锁经 2 次敌人行动后自动恢复」）。未验：精英蓄力→重击与封锁变暗/到期恢复的实机观感与手感。