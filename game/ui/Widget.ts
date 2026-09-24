// 轻量控件基类：只提供尺寸/锚点/可见与启用状态/绘制钩子/触控钩子/选中态。
// 刻意不引入布局系统、列表与滚动区域（见方案 R8）。

import { Color, DrawNode, Node, Size, Vec2 } from 'Dora';

/** 把 0xRRGGBB 转成 Dora 的 Color 对象。 */
export function colorFromHex(hex: number, alpha: number = 255): Color.Type {
	const r = Math.floor(hex / 65536) % 256;
	const g = Math.floor(hex / 256) % 256;
	const b = hex % 256;
	return Color(r, g, b, alpha);
}

/**
 * 所有 UI 元素的基类：方块、面板、按钮、血条、飘字均从此派生。
 * 控件自身不注册 schedule，动画由 Game 的单一循环调用 update(dt) 驱动。
 */
export class BaseWidget {
	readonly root: Node.Type;
	protected readonly canvas: DrawNode.Type;
	readonly width: number;
	readonly height: number;
	selected = false;
	enabled = true;
	/** 受击抖动的基准位置（由 setPosition 记录）。 */
	private baseX = 0;
	private baseY = 0;
	private shakeTimer = 0;
	private shakeDuration = 0.24;
	private shakeAmplitude = 5;

	constructor(width: number, height: number) {
		this.width = width;
		this.height = height;
		const root = Node();
		root.size = Size(width, height);
		root.anchor = Vec2(0.5, 0.5);
		root.touchEnabled = false;
		this.root = root;
		const canvas = DrawNode();
		canvas.addTo(root);
		this.canvas = canvas;
	}

	addTo(parent: Node.Type): void {
		this.root.addTo(parent);
	}

	setPosition(x: number, y: number): void {
		this.baseX = x;
		this.baseY = y;
		this.root.position = Vec2(x, y);
	}

	/** 受击抖动：在基准位置上做短促的水平抖动。 */
	shake(duration: number = 0.24, amplitude: number = 5): void {
		this.shakeDuration = duration > 0 ? duration : 0.24;
		this.shakeAmplitude = amplitude;
		this.shakeTimer = this.shakeDuration;
	}

	/** 推进抖动动画（由子类 update 调用，控件不自行注册 schedule）。 */
	protected advanceShake(dt: number): void {
		if (this.shakeTimer <= 0) {
			return;
		}
		this.shakeTimer -= dt;
		if (this.shakeTimer <= 0) {
			this.shakeTimer = 0;
			this.root.position = Vec2(this.baseX, this.baseY);
			return;
		}
		const t = this.shakeTimer / this.shakeDuration;
		this.root.position = Vec2(this.baseX + Math.sin(this.shakeTimer * 62) * this.shakeAmplitude * t, this.baseY);
	}

	get visible(): boolean {
		return this.root.visible;
	}

	set visible(value: boolean) {
		this.root.visible = value;
	}

	get z(): number {
		return this.root.z;
	}

	set z(value: number) {
		this.root.z = value;
	}

	/** 开启触控：仅注册手势插槽，不占用 schedule 槽。 */
	enableTouch(): void {
		this.root.touchEnabled = true;
		this.root.onTapBegan((touch) => this.handleTapBegan(touch.location));
		this.root.onTapMoved((touch) => this.handleTapMoved(touch.location));
		this.root.onTapEnded((touch) => this.handleTapEnded(touch.location));
	}

	setSelected(on: boolean): void {
		if (this.selected === on) {
			return;
		}
		this.selected = on;
		this.redraw();
	}

	/** 由 Game 的单一循环统一驱动；基类无动画。 */
	update(_dt: number): void {
	}

	redraw(): void {
		this.canvas.clear();
		this.drawSelf();
	}

	/** 子类在此绘制自身内容，画布原点在控件矩形左下角。 */
	protected drawSelf(): void {
	}

	protected handleTapBegan(_location: Vec2.Type): void {
	}

	protected handleTapMoved(_location: Vec2.Type): void {
	}

	protected handleTapEnded(_location: Vec2.Type): void {
	}
}
