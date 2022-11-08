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

Config.PlayerHUD = {
	Default = {
		-- Cast Bar
		CastBarPosition = { "BOTTOM", UIParent, "BOTTOM", 0, 290 },
		CastBarSize = { 112, 11 },
		CastBarTexture = GetMedia("cast_bar"),
		CastBarColor = { Colors.cast[1], Colors.cast[2], Colors.cast[3], .69 },
		CastBarOrientation = "RIGHT",
		CastBarSparkMap = castBarSparkMap,
		CastBarTimeToHoldFailed = .5,

		CastBarBackgroundPosition = { "CENTER", 1, -1 },
		CastBarBackgroundSize = { 193,93 },
		CastBarBackgroundTexture = GetMedia("cast_back"),
		CastBarBackgroundColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },

		CastBarShieldPosition = { "CENTER", 1, -2 },
		CastBarShieldSize = { 193, 93 },
		CastBarShieldTexture = GetMedia("cast_back_spiked"),
		CastBarShieldColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },

		CastBarSpellQueueTexture = GetMedia("cast_bar"),
		CastBarSpellQueueColor = { 1, 1, 1, .5 },

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

		-- Class Power
		-- *also include layout data for Stagger and Runes,
		--  which are separate elements from ClassPower.
		ClassPowerPointOrientation = "UP",
		ClassPowerSparkTexture = GetMedia("blank"),
		ClassPowerCaseColor = { 211/255, 200/255, 169/255 },
		ClassPowerSlotColor = { 130/255 *.3, 133/255 *.3, 130/255 *.3, 2/3 },

		-- Note that the following are just layout names.
		-- They may not always be used for what their name implies.
		-- The important part is number of points and layout. Not powerType.
		ClassPowerLayouts = {
			Stagger = { --[[ 3 ]]
				[1] = {
					PointPosition = {}, PointSize = {}, PointTexture = {},
					BackdropPosition = {}, BackdropSize = {}, BackdropTexture = {},
					SlotPosition = {}, SlotSize = {}, SlotTexture = {}
				},
				[2] = {
					PointPosition = {}, PointSize = {}, PointTexture = {},
					BackdropPosition = {}, BackdropSize = {}, BackdropTexture = {},
					SlotPosition = {}, SlotSize = {}, SlotTexture = {}
				},
				[3] = {
					PointPosition = {}, PointSize = {}, PointTexture = {},
					BackdropPosition = {}, BackdropSize = {}, BackdropTexture = {},
					SlotPosition = {}, SlotSize = {}, SlotTexture = {}
				}
			},
			ArcaneCharges = { --[[ 4 ]]
				[1] = {
					PointPosition = {}, PointSize = {}, PointTexture = {},
					BackdropPosition = {}, BackdropSize = {}, BackdropTexture = {},
					SlotPosition = {}, SlotSize = {}, SlotTexture = {}
				},
				[2] = {
					PointPosition = {}, PointSize = {}, PointTexture = {},
					BackdropPosition = {}, BackdropSize = {}, BackdropTexture = {},
					SlotPosition = {}, SlotSize = {}, SlotTexture = {}
				},
				[3] = {
					PointPosition = {}, PointSize = {}, PointTexture = {},
					BackdropPosition = {}, BackdropSize = {}, BackdropTexture = {},
					SlotPosition = {}, SlotSize = {}, SlotTexture = {}
				},
				[4] = {
					PointPosition = {}, PointSize = {}, PointTexture = {},
					BackdropPosition = {}, BackdropSize = {}, BackdropTexture = {},
					SlotPosition = {}, SlotSize = {}, SlotTexture = {}
				}
			},
			ComboPoints = { --[[ 5 ]]
				[1] = {
					PointPosition = {}, PointSize = {}, PointTexture = {},
					BackdropPosition = {}, BackdropSize = {}, BackdropTexture = {},
					SlotPosition = {}, SlotSize = {}, SlotTexture = {}
				},
				[2] = {
					PointPosition = {}, PointSize = {}, PointTexture = {},
					BackdropPosition = {}, BackdropSize = {}, BackdropTexture = {},
					SlotPosition = {}, SlotSize = {}, SlotTexture = {}
				},
				[3] = {
					PointPosition = {}, PointSize = {}, PointTexture = {},
					BackdropPosition = {}, BackdropSize = {}, BackdropTexture = {},
					SlotPosition = {}, SlotSize = {}, SlotTexture = {}
				},
				[4] = {
					PointPosition = {}, PointSize = {}, PointTexture = {},
					BackdropPosition = {}, BackdropSize = {}, BackdropTexture = {},
					SlotPosition = {}, SlotSize = {}, SlotTexture = {}
				},
				[5] = {
					PointPosition = {}, PointSize = {}, PointTexture = {},
					BackdropPosition = {}, BackdropSize = {}, BackdropTexture = {},
					SlotPosition = {}, SlotSize = {}, SlotTexture = {}
				}
			},
			Chi = { --[[ 5 ]]
				[1] = {
					PointPosition = {}, PointSize = {}, PointTexture = {},
					BackdropPosition = {}, BackdropSize = {}, BackdropTexture = {},
					SlotPosition = {}, SlotSize = {}, SlotTexture = {}
				},
				[2] = {
					PointPosition = {}, PointSize = {}, PointTexture = {},
					BackdropPosition = {}, BackdropSize = {}, BackdropTexture = {},
					SlotPosition = {}, SlotSize = {}, SlotTexture = {}
				},
				[3] = {
					PointPosition = {}, PointSize = {}, PointTexture = {},
					BackdropPosition = {}, BackdropSize = {}, BackdropTexture = {},
					SlotPosition = {}, SlotSize = {}, SlotTexture = {}
				},
				[4] = {
					PointPosition = {}, PointSize = {}, PointTexture = {},
					BackdropPosition = {}, BackdropSize = {}, BackdropTexture = {},
					SlotPosition = {}, SlotSize = {}, SlotTexture = {}
				},
				[5] = {
					PointPosition = {}, PointSize = {}, PointTexture = {},
					BackdropPosition = {}, BackdropSize = {}, BackdropTexture = {},
					SlotPosition = {}, SlotSize = {}, SlotTexture = {}
				}
			},
			SoulShards = { --[[ 5 ]]
				[1] = {
					PointPosition = {}, PointSize = {}, PointTexture = {},
					BackdropPosition = {}, BackdropSize = {}, BackdropTexture = {},
					SlotPosition = {}, SlotSize = {}, SlotTexture = {}
				},
				[2] = {
					PointPosition = {}, PointSize = {}, PointTexture = {},
					BackdropPosition = {}, BackdropSize = {}, BackdropTexture = {},
					SlotPosition = {}, SlotSize = {}, SlotTexture = {}
				},
				[3] = {
					PointPosition = {}, PointSize = {}, PointTexture = {},
					BackdropPosition = {}, BackdropSize = {}, BackdropTexture = {},
					SlotPosition = {}, SlotSize = {}, SlotTexture = {}
				},
				[4] = {
					PointPosition = {}, PointSize = {}, PointTexture = {},
					BackdropPosition = {}, BackdropSize = {}, BackdropTexture = {},
					SlotPosition = {}, SlotSize = {}, SlotTexture = {}
				},
				[5] = {
					PointPosition = {}, PointSize = {}, PointTexture = {},
					BackdropPosition = {}, BackdropSize = {}, BackdropTexture = {},
					SlotPosition = {}, SlotSize = {}, SlotTexture = {}
				}
			},
			Runes = { --[[ 6 ]]
				[1] = {
					PointPosition = {}, PointSize = {}, PointTexture = {},
					BackdropPosition = {}, BackdropSize = {}, BackdropTexture = {},
					SlotPosition = {}, SlotSize = {}, SlotTexture = {}
				},
				[2] = {
					PointPosition = {}, PointSize = {}, PointTexture = {},
					BackdropPosition = {}, BackdropSize = {}, BackdropTexture = {},
					SlotPosition = {}, SlotSize = {}, SlotTexture = {}
				},
				[3] = {
					PointPosition = {}, PointSize = {}, PointTexture = {},
					BackdropPosition = {}, BackdropSize = {}, BackdropTexture = {},
					SlotPosition = {}, SlotSize = {}, SlotTexture = {}
				},
				[4] = {
					PointPosition = {}, PointSize = {}, PointTexture = {},
					BackdropPosition = {}, BackdropSize = {}, BackdropTexture = {},
					SlotPosition = {}, SlotSize = {}, SlotTexture = {}
				},
				[5] = {
					PointPosition = {}, PointSize = {}, PointTexture = {},
					BackdropPosition = {}, BackdropSize = {}, BackdropTexture = {},
					SlotPosition = {}, SlotSize = {}, SlotTexture = {}
				},
				[6] = {
					PointPosition = {}, PointSize = {}, PointTexture = {},
					BackdropPosition = {}, BackdropSize = {}, BackdropTexture = {},
					SlotPosition = {}, SlotSize = {}, SlotTexture = {}
				}
			},
		},

	}
}
