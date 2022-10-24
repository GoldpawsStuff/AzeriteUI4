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
local UnitStyles = ns.UnitStyles
if (not UnitStyles) then
	return
end

-- Lua API
local getmetatable = getmetatable
local math_huge = math.huge
local pairs = pairs
local table_sort = table.sort
local unpack = unpack

-- WoW API
local IsPlayerAtEffectiveMaxLevel = IsPlayerAtEffectiveMaxLevel
local IsXPUserDisabled = IsXPUserDisabled
local UnitLevel = UnitLevel

-- Addon API
local Colors = ns.Colors
local Config = ns.Config
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia
local IsAddOnEnabled = ns.API.IsAddOnEnabled

-- Constants
local playerClass = select(2, UnitClass("player"))
local playerLevel = UnitLevel("player")
local playerXPDisabled = IsXPUserDisabled()
local hardenedLevel = ns.IsRetail and 10 or ns.IsClassic and 40 or 30

-- Utility Functions
--------------------------------------------

-- Element Callbacks
--------------------------------------------

-- Frame Script Handlers
--------------------------------------------

-- Callbacks
--------------------------------------------
local OnEvent = function(self, event, unit, ...)

	print("player event", event, unit, ...)

	if (event == "PLAYER_ENTERING_WORLD") then
		playerXPDisabled = IsXPUserDisabled()

	elseif (event == "ENABLE_XP_GAIN") then
		playerXPDisabled = nil

	elseif (event == "DISABLE_XP_GAIN") then
		playerXPDisabled = true

	elseif (event == "PLAYER_LEVEL_UP") then
		local level = ...
		if (level and (level ~= playerLevel)) then
			playerLevel = level
		else
			local level = UnitLevel("player")
			if (level ~= self.playerLevel) then
				playerLevel = level
			end
		end
	end

	local key = (playerXPDisabled or IsPlayerAtEffectiveMaxLevel()) and "Seasoned" or playerLevel < hardenedLevel and "Novice" or "Hardened"
	local db = ns.Config.Player[key]

	print("player decided on", key)

	local health = self.Health
	health:ClearAllPoints()
	health:SetPoint(unpack(db.HealthBarPosition))
	health:SetSize(unpack(db.HealthBarSize))
	health:SetStatusBarTexture(db.HealthBarTexture)
	health:SetStatusBarColor(unpack(db.HealthBarColor))
	health:SetOrientation(db.HealthBarOrientation)
	health:SetSparkMap(db.HealthBarSparkMap)

	local backdrop = self.Health.Backdrop
	backdrop:ClearAllPoints()
	backdrop:SetPoint(unpack(db.HealthBackdropPosition))
	backdrop:SetSize(unpack(db.HealthBackdropSize))
	backdrop:SetTexture(db.HealthBackdropTexture)
	backdrop:SetVertexColor(unpack(db.HealthBackdropColor))

	local cast = self.Cast
	cast:ClearAllPoints()
	cast:SetPoint(unpack(db.HealthBarPosition))
	cast:SetSize(db.HealthBarSize)
	cast:SetStatusBarTexture(db.HealthBarTexture)
	cast:SetStatusBarColor(unpack(db.CastBarColor))
	cast:SetOrientation(db.HealthBarOrientation)
	cast:SetSparkMap(db.HealthBarSparkMap)

end

UnitStyles["Player"] = function(self, unit, id)

	print("creating player style")

	self:SetSize(unpack(ns.Config.Player.Size))
	self:SetPoint(unpack(ns.Config.Player.Position))

	self.Health = self:CreateBar()
	self.Health.Backdrop = self:CreateTexture(nil, "BACKGROUND", nil, -1)
	self.Health.Override = ns.API.UpdateHealth

	self.Cast = self:CreateBar()
	self.Cast:DisableSmoothing()

	self:RegisterEvent("PLAYER_ALIVE", OnEvent, true)
	self:RegisterEvent("PLAYER_ENTERING_WORLD", OnEvent, true)
	self:RegisterEvent("DISABLE_XP_GAIN", OnEvent, true)
	self:RegisterEvent("ENABLE_XP_GAIN", OnEvent, true)
	self:RegisterEvent("PLAYER_LEVEL_UP", OnEvent, true)
	self:RegisterEvent("PLAYER_XP_UPDATE", OnEvent, true)

end
