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

Config.PetBar = {

	Position = { "BOTTOM", UIParent, "BOTTOM", 0, 200 },
	Size = { 498, 48 },

	ButtonPositions = {
		[1] = { "BOTTOMLEFT", 0, 0 },
		[2] = { "BOTTOMLEFT", 50, 0 },
		[3] = { "BOTTOMLEFT", 100, 0 },
		[4] = { "BOTTOMLEFT", 150, 0 },
		[5] = { "BOTTOMLEFT", 200, 0 },
		[6] = { "BOTTOMLEFT", 250, 0 },
		[7] = { "BOTTOMLEFT", 300, 0 },
		[8] = { "BOTTOMLEFT", 350, 0 },
		[9] = { "BOTTOMLEFT", 400, 0 },
		[10] = { "BOTTOMLEFT", 450, 0 }
	},
	ButtonSize = { 48, 48 },
	ButtonHitRects =  { -10, -10, -10, -10 },
	ButtonMaskTexture = GetMedia("actionbutton-mask-circular"),

	ButtonBackdropPosition = { "CENTER", 0, 0 },
	ButtonBackdropSize = { 100.721311475, 100.721311475 },
	ButtonBackdropTexture = GetMedia("actionbutton-backdrop"),
	ButtonBackdropColor = { .67, .67, .67, 1 },

	ButtonIconPosition = { "CENTER", 0, 0 },
	ButtonIconSize = { 33, 33 },

	ButtonKeybindPosition = { "TOPLEFT", -15, -5 },
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

	ButtonBorderPosition = { "CENTER", 0, 0 },
	ButtonBorderSize = { 100.721311475, 100.721311475 },
	ButtonBorderTexture = GetMedia("actionbutton-border"),
	ButtonBorderColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3], 1 },

	ButtonSpellHighlightPosition = { "CENTER", 0, 0 },
	ButtonSpellHighlightSize = { 100.721311475, 100.721311475 },
	ButtonSpellHighlightTexture = GetMedia("actionbutton-spellhighlight"),

}
