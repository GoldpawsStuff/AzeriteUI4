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

Config.Target = {

	-- General Settings
	-----------------------------------------
	Size = { 439, 93 },
	Position = { "TOPLEFT", -6, 6 },
	HitRectInsets = { 0, 0, 0, 6 },

	-- Auras
	-----------------------------------------
	AurasPosition = { "TOPRIGHT", -37, -87 },
	AurasSize = { 40*6 - 4, 40*2 - 4 },
	AurasSizeBoss = { 40*10 - 4, 40*2 - 4 },
	AuraSize = 36,
	AuraSpacing = 4,
	AurasNumTotal = 12,
	AurasNumTotalBoss = 20,
	AurasDisableMouse = false,
	AurasDisableCooldown = true,
	AurasOnlyShowPlayer = false,
	AurasShowStealableBuffs = false,
	AurasInitialAnchor = "TOPRIGHT",
	AurasSpacingX = 4,
	AurasSpacingY = 4,
	AurasGrowthX = "LEFT",
	AurasGrowthY = "DOWN",
	AurasTooltipAnchor = "ANCHOR_BOTTOMLEFT",
	AurasSortMethod = "TIME_REMAINING",
	AurasSortDirection = "DESCENDING",

	-- Seasonal Overrides & Additions
	-----------------------------------------
	Seasonal = {
		-- Love Festival Target Eye
		LoveFestivalCombatIndicatorPosition = { "BOTTOMLEFT", -61, 2 },
		LoveFestivalCombatIndicatorSize = { 48, 48 },
		LoveFestivalCombatIndicatorTexture = GetMedia("icon-heart-red"),
		LoveFestivalCombatIndicatorColor = { Colors.ui[1] *.75, Colors.ui[2] *.75, Colors.ui[3] *.75 },
	},

	-- Orb and Crystal Colors
	-----------------------------------------
	PowerBarColors = {
		ENERGY = { 0/255, 208/255, 176/255 },
		FOCUS = { 116/255, 156/255, 255/255 },
		LUNAR_POWER = { 116/255, 156/255, 255/255 },
		MAELSTROM = { 116/255, 156/255, 255/255 },
		RUNIC_POWER = { 116/255, 156/255, 255/255 },
		FURY = { 156/255, 116/255, 255/255 },
		INSANITY = { 156/255, 116/255, 255/255 },
		PAIN = { 156/255, 116/255, 255/255 },
		RAGE = { 156/255, 116/255, 255/255 },
		MANA = { 101/255, 93/255, 191/255 }
	},

	-- Level Specific Settings
	-----------------------------------------
	Critter = {},
	Novice = {},
	Hardened = {},
	Seasoned = {},
	Boss = {}
}
