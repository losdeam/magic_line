// 复用 BaseWidget 的基础 UI 控件：面板 / 进度条 / 按钮 / 飘字，以及统一的文本标签工厂。
// 所有控件自身不注册 schedule，动画由 Game 的单一循环调用 update(dt) 驱动。

import { Color, Label, Vec2 } from 'Dora';
import { BaseWidget, colorFromHex } from 'game/ui/Widget';

/** 统一创建文本标签（`Label` 可能返回 undefined，因此集中判空与设置锚点）。 */
export function makeLabel(text: string, fontSize: number): Label.Type | undefined {
	const label = Label('sarasa-mono-sc-regular', fontSize);
	if (label === undefined) {
		return undefined;
	}
	label.text = text;
	label.color = Color(240, 245, 255, 255);
	label.anchor = Vec2(0.5, 0.5);
	return label;
}

/** 纯色面板：HUD 底板与结算面板背景。 */
export class PanelWidget extends BaseWidget {
	private fillHex: number;

	constructor(width: number, height: number, fillHex: number) {
		super(width, height);
		this.fillHex = fillHex;
		this.redraw();
	}

	protected drawSelf(): void {
		this.canvas.drawPolygon(
			[Vec2(0, 0), Vec2(this.width, 0), Vec2(this.width, this.height), Vec2(0, this.height)],
			colorFromHex(this.fillHex, 235),
			2,
			colorFromHex(0x7f8ca3, 200)
		);
	}
}

/** 进度条：血条 / 魔力条 / 敌方血条；内置数值文本，并做缓动过渡。 */
export class BarWidget extends BaseWidget {
	private readonly label: Label.Type | undefined;
	/** 当前显示比例（缓动逼近 targetRatio）。 */
	private shownRatio = 1;
	private targetRatio = 1;
	private initialized = false;
	private fillHex: number;
	/** 受击闪烁：剩余时间与颜色（血条受击反馈）。 */
	private flashTimer = 0;
	private flashDuration = 0.24;
	private flashHex = 0xffffff;
	/** 上次的映射文本，用于判断是否需要重绘。 */
	private lastText = '';

	/** 受击闪烁：血条短暂叠一层亮色。 */
	flash(hex: number, duration: number): void {
		this.flashHex = hex;
		this.flashDuration = duration > 0 ? duration : 0.24;
		this.flashTimer = this.flashDuration;
		this.redraw();
	}

	constructor(width: number, height: number, fillHex: number) {
		super(width, height);
		this.fillHex = fillHex;
		const label = makeLabel('', Math.max(14, Math.floor(height * 0.66)));
		if (label !== undefined) {
			label.position = Vec2(width / 2, height / 2);
			label.addTo(this.root);
		}
		this.label = label;
		this.redraw();
	}

	/** 设置显示文本与进度（value/max 会自动夹在 0~1，并缓动过渡）。 */
	set(text: string, value: number, max: number): void {
		let ratio = max > 0 ? value / max : 0;
		if (ratio < 0) {
			ratio = 0;
		}
		if (ratio > 1) {
			ratio = 1;
		}
		this.targetRatio = ratio;
		if (!this.initialized) {
			// 首次赋值直接对齐，避免启动时出现无意义的滑动
			this.initialized = true;
			this.shownRatio = ratio;
		}
		if (this.label !== undefined) {
			this.label.text = text;
		}
		this.lastText = text;
		this.redraw();
	}

	/** 当前的数值文本（自检与外部系统只读）。 */
	get text(): string {
		return this.lastText;
	}

	/** 逐帧缓动 + 受击闪烁（由 Game 的单一循环驱动）。 */
	update(dt: number): void {
		this.advanceShake(dt);
		let needRedraw = false;
		if (this.flashTimer > 0) {
			this.flashTimer -= dt;
			if (this.flashTimer < 0) {
				this.flashTimer = 0;
			}
			needRedraw = true;
		}
		const gap = this.targetRatio - this.shownRatio;
		if (Math.abs(gap) >= 0.002) {
			let step = dt * 7;
			if (step > 1) {
				step = 1;
			}
			this.shownRatio += gap * step;
			needRedraw = true;
		} else if (this.shownRatio !== this.targetRatio) {
			this.shownRatio = this.targetRatio;
			needRedraw = true;
		}
		if (needRedraw) {
			this.redraw();
		}
	}

	protected drawSelf(): void {
		const w = this.width;
		const h = this.height;
		this.canvas.drawPolygon([Vec2(0, 0), Vec2(w, 0), Vec2(w, h), Vec2(0, h)], colorFromHex(0x11161f, 230));
		if (this.shownRatio > 0) {
			this.canvas.drawPolygon(
				[Vec2(0, 0), Vec2(w * this.shownRatio, 0), Vec2(w * this.shownRatio, h), Vec2(0, h)],
				colorFromHex(this.fillHex, 240)
			);
		}
		// 受击闪烁：在填充之上叠一层亮色后淡出
		if (this.flashTimer > 0) {
			const alpha = Math.floor(200 * (this.flashTimer / this.flashDuration));
			this.canvas.drawPolygon(
				[Vec2(0, 0), Vec2(w, 0), Vec2(w, h), Vec2(0, h)],
				colorFromHex(this.flashHex, alpha)
			);
		}
		// 描边：魔力条装满前也能看清条的边界。
		// 注意：drawPolygon 的填充色默认是【白色】，传 undefined 会把整条涂成纯白，
		// 因此这里显式传全透明填充色，只保留边框。
		this.canvas.drawPolygon(
			[Vec2(0, 0), Vec2(w, 0), Vec2(w, h), Vec2(0, h)],
			Color(0, 0, 0, 0),
			2,
			colorFromHex(0x8fa2bd, 170)
		);
	}
}

/** 按钮：点按结束触发 `onClick`；禁用时变灰且不再接收触控。 */
export class ButtonWidget extends BaseWidget {
	private readonly label: Label.Type | undefined;
	private hex: number;
	/** 按下反馈：按住期间整体缩小，松手复位。 */
	private pressed = false;
	/** 成功反馈：按钮叠一层亮光后淡出（技能释放等）。 */
	private glowTimer = 0;
	private readonly glowDuration = 0.45;
	onClick: () => void = () => {};

	constructor(text: string, width: number, height: number, hex: number) {
		super(width, height);
		this.hex = hex;
		const label = makeLabel(text, Math.max(16, Math.floor(height * 0.4)));
		if (label !== undefined) {
			label.position = Vec2(width / 2, height / 2);
			label.addTo(this.root);
		}
		this.label = label;
		this.enableTouch();
		this.redraw();
	}

	setText(text: string): void {
		if (this.label !== undefined) {
			this.label.text = text;
		}
	}

	/** 成功反馈：按钮亮一下（技能释放、开关切换等可见动效）。 */
	glow(): void {
		this.glowTimer = this.glowDuration;
		this.redraw();
	}

	/** 推进按下与亮光动画（由 Game 的单一循环驱动，按钮不自行注册 schedule）。 */
	update(dt: number): void {
		this.advanceShake(dt);
		if (this.glowTimer <= 0) {
			return;
		}
		this.glowTimer -= dt;
		if (this.glowTimer < 0) {
			this.glowTimer = 0;
		}
		this.redraw();
	}

	setEnabled(on: boolean): void {
		if (this.enabled === on) {
			return;
		}
		this.enabled = on;
		this.root.touchEnabled = on;
		this.redraw();
	}

	protected handleTapBegan(_location: Vec2.Type): void {
		if (!this.enabled) {
			return;
		}
		this.pressed = true;
		this.root.scaleX = 0.93;
		this.root.scaleY = 0.93;
	}

	protected handleTapEnded(_location: Vec2.Type): void {
		if (this.pressed) {
			this.pressed = false;
			this.root.scaleX = 1;
			this.root.scaleY = 1;
		}
		if (this.enabled) {
			this.onClick();
		}
	}

	protected drawSelf(): void {
		const w = this.width;
		const h = this.height;
		const base = this.enabled ? this.hex : 0x39414f;
		this.canvas.drawPolygon(
			[Vec2(0, 0), Vec2(w, 0), Vec2(w, h), Vec2(0, h)],
			colorFromHex(base, 245),
			3,
			colorFromHex(0x9fb3d1, 220)
		);
		if (this.glowTimer > 0) {
			const alpha = Math.floor(215 * (this.glowTimer / this.glowDuration));
			this.canvas.drawPolygon([Vec2(0, 0), Vec2(w, 0), Vec2(w, h), Vec2(0, h)], Color(255, 255, 255, alpha));
		}
	}
}

/** 飘字：向上飘并淡出，用于展示效果与提示。 */
export class FloatTextWidget extends BaseWidget {
	private readonly label: Label.Type | undefined;
	private readonly duration = 1.2;
	private life = 0;

	constructor(fontSize: number) {
		super(560, 40);
		const label = makeLabel('', fontSize);
		if (label !== undefined) {
			label.position = Vec2(280, 20);
			label.addTo(this.root);
		}
		this.label = label;
		this.visible = false;
	}

	get active(): boolean {
		return this.life > 0;
	}

	show(text: string, hex: number, x: number, y: number): void {
		if (this.label !== undefined) {
			this.label.text = text;
			this.label.color = colorFromHex(hex, 255);
		}
		this.life = this.duration;
		this.visible = true;
		this.root.opacity = 1;
		this.setPosition(x, y);
	}

	update(dt: number): void {
		if (this.life <= 0) {
			return;
		}
		this.life -= dt;
		if (this.life <= 0) {
			this.life = 0;
			this.visible = false;
			return;
		}
		const t = this.life / this.duration;
		this.root.position = Vec2(this.root.x, this.root.y + 46 * dt);
		this.root.opacity = t > 0.5 ? 1 : t * 2;
	}
}
