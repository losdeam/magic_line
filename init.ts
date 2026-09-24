// @preview-file on clear
// 入口：屏幕自适应 + 启动游戏主控制器（逐帧逻辑集中在 game/Game.ts 的单一 schedule 循环内）。

import { Director, Node, TypeName, View, tolua } from 'Dora';
import { Game } from 'game/Game';
import { zoomFor } from 'game/UiLayout';

// 场景根：内容全部挂在其下，便于在拿不到 2D 摄像机时直接缩放整个场景。
const scene = Node();
scene.addTo(Director.entry);

const updateViewSize = (): void => {
	// zoom 公式与 game/UiLayout.ts 的 zoomFor() 共用：自检会把同一函数在极端宽高比下的
	// 可见范围与安全区（960×1080 设计单位）对照断言，从而保证这里不会把 HUD 裁掉。
	const scale = zoomFor(View.size.width, View.size.height);
	const camera = tolua.cast(Director.currentCamera, TypeName.Camera2D);
	if (camera === undefined) {
		// 没有可用的 2D 摄像机时退化为直接缩放场景根节点，避免设计坐标被当成像素使用
		scene.scaleX = scale;
		scene.scaleY = scale;
		return;
	}
	camera.zoom = scale;
	scene.scaleX = 1;
	scene.scaleY = 1;
};

updateViewSize();
Director.entry.onAppChange((settingName) => {
	if (settingName === 'Size') {
		updateViewSize();
	}
});

// 窗口可能在入口初始化后才就绪，因此在场景根的独立 schedule 槽里再校正一次（只执行一次）
scene.schedule(() => {
	updateViewSize();
	return true;
});

const game = new Game(scene);
game.start();
