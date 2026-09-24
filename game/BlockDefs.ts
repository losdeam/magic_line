// 方块类型注册表：纯数据定义（id、颜色、标识文字、是否可放置、效果规则列表）。
// 新增方块类型只需在 List 里加一条，控件与执行器无需改动。

import { Config } from 'game/Config';
import { EffectKind, EffectRule, EffectTarget, makeRule } from 'game/Effects';

/** 一种方块的数据定义（无行为函数，全部为可读数据）。 */
export interface BlockDef {
	id: string;
	/** 外观色（0xRRGGBB）。 */
	color: number;
	/** 方块上的标识文字。 */
	glyph: string;
	/** 是否可作为常规方块参与生成/补充/连通/消除；false 表示固定障碍（封锁格）。 */
	placeable: boolean;
	rules: EffectRule[];
}

export class BlockDefs {
	static readonly Physical = 'physical';
	static readonly Magic = 'magic';
	static readonly Status = 'status';
	static readonly Heal = 'heal';
	/** 封锁格：由精英重击经效果执行器放置的固定障碍（不可消除、不可放置方块）。 */
	static readonly Blocked = 'blocked';

	/** 注册表：前 4 条为可放置方块，末尾为封锁格。 */
	static readonly List: BlockDef[] = [
		{
			id: BlockDefs.Physical,
			color: 0xe2574c,
			glyph: '物',
			placeable: true,
			rules: [
				makeRule(EffectKind.PhysicalDamage, EffectTarget.CurrentEnemy, 4, 3),
				// 阶段解锁（共鸣 6-7）：额外破甲 1 层
				makeRule(EffectKind.DebuffArmor, EffectTarget.CurrentEnemy, 1, 0, 6),
				// 阶段解锁（超载 8+）：物伤溅射到全体敌人
				makeRule(EffectKind.PhysicalDamage, EffectTarget.AllEnemies, 2, 1, 8),
				// 魔力按原值产出，不受档位倍率影响（scaled = false）
				makeRule(EffectKind.ManaGain, EffectTarget.Self, 1, 3, Config.MinChainLength, 0, false),
			],
		},
		{
			id: BlockDefs.Magic,
			color: 0x3b7be0,
			glyph: '法',
			placeable: true,
			rules: [
				makeRule(EffectKind.MagicDamage, EffectTarget.CurrentEnemy, 3, 3),
				// 阶段解锁（共鸣 6-7）：法术溅射到全体敌人
				makeRule(EffectKind.MagicDamage, EffectTarget.AllEnemies, 1, 1, 6),
				// 阶段解锁（超载 8+）：自身增伤 1 层
				makeRule(EffectKind.BuffDamage, EffectTarget.Self, 1, 0, 8),
				makeRule(EffectKind.ManaGain, EffectTarget.Self, 1, 3, Config.MinChainLength, 0, false),
			],
		},
		{
			id: BlockDefs.Status,
			color: 0x9b59d0,
			glyph: '状',
			placeable: true,
			rules: [
				// 层数 = floor(n / 2)，链长 2 时即为 1 层
				makeRule(EffectKind.BuffDamage, EffectTarget.Self, 0, 0.5, Config.MinChainLength, 1),
				// 阶段解锁（连击 4-5）：额外给当前敌人挂破甲 1 层
				makeRule(EffectKind.DebuffArmor, EffectTarget.CurrentEnemy, 1, 0, 4, 0),
				// 阶段解锁（超载 8+）：额外增伤 1 层
				makeRule(EffectKind.BuffDamage, EffectTarget.Self, 1, 0, 8),
				makeRule(EffectKind.ManaGain, EffectTarget.Self, 1, 3, Config.MinChainLength, 0, false),
			],
		},
		{
			id: BlockDefs.Heal,
			color: 0x46b266,
			glyph: '治',
			placeable: true,
			rules: [
				makeRule(EffectKind.Heal, EffectTarget.Self, 3, 2),
				// 阶段解锁（连击 4-5）：额外净化玩家 1 个减益
				makeRule(EffectKind.Dispel, EffectTarget.Self, 1, 0, 4, 0),
				// 阶段解锁（超载 8+）：附带护盾
				makeRule(EffectKind.Shield, EffectTarget.Self, 2, 1, 8),
				makeRule(EffectKind.ManaGain, EffectTarget.Self, 1, 3, Config.MinChainLength, 0, false),
			],
		},
		{
			id: BlockDefs.Blocked,
			color: 0x5a5f6b,
			glyph: '锁',
			placeable: false,
			rules: [],
		},
	];

	static count(): number {
		return BlockDefs.List.length;
	}

	/** 可放置方块数量（生成/补充/连通统计只用前 placeableCount 条）。 */
	static placeableCount(): number {
		let count = 0;
		for (const def of BlockDefs.List) {
			if (def.placeable) {
				count++;
			}
		}
		return count;
	}

	/** 该注册表下标是否可放置（越界与非可放置类型均返回 false）。 */
	static isPlaceable(index: number): boolean {
		if (index < 0 || index >= BlockDefs.List.length) {
			return false;
		}
		return BlockDefs.List[index].placeable;
	}

	/** 封锁格在注册表中的下标；注册表缺失时返回 -1。 */
	static lockedIndex(): number {
		return BlockDefs.indexOf(BlockDefs.Blocked);
	}

	static at(index: number): BlockDef {
		const list = BlockDefs.List;
		if (index <= 0) {
			return list[0];
		}
		if (index >= list.length) {
			return list[list.length - 1];
		}
		return list[index];
	}

	/** 返回注册表下标；未找到时返回 -1。 */
	static indexOf(id: string): number {
		const list = BlockDefs.List;
		for (let i = 0; i < list.length; i++) {
			if (list[i].id === id) {
				return i;
			}
		}
		return -1;
	}

	static find(id: string): BlockDef | undefined {
		const index = BlockDefs.indexOf(id);
		if (index < 0) {
			return undefined;
		}
		return BlockDefs.List[index];
	}
}
