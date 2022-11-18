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

Config.Clutter = {

	TopCenterWidgetsPosition = { "TOP", UIParent, "TOP", 0, -10 },
	BelowMinimapWidgetsPosition = { "TOP", Minimap, "BOTTOM", 0, -40 },

	RaidWarningFramePosition = { "TOP", UIParent, "TOP", 0, -340 },
	RaidWarningFrameAlpha = .85,
	RaidWarningFrameHeight = 80,
	RaidWarningFrameFontSize = 26,
	RaidWarningFrameFont = GetFont(26, true, "Chat"),
	RaidWarningFrameFontShadow = { 0, 0, 0, .5 },
	RaidWarningFrameSlotWidth = 760,

	RaidBossEmoteFramePosition = { "TOP", UIParent, "TOP", 0, -440 },
	RaidBossEmoteFrameAlpha = .85,
	RaidBossEmoteFrameHeight = 80,
	RaidBossEmoteFrameFontSize = 26,
	RaidBossEmoteFrameFont = GetFont(26, true, "Chat"),
	RaidBossEmoteFrameFontShadow = { 0, 0, 0, .5 },
	RaidBossEmoteFrameSlotWidth = 760,

	UIErrorsFramePosition = { "TOP", UIParent, "TOP", 0, -600 },
	UIErrorsFrameHeight = 22,
	UIErrorsFrameAlpha = .75,
	UIErrorsFrameFont = GetFont(18, true),
	UIErrorsFrameFontShadow = { 0, 0, 0, .5 },

	VehicleSeatIndicatorPosition = { "CENTER", UIParent, "BOTTOMRIGHT", -130, 80 },
	ArcheologyDigsiteProgressBarPosition = { "BOTTOM", UIParent, "BOTTOM", 0, 390 }

}