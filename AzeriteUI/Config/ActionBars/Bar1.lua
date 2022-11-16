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

Config.Bar1 = {

	Position = { "BOTTOMLEFT", UIParent, "BOTTOMLEFT", 60, 42 },
	Size = { 64, 64 },

	ButtonPositions = {
		[1] = { "BOTTOMLEFT", 0, 0 }, -- bottom row
		[2] = { "BOTTOMLEFT", 72, 0 }, -- bottom row
		[3] = { "BOTTOMLEFT", 144, 0 }, -- bottom row
		[4] = { "BOTTOMLEFT", 216, 0 }, -- bottom row
		[5] = { "BOTTOMLEFT", 288, 0 }, -- bottom row
		[6] = { "BOTTOMLEFT", 360, 0 }, -- bottom row
		[7] = { "BOTTOMLEFT", 432, 0 }, -- bottom row
		[8] = { "BOTTOMLEFT", 476, 72 }, -- top row
		[9] = { "BOTTOMLEFT", 504, 0 }, -- bottom row
		[10] = { "BOTTOMLEFT", 548, 72 }, -- top row
		[11] = { "BOTTOMLEFT", 576, 0 }, -- bottom row
		[12] = { "BOTTOMLEFT", 620, 72 }, -- top row
	},
	ButtonSize = { 64, 64 },
	ButtonHitRects =  { -4, -4, -4, -4 },
	ButtonMaskTexture = GetMedia("actionbutton-mask-circular"),

	ButtonBackdropPosition = { "CENTER", 0, 0 },
	ButtonBackdropSize = { 134.295081967, 134.295081967 },
	ButtonBackdropTexture = GetMedia("actionbutton-backdrop"),
	ButtonBackdropColor = { .67, .67, .67, 1 },

	ButtonIconPosition = { "CENTER", 0, 0 },
	ButtonIconSize = { 44, 44 },

	ButtonKeybindPosition = { "TOPLEFT", 5, -5 },
	ButtonKeybindJustifyH = "CENTER",
	ButtonKeybindJustifyV = "BOTTOM",
	ButtonKeybindFont = GetFont(15, true),
	ButtonKeybindColor = { Colors.quest.gray[1], Colors.quest.gray[2], Colors.quest.gray[3], .75 },

	ButtonCountPosition = { "BOTTOMRIGHT", -3, 3 },
	ButtonCountJustifyH = "CENTER",
	ButtonCountJustifyV = "BOTTOM",
	ButtonCountFont = GetFont(18, true),
	ButtonCountColor = { Colors.normal[1], Colors.normal[2], Colors.normal[3], .85 },

	ButtonCooldownCountPosition = { "CENTER", 1, 0 },
	ButtonCooldownCountJustifyH = "CENTER",
	ButtonCooldownCountJustifyV = "MIDDLE",
	ButtonCooldownCountFont = GetFont(16, true),
	ButtonCooldownCountColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .85 },

	ButtonSpellHighlightPosition = { "CENTER", 0, 0 },
	ButtonSpellHighlightSize = { 134.295081967, 134.295081967 },
	ButtonSpellHighlightTexture = GetMedia("actionbutton-spellhighlight"),

}
