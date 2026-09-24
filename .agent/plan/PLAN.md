# 开发方案：连线消除战斗游戏

## 目标

在 Dora SSR 工程中从零实现一款“连线消除 + 战斗”游戏：玩家按住并滑过相邻同色方块形成连线，松手统一结算，把连线转化为物攻／法攻／状态／治疗四类效果对抗敌人；同一套棋盘与战斗内核支持两种模式（回合制休闲策略 / 实时战斗爽），可在设置中切换并持久化。

## 背景与当前实现

- 工程为全新空工程：仅 `init.ts`（4 行，`import {} from 'Dora';` 后为空），无任何美术、音频、脚本模块或测试。
- `.agent/plan`、`.agent/main` 均为空模板，无历史约束。
- 目标平台：PC 鼠标 + 移动端触控；资源策略：全程序化绘制（`DrawNode` + `Label`），无音频。

已查证的 Dora 能力（实施时可直接使用，无需重复搜索）：

| 能力 | 证据（已确认签名/说明） |
| --- | --- |
| 手势输入 | `node.touchEnabled = true` 后触发 `onTapBegan/onTapMoved/onTapEnded/onTapped`；插槽名 `TapBegan/TapMoved/TapEnded/Tapped`；`Touch` 类注释为“代表触摸输入或鼠标点击事件的类”，即鼠标拖拽同样触发 |
| Touch 字段 | `id`、`first`、`delta: Vec2`、`location`（节点本地坐标）、`viewLocation`、`worldLocation` |
| 鼠标 | `Mouse.leftButtonPressed` 等只读状态（本方案优先用节点手势，不依赖它） |
| 绘制/文本 | `DrawNode.drawPolygon/drawDot/drawSegment`（无 `drawRect`）、`Label(font, size)` 可能返回 `undefined` 需判空 |
| 存档 | `Content.loadAsync(filename): string`、`Content.saveAsync(filename, content): boolean` |
| 自适应 | `Director.currentCamera` + `tolua.cast(..., TypeName.Camera2D)` 设 `camera.zoom = View.size.height / DesignSceneHeight`；`Director.entry.onAppChange(name => name === 'Size')` 监听尺寸变化（来源 `@dora-doc/dora-tutorial/ts/adapting-to-screen.md`） |
| UI 布局备选 | `AlignNode(true)` + `css()`（Yoga Flex），用于复杂面板时再引入 |

## 范围

### 包含

- 7×7 棋盘系统：生成、连线选择、消除、重力塌落、顶部补充，以及“最大连通块规模”约束与“至少存在可连线区域”的兜底保证。
- 四类方块：物攻、法攻、状态、治疗，各有颜色与文字标识，连线转化为战斗效果。
- 通用化架构：方块由「注册表纯数据定义 + 通用方块控件」构建；功能本质是效果列表 `[{执行效果 kind, 执行数值 value, 执行对象 target}]`；新增方块类型只加一条注册表数据，新增效果种类只注册一条 handler。
- 战斗内核：玩家/敌人血量、护盾、增伤与减益层数、伤害/治疗公式、敌人行动条、波次推进、失败与重开结算。
- 双模式：回合制（敌人按“回合”行动）与实时模式（敌人按秒倒计时行动），共享棋盘与战斗内核，仅时间源与节奏参数不同。
- 设置：模式切换、难度、提示开关，使用 `Content.saveAsync/loadAsync` 持久化。
- 自动自检模块（`game/Tests.ts` 导出 `runTests()`，报告首行为 `passed`/`failed`），覆盖棋盘不变量、公式、行动时点、胜负切换、设置读写。

### 不包含

- 音频与音效（用户已明确选择无音频）。
- 外部贴图/美术资源、粒子与特效系统、骨骼或帧动画。
- 自动连锁（cascade）二次消除：初版不做，避免与“玩家自行取舍、预留连续区域”的设计冲突；列为后续可选机制。
- 必杀技槽（问卷未选）、无尽模式、Boss 多阶段、多语言、联网与排行榜。

## 已确认决策

- 交互：按住并滑过【相邻】同色块形成连线，松手统一结算；不限制玩家滑动长度，由玩家自行决策消除哪些方块，并预留连续方块区域应对敌方突发情况。
- 棋盘规格：7×7。
- 战斗结构：关卡制，多波小怪 + 关底精英；玩家有血、敌人有血，玩家血量为 0 即失败。
- 第一版系统：血量与伤害结算、敌人行动计时条、连线长度→效果强度换算、状态块增益/减益、治疗块、关卡/波次推进与胜负结算重开、设置界面与存档持久化；必杀技槽不在第一版。
- 交付顺序：先做共享棋盘 + 回合制 MVP 跑通，再叠加实时/战斗爽模式。
- 平台与输入：PC 鼠标 + 移动端触控（使用节点手势插槽，天然同时覆盖两者）。
- 资源：全部程序化绘制，无音频。
- 控件架构：方块做成通用控件，并建立一套轻量控件基类供所有 UI 元素（方块/面板/按钮/血条/飘字）复用。
- 扩展机制：注册表 + 纯数据配置；方块定义与效果条目均为纯数据，引擎侧查表解析，控件与执行器核心不含按类型分支。
- 效果模型（功能本质）：一次连线的结算产物是效果列表 `[{执行效果 kind, 执行数值 value, 执行对象 target}]`；`target` 初版含 玩家自身 / 当前敌人 / 全体敌人 / 棋盘本身，另留一个未实现的预留枚举位；`kind` 初版含 物理伤害 / 魔法伤害 / 治疗 / 净化 / 护盾 / 增伤 buff / 破甲 debuff / 棋盘效果。
- 魔力与技能（本轮新增）：消除按「链长 → 魔力值」提供魔力（数据驱动：每种方块带一条 `manaGain` 规则）；魔力用于释放技能；技能用于应对难以消除的局面（初版：重排棋盘、引爆最大连通块）。
- 棋盘可执行性（本轮新增）：每次消除与补充后校验棋盘是否存在 ≥ `MinChainLength` 的可连线区域；若不可执行，则触发事件直接重排棋盘，并对玩家施加惩罚（扣除生命）。
- 链长下限改为 **2**（只要 ≥2 个同色连通块即可消除）；链长 ≥5 的额外效果保持不变。
- 人工验收：M1/M2 的拖动高亮与松手后棋盘变化已由用户实际点按确认通过。

## 待确认问题

无

## 技术方案

### 坐标系与布局

- 设计基准高度 `DesignSceneHeight = 1080`，通过 2D 摄像机 `zoom = View.size.height / DesignSceneHeight` 适配；`onAppChange('Size')` 时重算。
- 棋盘、HUD、面板全部放在 `Director.entry` 的设计空间内（屏幕中心为原点、+X 右、+Y 上），避免“场景用设计单位、UI 用像素单位”两套缩放混用。
- 棋盘容器是一个【有尺寸】的 `Node`：`size = (7*Cell, 7*Cell)`，`anchor = Vec2(0.5, 0.5)`，位置在屏幕中偏下（HUD 预留上方 180–220 设计单位）。方块绘制节点作为它的子节点，使用以左下角为原点的局部坐标（`col*Cell, row*Cell`）。
- 命中检测直接使用棋盘容器手势回调里的 `touch.location`（该节点本地坐标，左下角原点），换算：`col = floor(x / Cell)`，`row = floor(y / Cell)`；越界即忽略。这一条同时在最大程度上规避“锚点与子节点原点混淆”的风险。
- **已实测验证（M1）**：`size = (200,100)`、`anchor = (0.5,0.5)`、`position = (0,0)` 的节点，其 `convertToWorldSpace(Vec2(0,0))` 返回 `(-100,-50)`，证实子节点局部原点确实在矩形左下角，上述换算成立（风险 R1 排除）。

### 方块与数值（以纯数据写在 `game/BlockDefs.ts` 注册表中，可调）

| 类型 | 颜色 | 标识 | 效果（n = 连线长度，n < 2 不生效） |
| --- | --- | --- | --- |
| 物攻 Physical | 红 `#E2574C` | “物” | 物理伤害 = 4 + 3n，受敌人护甲减免 |
| 法攻 Magic | 蓝 `#3B7BE0` | “法” | 魔法伤害 = 3 + 3n，无视护甲；对带护盾目标 ×1.5 |
| 状态 Status | 紫 `#9B59D0` | “状” | 层数 = max(1, floor(n/2))，给玩家 +15%/层 增伤（持续 2 回合）；n ≥ 5 额外给敌人挂 −20% 护甲（2 回合） |
| 治疗 Heal | 绿 `#46B266` | “治” | 治疗 = 3 + 2n；n ≥ 5 额外净化玩家 1 个减益 |

- 链长下限 **2**（≥ 2 个同色连通块即可消除）；无长度上限；不生效的连线不消耗回合、不改变棋盘。
- 魔力值：每种方块都带一条 `manaGain` 规则（base 1, perBlock 3），一次消除提供约 7~16 点魔力，上限 `MaxMana = 100`。
- 状态块不分敌我目标选择，效果由链长决定（n≥5 时同时作用于敌人），避免额外的目标选择 UI。

### 通用控件体系（`game/ui/`）

- `widget_base` 决策：方块、面板、按钮、血条、飘字全部从同一个轻量基类 `BaseWidget` 派生，避免重复的触控与绘制代码。
- 基类职责刻意收窄，只提供：`size`/`anchor`/`position`/`z`、`visible`/`enabled` 状态、`draw()` 钩子、`onTapBegan/onTapMoved/onTapEnded` 钩子透传、`setSelected(on)` 选中表现、`update(dt)` 动画推进。**不引入布局系统、列表、滚动区域**（对应问卷“不做完整 UI 控件库”）。
- `BlockWidget` 是通用方块控件：它只持有“一个方块数据 + 一个 `BlockDef` 引用”，按 `BlockDef.color/glyph` 绘制，不写任何按方块类型的 `if/switch`。
- 控件自身不注册 `schedule`；所有控件的 `update(dt)` 由 `Game` 的单一循环统一驱动。

### 效果列表与执行器（`game/Effects.ts`）

模型（严格三元组，不含可选字段，规避 Lua 数组不能存 `undefined` 的限制）：

```ts
export const enum EffectKind {
	PhysicalDamage = 'physicalDamage',
	MagicDamage = 'magicDamage',
	Heal = 'heal',
	Dispel = 'dispel',
	Shield = 'shield',
	BuffDamage = 'buffDamage',
	DebuffArmor = 'debuffArmor',
	BoardBlock = 'boardBlock',
	BoardShuffle = 'boardShuffle',
}

export const enum EffectTarget {
	Self = 'self',
	CurrentEnemy = 'currentEnemy',
	AllEnemies = 'allEnemies',
	Board = 'board',
	Reserved = 'reserved', // 预留未实现的目标枚举位
}

export interface EffectSpec {
	kind: EffectKind;
	value: number;
	target: EffectTarget;
}
```

- 持续回合等时间性质不进入三元组，统一放在 `game/Config.ts` 的持续时间表里；这样三元组保持“效果/数值/对象”三字段，便于序列化、日志与测试。
- 方块定义同样是纯数据（“链长 → 数值”也是数据，不是函数）：

```ts
export interface EffectRule {
	kind: EffectKind;
	target: EffectTarget;
	base: number;      // 链长下限时的数值
	perBlock: number;  // 每多一块的增量（可选 0）
	minChain: number;  // 生效所需最小链长（默认 3）
	floorTo: number;   // 取整粒度：0 = 四舍五入，1 = 向下取整（状态层数用）
}

export interface BlockDef {
	id: string;        // 扩展新类型只加一条
	color: number;     // 外观（十六进制颜色）
	glyph: string;     // 标识文字
	rules: EffectRule[];
}
```

- 解析：`resolveEffects(def, chainLength): EffectSpec[]` 把规则列表在链长满足 `minChain` 时展开为 `value = base + perBlock * n`（按 `floorTo` 取整）的三元组列表；n < 链长下限时返回空列表。
- 执行：`EffectHandlers: Record<EffectKind, Handler>` 注册表 + `executeEffects(specs, combat, board)` 统一执行器。执行器内部**没有** `if (kind === ...)` 链，只做“查表 → 按 `target` 取接收者 → 调用 handler”，因此新增效果种类是单点注册（控件与执行器核心不动）。
- 初版注册的 handler：物理伤害（受护甲减免）、魔法伤害（无视护甲，对护盾目标 ×1.5）、治疗、净化、护盾、增伤 buff（+15%/层）、破甲 debuff（−20% 护甲）、棋盘效果（封锁块/洗牌）。

### 效果表（由注册表数据产出，n = 连线长度，n < 2 不生效）

| 方块 | kind / target（按顺序） | 规则 |
| --- | --- | --- |
| 物攻 | `physicalDamage` → `currentEnemy`；`manaGain` → `self` | base 4, perBlock 3；魔力 base 1, perBlock 3 |
| 法攻 | `magicDamage` → `currentEnemy`；`manaGain` → `self` | base 3, perBlock 3；魔力 base 1, perBlock 3 |
| 状态 | `buffDamage` → `self`；`debuffArmor` → `currentEnemy`（minChain 5）；`manaGain` → `self` | base 0, perBlock 0.5, floorTo 1（即 floor(n/2)，n≥2 时 ≥ 1）；第二条 base 1, perBlock 0；魔力 base 1, perBlock 3 |
| 治疗 | `heal` → `self`；`dispel` → `self`（minChain 5）；`manaGain` → `self` | base 3, perBlock 2；第二条 base 1, perBlock 0；魔力 base 1, perBlock 3 |

### 魔力与技能（`game/Skills.ts`）

- 魔力是玩家资源：每次有效消除由效果列表中的 `manaGain` 条目累加（“消除提供魔力”同样是数据驱动的，可为不同方块类型配置不同魔力）。
- 技能同样是纯数据：`SkillDef { id, name, cost, effects: EffectSpec[] }`；释放技能 = 扣魔力 + 把 `effects` 交给同一个执行器，不新增任何特例代码。
- 初版技能：

| id | 名称 | 消耗 | 效果列表 | 用途 |
| --- | --- | --- | --- | --- |
| `shuffle` | 重排棋盘 | 20 | `boardShuffle` → `board` | 现场确实难以连线时主动换盘 |
| `blast` | 引爆最大连通块 | 35 | `boardBlast` → `board` | 直接消掉场上最大的一块，打开局面 |

### 棋盘可执行性与重置惩罚

- 判定：`Board.isPlayable()` = 存在长度 ≥ `MinChainLength` 的可连线区域（链长下限为 2 时即“存在一对相邻同色块”）。
- 检查时机：每次「消除 → 塌落 → 补充」之后；主循环每帧也可低成本复查。
- 不可执行时的事件：`Combat.ensureBoardPlayable(board)` → 直接 `board.reset()` 重排整盘 + 对玩家施以惩罚（`Config.BoardResetPenalty = 8` 点生命），并返回提示文本供 HUD 飘字；`Combat.boardResetCount` 记录次数供自检观测。
- 惩罚数值集中在 `game/Config.ts`，可调；重排后必定再次校验，避免连续触发。

### 棋盘约束与生成算法

约束（`game/Board.ts` 纯逻辑，可测试）：

- C1（放置约束，可逐级放宽）：生成/补充时任一颜色的最大连通块规模 ≤ `MaxGroupSize`（默认 5）；无法满足时逐级放宽到 `GroupSizeRelaxLimit`（默认 7）并记录告警。
- C2（硬约束，必须成立）：每次生成/补充完成后，棋盘至少存在一条长度 ≥ `MinChainLength` 的可连线区域，保证玩家始终能出手。
- C2b（偏好）：每种颜色至少存在长度 ≥ `ReserveGroupMin`（默认 2）的储备区域，供玩家预留应对敌方突发。
- C3（硬约束）：棋盘始终 7×7 满格。

算法：逐格随机取色，若破坏 C1 则在候选里选连通块最小的颜色（单格最多 12 次），仍不满足则逐级放宽；整体生成后校验 C2/C2b，不满足则整盘重洗（有限次），绝不死循环。补充阶段分三段：阶段一争取「C1 + C2b + C2」，阶段二退让为「C1 + C2」，阶段三放宽上限重试；若仍失败，则把消除路径留下的相邻空格强行设为同色（颜色取使全盘最大连通块最小的那个）以构造 C2。

**M2 实测修正（重要）**：C2 最初只要求“每种颜色至少一个 ≥2 的连通区域”，而生效链长下限是 3——“全盘只有 2 连”的多米诺棋盘也算满足约束，于是补充循环立即返回、棋盘在若干次操作后彻底无法连线（同一夹具 200 次随机操作仅 7~13 次可执行）。把 C2 改为“至少存在长度 ≥ MinChainLength 的可连线区域”后，同一夹具 200/200 次操作全部可执行、无死局。另：消除后“重力合流”（上下同色块跨空隙合并）属于涌现结果，可能超过放宽上限，按告警计数上报，不作为硬约束。

### 战斗与模式

- 玩家：HP 100，护盾 0，增伤/减益层数若干（层数带剩余回合计时）。
- 敌人波次（同一关卡内）：波 1 小怪 HP 40 / 攻击 8；波 2 小怪 HP 60 / 攻击 10；波 3 精英 HP 120 / 攻击 14（含蓄力重击 24）。
- 回合制：玩家每次有效消除算 1 回合；敌人行动条以回合计数，间隔波 1/2 = 3 回合、波 3 = 2 回合；HUD 明示“敌方行动倒计时 X 回合”。
- 实时模式：敌人行动条为秒级倒计时，间隔波 1/2/3 = 5.0/4.0/3.0 秒；玩家消除不重置计时，越快操作出手次数越多。
- 时间源抽象：`Combat` 只依赖“已消耗回合数”或“累计 dt 秒”中的一种抽象推进接口，两种模式共用同一套结算与行动逻辑。
- 关卡推进：3 波全部清除 → 通关该关并进入下一关，敌人数值 ×1.25，玩家回复 30% 最大生命；玩家 HP ≤ 0 → 失败结算面板，可重开当前关卡或返回主菜单。

### 设置与持久化

- 设置项：模式（回合制/实时，默认回合制）、难度（休闲 0.8 / 标准 1.0 / 困难 1.3，缩放敌人攻击与 HP）、显示操作提示开关。
- 持久化：`Content.saveAsync('settings.json', json)` 写入，启动时 `Content.loadAsync('settings.json')` 读取并用 `pcall`-式容错解析，任何失败回退默认值并在界面提示“设置未保存”。
- 模式切换入口：主菜单与战斗内暂停面板；切换后保存设置并重开当前关卡（避免中途切换导致行动条状态不一致），界面给出提示。

### 文件结构

| 文件 | 职责 |
| --- | --- |
| `init.ts` | 入口：创建摄像机自适应、构建场景根、实例化并启动 `Game` |
| `game/Config.ts` | 全局数值常量：模式/难度参数、波次表、链长下限、效果持续时间表（外观与效果规则已下沉到注册表） |
| `game/Effects.ts` | `EffectKind`/`EffectTarget` 枚举、`EffectSpec {kind, value, target}` 三元组、`EffectRule`→`EffectSpec` 解析器 `resolveEffects`、`EffectHandlers` 注册表与统一执行器 `executeEffects` |
| `game/BlockDefs.ts` | 方块类型注册表：纯数据定义（id、颜色、标识文字、效果规则列表）；新增方块类型只改此文件 |
| `game/Board.ts` | 棋盘数据模型：生成、约束校验、连线合法性、消除、塌落、补充（纯逻辑） |
| `game/Combat.ts` | 战斗状态：玩家/敌人属性、护盾与层数、时间源抽象、波次与关卡推进、胜负（纯逻辑） |
| `game/ui/Widget.ts` | 轻量控件基类 `BaseWidget`：尺寸/锚点/启用/绘制钩子/触控回调/选中态/`update(dt)`，不含布局系统 |
| `game/ui/BlockWidget.ts` | 通用方块控件：读取 `BlockDef` 绘制与表现，不硬编码任何方块类型 |
| `game/ui/Controls.ts` | 复用基类的 `ButtonWidget` / `PanelWidget` / `BarWidget` / `FloatTextWidget` |
| `game/BoardView.ts` | 棋盘视图与手势：7×7 `BlockWidget` 池、路径高亮、`touch.location`→格子换算、松手产出 `EffectSpec[]` |
| `game/Hud.ts` | HUD 与面板：双方血条、行动条、关卡/波次、飘字、设置面板、结算面板（由 `ui/Controls.ts` 拼装） |
| `game/Settings.ts` | 设置模型 + 读写持久化与容错 |
| `game/Game.ts` | 主控制器：唯一 `schedule` 循环，串联 Board/Combat/Hud/View 与所有控件的 `update(dt)` |
| `game/Tests.ts` | 导出 `runTests()`，返回首行为 `passed`/`failed` 的报告 |
| `tests/Entry.ts` | Agent 运行时自检入口：组合 `runTests()`、视图交互自检、运行时链路观测与坐标原点探针，把报告写入 `.agent/test-results/`（不参与正式游戏流程） |

导入路径使用 Dora 根模块写法的斜杠路径（如 `import { Board } from 'game/Board'`），不使用 `./`、`../` 或文件扩展名。

### 调度约束

- 每个节点只有一个 schedule 槽：全部逐帧逻辑（输入结算、动画推进、敌人计时、HUD 刷新）集中在 `Game` 根节点的单一 `schedule((dt) => { ...; return false; })` 中，不额外挂载并发回调。
- 运行时校验探针不得占用被观察节点的 schedule 槽。
- 所有控件（`BaseWidget` 及其子类）不注册 schedule，只暴露 `update(dt)` 由 `Game` 统一调用，保证控件数量增长不会引入并发回调。

## 实施步骤

| ID | 工作项 | 依赖 | 验收条件 |
| --- | --- | --- | --- |
| M1 | 工程骨架 + 通用控件与方块注册表 + 棋盘生成渲染：`init.ts`、`game/Config.ts`、`game/Effects.ts`（枚举/三元组/`resolveEffects`）、`game/BlockDefs.ts`、`game/ui/Widget.ts`、`game/ui/BlockWidget.ts`、`game/Board.ts`（生成与 C1/C2 校验）、`game/BoardView.ts`（手势连线，松手产出 `EffectSpec[]`） | 无 | (1) 源码实现：上述文件存在且导出被 `init.ts` 实际引用；`BlockWidget` 内无按方块类型的硬编码分支（源码可查证）；(2) build 通过且逐文件 `messages` 无失败或诊断；(3) 运行时存活：启动真实 `init.ts` 后连续 ≥2 次观察仍 `running`；(4) 自动化：`runTests()` 首行 `passed`，覆盖注册表完整性（每个方块类型都能由链长产出非空 `EffectSpec[]`）与 C1/C2 生成约束；(5) 手动/视觉：7×7 彩色方块可见、按住拖动出现路径高亮、松手输出效果三元组（视觉检查，未做则记 `not_run` 并请用户人工验收） |
| M2 | 消除结算与棋盘维护：链上块移除、重力塌落、顶部补充后 C1/C2 重新成立；消除统计 | M1 | (1) 源码实现；(2) build 通过且逐文件无诊断；(3) 自动化：`runTests()` 首行 `passed`，覆盖消除后满格、C1、C2 与 200 次随机操作不变量；(4) 运行时：连续多次消除后棋盘仍为 7×7 满格（运行时观测） |
| M3 | 战斗核心 + 效果执行器 + 回合制 MVP + 魔力/技能/棋盘兜底：`game/Combat.ts`、`game/Effects.ts`（`EffectHandlers` 注册与 `executeEffects`）、`game/Skills.ts`、`game/ui/Controls.ts`、`game/Hud.ts`、`game/Game.ts` 完整闭环（HP/护盾/层数/魔力、四类效果经三元组列表结算、技能释耗魔、敌人行动条与行动、3 波推进、失败结算与重开、棋盘不可执行时重排+惩罚） | M2 | 【已验收】(1) 源码：执行器按 `kind` 查表分发、无 `if (kind === ...)` 链，技能与方块共用同一执行器；(2) build 13/13 + 1/1 无诊断；(3) 自动化：`runTests()` 首行 passed（178 项），覆盖四类效果数值、`target` 分发、魔力获取与上限、技能扣魔与魔力不足拒绝、重排/引爆效果、不可执行棋盘的判定与重排惩罚、敌人行动时点、HP=0 → 失败、清波 → 下一波；(4) 运行时：`init.ts` 连续 4 次观察存活，自检入口注入 40 条真实触点连线后敌人 HP 40→0、魔力 0→60；(5) 视觉：首帧确认棋盘、双血条、魔力条、倒计时与两个技能按钮均可见且无遮挡/裁切。残留未验：真人拖拽的手感与结算面板观感（需人工游玩确认） |
| M4 | 实时模式与设置：`Combat` 时间源抽象、设置面板、`game/Settings.ts` 持久化、模式切换重开流程 | M3 | (1) 源码实现；(2) build 通过且逐文件无诊断；(3) 自动化：两种模式下敌人行动触发时点（回合计数 vs 累计 dt ≥ 阈值）、设置写→读一致；(4) 运行时：切换模式后战斗以新模式时间源运行（运行时观测）；(5) 视觉：设置面板可读、选项状态可见 |
| M5 | 突发情况：精英蓄力重击（提前 1 次行动预告）与封锁块（不可连线、到期恢复） | M4 | (1) 源码实现；(2) build 通过且逐文件无诊断；(3) 自动化：封锁块不可进入连线路径、到期自动恢复、蓄力重击在敌人下一次行动结算；(4) 视觉：封锁块外观与普通块可区分 |
| M6 | 手感与视觉打磨：消除反馈动画、伤害/治疗飘字、血条缓动、配色与排版统一、极端宽高比自适应检查 | M5 | (1) 源码实现；(2) build 通过且逐文件无诊断；(3) 运行时存活；(4) 视觉：操作前后两帧对比，确认无裁切、遮挡、层级错误；音频缺失作为明确非目标记录 |
| M7 | 扩展性验收：仅通过注册表新增一种方块类型与一条新效果条目（如“毒”：持续伤害），验证无需改动 `Widget`/`BlockWidget`/执行器核心 | M3 | (1) 源码：改动仅落在注册表与常量文件（diff 范围可查证）；(2) build 通过且逐文件无诊断；(3) 自动化：`runTests()` 覆盖新类型的 `EffectSpec` 解析与结算结果；(4) 运行时/视觉：新类型方块出现在棋盘、可连线、效果生效 |

## 风险与回退方案

| 编号 | 风险 | 缓解/回退 |
| --- | --- | --- |
| R1 | 触摸坐标与格子换算错位（锚点 vs 子节点原点） | 使用有尺寸棋盘容器 + `touch.location`（左下角原点）直接换算；若仍偏移，回退用 `viewLocation` 结合容器世界位置反算 |
| R2 | 单节点仅一个 schedule 槽导致更新互相覆盖 | 所有逐帧逻辑集中在 `Game` 根节点单一回调；校验探针不占用该槽 |
| R3 | 生成约束（C1/C2）导致死循环或长时间卡顿 | 单格换色重试上限、整盘重洗上限，最终逐级放宽 `MaxGroupSize` 到 7 并记录告警 |
| R4 | 设置文件不可写（沙箱/只读目录） | 内存态设置照常生效 + 界面提示“设置未保存”；不阻塞游戏流程 |
| R5 | 实时模式节奏手感仅凭代码无法判定 | 节奏参数全部集中在 `game/Config.ts` 便于快速调参；若实测不达标，保留回合制为默认并把实时模式标注为实验性 |
| R6 | TS→Lua 子集限制（无 `Math.hypot`、禁用 `any`/`null`、不可用含 `undefined` 的数组） | 统一用 `Math.sqrt`、明确类型、可选值判空后再入数组；以 build 诊断驱动修正 |
| R7 | 无音频/无贴图导致反馈偏弱 | 用颜色、缩放/淡出动画与飘字补偿；明确记为设计取舍而非缺陷 |
| R8 | 控件基类抽象过度，样板代码与调试成本高于收益 | 基类只提供尺寸/锚点/绘制钩子/触控回调与选中态，不引入布局系统；按钮/面板/血条/飘字必须实际复用同一个基类；若某类控件抽象不划算，回退为纯函数式绘制 + 数据表 |
| R9 | 效果三元组过度泛化导致战斗数值难调、难查 | 所有数值只存在于 `game/BlockDefs.ts` 与 `game/Config.ts`；`runTests()` 用固定夹具锁定每类效果的期望数值，任何漂移立即暴露 |
| R10 | 重力合流造出超过放宽上限的同色块后会长期存在（补充阶段不改动已有方块），使 C1 的“控制最大连续数量”失效 | 短期：作为告警统计上报（无死局）；中期（M6）：调参降低合并概率，或增加“定向拆分修复”（仅对刚合并出的超大块重着色最小必要格子） |
| R11 | 编译期错误（如 `Node` 无 `scale` 属性）会让用户侧“编译生成后无法运行” | 每次改动后必跑 `build` 并逐文件看 `messages`；用户报告运行失败时先看编译产物与引擎日志，而不是只依赖 Agent 侧的隔离运行 |

回退总则：模块按职责分文件，M3 之后不改动 M1/M2 已稳定的棋盘接口；实时模式与回合制共享 `Combat`，如实时模式被判定为不可用，可通过设置仅暴露回合制（代码保留，功能降级而非删除）。

## 验证计划

1. 构建：每次源码改动后执行 build，并逐文件检查 `messages`，不只看顶层 `success`。
2. 逻辑自动化：`game/Tests.ts` 的 `runTests()` 返回首行为 `passed`/`failed` 的报告；覆盖棋盘约束与不变量、四类效果公式、敌人行动时点、胜负切换、设置读写。首行 `failed` 即视为失败，修复最小逻辑/夹具后重跑。
3. 运行存活：启动真实 `init.ts`（不是测试入口），连续 ≥2 次观察 `running`，注入一次有意义的输入，再停止并确认不再运行。
4. 视觉/手动：有视觉工具时检查首帧与一次操作后的帧（棋盘、方块、HUD、行动条、层级与遮挡）；无视觉工具时显式报告 `not_run` 并请用户人工验收。
5. 证据分级：源码实现、构建通过、运行存活、自动化行为、手动交互、视觉检查分别记录，互不替代。

## 变更记录

- 2026-01-01（本轮规划）：创建方案骨架。项目为全新空工程（仅空 `init.ts`），无既有实现可复用。完成一轮 Dora API 与自适应文档查证（节点手势插槽、`Touch` 字段、`Content.loadAsync/saveAsync`、摄像机 `zoom` 自适应），并通过问卷确认交互方式、约束含义、棋盘规格、战斗结构、系统范围、交付顺序、目标平台与资源策略。产出 M1–M6 实施步骤、风险回退与验证计划；本轮无源码改动。
- 2026-01-01（需求追加·储备约束简化）：用户确认「无需每种颜色都保留 ≥2 储备区域，只要存在任意一种即可；仅当所有颜色都不存在 ≥2 区域时才重置棋盘」。据此删除 C2b（每色储备）与 `Config.ReserveGroupMin`/`IdealRefillRetries`，生成/补充只保留硬约束「存在长度 ≥ MinChainLength 的可连线区域」；重置触发条件与 `Board.isPlayable()` 等价。
- 2026-01-01（实施 M3 交互层）：新增 `game/ui/Controls.ts`（Panel/Bar/Button/FloatText 控件与标签工厂）、`game/Hud.ts`（双方血条、魔力条、敌方行动倒计时、技能按钮、关卡/波次、飘字、结算面板）、`game/Game.ts`（唯一 schedule 循环：连线→结算→棋盘维护→棋盘兑底→敌人行动→波次推进→失败/重开）；`game/Combat.ts` 新增波次/关卡推进与敌人出手；`init.ts` 改为只做自适应 + 启动 `Game`。
- 2026-01-01（运行问题处理）：用户反馈“编译生成后无法正确运行”。修复：① `init.ts` 原用 `Node.scale` 造成编译错误，改用 `scaleX/scaleY`；② 缩放改为“宽/高缩放取最小”（窄屏/竖屏不再横向裁切棋盘），并在拿不到 2D 摄像机时降级为缩放场景根节点；③ `Hud` 隐藏结算面板时禁用重开按钮，避免不可见按钮遮挡棋盘触控；④ `Game` 公开只读 `board/view/combat` 并新增 `submitChain()`，使“松手→结算→HUD→波次”全路径可被自动化覆盖（新增主循环自检 85 项）。新增风险 R10（重力合流超大色块长期存在）与 R11（编译期错误导致用户侧无法运行）。
- 2026-01-01（需求追加·储备约束简化）：用户确认“无需每种颜色都保留 ≥2 储备区域，只要任意一种存在即可；仅当所有颜色都不存在 ≥2 区域时才重置棋盘”。据此删除 C2b（每色储备）与 `Config.ReserveGroupMin`/`IdealRefillRetries`，生成/补充只保留硬约束“存在长度 ≥ MinChainLength 的可连线区域”；重置触发条件与 `Board.isPlayable()` 等价。
- 2026-01-01（本轮规划·架构修订）：按用户要求把方块改为「通用控件 + 注册表纯数据」构建，并明确功能本质是效果列表 `[{执行效果, 执行数值, 执行对象}]`。问卷确认控件范围（方块控件 + 一套轻量控件基类，所有 UI 元素复用）、扩展机制（注册表 + 纯数据）、`target` 集合（自身/当前敌人/全体敌人/棋盘/预留位）、`kind` 集合（物理伤害/魔法伤害/治疗/净化/护盾/增伤 buff/破甲 debuff/棋盘效果）。新增 `game/Effects.ts`、`game/BlockDefs.ts`、`game/ui/Widget.ts`、`game/ui/BlockWidget.ts`、`game/ui/Controls.ts` 与实施步骤 M7（扩展性验收），新增风险 R8/R9；本轮无源码改动。
- 2026-01-01（实施 M1/M2）：新增 `game/Config.ts`、`game/Effects.ts`、`game/BlockDefs.ts`、`game/ui/Widget.ts`、`game/ui/BlockWidget.ts`、`game/Board.ts`、`game/BoardView.ts`、`game/Tests.ts`、`tests/Entry.ts`，改写 `init.ts`。修订两处方案细节：①C2 由“每种颜色 ≥2 连通区域”改为“棋盘必须存在长度 ≥ MinChainLength 的可连线区域”（旧条款会产出无解的多米诺棋盘，实测 200 次操作仅 7~13 次可执行）；②效果表中状态块规则改为 base 0 / perBlock 0.5 / floorTo 1，与“层数 = floor(n/2)”一致。
