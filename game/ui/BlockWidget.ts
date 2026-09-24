// 通用方块控件：只按 BlockDef 的数据绘制与表现。
// 内部不出现任何按方块类型的 if/switch，新增类型无需改动本文件。

import { Color, Label, Vec2 } from 'Dora';
import { BlockDef } from 'game/BlockDefs';
import { BaseWidget, colorFromHex } from 'game/ui/Widget';

/** 把颜色向白色插值，用于方块描边，不改动注册表数据。 */
function lighten(hex: number, ratio: number): number {
	const r = Math.floor(hex / 65536) % 256;
	const g = Math.floor(hex / 256) % 256;
	const b = hex % 256;
	const nr = Math.min(255, Math.floor(r + (255 - r) * ratio));
	const ng = Math.min(255, Math.floor(g + (255 - g) * ratio));
	const nb = Math.min(255, Math.floor(b + (255 - b) * ratio));
	return nr * 65536 + ng * 256 + nb;
}

export class BlockWidget extends BaseWidget {
	private current: BlockDef;
	private readonly glyph: Label.Type | undefined;
	/** 锁定剩余解除次数角标（0 = 隐藏），数值来自棋盘计时数据。 */
	private readonly badge: Label.Type | undefined;
	private lockTurns = 0;
	/** 不可连线（例如被封锁）时的表现开关。 */
	locked = false;

	/** 角标字号/位置相对格子尺寸的比例（外观常数，非方块类型分支）。 */
	private static readonly badgeRatio = 0.24;

	constructor(def: BlockDef, size: number) {
		super(size, size);
		this.current = def;
		const label = Label('sarasa-mono-sc-regular', Math.floor(size * 0.4));
		if (label !== undefined) {
			label.text = def.glyph;
			label.batched = true;
			label.color = Color(255, 255, 255, 255);
			label.position = Vec2(size / 2, size / 2);
			label.addTo(this.root);
		}
		this.glyph = label;
		const badge = Label('sarasa-mono-sc-regular', Math.max(12, Math.floor(size * 0.3)));
		if (badge !== undefined) {
			badge.text = '';
			badge.batched = true;
			badge.color = Color(255, 214, 120, 255);
			badge.position = Vec2(size - size * BlockWidget.badgeRatio, size - size * BlockWidget.badgeRatio);
			badge.visible = false;
			badge.addTo(this.root);
		}
		this.badge = badge;
		this.redraw();
	}

	get def(): BlockDef {
		return this.current;
	}

	/** 重新绑定方块数据（补充/洗牌后复用同一个控件实例）。 */
	setDef(def: BlockDef): void {
		this.current = def;
		const label = this.glyph;
		if (label !== undefined) {
			label.text = def.glyph;
		}
		this.redraw();
	}

	setLocked(on: boolean): void {
		if (this.locked === on) {
			return;
		}
		this.locked = on;
		if (!on) {
			// 解除封锁后立即收起剩余次数角标
			this.lockTurns = 0;
			this.applyBadge();
		}
		this.redraw();
	}

	/** 更新锁定剩余解除次数（0 = 隐藏），由视图按棋盘计时数据驱动。 */
	setLockTurns(turns: number): void {
		const next = turns > 0 ? Math.floor(turns) : 0;
		if (this.lockTurns === next) {
			return;
		}
		this.lockTurns = next;
		this.applyBadge();
		this.redraw();
	}

	/** 角标当前文本（隐藏时为空串，自检与调试用）。 */
	get badgeText(): string {
		const badge = this.badge;
		return badge !== undefined ? badge.text : '';
	}

	private applyBadge(): void {
		const badge = this.badge;
		if (badge === undefined) {
			return;
		}
		const show = this.locked && this.lockTurns > 0;
		badge.text = show ? '' + this.lockTurns : '';
		badge.visible = show;
		// 只剩最后一次敌人行动时用暖色提醒
		badge.color = this.lockTurns <= 1 ? Color(255, 156, 120, 255) : Color(255, 214, 120, 255);
	}

	protected drawSelf(): void {
		const size = this.width;
		const inset = Math.max(2, Math.floor(size * 0.06));
		const verts: Vec2.Type[] = [
			Vec2(inset, inset),
			Vec2(size - inset, inset),
			Vec2(size - inset, size - inset),
			Vec2(inset, size - inset),
		];
		const alpha = this.locked ? 130 : 255;
		const fill = colorFromHex(this.current.color, alpha);
		if (this.selected) {
			this.canvas.drawPolygon(verts, fill, 6, Color(255, 255, 255, 255));
		} else {
			this.canvas.drawPolygon(verts, fill, 2, colorFromHex(lighten(this.current.color, 0.35), 220));
		}
		if (this.locked && this.lockTurns > 0) {
			// 角标底盘：让剩余次数在深色封锁块上依旧清晰
			const radius = Math.max(9, Math.floor(size * 0.2));
			this.canvas.drawDot(
				Vec2(size - size * BlockWidget.badgeRatio, size - size * BlockWidget.badgeRatio),
				radius,
				Color(24, 26, 32, 235)
			);
		}
	}
}
