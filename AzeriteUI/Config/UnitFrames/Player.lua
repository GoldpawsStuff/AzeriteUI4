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

	Size = { 439, 93 },
	Position = { "BOTTOMLEFT", 167, 100 },
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
		HealthCastOverlayColor = { 1, 1, 1, .25 },
		HealthThreatTexture = GetMedia("hp_low_case_glow"),


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
		HealthCastOverlayColor = { 1, 1, 1, .25 },
		HealthThreatTexture = GetMedia("hp_mid_case_glow"),

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
		HealthCastOverlayColor = { 1, 1, 1, .25 },
		HealthThreatTexture = GetMedia("hp_cap_case_glow"),

	}
}
