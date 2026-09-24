## Session Summary

### Current Goal

按 `.agent/plan/PLAN.md` 推进「连线消除 + 战斗」游戏。M1–M4 已完成并验收；M6 部分手感项已做（含掉落动画）；**本轮完成 M6 排版统一与极端宽高比验收（新增 `game/UiLayout.ts` 排版审计 API + 自检 13d 段 45 条断言）**，构建 3 目标无诊断、自检 passed（逻辑 280 / 交互 27 / 运行时 46 / 主循环 94）。M5 已由用户实机确认。剩余：配色统一观感 + 真人手感与特效节奏确认（需实机）、M7 扩展性验收。

### Recent Progress

- M6 排版统一与极端宽高比（本轮，已完成）：新增 `game/UiLayout.ts`（`Palette`/`HudLayout`/`SafeBox`/`zoomFor`/`visibleHalfExtent`/`insideSafeBox`/`hudLayoutRects`/`boardLayoutRect`）；`game/Tests.ts` 13d 段 45 条断言（12 种窗口最小可见区 ≥ 960×1080、17 个 HUD/面板元素 + 棋盘逐个不越界、3 条相邻性）；审计首次即暴露真实越界 —— `Config.NoticeEnemyY=190` 时对敌飘字上浮终点 265.5 升进技能按钮区（下沿 264），改 176（终点 251，余量 12.5）；`init.ts`/`Hud.ts` 改用 UiLayout 常量。
- M5 封锁格剩余次数角标（已完成）：
  - `game/ui/BlockWidget.ts`：右上角角标 `badge`（`Label`，默认隐藏）；`drawSelf()` 在 `locked && lockTurns>0` 时画深色底盘 `drawDot`（24,26,32,235，半径 `max(9, size*0.2)`）；`applyBadge()` 控制显隐与颜色（`lockTurns<=1` 转暖红 255,156,120）；导出 `badgeText` getter。
  - `game/BoardView.ts`：`refreshFromBoard()` 用 `board.lockTurnsAt(flat)` 调 `setLockTurns()`；新增公开访问器 `lockTurnsLabelAt(flat)`。
  - `tests/Entry.ts`：运行时段 +2 条角标断言（邻格起手链长、角标文本）与正面证据行；同时修复**相邻封锁格导致的夹具缺陷**（`blockCells(2)` 可能选出相邻两格，旧夹具固定取左邻格作起手点 → 起手点本身即封锁格，`chainLength` 断言偶发 failed；游戏逻辑无误，改为动态挑非封锁邻格），检查项 44 → 46。
  - 抓帧：临时探针 `tests/PreviewLock.ts`（已删除）→ `.agent/vision/1790209390-61343960.png`（封锁角标「2」）、`1790209392-922238346.png`（剩最后一次转暖色「1」），**尚未判读**。
- M5 封锁到期自动恢复（上一轮，已完成）：
  - `game/Config.ts`：`LockDurationActions = 2`。
  - `game/Board.ts`：`lockTimers`（与 cells 等长、`resetCells()` 清零）/`lockedCount()`/`lockTurnsAt()`/`lastExpiredLocks`/`expireLocks()`（递减计时，到期格置 -1 后走标准 `refillRestore()`，C1/C2/C3 自动成立）；`reset()` = `resetCells() + fill()`。
  - `game/Combat.ts`：`expiredLockCount`/`lastExpiredLocks`；`enemyAct()` 首行先推进旧锁再出手。
  - `game/Game.ts`：解除时播报「封锁自动解除 N 格」（System 车道）并刷新视图。
  - 测试：`game/Tests.ts` 13c 段（14 条）；`tests/Entry.ts` 运行时段 +13 条（含视图 `isLockedAt` 到期全归零）。
- 上一轮：方块掉落动画（`Board.collapse` 记录轨迹 → `BoardView.animateFall` 0.18s 缓出）与渲染根因修复（描边透明填充、图层分离、技能扫光）。历史细节见 HISTORY.jsonl 与 `.agent/plan/PROGRESS.md`。

### Validation Ledger

- 构建（本轮）：`build paths=['game','tests','init.ts']` → game **15/15**（新增 UiLayout.ts）、tests 1/1、init.ts 1/1，逐文件无诊断（PASS）。
- 运行时自检（本轮）：`.agent/test-results/m3.txt` 首行 `passed`（`runTime=2876.65`）：逻辑 **280**（+45）/ 交互 27 / 运行时 46 / 主循环 94，0 失败（PASS）；含「M6 排版：12 种窗口下最小可见区 960×1080 ≥ 安全区 960×1080，HUD/面板 17 个元素与棋盘均在安全区内；棋盘底边 -484，提示行上沿 -489，对敌飘字上浮终点 251（技能按钮下沿 264）」。
- 视觉/真人验收：M5 已由用户实机确认（「动效均可」）；本轮排版审计为纯几何断言，**配色统一观感与真人手感仍未验（not_run）**。

### Open Issues

- **待实机验收（用户侧）**：第 3 波精英蓄力预告 → 下次行动重击并封锁 2 格；封锁格外观与「封锁自动解除」播报；血条/魔力条/行动条色彩差异；消除爆点、技能扫光、掉落动画是否可见。
- 注意：`tests/Entry.ts` 断言 `formatEffects(result.specs).indexOf('物理伤害 16') === 0`，改动 `formatEffects` 文本会破坏该断言。
- M6 待做：配色统一观感 + 真人手感与特效节奏确认（排版统一与极端宽高比已完成并通过 13d 段审计）。
- M7（扩展性验收，仅改注册表新增方块/效果）未开始。
- 重力合流可造出超过放宽上限（7）的同色块并长期存在（无死局）→ M6 调参或定向拆分修复。
- 实时模式节奏参数（5/4/3 秒）与设置面板点击流程仍缺真人/视觉确认。

### Active Checkpoint

- 当前目标：M6 仅剩「配色统一观感 + 真人手感与特效节奏确认」，需用户实机。
- 已完成：M1–M5 全部 done（M5 经用户实机确认）；M6 已做掉落动画、受击/飘字动效、技能扫光、UiLayout 排版统一与 13d 段极端宽高比审计（并修掉 NoticeEnemyY 越界）。
- 最新具体证据：`build` → game **15/15** + tests 1/1 + init.ts 1/1；`.agent/test-results/m3.txt` 首行 passed、runTime=2876.65（280 / 27 / 46 / 94，0 失败）；`.agent/plan/PROGRESS.md` 与 `.agent/main/PROJECT_MEMORY.md` 已同步。
- 待用户目视：`.agent/vision/1790209390-61343960.png`（角标「2」）、`1790209392-922238346.png`（暖红「1」）。
- 若用户反馈异常：先核对 `.agent/test-results/m3.txt` 对应断言段与 `@dora_full_logs.txt`，再考虑 `previewGame` 抓帧（可用测试夹具直达第 3 波精英）或 Lua 探针。
- 待验：视觉判读（本会话无 analyze_image）与真人手感。
- **Next tool**：等用户实机反馈；如需视觉证据则 `previewGame` + 用户目视/analyze_image。