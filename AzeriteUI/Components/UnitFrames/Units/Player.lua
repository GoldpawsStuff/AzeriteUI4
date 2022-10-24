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
local next = next
local unpack = unpack

-- WoW API
local IsPlayerAtEffectiveMaxLevel = IsPlayerAtEffectiveMaxLevel
local IsXPUserDisabled = IsXPUserDisabled
local UnitHasVehicleUI = UnitHasVehicleUI
local UnitLevel = UnitLevel
local UnitPowerType = UnitPowerType

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

-- sourced from FrameXML/AlternatePowerBar.lua
local ADDITIONAL_POWER_BAR_NAME = ADDITIONAL_POWER_BAR_NAME or "MANA"
local ADDITIONAL_POWER_BAR_INDEX = ADDITIONAL_POWER_BAR_INDEX or 0
local ALT_MANA_BAR_PAIR_DISPLAY_INFO = ALT_MANA_BAR_PAIR_DISPLAY_INFO

-- Utility Functions
--------------------------------------------

-- Element Callbacks
--------------------------------------------
local Mana_UpdateVisibility = function(self, event, unit)
	local element = self.AdditionalPower

	local shouldEnable = not UnitHasVehicleUI("player") and UnitPowerType(unit) == Enum.PowerType.Mana
	local isEnabled = element.__isEnabled

	if (shouldEnable and not isEnabled) then

		if (element.frequentUpdates) then
			self:RegisterEvent("UNIT_POWER_FREQUENT", Path)
		else
			self:RegisterEvent("UNIT_POWER_UPDATE", Path)
		end

		self:RegisterEvent("UNIT_MAXPOWER", Path)

		element:Show()

		element.__isEnabled = true
		element.Override(self, "ElementEnable", "player", ADDITIONAL_POWER_BAR_NAME)

		--[[ Callback: AdditionalPower:PostVisibility(isVisible)
		Called after the element's visibility has been changed.

		* self      - the AdditionalPower element
		* isVisible - the current visibility state of the element (boolean)
		--]]
		if (element.PostVisibility) then
			element:PostVisibility(true)
		end

	elseif (not shouldEnable and (isEnabled or isEnabled == nil)) then

		self:UnregisterEvent("UNIT_MAXPOWER", Path)
		self:UnregisterEvent("UNIT_POWER_FREQUENT", Path)
		self:UnregisterEvent("UNIT_POWER_UPDATE", Path)

		element:Hide()

		element.__isEnabled = false
		element.Override(self, "ElementDisable", "player", ADDITIONAL_POWER_BAR_NAME)

		if (element.PostVisibility) then
			element:PostVisibility(false)
		end

	elseif (shouldEnable and isEnabled) then
		element.Override(self, event, unit, ADDITIONAL_POWER_BAR_NAME)
	end
end

local Power_UpdateVisibility = function(element, unit, cur, min, max)
	local powerType = UnitPowerType(unit)
	if (powerType == Enum.PowerType.Mana) then
		element:Hide()
	else
		element:Show()
	end
end

-- Frame Script Handlers
--------------------------------------------

-- Callbacks
--------------------------------------------
local OnEvent = function(self, event, unit, ...)

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

	local cast = self.Castbar
	cast:ClearAllPoints()
	cast:SetPoint(unpack(db.HealthBarPosition))
	cast:SetSize(unpack(db.HealthBarSize))
	cast:SetStatusBarTexture(db.HealthBarTexture)
	cast:SetStatusBarColor(unpack(db.HealthCastOverlayColor))
	cast:SetOrientation(db.HealthBarOrientation)
	cast:SetSparkMap(db.HealthBarSparkMap)

end

UnitStyles["Player"] = function(self, unit, id)

	self:SetSize(unpack(ns.Config.Player.Size))
	self:SetPoint(unpack(ns.Config.Player.Position))

	-- Health Bar
	--------------------------------------------
	local health = self:CreateBar()
	health.Backdrop = self:CreateTexture(nil, "BACKGROUND", nil, -1)

	self.Health = health
	self.Health.Override = ns.API.UpdateHealth

	-- Health Bar Cast Overlay
	--------------------------------------------
	local castbar = self:CreateBar()
	castbar:SetFrameLevel(self.Health:GetFrameLevel() + 1)
	castbar:DisableSmoothing()

	self.Castbar = castbar

	-- Power Crystal
	--------------------------------------------
	local power = self:CreateBar()
	power.frequentUpdates = true
	power.displayAltPower = true

	self.Power = power
	self.Power.Override = ns.API.UpdatePower
	self.Power.PostUpdate = Power_UpdateVisibility

	-- Mana Orb
	--------------------------------------------
	local mana = self:CreateOrb()
	mana:SetStatusBarColor(unpack(Colors.power.MANA_ORB))

	self.AdditionalPower = mana
	self.AdditionalPower.Override = ns.API.UpdatePower
	self.AdditionalPower.OverrideVisibility = Mana_UpdateVisibility

	-- CombatFeedback
	--------------------------------------------
	local feedbackText = overlay:CreateFontString(nil, "OVERLAY")
	feedbackText:SetPoint("CENTER", health, "CENTER", 0, 0)
	feedbackText.feedbackFont = GetFont(20, true)
	feedbackText.feedbackFontLarge = GetFont(24, true)
	feedbackText.feedbackFontSmall = GetFont(18, true)

	self.CombatFeedback = feedbackText

	self:RegisterEvent("PLAYER_ALIVE", OnEvent, true)
	self:RegisterEvent("PLAYER_ENTERING_WORLD", OnEvent, true)
	self:RegisterEvent("DISABLE_XP_GAIN", OnEvent, true)
	self:RegisterEvent("ENABLE_XP_GAIN", OnEvent, true)
	self:RegisterEvent("PLAYER_LEVEL_UP", OnEvent, true)
	self:RegisterEvent("PLAYER_XP_UPDATE", OnEvent, true)

end
