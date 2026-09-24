// 战斗状态（纯逻辑，可单独测试）：玩家/敌人属性、魔力与技能释放、波次与关卡推进、棋盘可执行性兜底。
// 模式时间源（回合制/实时）在 M4 接入；HUD 只读本类的状态。

import { Board } from 'game/Board';
import { Config, WaveDef } from 'game/Config';
import { ActorState, EffectContext, EffectKind, EffectSpec, EffectTarget, applyDamage, executeEffects, makeActor } from 'game/Effects';
import { SkillDef, Skills } from 'game/Skills';

export interface SkillResult {
	ok: boolean;
	message: string;
}

/** 敌人一次行动的类别：普通攻击 / 蓄力（不出手，预告重击）/ 重击（高伤害 + 封锁棋盘）。 */
export const enum EnemyAction {
	Attack = 'attack',
	Charge = 'charge',
	Heavy = 'heavy',
}

export class Combat {
	readonly player: ActorState;
	readonly enemy: ActorState;
	private readonly board: Board;
	private readonly enemies: ActorState[];
	private resetCount = 0;
	private waveIndex = 0;
	private stage = 1;
	private difficultyScale = 1;
	private realtime = false;
	private realtimeTimer = 0;
	/** 精英蓄力状态：true 表示已蓄力，下次行动的敌人应为重击。 */
	private charged = false;
	/** 最近一次敌人行动的类别（HUD 据此分道播报）。 */
	private lastAction = EnemyAction.Attack;
	/** 最近一次敌人行动时自动恢复（封锁到期）的格子数。 */
	private expiredLockCount = 0;

	constructor(board: Board) {
		this.board = board;
		this.player = makeActor(Config.PlayerMaxHp, 0, Config.MaxMana);
		const wave = Config.wave(0);
		this.enemy = makeActor(wave.hp, wave.armor, 0);
		this.enemies = [this.enemy];
		this.loadWave();
	}

	/** 棋盘因不可执行而被动重排的次数。 */
	get boardResetCount(): number {
		return this.resetCount;
	}

	/** 玩家是否已被击败。 */
	get defeated(): boolean {
		return this.player.hp <= 0;
	}

	/** 当前关卡序号（从 1 开始）。 */
	get stageNumber(): number {
		return this.stage;
	}

	/** 当前波次序号（从 1 开始）。 */
	get waveNumber(): number {
		return this.waveIndex + 1;
	}

	/** 每关波数。 */
	get waveCount(): number {
		return Config.StageWaveCount;
	}

	currentWave(): WaveDef {
		return Config.wave(this.waveIndex);
	}

	/** 当前波次的敌人行动间隔（回合制：回合数）。 */
	get enemyInterval(): number {
		return Config.wave(this.waveIndex).actionTurns;
	}

	/** 是否实时模式（敌人按秒倒计时行动）。 */
	get isRealtime(): boolean {
		return this.realtime;
	}

	/** 当前波次的敌人行动间隔（实时模式：秒）。 */
	get enemyIntervalSeconds(): number {
		return Config.wave(this.waveIndex).actionSeconds;
	}

	/** 实时模式剩余秒数（HUD 显示用）。 */
	get secondsLeft(): number {
		return this.realtimeTimer;
	}

	/** 切换时间源：回合计数 / 秒级倒计时，并重置倒计时。 */
	setRealtime(on: boolean): void {
		this.realtime = on;
		this.resetTimer();
	}

	resetTimer(): void {
		this.realtimeTimer = this.enemyIntervalSeconds;
	}

	/**
	 * 推进实时倒计时；返回 true 表示敌人应当出手（调用方随后执行 enemyAct）。
	 * 回合制下始终返回 false（由回合计数驱动）。
	 */
	advanceTime(dt: number): boolean {
		if (!this.realtime) {
			return false;
		}
		this.realtimeTimer -= dt;
		if (this.realtimeTimer > 0) {
			return false;
		}
		this.resetTimer();
		return true;
	}

	setDifficultyScale(scale: number): void {
		this.difficultyScale = scale;
	}

	/** 载入当前波次的敌人属性（按关卡与难度缩放）。 */
	loadWave(): void {
		const wave = Config.wave(this.waveIndex);
		const scale = this.difficultyScale * Config.stageEnemyScale(this.stage);
		this.enemy.maxHp = Math.round(wave.hp * scale);
		this.enemy.hp = this.enemy.maxHp;
		this.enemy.shield = 0;
		this.enemy.armor = wave.armor;
		this.enemy.debuffStacks = 0;
		// 换波/换关时清除蓄力状态
		this.charged = false;
		this.lastAction = EnemyAction.Attack;
		this.resetTimer();
	}

	/** 精英是否已经蓄力、下次行动将打出重击。 */
	get isCharged(): boolean {
		return this.charged;
	}

	/** 最近一次敌人行动的类别（在 enemyAct() 之后读取）。 */
	get lastEnemyAction(): EnemyAction {
		return this.lastAction;
	}

	/** 最近一次敌人行动后自动解除的封锁格数（0 表示没有封锁到期）。 */
	get lastExpiredLocks(): number {
		return this.expiredLockCount;
	}

	/**
	 * 敌人出手：小怪直接按攻击力攻击玩家；
	 * 精英先蓄力一次（0 伤害、仅预告），下一次行动打出重击，
	 * 重击经统一效果执行器下发 `BoardBlock` 效果封锁棋盘格子（无特例分支）。
	 */
	enemyAct(): number {
		// 先推进封锁计时：到期的封锁格自动恢复为常规方块（恢复走棋盘标准补充流程），
		// 因此本次刚下发的封锁不会被立刻扣减。
		this.expiredLockCount = this.board.expireLocks();
		const wave = Config.wave(this.waveIndex);
		const scale = this.difficultyScale * Config.stageEnemyScale(this.stage);
		if (wave.isElite) {
			if (!this.charged) {
				this.charged = true;
				this.lastAction = EnemyAction.Charge;
				return 0;
			}
			this.charged = false;
			this.lastAction = EnemyAction.Heavy;
			const block: EffectSpec = {
				kind: EffectKind.BoardBlock,
				value: Config.EliteHeavyBlockCells,
				target: EffectTarget.Board,
			};
			this.applySpecs([block]);
			return applyDamage(this.player, wave.heavyAttack * scale);
		}
		this.lastAction = EnemyAction.Attack;
		return applyDamage(this.player, wave.attack * scale);
	}

	/** 推进到下一波；返回 true 表示本关三波已清完。 */
	advanceWave(): boolean {
		this.waveIndex++;
		if (this.waveIndex >= Config.StageWaveCount) {
			return true;
		}
		this.loadWave();
		return false;
	}

	/** 进入下一关：波次归零、敌人数值增长、玩家回复一定生命。 */
	nextStage(): void {
		this.stage++;
		this.waveIndex = 0;
		this.loadWave();
		this.player.hp += Math.round(this.player.maxHp * Config.StageClearHealRatio);
		if (this.player.hp > this.player.maxHp) {
			this.player.hp = this.player.maxHp;
		}
	}

	/** 重开本关：波次、关卡与双方状态复位。 */
	resetBattle(): void {
		this.waveIndex = 0;
		this.stage = 1;
		this.resetCount = 0;
		this.player.hp = this.player.maxHp;
		this.player.shield = 0;
		this.player.buffStacks = 0;
		this.player.debuffStacks = 0;
		this.player.mana = 0;
		this.loadWave();
	}

	/** 把效果三元组列表交给统一执行器，返回实际执行条数。 */
	applySpecs(specs: EffectSpec[]): number {
		return executeEffects(specs, this.makeContext());
	}

	/** 释放技能：先扣魔力，再执行技能的效果列表。 */
	useSkill(id: string): SkillResult {
		const def = Skills.find(id);
		if (def === undefined) {
			return { ok: false, message: '技能不存在：' + id };
		}
		if (this.player.mana < def.cost) {
			return { ok: false, message: def.name + ' 需要 ' + def.cost + ' 魔力，当前 ' + this.player.mana };
		}
		this.player.mana -= def.cost;
		this.applySpecs(def.effects);
		return { ok: true, message: def.name + '（魔力 −' + def.cost + '）' };
	}

	/** 可释放的技能列表，供 HUD 绘制按钮。 */
	availableSkills(): SkillDef[] {
		return Skills.List;
	}

	/**
	 * 棋盘可执行性兜底：不可执行（所有颜色都不存在 ≥ MinChainLength 的区域）时
	 * 直接重排整盘并惩罚玩家，返回提示文本；返回 undefined 表示无需处理。
	 */
	ensureBoardPlayable(): string | undefined {
		if (this.board.isPlayable()) {
			return undefined;
		}
		this.board.reset();
		this.resetCount++;
		this.player.hp -= Config.BoardResetPenalty;
		if (this.player.hp < 0) {
			this.player.hp = 0;
		}
		return '棋盘无可连线区域，已重排棋盘（生命 −' + Config.BoardResetPenalty + '）';
	}

	private makeContext(): EffectContext {
		return { player: this.player, currentEnemy: this.enemy, allEnemies: this.enemies, board: this.board };
	}
}
