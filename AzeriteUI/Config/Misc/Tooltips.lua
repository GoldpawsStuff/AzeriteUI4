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

Config.Tooltips = {
	Position = { "BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -319, 166 },

	-- Tooltip Backdrop
	Backdrop = {
		bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
		edgeSize = 32, edgeFile = GetMedia("border-tooltip"),
		tile = true,
		insets = { left = 8, right = 8, top = 16, bottom = 16 }
	},
	BackdropColor = { .05, .05, .05, .95 },
	BackdropOffsetLeft = -10,
	BackdropOffsetRight = 10,
	BackdropOffsetTop = 18,
	BackdropOffsetBottom = -18,
	BackdropOffsetBar = 0,
	BackdropOffsetBarBottom = -6,

	-- Tooltip statusbar
	StatusBarSize = 4,
	StatusBarOffsetV = 1,
	StatusBarOffsetH = 4,
	StatusBarTexture = GetMedia("bar-progress"),
	StatusBarTextPosition = { "CENTER", 0, 0 },
	StatusBarTextFont = GetFont(13,true),
	StatusBarTextColor = { ns.Colors.offwhite[1], ns.Colors.offwhite[2], ns.Colors.offwhite[3] }

}
