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

local castBarSparkMap = {
	top = {
		{ keyPercent =   0/128, offset = -16/32 },
		{ keyPercent =  10/128, offset =   0/32 },
		{ keyPercent = 119/128, offset =   0/32 },
		{ keyPercent = 128/128, offset = -16/32 }
	},
	bottom = {
		{ keyPercent =   0/128, offset = -16/32 },
		{ keyPercent =  10/128, offset =   0/32 },
		{ keyPercent = 119/128, offset =   0/32 },
		{ keyPercent = 128/128, offset = -16/32 }
	}
}

-- Proper conversion constant.
local deg2rad = math.pi / 180
local degreesToRadians = function(degrees)
	return degrees*deg2rad
end

Config.PlayerHUD = {

	-- Cast Bar
	CastBarPosition = { "BOTTOM", UIParent, "BOTTOM", 0, 290 },
	CastBarSize = { 112, 11 },
	CastBarTexture = GetMedia("cast_bar"),
	CastBarColor = { Colors.cast[1], Colors.cast[2], Colors.cast[3], .69 },
	CastBarOrientation = "RIGHT",
	CastBarSparkMap = castBarSparkMap,
	CastBarTimeToHoldFailed = .5,

	CastBarSpellQueueTexture = GetMedia("cast_bar"),
	CastBarSpellQueueColor = { 1, 1, 1, .5 },

	CastBarBackgroundPosition = { "CENTER", 1, -1 },
	CastBarBackgroundSize = { 193,93 },
	CastBarBackgroundTexture = GetMedia("cast_back"),
	CastBarBackgroundColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },

	CastBarTextPosition = { "TOP", 0, -26 },
	CastBarTextJustifyH = "CENTER",
	CastBarTextJustifyV = "MIDDLE",
	CastBarTextFont = GetFont(15, true),
	CastBarTextColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .5 },

	CastBarValuePosition = { "CENTER", 0, 0 },
	CastBarValueJustifyH = "CENTER",
	CastBarValueJustifyV = "MIDDLE",
	CastBarValueFont = GetFont(14, true),
	CastBarValueColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .5 },

	CastBarShieldPosition = { "CENTER", 1, -2 },
	CastBarShieldSize = { 193, 93 },
	CastBarShieldTexture = GetMedia("cast_back_spiked"),
	CastBarShieldColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },

	-- Class Power
	-- *also include layout data for Stagger and Runes,
	--  which are separate elements from ClassPower.
	ClassPowerPointOrientation = "UP",
	ClassPowerSparkTexture = GetMedia("blank"),
	ClassPowerCaseColor = { 211/255, 200/255, 169/255 },
	ClassPowerSlotColor = { 130/255 *.3, 133/255 *.3, 130/255 *.3, 2/3 },
	ClassPowerSlotOffset = 1.5,

	-- Note that the following are just layout names.
	-- They may not always be used for what their name implies.
	-- The important part is number of points and layout. Not powerType.
	ClassPowerLayouts = {
		Stagger = { --[[ 3 ]]
			[1] = {
				Position = { "CENTER", UIParent, "CENTER", -223, -109 },
				Size = { 13, 13 }, BackdropSize = { 60, 60 },
				Texture = GetMedia("point_crystal"), BackdropTexture = GetMedia("point_plate"),
				Rotation = degreesToRadians(5)
			},
			[2] = {
				Position = { "CENTER", UIParent, "CENTER", -234, -73 },
				Size = { 39, 40 }, BackdropSize = { 80, 80 },
				Texture = GetMedia("point_hearth"), BackdropTexture = GetMedia("point_plate"),
				Rotation = nil
			},
			[3] = {
				Position = { "CENTER", UIParent, "CENTER", -221, -36 },
				Size = { 13, 13 }, BackdropSize = { 60, 60 },
				Texture = GetMedia("point_crystal"), BackdropTexture = GetMedia("point_plate"),
				Rotation = nil
			}
		},
		ArcaneCharges = { --[[ 4 ]]
			[1] = {
				Position = { "CENTER", UIParent, "CENTER", -207, -139 },
				Size = { 13, 13 }, BackdropSize = { 58, 58 },
				Texture = GetMedia("point_crystal"), BackdropTexture = GetMedia("point_plate"),
				Rotation = degreesToRadians(6)
			},
			[2] = {
				Position = { "CENTER", UIParent, "CENTER", -228, -111 },
				Size = { 13, 13 }, BackdropSize = { 60, 60 },
				Texture = GetMedia("point_crystal"),  BackdropTexture = GetMedia("point_plate"),
				Rotation = degreesToRadians(5)
			},
			[3] = {
				Position = { "CENTER", UIParent, "CENTER", -236, -76 },
				Size = { 13, 13 }, BackdropSize = { 60, 60 },
				Texture = GetMedia("point_crystal"),  BackdropTexture = GetMedia("point_plate"),
				Rotation = degreesToRadians(4)
			},
			[4] = {
				Position = { "CENTER", UIParent, "CENTER", -213, -33 },
				Size = { 51, 52 }, BackdropSize = { 104, 104 },
				Texture = GetMedia("point_hearth"),  BackdropTexture = GetMedia("point_plate"),
				Rotation = nil
			}
		},
		ComboPoints = { --[[ 5 ]]
			[1] = {
				Position = { "CENTER", UIParent, "CENTER", -203, -137 },
				Size = { 13, 13 }, BackdropSize = { 58, 58 },
				Texture = GetMedia("point_crystal"),  BackdropTexture = GetMedia("point_plate"),
				Rotation = degreesToRadians(6)
			},
			[2] = {
				Position = { "CENTER", UIParent, "CENTER", -221, -111 },
				Size = { 13, 13 }, BackdropSize = { 60, 60 },
				Texture = GetMedia("point_crystal"),  BackdropTexture = GetMedia("point_plate"),
				Rotation = degreesToRadians(5)
			},
			[3] = {
				Position = { "CENTER", UIParent, "CENTER", -231, -79 },
				Size = { 13, 13 }, BackdropSize = { 60, 60 },
				Texture = GetMedia("point_crystal"),  BackdropTexture = GetMedia("point_plate"),
				Rotation = degreesToRadians(4)
			},
			[4] = {
				Position = { "CENTER", UIParent, "CENTER", -225, -44 },
				Size = { 13, 13 }, BackdropSize = { 60, 60 },
				Texture = GetMedia("point_crystal"),  BackdropTexture = GetMedia("point_plate"),
				Rotation = nil
			},
			[5] = {
				Position = { "CENTER", UIParent, "CENTER", -203, -11 },
				Size = { 14, 21 }, BackdropSize = { 82, 96 },
				Texture = GetMedia("point_crystal"),  BackdropTexture = GetMedia("point_diamond"),
				Rotation = degreesToRadians(1)
			}
		},
		Chi = { --[[ 5 ]]
			[1] = {
				Position = { "CENTER", UIParent, "CENTER", -203, -137 },
				Size = { 13, 13 }, BackdropSize = { 58, 58 },
				Texture = GetMedia("point_crystal"),  BackdropTexture = GetMedia("point_plate"),
				Rotation = degreesToRadians(6)
			},
			[2] = {
				Position = { "CENTER", UIParent, "CENTER", -223, -109 },
				Size = { 13, 13 }, BackdropSize = { 60, 60 },
				Texture = GetMedia("point_crystal"),  BackdropTexture = GetMedia("point_plate"),
				Rotation = degreesToRadians(5)
			},
			[3] = {
				Position = { "CENTER", UIParent, "CENTER", -234, -73 },
				Size = { 39, 40  }, BackdropSize = { 80, 80 },
				Texture = GetMedia("point_hearth"),  BackdropTexture = GetMedia("point_plate"),
				Rotation = nil
			},
			[4] = {
				Position = { "CENTER", UIParent, "CENTER", -221, -36 },
				Size = { 13, 13 }, BackdropSize = { 60, 60 },
				Texture = GetMedia("point_crystal"),  BackdropTexture = GetMedia("point_plate"),
				Rotation = nil
			},
			[5] = {
				Position = { "CENTER", UIParent, "CENTER", -203, -9 },
				Size = { 13, 13 }, BackdropSize = { 60, 60 },
				Texture = GetMedia("point_crystal"),  BackdropTexture = GetMedia("point_plate"),
				Rotation = nil
			}
		},
		SoulShards = { --[[ 5 ]]
			[1] = {
				Position = { "CENTER", UIParent, "CENTER", -203, -137 },
				Size = { 12, 12 }, BackdropSize = { 54, 54 },
				Texture = GetMedia("point_crystal"),  BackdropTexture = GetMedia("point_plate"),
				Rotation = degreesToRadians(6)
			},
			[2] = {
				Position = { "CENTER", UIParent, "CENTER", -221, -111 },
				Size = { 13, 13 }, BackdropSize = { 60, 60 },
				Texture = GetMedia("point_crystal"),  BackdropTexture = GetMedia("point_plate"),
				Rotation = degreesToRadians(5)
			},
			[3] = {
				Position = { "CENTER", UIParent, "CENTER", -235, -80 },
				Size = { 11, 15 }, BackdropSize = { 65, 60 },
				Texture = GetMedia("point_crystal"),  BackdropTexture = GetMedia("point_diamond"),
				Rotation = degreesToRadians(3)
			},
			[4] = {
				Position = { "CENTER", UIParent, "CENTER", -227, -44 },
				Size = { 12, 18 }, BackdropSize = { 78, 79 },
				Texture = GetMedia("point_crystal"),  BackdropTexture = GetMedia("point_diamond"),
				Rotation = degreesToRadians(3)
			},
			[5] = {
				Position = { "CENTER", UIParent, "CENTER", -203, -11 },
				Size = { 14, 21 }, BackdropSize = { 82, 96 },
				Texture = GetMedia("point_crystal"),  BackdropTexture = GetMedia("point_diamond"),
				Rotation = degreesToRadians(1)
			}
		},
		Runes = { --[[ 6 ]]
			[1] = {
				Position = { "CENTER", UIParent, "CENTER", -203, -131 },
				Size = { 28, 28 }, BackdropSize = { 58, 58 },
				Texture = GetMedia("point_rune2"),  BackdropTexture = GetMedia("point_dk_block"),
				Rotation = nil
			},
			[2] = {
				Position = { "CENTER", UIParent, "CENTER", -227, -107 },
				Size = { 28, 28 }, BackdropSize = { 68, 68 },
				Texture = GetMedia("point_rune4"),  BackdropTexture = GetMedia("point_dk_block"),
				Rotation = nil
			},
			[3] = {
				Position = { "CENTER", UIParent, "CENTER", -253, -83 },
				Size = { 30, 30 }, BackdropSize = { 74, 74 },
				Texture = GetMedia("point_rune1"),  BackdropTexture = GetMedia("point_dk_block"),
				Rotation = nil
			},
			[4] = {
				Position = { "CENTER", UIParent, "CENTER", -220, -64 },
				Size = { 28, 28 }, BackdropSize = { 68, 68 },
				Texture = GetMedia("point_rune3"),  BackdropTexture = GetMedia("point_dk_block"),
				Rotation = nil
			},
			[5] = {
				Position = { "CENTER", UIParent, "CENTER", -246, -38 },
				Size = { 32, 32 }, BackdropSize = { 78, 78 },
				Texture = GetMedia("point_rune2"),  BackdropTexture = GetMedia("point_dk_block"),
				Rotation = nil
			},
			[6] = {
				Position = { "CENTER", UIParent, "CENTER", -214,-10 },
				Size = { 40, 40 }, BackdropSize = { 98, 98 },
				Texture = GetMedia("point_rune1"),  BackdropTexture = GetMedia("point_dk_block"),
				Rotation = nil
			}
		},
	}
}
