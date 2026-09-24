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

### Stable Facts

- 设计分辨率基准高度 1080（摄像机 zoom = `min(View.size.width / 960, View.size.height / 1080)`），所有元素放 `Director.entry` 设计空间。**该取最小策略保证任何宽高比下至少 960×1080 设计单位可见（x∈[-480,480]、y∈[-540,540]），因此所有 HUD/棋盘元素必须落在该盒内。** 该公式已抽成 `game/UiLayout.ts` 的 `zoomFor(viewWidth, viewHeight)`（含 width/height<1 时回退设计尺寸、scale<0.05 时钳到 0.05 的兜底），`init.ts` 已改为调用它；`visibleHalfExtent(w,h)` 返回实际可见半宽/半高。
- 有尺寸节点的子节点局部原点在矩形左下角（已实测：`size=(200,100)`、`anchor=(0.5,0.5)`、`position=(0,0)` 时 `convertToWorldSpace(Vec2(0,0)) = (-100,-50)`）。
- 节点手势：`touchEnabled = true` 后触发 `onTapBegan/onTapMoved/onTapEnded`；`Touch.location` 为节点本地坐标；鼠标拖拽同样触发。
- 一个节点只有一个 `schedule` 槽；控件不注册 schedule，由根循环统一 `update(dt)`。
- **`Content.saveAsync/loadAsync` 必须在协程/线程中调用**（否则 `tolua_embedded/Initialization.lua:364` assert 失败）；同步版本 `Content.load(filename): string`、`Content.save(filename, content): boolean`、`Content.exist(filename): boolean` 可直接调用。
- **命令沙箱（execute_command 的 Lua 模式）的 Content 只接受项目相对路径字符串，且无 mkdir/remove/写**：`Content:exist(".agent/test-results/m3.txt")` 可用；`Path(projectDir, ...)` 拼出的绝对路径会报 `Content path must stay inside projectDir`（本轮再次复现）；`Content:remove/mkdir/save` 不可用（`Content.searchPaths` 在沙箱里取值为 nil，勿用）。判定新报告 = `enterEntryAsync({fileName='tests/Entry.ts'})` → 轮询 `Content:exist(".agent/test-results/m3.txt")` 且内容变化（含本轮新增断言文本）→ `Content:load` 相对路径 → `stopEntry()`。目录与文件由 TS 入口在引擎内创建。
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
- **`grep_files` 的 `path` 与 `globs` 会叠加过滤**：`path="game"` + `globs=["game/*.ts"]` 会返回 0 结果；应使用 `path="."` + `globs=["game/*.ts"]`。
- **`edit_file` 大批量参数会在 max_output_tokens 处被截断**：一次提交 6 个操作（含 140 行全量重写）时返回 `saved 6/6 operations` 但警告截断 → 大批量编辑后必须立即重读受影响文件确认完整性，再 build。**已确认该截断真实造成过损坏**（`game/Board.ts` 的 `collapse()` 被截断成未闭合表达式，导致 30+ 条 TS 错误）。
- **`edit_file` 批量中单个操作失败会静默降级**：返回 `saved 2/3 operations` 时未保存的那条不报原因；常见原因是 `old_str` 与文件实际文本不完全一致（曾把「运行时自检」误写成「版本自检」导致 3/4）→ 必须用 `grep_files`/`read_file` 取精确锚点后重做，并核对行数增量。**另注意：批量部分失败后可能出现重复行**（曾出现两条「构建（本轮）」），需回读并去重。**本轮再次出现 `saved 4/5 operations`（锚点已被前一轮更新过导致不匹配），但文件最终内容自洽、无重复行。**
- **`FloatTextWidget` 参数**：`new FloatTextWidget(fontSize)`，内部 `super(560, 40)`、`duration = 1.2`、每帧 `y += 46 * dt` → 总上升约 55 设计单位（`HudLayout.NoticeRise = 56`）；`show(text, hex, x, y)` 设置位置并重置生命。

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
- **M6 排版/配色统一（进行中，排版审计已完成）**：`game/UiLayout.ts` 是 HUD/棋盘坐标、字号、配色的唯一来源 —— `SafeBox`（HalfWidth=480/HalfHeight=540）、`zoomFor`/`visibleHalfExtent`、`insideSafeBox(rect)`、`Palette`（EnemyBar/PlayerBar/ManaBar/TimerBar/ButtonPrimary/ButtonNeutral/PanelBackground/NoticeDefault/NoticeDamage/HitFlash*/TextOk/TextWarn）、`HudLayout`（字号阶梯 FontStage=24/FontName=28/FontLabel=22/FontNotice=26/FontSmall=20/FontPanelTitle=34/FontPanelTitleLarge=40；顶部信息区 Y 阶梯 StageY=508/EnemyNameY=480/EnemyBarY=448/TimerBarY=428/TimerLabelY=412/PlayerBarY=372/ManaBarY=340/SkillButtonY=292；SettingsButtonX=370/Y=492；HintY=-505；`NoticeRise=56`；设置面板 560×420 与结算面板 640×360 的行坐标）、`LayoutRect` + `hudLayoutRects()`（17 个 HUD/面板矩形，文本宽度按 `*MaxChars` 显式估算，避免 Lua `#str` 按字节计数的坑）+ `boardLayoutRect()`（7×104 以 `BoardCenterY` 为中心）。**新增 HUD 元素必须同步补 `hudLayoutRects()`。** `init.ts` 已改用 `zoomFor`；`game/Hud.ts` 已全面改用 HudLayout/Palette。**注意：StageY 由 522 下调到 508、SettingsButtonY 由 505 下调到 492**（原值在极端宽高比下距安全盒上边界仅 1 单位）。
- **M6 极端宽高比审计（已实现并验证）**：`game/Tests.ts` 13d 段 45 条断言 —— 12 种窗口（5120×1440 … 600×1040、含 0×0 未就绪）断言最小可见区 ≥ 960×1080；17 个 HUD/面板元素 + 棋盘逐个 `insideSafeBox`；3 条相邻性（棋盘底边 -484 ↔ 提示行上沿 -489、对敌飘字上浮终点 ↔ 技能按钮下沿 264、我方飘字下沿 ↔ 提示行）。**审计首次即暴露真实越界：`Config.NoticeEnemyY = 190` 时对敌飘字上浮终点 265.5 升进技能按钮区（下沿 264）→ 已下移到 176（终点 251，余量 12.5）。**

### Known Issues

- build 偶发 “TypeScript transpiler is not ready”，重试即可。
- 重力合流可造出超过放宽上限（7）的同色块并长期存在（无死局），待 M6 调参或定向拆分修复。
- HUD 布局自检断言（playerBar 可见且不被可见飘字矩形覆盖）尚未加；极端宽高比下的布局边界自检**已加**（`game/Tests.ts` 13d 段）。
- 视觉分析（analyze_image）对元素几何位置的判断不可靠，需与代码几何核对；**本会话该工具不可用**，视觉验证只能记 not_run（可抓帧留 PNG 给用户看）。
- **`spawn_sub_agent` 调用失败（已复现两次）**：返回 `{"message":"sub agent prompt is empty","success":false}` → 该工具在本环境不可用，勿再重试。
- **`edit_file` 大批量编辑可能被 max_output_tokens 截断并静默损坏文件** → 大批量编辑后必须重读文件 + 立即 build。
- **`edit_file` 批量中失败的操作只体现在 `saved N/M operations` 计数上**，不给出原因 → 用行数增量与 grep 复核，锚点必须逐字精确；部分失败后可能残留重复行，需去重。
- **命令沙箱 Content 无写能力** → 判定新报告用「相对路径轮询 + 匹配本轮新增断言文本」。
- **自检夹具易受随机棋盘影响**：`blockCells(2)` 可能选出相邻两格，凡「取封锁格邻格」的夹具必须动态挑非封锁邻格（已修 `tests/Entry.ts`）。
- 飘字车道位置（对敌 y=176、我方 y=-430）实际落在棋盘矩形内（棋盘 y∈[-484,244]），飘字会叠在方块之上；尚未判定是否为观感问题，待用户目视。