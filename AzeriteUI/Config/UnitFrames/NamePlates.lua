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

	HealthBarPosition = { "TOP", 0, -2 },
	HealthBarSize = { 84, 14 },
	HealthBarTexCoord = { 14/256, 242/256, 14/64, 50/64 },
	HealthBarTexture = GetMedia("nameplate_bar"),
	HealthBarSparkMap = barSparkMap,
	HealthBarOrientation = "LEFT",
	HealthBarOrientationPlayer = "RIGHT",

	HealthBackdropPosition = { "CENTER", 0, 0 },
	HealthBackdropSize = { 94.315789474, 24.888888889 },
	HealthBackdropTexture = GetMedia("nameplate_backdrop"),

	HealthValuePosition = { "TOP", 0, -18 },
	HealthValueJustifyH = "CENTER",
	HealthValueJustifyV = "MIDDLE",
	HealthValueFontObject = GetFont(12,true),
	HealthValueColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .5 },

	PowerBarPosition = { "TOP", 0, -20 },
	PowerBarSize = { 84, 14 },
	PowerBarTexCoord = { 14/256, 242/256, 14/64, 50/64 },
	PowerBarOrientation = "RIGHT",
	PowerBarTexture = GetMedia("nameplate_bar"),
	PowerBarSparkMap = barSparkMap,
	PowerBarBackdropPlace = { "CENTER", 0, 0 },
	PowerBarBackdropSize = { 94.315789474, 24.888888889 },
	PowerBarBackdropTexture = GetMedia("nameplate_backdrop"),

	RaidTargetDrawLayer = { "ARTWORK", 0 },
	RaidTargetPoint = "BOTTOM",
	RaidTargetRelPoint = "TOP",
	RaidTargetOffsetX = 0,
	RaidTargetOffsetY = 6,
	RaidTargetSize = { 64, 64 },
	RaidTargetTexture = GetMedia("raid_target_icons"),

	TargetHighlightSize = { 99.031578947, 29.866666667 },
	TargetHighlightTexture = GetMedia("nameplate_outline"),
	TargetHighlightFocusColor = { 144/255, 195/255, 255/255, 1 },
	TargetHighlightTargetColor = { 255/255, 239/255, 169/255, 1 },

	ThreatDrawLayer = { "BACKGROUND", -3 },
	ThreatPosition = { "CENTER", 0, 0 },
	ThreatSize = { 94.315789474, 24.888888889 },
	ThreatTexture = GetMedia("nameplate_glow")

}
