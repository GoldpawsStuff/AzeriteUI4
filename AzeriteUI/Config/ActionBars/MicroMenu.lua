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

Config.MicroMenu = {

	MicroMenuPosition = { "BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -26, 64 },

	MicroMenuBackdropOffsetTop = 18,
	MicroMenuBackdropOffsetBottom = -18,
	MicroMenuBackdropOffsetLeft = -10,
	MicroMenuBackdropOffsetRight = 10,
	MicroMenuBackdropColor = { .05, .05, .05, .95 },
	MicroMenuBackdrop = {
		bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
		edgeSize = 32, edgeFile = GetMedia("border-tooltip"),
		tile = true,
		insets = { left = 8, right = 8, top = 16, bottom = 16 }
	},

	MicroMenuButtonSize = { 200, 30 },
	MicroMenuButtonFont = GetFont(13,true),

	MicroMenuToggleButtonPosition = { "BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -4, 4 },
	MicroMenuToggleButtonSize = { 48, 48 },
	MicroMenuToggleButtonTexturePosition = { "CENTER", 0, 0 },
	MicroMenuToggleButtonTextureSize = { 96, 96 },
	MicroMenuToggleButtonTexture = GetMedia("config_button"),
	MicroMenuToggleButtonColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3] },

}
