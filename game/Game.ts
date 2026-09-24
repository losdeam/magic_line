// 主控制器：唯一 schedule 循环，串联棋盘、战斗、HUD 与设置。
// 回合制：每次有效消除 = 1 回合，敌人按回合间隔行动；
// 实时模式：敌人按秒倒计时行动，玩家消除不重置计时。

import { Node, Vec2 } from 'Dora';
import { Board } from 'game/Board';
import { BoardView, ChainResult } from 'game/BoardView';
import { Combat, EnemyAction } from 'game/Combat';
import { Config, GameMode } from 'game/Config';
import { EffectKind, formatEffects } from 'game/Effects';
import { Hud, NoticeLane } from 'game/Hud';
import { Settings } from 'game/Settings';
import { Skills } from 'game/Skills';

export class Game {
	private readonly parent: Node.Type;
	private readonly root: Node.Type;
	/** 棋盘、视图与战斗状态对自检与外部系统只读公开。 */
	readonly board: Board;
	readonly view: BoardView;
	readonly combat: Combat;
	readonly settings: Settings;
	private readonly hud: Hud;
	private turnsUntilEnemy = 0;
	private defeated = false;

	constructor(parent: Node.Type) {
		this.parent = parent;
		this.settings = Settings.load();
		this.board = new Board();
		this.combat = new Combat(this.board);
		this.combat.setDifficultyScale(this.settings.difficultyScale());
		this.combat.setRealtime(this.settings.mode === GameMode.Realtime);
		this.view = new BoardView(this.board);
		this.hud = new Hud(Skills.List);
		this.root = Node();
		this.view.root.position = Vec2(0, Config.BoardCenterY);
		this.view.root.addTo(this.root);
		this.hud.root.addTo(this.root);
		this.hud.onSkill = (id) => this.handleSkill(id);
		this.hud.onRestart = () => this.restart();
		this.hud.onToggleMode = () => this.toggleMode();
		this.hud.onCycleDifficulty = () => this.cycleDifficulty();
		this.hud.onToggleHint = () => this.toggleHint();
		this.turnsUntilEnemy = this.combat.enemyInterval;
	}

	/** 挂到传入的场景节点并启动单一循环。 */
	start(): void {
		this.root.addTo(this.parent);
		this.refreshHud();
		this.hud.showNotice('按住滑过相邻同色方块，松手结算');
		if (!this.settings.saved) {
			this.hud.showNotice('设置未保存（仅内存态生效）');
		}
		this.root.schedule((dt) => {
			this.tick(dt);
			return false;
		});
	}

	/** 单帧逻辑：输入结算 → 实时倒计时 → HUD 刷新。 */
	private tick(dt: number): void {
		this.view.update(dt);
		this.hud.update(dt);
		const result = this.view.takePendingResult();
		if (result !== undefined) {
			if (this.hud.isSettingsOpen) {
				// 设置面板打开时忽略棋盘输入，避免误操作
				this.view.refreshFromBoard();
			} else {
				this.handleChain(result);
			}
		}
		if (!this.defeated && this.combat.advanceTime(dt)) {
			this.enemyAct();
		}
		if (this.combat.isRealtime && !this.defeated) {
			this.hud.setTimerInfo(
				'敌方行动倒计时 ' + Math.ceil(this.combat.secondsLeft) + ' 秒',
				this.combat.secondsLeft / this.combat.enemyIntervalSeconds
			);
		}
	}

	/** 供自检/模拟使用：同步注入一条连线并走完整结算流程（等价于玩家一次松手）。 */
	submitChain(cells: number[]): void {
		this.view.submitChain(cells);
		const result = this.view.takePendingResult();
		if (result !== undefined) {
			this.handleChain(result);
		}
	}

	private handleChain(result: ChainResult): void {
		if (this.defeated) {
			return;
		}
		const enemyHpBefore = this.combat.enemy.hp;
		const playerHpBefore = this.combat.player.hp;
		this.combat.applySpecs(result.specs);
		const enemyLost = enemyHpBefore - this.combat.enemy.hp;
		const hpGained = this.combat.player.hp - playerHpBefore;
		this.board.applyChain(result.cells);
		this.view.flashCleared(result.cells);
		this.view.animateFall(this.board.collapseMoves, this.board.collapseSpawns);
		this.view.refreshFromBoard();
		this.reportChain(result, enemyLost, hpGained);
		const resetNotice = this.combat.ensureBoardPlayable();
		if (resetNotice !== undefined) {
			this.hud.showNotice(resetNotice);
			this.view.refreshFromBoard();
		}
		if (this.combat.enemy.hp <= 0) {
			this.handleWaveCleared();
		} else if (!this.combat.isRealtime) {
			// 回合制：每次有效消除消耗 1 回合
			this.turnsUntilEnemy--;
			if (this.turnsUntilEnemy <= 0) {
				this.enemyAct();
			}
		}
		if (this.combat.player.hp <= 0) {
			this.defeat();
			return;
		}
		this.refreshHud();
	}

	/**
	 * 分道播报一次连线的结算结果：对敌伤害走对敌道，治疗/受伤走我方道，
	 * 状态与魔力走系统道，因此同一次结算的多条飘字不会叠在同一位置。
	 */
	private reportChain(result: ChainResult, enemyLost: number, hpGained: number): void {
		let mana = 0;
		let buff = 0;
		let debuff = 0;
		let shield = 0;
		for (const spec of result.specs) {
			if (spec.kind === EffectKind.ManaGain) {
				mana += spec.value;
			} else if (spec.kind === EffectKind.Shield) {
				shield += spec.value;
			} else if (spec.kind === EffectKind.BuffDamage) {
				buff += spec.value;
			} else if (spec.kind === EffectKind.DebuffArmor) {
				debuff += spec.value;
			}
		}
		if (enemyLost > 0) {
			this.hud.showNotice('-' + enemyLost, NoticeLane.Enemy, 0xffe58a);
			this.hud.hitEnemy();
		}
		if (hpGained > 0) {
			this.hud.showNotice('+' + hpGained, NoticeLane.Player, 0x9fe0a0);
		}
		if (debuff > 0) {
			this.hud.showNotice('破甲 ' + debuff + ' 层', NoticeLane.Enemy, 0xd0a0ff);
		}
		if (buff > 0) {
			this.hud.showNotice('增伤 +' + buff + ' 层', NoticeLane.System, 0xffe58a);
		}
		if (shield > 0) {
			this.hud.showNotice('护盾 +' + shield, NoticeLane.System, 0x8fc4ff);
		}
		if (mana > 0) {
			this.hud.showNotice('魔力 +' + mana, NoticeLane.System, 0x8fc4ff);
		}
		if (enemyLost <= 0 && hpGained <= 0 && mana <= 0 && buff <= 0 && shield <= 0) {
			// 兜底：没有可展示的数值时（如洗牌/引爆/净化类效果）直接展示效果文本
			this.hud.showNotice(formatEffects(result.specs), NoticeLane.System);
		}
	}

	private handleWaveCleared(): void {
		if (this.combat.advanceWave()) {
			this.combat.nextStage();
			this.hud.showNotice('本关通关，进入第 ' + this.combat.stageNumber + ' 关（生命已回复）');
		} else {
			this.hud.showNotice('第 ' + this.combat.waveNumber + ' 波来袭');
		}
		// 换波时清除上一波（精英重击）留下的封锁格
		this.board.reset();
		this.view.refreshFromBoard();
		this.turnsUntilEnemy = this.combat.enemyInterval;
	}

	private enemyAct(): void {
		const damage = this.combat.enemyAct();
		const action = this.combat.lastEnemyAction;
		if (action === EnemyAction.Prepare) {
			// 预告：本次不出手，仅提示下一次将释放的技能名
			this.hud.showNotice('敌方蓄力「' + this.combat.lastSkillName + '」 — 下次行动释放', NoticeLane.Enemy, 0xffb36b);
		} else if (action === EnemyAction.Release) {
			this.hud.hitPlayer(damage);
			const lockText = this.combat.lastNewLocks > 0 ? '，封锁 ' + this.combat.lastNewLocks + ' 格' : '';
			this.hud.showNotice('敌方「' + this.combat.lastSkillName + '」 −' + damage + lockText, NoticeLane.Enemy, 0xff8a8a);
		} else {
			this.hud.hitPlayer(damage);
			this.hud.showNotice('敌方' + this.combat.lastSkillName + ' −' + damage, NoticeLane.System, 0xffb36b);
		}
		if (this.combat.lastExpiredLocks > 0) {
			this.hud.showNotice('封锁自动解除 ' + this.combat.lastExpiredLocks + ' 格', NoticeLane.System, 0x9fd6ff);
		}
		// 重击可能经效果执行器封锁棋盘格子，这里同步方块外观（封锁格置暗）
		this.view.refreshFromBoard();
		this.turnsUntilEnemy = this.combat.enemyInterval;
		if (this.combat.player.hp <= 0) {
			this.defeat();
			return;
		}
		this.refreshHud();
	}

	private handleSkill(id: string): void {
		if (this.defeated) {
			return;
		}
		const before = this.captureBlocks();
		const result = this.combat.useSkill(id);
		this.hud.showNotice(result.message, NoticeLane.System, result.ok ? 0x8fd8ff : 0xffb36b);
		if (result.ok) {
			// 技能动画：按钮亮起 + 受技能影响的格子扫过一片亮光；棋盘兑底后重新同步外观
			this.hud.glowSkill(id);
			const changed = this.diffBlocks(before);
			const resetNotice = this.combat.ensureBoardPlayable();
			if (resetNotice !== undefined) {
				this.hud.showNotice(resetNotice);
			}
			this.view.refreshFromBoard();
			this.view.skillCast(changed);
		}
		this.refreshHud();
	}

	/** 快照当前棋盘每个格子的方块类型下标（行优先），用于比对技能改动了哪些格子。 */
	private captureBlocks(): number[] {
		const snapshot: number[] = [];
		for (let row = 0; row < this.board.rows; row++) {
			for (let col = 0; col < this.board.columns; col++) {
				snapshot.push(this.board.cellIndex(col, row));
			}
		}
		return snapshot;
	}

	/** 对比快照，返回方块类型发生变化的格子下标（flat）；无变化时返回空列表。 */
	private diffBlocks(before: number[]): number[] {
		const changed: number[] = [];
		let i = 0;
		for (let row = 0; row < this.board.rows; row++) {
			for (let col = 0; col < this.board.columns; col++) {
				const index = this.board.cellIndex(col, row);
				if (i < before.length && before[i] !== index) {
					changed.push(this.board.flatIndex(col, row));
				}
				i++;
			}
		}
		return changed;
	}

	/** 切换模式（回合制 ↔ 实时）：保存设置并重开本关。 */
	toggleMode(): void {
		const mode = this.settings.toggleMode();
		const saved = this.settings.save();
		this.combat.setRealtime(mode === GameMode.Realtime);
		// 模式切换后重开本关，避免行动条状态不一致
		this.restart();
		this.hud.showNotice('已切换为' + this.settings.modeName() + (saved ? '' : '（设置未保存）'));
		this.refreshHud();
	}

	/** 循环切换难度：保存设置并刷新当前波次数值。 */
	cycleDifficulty(): void {
		this.settings.cycleDifficulty();
		const saved = this.settings.save();
		this.combat.setDifficultyScale(this.settings.difficultyScale());
		this.combat.loadWave();
		this.hud.showNotice('难度：' + this.settings.difficultyName() + (saved ? '' : '（设置未保存）'));
		this.refreshHud();
	}

	/** 开关底部操作提示。 */
	toggleHint(): void {
		this.settings.toggleHint();
		const saved = this.settings.save();
		this.hud.showNotice('操作提示：' + (this.settings.showHint ? '开' : '关') + (saved ? '' : '（设置未保存）'));
		this.refreshHud();
	}

	private defeat(): void {
		this.defeated = true;
		this.hud.showDefeat('玩家生命归零 — 止步于第 ' + this.combat.stageNumber + ' 关第 ' + this.combat.waveNumber + ' 波');
		this.refreshHud();
	}

	private restart(): void {
		this.defeated = false;
		this.board.reset();
		this.view.refreshFromBoard();
		this.combat.resetBattle();
		this.combat.setDifficultyScale(this.settings.difficultyScale());
		this.combat.setRealtime(this.settings.mode === GameMode.Realtime);
		this.turnsUntilEnemy = this.combat.enemyInterval;
		this.hud.hideDefeat();
		this.hud.showNotice('重新开始本关');
		this.refreshHud();
	}

	private refreshHud(): void {
		const wave = this.combat.currentWave();
		this.hud.setStageInfo('第 ' + this.combat.stageNumber + ' 关 · 波次 ' + this.combat.waveNumber + '/' + this.combat.waveCount);
		this.hud.setEnemyInfo(wave.name, this.combat.enemy.hp, this.combat.enemy.maxHp);
		this.hud.setPlayerInfo(this.combat.player.hp, this.combat.player.maxHp, this.combat.player.mana, this.combat.player.maxMana);
		if (this.combat.isRealtime) {
			this.hud.setTimerInfo(
				'敌方行动倒计时 ' + Math.ceil(this.combat.secondsLeft) + ' 秒',
				this.combat.secondsLeft / this.combat.enemyIntervalSeconds
			);
		} else {
			this.hud.setTimerInfo(
				'敌方行动倒计时 ' + this.turnsUntilEnemy + ' 回合',
				this.turnsUntilEnemy / this.combat.enemyInterval
			);
		}
		this.hud.syncSkills(this.combat.player.mana);
		this.hud.syncSettings(this.settings.modeName(), this.settings.difficultyName(), this.settings.showHint, this.settings.saved);
	}
}
