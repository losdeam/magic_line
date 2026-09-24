-- [ts]: init.ts
local ____lualib = require("lualib_bundle") -- 1
local __TS__New = ____lualib.__TS__New -- 1
local ____exports = {} -- 1
local ____Dora = require("Dora") -- 4
local Director = ____Dora.Director -- 4
local Node = ____Dora.Node -- 4
local View = ____Dora.View -- 4
local tolua = ____Dora.tolua -- 4
local ____Game = require("game.Game") -- 5
local Game = ____Game.Game -- 5
local ____UiLayout = require("game.UiLayout") -- 6
local zoomFor = ____UiLayout.zoomFor -- 6
local scene = Node() -- 9
scene:addTo(Director.entry) -- 10
local function updateViewSize() -- 12
	local scale = zoomFor(View.size.width, View.size.height) -- 15
	local camera = tolua.cast(Director.currentCamera, "Camera2D") -- 16
	if camera == nil then -- 16
		scene.scaleX = scale -- 19
		scene.scaleY = scale -- 20
		return -- 21
	end -- 21
	camera.zoom = scale -- 23
	scene.scaleX = 1 -- 24
	scene.scaleY = 1 -- 25
end -- 12
updateViewSize() -- 28
Director.entry:onAppChange(function(settingName) -- 29
	if settingName == "Size" then -- 29
		updateViewSize() -- 31
	end -- 31
end) -- 29
scene:schedule(function() -- 36
	updateViewSize() -- 37
	return true -- 38
end) -- 36
local game = __TS__New(Game, scene) -- 41
game:start() -- 42
return ____exports -- 42