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

local Colors = ns.Colors
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia

Config.Player = {

	-- General Settings
	-----------------------------------------
	Size = { 439, 93 },
	Position = { "BOTTOMLEFT", 167, 100 },

	-- Orb and Crystal Colors
	ManaOrbColor = { 135/255, 125/255, 255/255 },
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

	Seasonal = {

		-- Winter Veil Power Crystal Decorations
		WinterVeilPowerSize = { 197, 197 },
		WinterVeilPowerPlace = { "CENTER", -2, 24 },
		WinterVeilPowerTexture = GetMedia("seasonal_winterveil_crystal"),

		-- Winter Veil Mana Orb Decorations
		WinterVeilManaSize = { 188, 188 },
		WinterVeilManaPlace = { "CENTER", 0, 0 },
		WinterVeilManaTexture = GetMedia("seasonal_winterveil_orb")
	},

	-- Level Specific Settings
	-----------------------------------------
	Novice = {

		-- Health Bar
		HealthBarSize = { 385, 37 },
		HealthBarPosition = { "BOTTOMLEFT", 27, 27 },
		HealthBarTexture = GetMedia("hp_lowmid_bar"),
		HealthBarColor = { Colors.health[1], Colors.health[2], Colors.health[3] },
		HealthBarOrientation = "RIGHT",
		HealthBarSparkMap = {
			{ ["keyPercent"] =   0/512, ["topOffset"] = -24/64, ["bottomOffset"] = -39/64 },
			{ ["keyPercent"] =   9/512, ["topOffset"] =   0/64, ["bottomOffset"] = -16/64 },
			{ ["keyPercent"] = 460/512, ["topOffset"] =   0/64, ["bottomOffset"] = -16/64 },
			{ ["keyPercent"] = 478/512, ["topOffset"] =   0/64, ["bottomOffset"] =   0/64 },
			{ ["keyPercent"] = 483/512, ["topOffset"] =   0/64, ["bottomOffset"] =  -3/64 },
			{ ["keyPercent"] = 507/512, ["topOffset"] =   0/64, ["bottomOffset"] = -46/64 },
			{ ["keyPercent"] = 512/512, ["topOffset"] = -11/64, ["bottomOffset"] = -54/64 }
		},
		HealthBackdropSize = { 716, 188 },
		HealthBackdropPosition = { "CENTER", 1, -.5 },
		HealthBackdropTexture = GetMedia("hp_low_case"),
		HealthBackdropColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },
		HealthCastOverlayColor = { 1, 1, 1, .35 },
		HealthThreatTexture = GetMedia("hp_low_case_glow"),

		-- Power Crystal
		PowerBarSize = { 120, 140 },
		PowerBarPosition = { "BOTTOMLEFT", -101, 38 },
		PowerBarTexture = ns.IsWrath and GetMedia("power-crystal-ice-front") or GetMedia("power_crystal_front"),
		PowerBarTexCoord = { 50/255, 206/255, 37/255, 219/255 },
		PowerBarOrientation = "UP",
		PowerBarSparkMap = {
			["top"] = {
				{ ["keyPercent"] =   0/256, offset =  -65/256 },
				{ ["keyPercent"] =  72/256, offset =    0/256 },
				{ ["keyPercent"] = 116/256, offset =  -16/256 },
				{ ["keyPercent"] = 128/256, offset =  -28/256 },
				{ ["keyPercent"] = 256/256, offset =  -84/256 },
			},
			["bottom"] = {
				{ ["keyPercent"] =   0/256, offset =  -47/256 },
				{ ["keyPercent"] =  84/256, offset =    0/256 },
				{ ["keyPercent"] = 135/256, offset =  -24/256 },
				{ ["keyPercent"] = 142/256, offset =  -32/256 },
				{ ["keyPercent"] = 225/256, offset =  -79/256 },
				{ ["keyPercent"] = 256/256, offset = -168/256 },
			}
		},

		PowerBackdropSize = { 196, 196 },
		PowerBackdropPosition = { "CENTER", 0, 0 },
		PowerBackdropTexture = ns.IsWrath and GetMedia("power-crystal-ice-back") or GetMedia("power_crystal_back"),

		PowerBarForegroundSize = { 198,98 },
		PowerBarForegroundPosition = { "BOTTOM", 7, -51 },
		PowerBarForegroundTexture = GetMedia("pw_crystal_case_low"),
		PowerBarForegroundColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },

		-- Mana Orb
		ManaOrbSize = { 103, 103 },
		ManaOrbPosition = { "BOTTOMLEFT", -92, 27 },
		ManaOrbTexture = { GetMedia("orb2"), GetMedia("orb2") },

		ManaOrbBackdropSize = { 180, 180 },
		ManaOrbBackdropPosition = { "CENTER", 0, 0 },
		ManaOrbBackdropTexture = GetMedia("orb-backdrop2"),
		ManaOrbBackdropColor = { 1, 1, 1, 1 },

		ManaOrbShadeSize = { 127, 127 },
		ManaOrbShadePosition = { "CENTER", 0, 0 },
		ManaOrbShadeTexture = GetMedia("shade-circle"),
		ManaOrbShadeColor = { 0, 0, 0, 1 },

		ManaOrbForegroundSize = { 188, 188 },
		ManaOrbForegroundPosition = { "CENTER", 0, 0 },
		ManaOrbForegroundTexture = GetMedia("orb_case_low"),
		ManaOrbForegroundColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },

		-- Combat Feedback
		CombatFeedbackAnchorElement = "Health",
		CombatFeedbackPosition = { "CENTER", 0, 0 },
		CombatFeedbackFont = GetFont(20, true), -- standard font
		CombatFeedbackFontLarge = GetFont(24, true), -- crit/drushing font
		CombatFeedbackFontSmall = GetFont(18, true), -- glancing blow font

	},
	Hardened = {

		-- Health Bar
		HealthBarSize = { 385, 37 },
		HealthBarPosition = { "BOTTOMLEFT", 27, 27 },
		HealthBarTexture = GetMedia("hp_lowmid_bar"),
		HealthBarColor = { Colors.health[1], Colors.health[2], Colors.health[3] },
		HealthBarOrientation = "RIGHT",
		HealthBarSparkMap = {
			{ ["keyPercent"] =   0/512, ["topOffset"] = -24/64, ["bottomOffset"] = -39/64 },
			{ ["keyPercent"] =   9/512, ["topOffset"] =   0/64, ["bottomOffset"] = -16/64 },
			{ ["keyPercent"] = 460/512, ["topOffset"] =   0/64, ["bottomOffset"] = -16/64 },
			{ ["keyPercent"] = 478/512, ["topOffset"] =   0/64, ["bottomOffset"] =   0/64 },
			{ ["keyPercent"] = 483/512, ["topOffset"] =   0/64, ["bottomOffset"] =  -3/64 },
			{ ["keyPercent"] = 507/512, ["topOffset"] =   0/64, ["bottomOffset"] = -46/64 },
			{ ["keyPercent"] = 512/512, ["topOffset"] = -11/64, ["bottomOffset"] = -54/64 }
		},
		HealthBackdropSize = { 716, 188 },
		HealthBackdropPosition = { "CENTER", 1, -.5 },
		HealthBackdropTexture = GetMedia("hp_mid_case"),
		HealthBackdropColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },
		HealthCastOverlayColor = { 1, 1, 1, .35 },
		HealthThreatTexture = GetMedia("hp_mid_case_glow"),

		-- Power Crystal
		PowerBarSize = { 120, 140 },
		PowerBarPosition = { "BOTTOMLEFT", -101, 38 },
		PowerBarTexture = ns.IsWrath and GetMedia("power-crystal-ice-front") or GetMedia("power_crystal_front"),
		PowerBarTexCoord = { 50/255, 206/255, 37/255, 219/255 },
		PowerBarOrientation = "UP",
		PowerBarSparkMap = {
			["top"] = {
				{ ["keyPercent"] =   0/256, offset =  -65/256 },
				{ ["keyPercent"] =  72/256, offset =    0/256 },
				{ ["keyPercent"] = 116/256, offset =  -16/256 },
				{ ["keyPercent"] = 128/256, offset =  -28/256 },
				{ ["keyPercent"] = 256/256, offset =  -84/256 },
			},
			["bottom"] = {
				{ ["keyPercent"] =   0/256, offset =  -47/256 },
				{ ["keyPercent"] =  84/256, offset =    0/256 },
				{ ["keyPercent"] = 135/256, offset =  -24/256 },
				{ ["keyPercent"] = 142/256, offset =  -32/256 },
				{ ["keyPercent"] = 225/256, offset =  -79/256 },
				{ ["keyPercent"] = 256/256, offset = -168/256 },
			}
		},

		PowerBackdropSize = { 196, 196 },
		PowerBackdropPosition = { "CENTER", 0, 0 },
		PowerBackdropTexture = ns.IsWrath and GetMedia("power-crystal-ice-back") or GetMedia("power_crystal_back"),

		PowerBarForegroundSize = { 198,98 },
		PowerBarForegroundPosition = { "BOTTOM", 7, -51 },
		PowerBarForegroundTexture = GetMedia("pw_crystal_case"),
		PowerBarForegroundColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },

		-- Mana Orb
		ManaOrbSize = { 103, 103 },
		ManaOrbPosition = { "BOTTOMLEFT", -92, 27 },
		ManaOrbTexture = { GetMedia("orb2"), GetMedia("orb2") },

		ManaOrbBackdropSize = { 180, 180 },
		ManaOrbBackdropPosition = { "CENTER", 0, 0 },
		ManaOrbBackdropTexture = GetMedia("orb-backdrop2"),
		ManaOrbBackdropColor = { 1, 1, 1, 1 },

		ManaOrbShadeSize = { 127, 127 },
		ManaOrbShadePosition = { "CENTER", 0, 0 },
		ManaOrbShadeTexture = GetMedia("shade-circle"),
		ManaOrbShadeColor = { 0, 0, 0, 1 },

		ManaOrbForegroundSize = { 188, 188 },
		ManaOrbForegroundPosition = { "CENTER", 0, 0 },
		ManaOrbForegroundTexture = GetMedia("orb_case_hi"),
		ManaOrbForegroundColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },

		-- Combat Feedback
		CombatFeedbackAnchorElement = "Health",
		CombatFeedbackPosition = { "CENTER", 0, 0 },
		CombatFeedbackFont = GetFont(20, true), -- standard font
		CombatFeedbackFontLarge = GetFont(24, true), -- crit/drushing font
		CombatFeedbackFontSmall = GetFont(18, true), -- glancing blow font

	},
	Seasoned = {

		-- Health Bar
		HealthBarSize = { 385, 40 },
		HealthBarPosition = { "BOTTOMLEFT", 27, 27 },
		HealthBarTexture = GetMedia("hp_cap_bar"),
		HealthBarColor = { Colors.health[1], Colors.health[2], Colors.health[3] },
		HealthBarOrientation = "RIGHT",
		HealthBarSparkMap = {
			{ ["keyPercent"] =   0/512, ["topOffset"] = -24/64, ["bottomOffset"] = -39/64 },
			{ ["keyPercent"] =   9/512, ["topOffset"] =   0/64, ["bottomOffset"] = -16/64 },
			{ ["keyPercent"] = 460/512, ["topOffset"] =   0/64, ["bottomOffset"] = -16/64 },
			{ ["keyPercent"] = 478/512, ["topOffset"] =   0/64, ["bottomOffset"] =   0/64 },
			{ ["keyPercent"] = 483/512, ["topOffset"] =   0/64, ["bottomOffset"] =  -3/64 },
			{ ["keyPercent"] = 507/512, ["topOffset"] =   0/64, ["bottomOffset"] = -46/64 },
			{ ["keyPercent"] = 512/512, ["topOffset"] = -11/64, ["bottomOffset"] = -54/64 }
		},
		HealthBackdropSize = { 716, 188 },
		HealthBackdropPosition = { "CENTER", 1, -.5 },
		HealthBackdropTexture = GetMedia("hp_cap_case"),
		HealthBackdropColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },
		HealthCastOverlayColor = { 1, 1, 1, .35 },
		HealthThreatTexture = GetMedia("hp_cap_case_glow"),

		-- Power Crystal
		PowerBarSize = { 120, 140 },
		PowerBarPosition = { "BOTTOMLEFT", -101, 38 },
		PowerBarTexture = ns.IsWrath and GetMedia("power-crystal-ice-front") or GetMedia("power_crystal_front"),
		PowerBarTexCoord = { 50/255, 206/255, 37/255, 219/255 },
		PowerBarOrientation = "UP",
		PowerBarSparkMap = {
			["top"] = {
				{ ["keyPercent"] =   0/256, offset =  -65/256 },
				{ ["keyPercent"] =  72/256, offset =    0/256 },
				{ ["keyPercent"] = 116/256, offset =  -16/256 },
				{ ["keyPercent"] = 128/256, offset =  -28/256 },
				{ ["keyPercent"] = 256/256, offset =  -84/256 },
			},
			["bottom"] = {
				{ ["keyPercent"] =   0/256, offset =  -47/256 },
				{ ["keyPercent"] =  84/256, offset =    0/256 },
				{ ["keyPercent"] = 135/256, offset =  -24/256 },
				{ ["keyPercent"] = 142/256, offset =  -32/256 },
				{ ["keyPercent"] = 225/256, offset =  -79/256 },
				{ ["keyPercent"] = 256/256, offset = -168/256 },
			}
		},

		PowerBackdropSize = { 196, 196 },
		PowerBackdropPosition = { "CENTER", 0, 0 },
		PowerBackdropTexture = ns.IsWrath and GetMedia("power-crystal-ice-back") or GetMedia("power_crystal_back"),

		PowerBarForegroundSize = { 198,98 },
		PowerBarForegroundPosition = { "BOTTOM", 7, -51 },
		PowerBarForegroundTexture = GetMedia("pw_crystal_case"),
		PowerBarForegroundColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },

		-- Mana Orb
		ManaOrbSize = { 103, 103 },
		ManaOrbPosition = { "BOTTOMLEFT", -92, 27 },
		ManaOrbTexture = { GetMedia("orb2"), GetMedia("orb2") },

		ManaOrbBackdropSize = { 180, 180 },
		ManaOrbBackdropPosition = { "CENTER", 0, 0 },
		ManaOrbBackdropTexture = GetMedia("orb-backdrop2"),
		ManaOrbBackdropColor = { 1, 1, 1, 1 },

		ManaOrbShadeSize = { 127, 127 },
		ManaOrbShadePosition = { "CENTER", 0, 0 },
		ManaOrbShadeTexture = GetMedia("shade-circle"),
		ManaOrbShadeColor = { 0, 0, 0, 1 },

		ManaOrbForegroundSize = { 188, 188 },
		ManaOrbForegroundPosition = { "CENTER", 0, 0 },
		ManaOrbForegroundTexture = GetMedia("orb_case_hi"),
		ManaOrbForegroundColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },

		-- Combat Feedback
		CombatFeedbackAnchorElement = "Health",
		CombatFeedbackPosition = { "CENTER", 0, 0 },
		CombatFeedbackFont = GetFont(20, true), -- standard font
		CombatFeedbackFontLarge = GetFont(24, true), -- crit/drushing font
		CombatFeedbackFontSmall = GetFont(18, true), -- glancing blow font

	}
}
