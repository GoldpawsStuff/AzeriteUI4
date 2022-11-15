--[[

	The MIT License (MIT)

	Copyright (c) 2022 Lars Norberg

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.

--]]
local Addon, ns = ...
local Config = ns.Config or {}
ns.Config = Config

-- Addon API
local Colors = ns.Colors
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia

local barSparkMap = {
	top = {
		{ keyPercent =   0/256, offset = -16/32 },
		{ keyPercent =   4/256, offset = -16/32 },
		{ keyPercent =  19/256, offset =   0/32 },
		{ keyPercent = 236/256, offset =   0/32 },
		{ keyPercent = 256/256, offset = -16/32 }
	},
	bottom = {
		{ keyPercent =   0/256, offset = -16/32 },
		{ keyPercent =   4/256, offset = -16/32 },
		{ keyPercent =  19/256, offset =   0/32 },
		{ keyPercent = 236/256, offset =   0/32 },
		{ keyPercent = 256/256, offset = -16/32 }
	}
}

Config.NamePlates = {

	Size = { 80, 32 },
	Orientation = "LEFT",
	OrientationReversed = "RIGHT",

	HealthBarPosition = { "TOP", 0, -2 },
	HealthBarSize = { 84, 14 },
	HealthBarTexCoord = { 14/256, 242/256, 14/64, 50/64 },
	HealthBarTexture = GetMedia("nameplate_bar"),
	HealthBarSparkMap = barSparkMap,

	HealthBackdropPosition = { "CENTER", 0, 0 },
	HealthBackdropSize = { 94.315789474, 24.888888889 },
	HealthBackdropTexture = GetMedia("nameplate_backdrop"),

	HealthValuePosition = { "TOP", 0, -18 },
	HealthValueJustifyH = "CENTER",
	HealthValueJustifyV = "MIDDLE",
	HealthValueFont = GetFont(12,true),
	HealthValueColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .5 },

	CastBarPosition = { "TOP", 0, -20 },
	CastBarPositionPlayer = { "TOP", 0, -(2 + 18 + 18) },
	CastBarSize = { 84, 14 },
	CastBarSparkMap = barSparkMap,
	CastBarOrientation = "LEFT",
	CastBarOrientationPlayer = "RIGHT",
	CastBarTexture = GetMedia("nameplate_bar"),
	CastBarTexCoord = { 14/256,(256-14)/256,14/64,(64-14)/64 },
	CastBarColor = { Colors.cast[1], Colors.cast[2], Colors.cast[3], 1 },

	CastBarBackdropPosition = { "CENTER", 0, 0 },
	CastBarBackdropSize = { 84*256/(256-28), 14*64/(64-28) },
	CastBarBackdropDrawLayer = { "BACKGROUND", 0 },
	CastBarBackdropTexture = GetMedia("nameplate_backdrop"),

	CastBarShieldDrawLayer = { "BACKGROUND", -5 },
	CastBarShieldPosition = { "CENTER", 0, -1 },
	CastBarShieldSize = { 124, 69 },
	CastBarShieldTexture = GetMedia("cast_back_spiked"),
	CastBarShieldColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },

	CastBarNameDrawLayer = { "OVERLAY", 1 },
	CastBarNamePosition = { "TOP", 0, -18 },
	CastBarNameJustifyH = "CENTER",
	CastBarNameJustifyV = "MIDDLE",
	CastBarNameFont = GetFont(12, true),
	CastBarNameColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .5 },

	PowerBarPosition = { "TOP", 0, -20 },
	PowerBarSize = { 84, 14 },
	PowerBarTexCoord = { 14/256, 242/256, 14/64, 50/64 },
	PowerBarOrientation = "RIGHT",
	PowerBarTexture = GetMedia("nameplate_bar"),
	PowerBarSparkMap = barSparkMap,
	PowerBarBackdropPosition = { "CENTER", 0, 0 },
	PowerBarBackdropSize = { 94.315789474, 24.888888889 },
	PowerBarBackdropTexture = GetMedia("nameplate_backdrop"),

	NamePosition = { "TOP", 0, 16 },
	NameDrawLayer = { "ARTWORK", 1 },
	NameJustifyH = "CENTER",
	NameJustifyV = "MIDDLE",
	NameFont = GetFont(12,true),
	NameColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .5 },

	ClassificationPosition = { "RIGHT", 18, -1 },
	ClassificationSize = { 40, 40 },
	ClassificationIndicatorBossTexture = GetMedia("icon_badges_boss"),
	ClassificationIndicatorEliteTexture = GetMedia("icon_classification_elite"),
	ClassificationIndicatorRareTexture = GetMedia("icon_classification_rare"),

	RaidTargetDrawLayer = { "ARTWORK", 0 },
	RaidTargetPoint = "BOTTOM",
	RaidTargetRelPoint = "TOP",
	RaidTargetOffsetX = 0,
	RaidTargetOffsetY = 6,
	RaidTargetSize = { 64, 64 },
	RaidTargetTexture = GetMedia("raid_target_icons"),

	TargetHighlightPosition = { "CENTER", 0, 0 },
	TargetHighlightSize = { 99.031578947, 29.866666667 },
	TargetHighlightTexture = GetMedia("nameplate_outline"),
	TargetHighlightFocusColor = { 144/255, 195/255, 255/255, 1 },
	TargetHighlightTargetColor = { 255/255, 239/255, 169/255, 1 },

	ThreatDrawLayer = { "BACKGROUND", -3 },
	ThreatPosition = { "CENTER", 0, 0 },
	ThreatSize = { 94.315789474, 24.888888889 },
	ThreatTexture = GetMedia("nameplate_glow")

}
