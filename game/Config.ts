// 全局数值常量：模式/难度参数、波次表、链长下限、效果持续时间表。
// 方块的外观与效果规则不在本文件，见 game/BlockDefs.ts。

export const enum GameMode {
	TurnBased = 'turnBased',
	Realtime = 'realtime',
}

export const enum Difficulty {
	Casual = 'casual',
	Standard = 'standard',
	Hard = 'hard',
}

/** 单波敌人的纯数据定义。 */
export interface WaveDef {
	name: string;
	isElite: boolean;
	hp: number;
	attack: number;
	heavyAttack: number;
	armor: number;
	actionTurns: number;
	actionSeconds: number;
}

/**
 * 全局配置表。所有可调数值集中在这里，便于手感快速调参。
 */
export class Config {
	/** 设计基准高度：摄像机 zoom 按该高度适配。 */
	static readonly DesignSceneHeight = 1080;
	/** 设计基准宽度：与高度一起取“缩放取最小”，保证 7×7 棋盘在任何宽高比下不被横向裁切。 */
	static readonly DesignSceneWidth = 960;
	static readonly Columns = 7;
	static readonly Rows = 7;
	static readonly CellSize = 104;
	static readonly CellGap = 6;
	/** 棋盘容器在设计空间中的垂直位置（略偏下，为上方 HUD 留出空间）。 */
	static readonly BoardCenterY = -120;
	/** 飘字起始高度：放在棋盘上方区域内部，避免升起时穿过 HUD 条与技能按钮。 */
	static readonly NoticeY = 150;
	/** 对敌效果飘字分道（棋盘上方，靠近敌方一侧）。上浮终点 176+56+19.5≈252，低于技能按钮下沿 264。 */
	static readonly NoticeEnemyX = -190;
	static readonly NoticeEnemyY = 176;
	/** 我方受伤/治疗飘字分道（棋盘下方，靠近玩家一侧）。 */
	static readonly NoticePlayerX = 190;
	static readonly NoticePlayerY = -430;
	/** 系统提示（波次/关卡/设置/技能）飘字分道：与上两条互不重叠。 */
	static readonly NoticeSystemX = 0;
	static readonly NoticeSystemY = -120;
	/** 受击反馈：血条闪白/闪红持续秒数与全屏受击红闪峰值透明度。 */
	static readonly HitFlashDuration = 0.24;
	static readonly PlayerHitTintAlpha = 90;

	/** 连线生效所需的最小长度（2 = 只要有两个及以上同色连通块即可消除）。 */
	static readonly MinChainLength = 2;
	/** 生成/补充时任一颜色允许的最大连通块规模。 */
	static readonly MaxGroupSize = 5;
	/** 约束无法满足时允许放宽的上限（绝不死循环）。 */
	static readonly GroupSizeRelaxLimit = 7;
	/** 单格重新取色的最大次数。 */
	static readonly CellColorRetries = 12;
	/** 整盘重洗的最大次数（含逐步放宽约束的轮次）。 */
	static readonly BoardRefillRetries = 24;
	/** 补充时放宽上限后的兜底重试次数。 */
	static readonly RefillFallbackRetries = 8;

	/** 单帧最大步长，避免卡帧时时间跳变。 */
	static readonly MaxFrameDelta = 0.1;

	static readonly PlayerMaxHp = 100;
	/** 玩家魔力值上限。 */
	static readonly MaxMana = 100;
	/** 棋盘不可执行时直接重排棋盘对玩家的惩罚（扣除生命）。 */
	static readonly BoardResetPenalty = 8;
	/** 精英重击（蓄力后下一次行动）封锁的棋盘格子数。 */
	static readonly EliteHeavyBlockCells = 2;

	/** 封锁格持续时长：经过多少次敌人行动后自动恢复为常规方块。 */
	static readonly LockDurationActions = 2;

	/** 增伤 buff：每层提升的伤害比例。 */
	static readonly BuffDamagePerStack = 0.15;
	/** 破甲 debuff：每层降低的护甲比例。 */
	static readonly DebuffArmorPerStack = 0.2;
	static readonly BuffDurationTurns = 2;
	static readonly DebuffDurationTurns = 2;
	/** 魔法伤害对带护盾目标的额外倍率。 */
	static readonly MagicShieldBonus = 0.5;
	/** 伤害结算后的最小伤害值。 */
	static readonly MinDamage = 1;

	/** 每关通关后玩家回复的最大生命比例。 */
	static readonly StageClearHealRatio = 0.3;
	/** 每进入下一关敌人攻防血量的缩放。 */
	static readonly StageEnemyScale = 1.25;
	/** 每关波数。 */
	static readonly StageWaveCount = 3;

	/** 难度对敌人 HP/攻击的缩放系数（纯数据）。 */
	static readonly DifficultyScales: Record<Difficulty, number> = {
		[Difficulty.Casual]: 0.8,
		[Difficulty.Standard]: 1.0,
		[Difficulty.Hard]: 1.3,
	};

	/** 同一关卡内的敌人波次表（纯数据，可调）。 */
	static readonly Waves: WaveDef[] = [
		{ name: '小怪', isElite: false, hp: 40, attack: 8, heavyAttack: 0, armor: 4, actionTurns: 3, actionSeconds: 5 },
		{ name: '小怪', isElite: false, hp: 60, attack: 10, heavyAttack: 0, armor: 6, actionTurns: 3, actionSeconds: 4 },
		{ name: '精英', isElite: true, hp: 120, attack: 14, heavyAttack: 24, armor: 10, actionTurns: 2, actionSeconds: 3 },
	];

	/** 取指定波次定义；越界时回退到最后一波，保证调用方无需判空。 */
	static wave(index: number): WaveDef {
		const list = Config.Waves;
		if (index < 0 || index >= list.length) {
			return list[list.length - 1];
		}
		return list[index];
	}

	static difficultyScale(difficulty: Difficulty): number {
		const scale = Config.DifficultyScales[difficulty];
		if (scale === undefined) {
			return 1;
		}
		return scale;
	}

	/** 第 stage 关的敌人数值缩放（每关 ×StageEnemyScale）。 */
	static stageEnemyScale(stage: number): number {
		let scale = 1;
		for (let i = 1; i < stage; i++) {
			scale *= Config.StageEnemyScale;
		}
		return scale;
	}
}
