// 技能注册表：纯数据（id / 名称 / 魔力消耗 / 效果三元组列表）。
// 释放技能 = 扣魔力 + 把 effects 交给 game/Effects.ts 的统一执行器，不新增特例代码。

import { EffectKind, EffectSpec, EffectTarget } from 'game/Effects';

export interface SkillDef {
	id: string;
	name: string;
	cost: number;
	effects: EffectSpec[];
}

/** 构造一条效果三元组（技能多为固定数值，因此无需链长规则）。 */
export function makeSpec(kind: EffectKind, value: number, target: EffectTarget): EffectSpec {
	return { kind, value, target };
}

/** 技能用于应对难以消除的局面：重排棋盘 / 引爆场上最大连通块。 */
export class Skills {
	static readonly Shuffle = 'shuffle';
	static readonly Blast = 'blast';

	static readonly List: SkillDef[] = [
		{
			id: Skills.Shuffle,
			name: '重排棋盘',
			cost: 20,
			effects: [makeSpec(EffectKind.BoardShuffle, 1, EffectTarget.Board)],
		},
		{
			id: Skills.Blast,
			name: '引爆最大块',
			cost: 35,
			effects: [makeSpec(EffectKind.BoardBlast, 1, EffectTarget.Board)],
		},
	];

	static count(): number {
		return Skills.List.length;
	}

	static find(id: string): SkillDef | undefined {
		for (const def of Skills.List) {
			if (def.id === id) {
				return def;
			}
		}
		return undefined;
	}
}
