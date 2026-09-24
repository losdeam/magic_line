# Core Memory

## Core Memory

### User Preferences

- 用简体中文交流与命名 UI 文本。
- 无音频、无外部美术资源：全程序化绘制（DrawNode 几何块 + Label 文字）。
- 方块必须通过「通用控件 + 注册表扩展」构建，功能本质是效果列表 `[{执行效果, 执行数值, 执行对象}]`。
- 两种模式（回合制休闲策略 / 实时战斗爽）在设置中切换；先做共享棋盘 + 回合制 MVP，再叠加实时模式。
- 不限制玩家滑动长度，由玩家自行取舍消除哪些方块，并预留连续方块区域应对敌方突发。
- 消除的动态效果（爆点、飘字、血条过渡等）需要完善，属于明确诉求。
- 伤害飘字与受伤飘字不能同时叠在同一位置（需分道/错开，保证可读）；需要补充受击等动效（受击抖动/闪白等）。
- **实机反馈已复验通过**：血条颜色差异、消除爆点、技能扫光/按钮亮光三项用户确认「均已完成」；用户又确认「动效均实现了」。
- **M5 视觉/手感验收已通过**：用户回复「动效均可，继续执行下一步」→ 精英蓄力→重击、封锁格变暗、封锁角标「2」→「1」→自动解除、掉落动画等观感均被接受，M5 转 done。
- **方块下坠动画已实现**：`Board.collapse()` 记录 `collapseMoves`/`collapseSpawns`，`BoardView.animateFall/advanceFall` 让方块从旧格中心滑到自身格中心（0.18s 缓出，新补充块从棋盘上方落下），`Game.handleChain` 在 `flashCleared` 后调用；自检断言「中途位移 >1」「结束偏移 <0.01」。
- **封锁格剩余解除时间角标已实现并经用户实机确认**：右上角数字角标（= 剩余敌方行动次数），由 `Board.lockTurnsAt()` 数据驱动；剩 1 次转暖色。
- **后续诉求（未实现）**：希望构建**多种流派**而非仅有攻防 —— 玩家可自由配置方块的真实技能（如冰=减速敌人、盾=加甲等），提升策略性。需设计「可配置方块/技能 + 流派预设」的数据驱动方案（注册表已支持扩展，缺配置层与 UI）。
- **本轮最新诉求（已确认决策，实施中）**：改为**关卡制**并构建 4 个界面 —— 1) 游戏开始界面 2) 关卡选择界面 3) 技能配置界面 4) 方块功能配置界面；关卡选择界面需**逐波**查看对应敌人的技能与效果。同时把当前技能/方块的构建方式梳理为**通用控件模板**，并把「新增能力 / 新增方块」的流程**固化为项目 skill**（`.agent/skills/<skill-name>/SKILL.md`，YAML frontmatter 必含 name/description）。**核心逻辑诉求：连的方块越多效果越好，分阶段给予不同强化效果（链长阶段强化），提高策略性。**

### 本轮已确认的产品决策（ask_user 两轮，用户权威作答）

1. **关卡结构**：6 个手工配置关卡，线性解锁；通关后进入「无尽挑战」（沿用现有 ×1.25 递增）。每关沿用「3 波小怪 + 关底精英」，敌人数值与技能在数据表逐关配置。
2. **结算与解锁**：顺序解锁，进度写入存档（重开游戏保留）；胜利 → 解锁下一关并返回关卡选择界面；失败 → 结算面板给「重试本关」与「返回关卡选择」。
3. **链长阶段**：4 档 —— 2–3 / 4–5 / 6–7 / ≥8。
4. **阶段强化形式**（多选全中）：数值倍率阶梯（每档提升该次结算倍率）+ 追加效果条目（高档位追加额外效果）+ 资源奖励（每上一档回赠额外魔力）+ HUD 显示「下一档还差几块」预告；**额外要求：滑动过程中要直观看到当前已连了几块**。
5. **技能配置**：**3 个上阵槽**，从技能库中选择（现有技能仅 2 个 → 需扩充技能池）；界面展示消耗与效果；战斗内只显示已装备技能。
6. **方块功能配置**：**图鉴**（展示每种方块「链长 → 各阶段效果」完整表格）+ **开关**（可启用/禁用方块，禁用后不再出现在棋盘）。**标准牌组槽位 = 4 种（沿用现有 4 种方块，不新增第 5 种）**；若启用数量少于标准数量，空余位置用**「空白方块」占位**（无任何特殊效果、仅占位，防止只选一种方块随意连线），并需对玩家做提示。默认 4 种全启用 → 无空白，仅当玩家关闭方块时才出现空白占位。
7. **敌人情报**：关卡选择界面**逐波列出**敌人名称、生命、攻击、技能名 + 效果数值文本 + 关键机制（蓄力重击伤害、封锁格数、行动间隔）。
8. **存档**：新增独立 `progress.txt` 保存关卡解锁 / 已选技能 / 方块开关，保留现有 `settings.txt`。
9. **敌方技能与特性池**：构建**敌方技能池**（小怪也可携带技能）+ **特性池**（如荆棘=反伤、自愈=回血等），各关组合不同。

### Stable Facts

- 设计分辨率基准高度 1080（摄像机 zoom = `min(View.size.width / 960, View.size.height / 1080)`），所有元素放 `Director.entry` 设计空间。**该取最小策略保证任何宽高比下至少 960×1080 设计单位可见（x∈[-480,480]、y∈[-540,540]），因此所有 HUD/棋盘元素必须落在该盒内。** 该公式已抽成 `game/UiLayout.ts` 的 `zoomFor(viewWidth, viewHeight)`（含 width/height<1 时回退设计尺寸、scale<0.05 时钳到 0.05 的兜底），`init.ts` 已改为调用它；`visibleHalfExtent(w,h)` 返回实际可见半宽/半高。
- 有尺寸节点的子节点局部原点在矩形左下角（已实测：`size=(200,100)`、`anchor=(0.5,0.5)`、`position=(0,0)` 时 `convertToWorldSpace(Vec2(0,0)) = (-100,-50)`）。
- 节点手势：`touchEnabled = true` 后触发 `onTapBegan/onTapMoved/onTapEnded`；`Touch.location` 为节点本地坐标；鼠标拖拽同样触发。
- 一个节点只有一个 `schedule` 槽；控件不注册 schedule，由根循环统一 `update(dt)`。
- **`Content.saveAsync/loadAsync` 必须在协程/线程中调用**（否则 `tolua_embedded/Initialization.lua:364` assert 失败）；同步版本 `Content.load(filename): string`、`Content.save(filename, content): boolean`、`Content.exist(filename): boolean` 可直接调用。
- **命令沙箱（execute_command 的 Lua 模式）的 Content 只接受项目相对路径字符串，且无 searchPaths/remove/mkdir/写**：`Content:exist(".agent/test-results/m3.txt")` 可用；`Path(projectDir, ...)` 拼出的绝对路径会报 `Content path must stay inside projectDir`；`Content.searchPaths` 在沙箱里取值为 nil（`attempt to index a nil value (field 'searchPaths')`）、`Content:remove` 报 `attempt to call a nil value (method 'remove')`，均不可用。判定新报告 = `enterEntryAsync({fileName='tests/Entry.ts'})` → 先读旧内容 → 轮询 `Content:exist(".agent/test-results/m3.txt")` 且内容变化（含本轮新增断言文本）→ `Content:load` 相对路径 → `stopEntry()`。目录与文件由 TS 入口在引擎内创建。
- **TSTL 陷阱**：Lua 中只有 false/nil 为假，空字符串为真值，`if (!text)` 与 JS 语义不同，必须显式 `===` 比较（诊断 TS100037）。
- **TSTL 字符串拼接**：`'文本' + number` 会转译为 `.. tostring(number)`（已在 `tests/Entry.lua` 核实），因此 `'' + n` 可安全用于数字转字符串；但 `'文本' + n - 1` 会先拼成字符串再减 1 → NaN，必须写 `+ (n - 1) +`。
- `Node` 没有 `scale` 属性，只有 `scaleX/scaleY`。
- 同一父节点内子节点按 `z` 排序绘制；`z` 可为负（负值先绘制，即更靠底层）。
- **Dora 颜色 API 已核实**：`Color(r, g, b, a)` 的 r/g/b/a 均为 0-255；另有 `Color(argb: number)` 与 `Color("#RRGGBBAA")` 重载；**`rgba(r,g,b,a)` 是另一个函数，其 a 为 0-1，勿与 `Color` 混用**。
- **`DrawNode.drawPolygon(verts, fillColor?, borderWidth?, borderColor?)` 的 `fillColor` 默认是白色** → 传 `undefined`/省略填充色会得到**纯白填充**；要只画描边必须显式传全透明填充 `Color(0,0,0,0)`。`drawDot`/`drawSegment` 的颜色参数同样默认白色。
- **`Label.batched`（默认 true）只禁用 `label.getCharacter()`，不影响运行时改 `text`/`visible` 的渲染**（已查 Dora.d.ts 确认）。
- `BaseWidget` 公开 `readonly root: Node.Type`，因此可用 `widget.root.position` 读取控件当前位置。
- **`BlockWidget` 已具备 `setDef(def)`、`setLocked(on)`（locked 时填充 alpha=130）、`setLockTurns(turns)`、`badgeText` getter**；`drawSelf` 内无按类型分支；角标 Label 在构造时创建（`batched=true`、字号 `max(12, size*0.3)`、位置 `(size - size*0.24, size - size*0.24)`、默认隐藏），`drawSelf` 在 `locked && lockTurns>0` 时用 `drawDot` 画深色底盘（半径 `max(9, size*0.2)`，色 24,26,32,235）；绘制顺序 canvas → glyph → badge，角标文字叠在底盘之上。
- **`makeSpec` 未从 `game/Effects.ts` 导出**（只存在于 `game/Skills.ts` 内部）→ 其他模块构造效果三元组应直接写 `EffectSpec` 字面量 `{ kind, value, target }`。
- **`grep_files` 的 `path` 与 `globs` 会叠加过滤**：`path="game"` + `globs=["game/*.ts"]` 会返回 0 结果；应使用 `path="."` + `globs=["game/*.ts"]`。**本轮再次踩坑：`path="."` + `globs=["*.ts"]` 也返回 0 结果；改用 `path="game"`（不带 globs）才拿到 37 条命中。**
- **`edit_file` 大批量参数会在 max_output_tokens 处被截断**：一次提交 6 个操作（含 140 行全量重写）时返回 `saved 6/6 operations` 但警告截断 → 大批量编辑后必须立即重读受影响文件确认完整性，再 build。**已确认该截断真实造成过损坏**（`game/Board.ts` 的 `collapse()` 被截断成未闭合表达式，导致 30+ 条 TS 错误）。**本轮再次复现：提交 7 个操作（含 34 行新 enemyAct）时返回 `saved 7/7 operations` + 截断警告（仅 7 个操作被安全解码，Combat.ts 8084→9307 字节、300 行）→ 必须回读确认。**
- **`edit_file` 批量中单个操作失败会静默降级**：返回 `saved 2/3 operations` 时未保存的那条不报原因；常见原因是 `old_str` 与文件实际文本不完全一致 → 必须用 `grep_files`/`read_file` 取精确锚点后重做，并核对行数增量。**另注意：批量部分失败后可能出现重复行**，需回读并去重。**本轮再次出现 `saved 4/5 operations`（锚点已被前一轮更新过导致不匹配），但文件最终内容自洽、无重复行。**
- **`edit_file` 替换会吞掉锚点文本**：本轮把 `### 文件结构\n\n| 文件 | 职责 |` 当作锚点替换时未在新文本里保留该表头，导致表格失去标题行 → 替换锚点若包含结构标记（标题/表头），新文本必须原样保留它们。
- **`FloatTextWidget` 参数**：`new FloatTextWidget(fontSize)`，内部 `super(560, 40)`、`duration = 1.2`、每帧 `y += 46 * dt` → 总上升约 55 设计单位（`HudLayout.NoticeRise = 56`）；`show(text, hex, x, y)` 设置位置并重置生命。
- **项目 skill 规范（skill-creator，已读全文 146 行）**：项目技能必须放在 `.agent/skills/<skill-name>/SKILL.md`（入口文件名固定 `SKILL.md`，kebab-case 目录名），文件首部必须有 YAML frontmatter 且至少含 `name`、`description`（可选 `always: true`、`requiredTools: [...]`）；正文建议含 When to Use / Steps / Constraints / Output；缺 name 或 description 则项目不识别为有效 skill。**当前项目尚无 `.agent/skills` 目录（本轮再次用 glob 确认 0 条目）。**
- **Git 模式限制**：不支持 `git log --oneline`（报 unsupported log option），需用 `git log`；`git add <目录>` 可用；`git commit -m "..."` 可用；提交者身份为 `Dora <dora@example.com>`。
- **`read_file` 参数约束**：`startLine` 必须小于 `endLine`（`startLine=301` 且默认 endLine=300 会报 "resolved endLine 300 is before startLine 301"）；压缩恢复阶段会自动截取为第 1-160 行，需从 161 行继续窄读。**大文件（如 PLAN.md 403 行、Tests.ts 590 行）单次 read_file 会被截断到约 110-160 行，需按 startLine/endLine 分段窄读；只给 startLine 时 endLine 默认 300，若 startLine>300 会直接报错，必须显式给 endLine。**

### Known Decisions

- 棋盘 7×7；链长下限 2；同色连通块上限 5（可放宽到 7）。
- 战斗：关卡制，多波小怪 + 关底精英；玩家 HP 100；玩家血量为 0 即失败。
- 存档用同步 `Content.save/load`；失败时回退内存态并提示“设置未保存”。
- 飘字为**三车道 + 每车道 FIFO 队列**（对敌 / 我方受伤治疗 / 系统提示），车道位置互不重叠，同车道串行显示；已在 `game/Hud.ts` 落地，`Game.reportChain` 按车道路由。
- 受击动效：血条 `flash(hex, duration)` 闪白/闪红 + `shake()` 抖动；玩家受击额外叠加全屏红闪 overlay（`z=-1`）；已接线到 `Hud.hitPlayer/hitEnemy`。
- 实时模式：`Combat.setRealtime(on)` 切换秒级行动条，间隔波 1/2/3 = 5.0/4.0/3.0 秒；切换模式/难度后 `Game.restart()` 重开本关。
- **渲染层约定**：所有「只描边不填充」的 `drawPolygon` 必须显式传 `Color(0,0,0,0)`；消除爆点画进 `BoardView.flashLayer`(z=10)，路径高亮画进 `highlight`(z=11)，技能扫光画进 `pulseLayer`(z=12)，三者互不擦除。
- 技能动画：`ButtonWidget` 按下缩放 + `glow()` 亮光；`BoardView.skillCast(cells)` 左→右扫光波；`Hud.glowSkill(id)`；`Game.handleSkill` 用棋盘前后快照 diff 决定扫光格子。
- **掉落动画**：`Board.collapse()` 记录成对 `collapseMoves`（from→to flat）与 `collapseSpawns`（腾空格）；`BoardView.animateFall(moves, spawns)` 设置起始偏移，`advanceFall(dt)` 缓出插值滑到 0 并精确归位；`fallDuration=0.18s`；`press()` 会 `finishFall()` 立即归位；`Game.handleChain` 顺序 = applyChain → flashCleared → animateFall → refreshFromBoard。
- **M5 设计方向（已确定并实现）**：封锁块必须走同一套效果注册表/执行器（`EffectKind.BoardBlock` + `EffectTarget.Board`），禁止在 Combat/Game 写特例分支；`BoardOps` 接口需扩展封锁能力；`Board.isPlayable()` 必须把封锁格视为阻挡；精英蓄力重击仅第 3 波，提前 1 次行动预告、下一次行动结算（默认 24，按难度缩放）。
- **M5 执行侧已落地**：`game/Effects.ts` `BoardOps.blockCells(count)` + `effectHandlers[EffectKind.BoardBlock]`；`game/Board.ts` `largestGroupCells()` 过滤 `BlockDefs.isPlaceable`、新增 `blockCells(count)`（逐格试锁 + `isPlayable()` 校验 + 失败回滚）；`game/BoardView.ts` `refreshFromBoard()` 调 `setLocked`、`canFollow()`/`appendCell()` 拒绝封锁格、公开访问器 `isLockedAt(flat)`；`game/Combat.ts` `EnemyAction` 枚举 + `charged`/`lastAction` + 精英蓄力→重击（`heavyAttack × difficultyScale × stageEnemyScale` + 下发 `BoardBlock` 字面量）；`game/Game.ts` 按 `lastEnemyAction` 分支播报 + `handleWaveCleared()` 清锁。
- **M5 封锁到期自动恢复（已实现并验证）**：`Config.LockDurationActions = 2`；`Board.lockTimers`（与 cells 等长、`resetCells()` 清零）、`lockedCount()`、`lockTurnsAt(flat)`、`lastExpiredLocks`、`expireLocks(): number`（递减计时，到期格置 -1 后调用标准 `refillRestore()`，因此恢复后 C1/C2/C3 自动成立，无特例逻辑）；`reset()` = `resetCells() + fill()`；`Combat.enemyAct()` 首行 `expiredLockCount = board.expireLocks()`（先推进旧锁再施加新锁）；`Game.enemyAct()` 在 `refreshFromBoard()` 前播报「封锁自动解除 N 格」（System 车道 0x9fd6ff）。
- **M5 封锁剩余次数角标（已实现、自动化验证并经用户实机确认）**：`BlockWidget` 右上角 badge Label（默认隐藏），`setLockTurns(turns)` 更新数字（`lockTurns<=1` 转红 255,156,120，否则琥珀 255,214,120），`drawSelf` 在 `locked && lockTurns>0` 时画深色底盘（24,26,32,235），`setLocked(false)` 收起角标，`badgeText` getter 供自检；`BoardView.refreshFromBoard()` 调 `widget.setLockTurns(widget.locked ? this.board.lockTurnsAt(flat) : 0)`，公开访问器 `lockTurnsLabelAt(flat): string`。数字语义 = 剩余敌方行动次数。自检正面证据行：「M5 封锁角标：封锁 2 格，剩余次数「2」→「1」→到期恢复后「」；到期后视图锁定格 0 个」。
- **M6 排版/配色统一（已完成，排版审计通过）**：`game/UiLayout.ts` 是 HUD/棋盘坐标、字号、配色的唯一来源 —— `SafeBox`（HalfWidth=480/HalfHeight=540）、`zoomFor`/`visibleHalfExtent`、`insideSafeBox(rect)`、`Palette`（EnemyBar/PlayerBar/ManaBar/TimerBar/ButtonPrimary/ButtonNeutral/PanelBackground/NoticeDefault/NoticeDamage/HitFlash*/TextOk/TextWarn）、`HudLayout`（字号阶梯 FontStage=24/FontName=28/FontLabel=22/FontNotice=26/FontSmall=20/FontPanelTitle=34/FontPanelTitleLarge=40；顶部信息区 Y 阶梯 StageY=508/EnemyNameY=480/EnemyBarY=448/TimerBarY=428/TimerLabelY=412/PlayerBarY=372/ManaBarY=340/SkillButtonY=292；SettingsButtonX=370/Y=492；HintY=-505；`NoticeRise=56`；设置面板 560×420 与结算面板 640×360 的行坐标）、`LayoutRect` + `hudLayoutRects()`（17 个 HUD/面板矩形，文本宽度按 `*MaxChars` 显式估算，避免 Lua `#str` 按字节计数的坑）+ `boardLayoutRect()`（7×104 以 `BoardCenterY` 为中心）。**新增 HUD 元素必须同步补 `hudLayoutRects()`。** `init.ts` 已改用 `zoomFor`；`game/Hud.ts` 已全面改用 HudLayout/Palette。**注意：StageY 由 522 下调到 508、SettingsButtonY 由 505 下调到 492**（原值在极端宽高比下距安全盒上边界仅 1 单位）。
- **M6 极端宽高比审计（已实现并验证）**：`game/Tests.ts` 13d 段 45 条断言 —— 12 种窗口（5120×1440 … 600×1040、含 0×0 未就绪）断言最小可见区 ≥ 960×1080；17 个 HUD/面板元素 + 棋盘逐个 `insideSafeBox`；3 条相邻性（棋盘底边 -484 ↔ 提示行上沿 -489、对敌飘字上浮终点 ↔ 技能按钮下沿 264、我方飘字下沿 ↔ 提示行）。**审计首次即暴露真实越界：`Config.NoticeEnemyY = 190` 时对敌飘字上浮终点 265.5 升进技能按钮区（下沿 264）→ 已下移到 176（终点 251，余量 12.5）。**
- **Git 提交基线（已完成）**：仓库此前无任何提交、无 `.gitignore`。提交 1 `c744003`「初始化连线消除战斗游戏：7x7 棋盘连线/效果执行器/双模式战斗/设置持久化/自检」= 34 文件（`init.ts`/`init.lua` + `game/**` 与 `tests/**` 的 TS 源与生成 Lua）。提交 2 `4d525b9`「补充 Agent 工作文档（AGENT.md/计划/记忆）并忽略抓帧与自检产物」= 9 文件（`.gitignore`、`.agent/AGENT.md`、`.agent/plan/PLAN.md`、`.agent/plan/PROGRESS.md`、`.agent/main/{MEMORY.md, PROJECT_MEMORY.md, SESSION_SUMMARY.md, HISTORY.jsonl, SESSION.jsonl}`）。`.gitignore` 内容 = `.agent/vision/` + `.agent/test-results/`。**`.agent/main/SESSION.jsonl` 是引擎每轮追加的会话尾巴，会长期显示 worktree M，属预期、非代码改动。**
- **关卡制改造计划（已定稿并复核，实施中）**：PLAN.md 新增 M8–M13 —— M8 关卡与敌人技能数据化（`game/Levels.ts` 的 `LevelDef`/`WaveDef`/`EnemySkillDef`；`Combat.enemyAct()` 去掉 `isElite` 硬编码，改为按 `wave.skills` 轮转并经同一执行器下发 `BoardBlock`；保留 M5 已验收时序作为断言基准）；M9 分阶段强化（`game/ChainTiers.ts` 四档 2-3 ×1.0 / 4-5 ×1.25 / 6-7 ×1.6 / 8+ ×2.1，严格单调；`EffectRule` 新增 `scaled: boolean`，`manaGain` 设 false 不受倍率影响；「阶段解锁额外效果」复用现有 `minChain` 阈值对齐 4/6/8；解析器内不得出现 `kind === ...` 分支）；M10 屏幕管理 + 开始界面 + 关卡选择（`game/App.ts` 屏幕容器 + 唯一 schedule 循环、`game/screens/{TitleScreen,LevelSelectScreen}.ts`、`init.ts` 改为 `new App()`；屏幕切换只改 `visible` 与触控开关）；M11 技能池扩充 + 3 装备槽 + 技能配置界面（`Combat.availableSkills()` 只按传入装备 id 列表返回，不直读设置）；M12 方块功能配置界面 + 启停（`BlockDefs.activeIndices(disabledIds)`，`Board` 所有枚举点改用活跃类型列表，UI 至少保留 2 种启用，非法配置回退默认）；M13 通用模板与工程 skill 固化（`.agent/skills/new-block-and-effect/SKILL.md`，须遵循 skill-creator 约定：`.agent/skills/<name>/SKILL.md` + 非空 `name`/`description` frontmatter）+ 扩展性验收（原 M7 归入）。新增风险 R12–R17（不可见屏幕抢触控、关卡数值漂移、倍率膨胀、禁用方块致死局、新屏幕排版越界、敌人技能数据化回归）。进度字段并入 `game/Settings.ts`（`cleared`/`equipped`/`disabledBlocks`），不新建 Progress 模块。**复核确认计划无遗漏、无事实偏差：`Combat.enemyAct()` 确有 `wave.isElite` 硬编码分支、`EffectRule` 现为 6 字段（kind/target/base/perBlock/minChain/floorTo）、`Settings` 现仅 mode/difficulty/showHint、`.agent/skills/` 尚不存在；`BlockDef` 实有 `placeable` 字段（封锁格 false）。**
- **M8 数据模型（已定稿并实现）**：`EnemySkillDef { id, name, damage, effects: EffectSpec[], preparesNext: boolean, cooldownActions: number }`（**相对 PLAN 原文新增 `damage` 字段**：敌方伤害需按难度/关卡缩放，而 handler 无难度上下文，若把伤害做成效果会迫使 Combat 按 kind 特判，违反「无 kind 分支」约束；`effects` 仍交统一执行器，重击的封锁仍走 `BoardBlock`）；`WaveDef { name, hp, attack, armor, isElite, actionTurns, actionSeconds, skills: EnemySkillDef[] }`（**去掉 `heavyAttack`，重击改为技能数据**）；`LevelDef { id, name, subtitle, waves: WaveDef[] }`。6 关数据写在 `game/Levels.ts`（纯数据），逐关引入新机制（第 1 关仅普攻 → 第 3 关首次封锁 → 第 5/6 关双精英/高频）；无尽挑战 = 复用最后一关 `waves` + 每轮 ×1.25。`Levels.Default` 由 `Config.Waves` 数值构造（精英技能 = 普攻 + 蓄力重击），使 `new Combat(new Board())` 保持 M5 行为与既有测试通过。**迁移约束：关卡表默认关数值必须等于现有 `Config.Waves`（hp 40/60/120、attack 8/10/14、重击 24、armor 4/6/10、actionTurns 3/3/2、actionSeconds 5/4/3），自检以字面量锁定该等式。** `Combat` 构造改为 `(board, level?)`，`waveCount` 改为 `level.waves.length`；`EnemyAction` 改为 `Attack/Prepare/Release` 并由 `Game` 用技能名播报（不再硬编码「精英」文案）。关卡选择预览用 `formatEffects(skill.effects)` + `preparesNext` 的「蓄力」+ `actionTurns/actionSeconds` 的「行动间隔」，预览与实际共用同一数据源。
- **M8 实施（已完成并验证）**：`game/Levels.ts`（226 行，含 `makeSkill/makeWave/blockSpec/buildDefaultLevel/buildLevels` 与 `Levels.Default/List/EndlessBase/get/waveOf/skillOf/fallbackSkill`）；`game/Combat.ts`（336 行）导入 `{ LevelDef, Levels, EnemySkillDef, WaveDef }`，`EnemyAction` = `Attack/Prepare/Release`，字段 `level`/`prepared`（待释放技能下标，-1 无）/`cooldowns`（与当前波技能等长）/`skillCursor`/`lastSkill`/`newLocks`/`expiredLockCount`，构造 `(board, level?)` 默认 `Levels.Default`，`waveCount` = `level.waves.length`，`levelDef` getter，`currentWave()` = `Levels.waveOf(level, waveIndex)`，`enemyInterval/enemyIntervalSeconds` 读 `currentWave()`，`loadWave()` 复位 `prepared=-1`/`skillCursor=0`/`cooldowns` 全 0，`isPreparing`（`prepared>=0`），`lastSkillName`/`lastNewLocks` getter；`enemyAct()` 顺序 = `expireLocks()` → 递减全部冷却 → 若 `prepared>=0` 则 Release（清 prepared、写回 `cooldowns[index]=skill.cooldownActions`）否则 `pickSkill` 且 `preparesNext` 则 Prepare（只预告、返回 0、不结算效果与伤害）→ 非 Prepare 时 `applySpecs(skill.effects)` 并 `applyDamage(skill.damage × difficultyScale × stageEnemyScale)`，`newLocks` 由 `board.lockedCount()` 前后差得出（无 kind 分支）；私有 `pickSkill(wave)`（从 cursor 轮转取首个冷却 ≤0 的技能，全冷却返回 -1，退回 `Levels.fallbackSkill`）；`advanceWave()` 用 `this.waveCount`。`game/Game.ts` `enemyAct()` 按 `lastEnemyAction` 分道播报（Prepare → Enemy 车道「敌方蓄力「技能名」— 下次行动释放」；Release → `hitPlayer` + 「敌方「技能名」−伤害，封锁 N 格」；否则普攻走 System 车道），`lastExpiredLocks>0` 时播报「封锁自动解除 N 格」。`game/Tests.ts` 已用 `EnemyAction.Prepare/Release` + `isPreparing`，新增 M8 断言（默认关卡数值逐项等于 `Config.Waves`、第 3 关第 2 波「封锁击」先预告后释放、轮转覆盖、`Levels.get(999)` 回退第 1 关、`Levels.skillOf(...,999).id==='strike'`）。`tests/Entry.ts` 不引用 EnemyAction 成员，无需改。

# Core Memory