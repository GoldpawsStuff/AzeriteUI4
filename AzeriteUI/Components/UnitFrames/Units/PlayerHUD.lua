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
local unpack = unpack

-- Addon API
local Colors = ns.Colors
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia
local IsAddOnEnabled = ns.API.IsAddOnEnabled

-- Constants
local _, playerClass = UnitClass("player")

-- Utility Functions
--------------------------------------------
-- Simplify the tagging process a little.
local prefix = function(msg)
	return string_gsub(msg, "*", ns.Prefix)
end

-- Element Callbacks
--------------------------------------------
local Cast_CustomDelayText = function(element, duration)
	if (element.casting) then
		duration = element.max - duration
	end
	element.Time:SetFormattedText("%.1f", duration)
	element.Delay:SetFormattedText("|cffff0000%s%.2f|r", element.casting and "+" or "-", element.delay)
end

local Cast_CustomTimeText = function(element, duration)
	if (element.casting) then
		duration = element.max - duration
	end
	element.Time:SetFormattedText("%.1f", duration)
	element.Delay:SetText()
end

-- Update cast bar color to indicate protected casts.
local Cast_UpdateInterruptible = function(element, unit)
	if (element.notInterruptible) then
		element:SetStatusBarColor(unpack(Colors.red))
	else
		element:SetStatusBarColor(unpack(Colors.cast))
	end
end

local ClassPower_CreatePoint = function(self, index)
end

local ClassPower_PostUpdateColor = function(element, r, g, b)
	for i = 1, #element do
		local bar = element[i]
		bar:SetStatusBarColor(r, g, b) -- needed?
	end
end

local ClassPower_PostUpdate = function(element, cur, max, hasMaxChanged, powerType)
	for i = 1, #element do
		local point = element[i]
		if (point:IsShown()) then
			local value = point:GetValue()
			local min, max = point:GetMinMaxValues()
			if (element.inCombat) then
				point:SetAlpha(allReady and 1 or (value < max) and .5 or 1)
			else
				point:SetAlpha(allReady and 0 or (value < max) and .5 or 1)
			end
		end
	end
end

local Runes_PostUpdate = function(element, runemap, hasVehicle, allReady)
	for i = 1, #element do
		local rune = element[i]
		if (rune:IsShown()) then
			local value = rune:GetValue()
			local min, max = rune:GetMinMaxValues()
			if (element.inCombat) then
				rune:SetAlpha(allReady and 1 or (value < max) and .5 or 1)
			else
				rune:SetAlpha(allReady and 0 or (value < max) and .5 or 1)
			end
		end
	end
end

local Runes_PostUpdateColor = function(element, r, g, b, color, rune)
	local m = ns.IsWrath and .5 or 1 -- Probably only needed on our current runes
	if (rune) then
		rune:SetStatusBarColor(r * m, g * m, b * m)
		rune.fg:SetVertexColor(r * m, g * m, b * m)
	else
		if (not ns.IsWrath) then
			color = element.__owner.colors.power.RUNES
			r, g, b = color[1] * m, color[2] * m, color[3] * m
		end
		for i = 1, #element do
			local rune = element[i]
			if (ns.IsWrath) then
				color = element.__owner.colors.runes[rune.runeType]
				r, g, b = color[1] * m, color[2] * m, color[3] * m
			end
			rune:SetStatusBarColor(r, g, b)
			rune.fg:SetVertexColor(r, g, b)
		end
	end
end

-- Script Handlers
--------------------------------------------
local UnitFrame_OnEvent = function(self, event)
	if (event == "PLAYER_REGEN_DISABLED") then
		local runes = self.Runes
		if (runes) and (not runes.inCombat) then
			runes.inCombat = true
			runes:ForceUpdate()
		end
		local classpower = self.ClassPower
		if (classpower) and (not classpower.inCombat) then
			classpower.inCombat = true
			classpower:ForceUpdate()
		end
	elseif (event == "PLAYER_REGEN_ENABLED") then
		local runes = self.Runes
		if (runes) and (runes.inCombat) then
			runes.inCombat = false
			runes:ForceUpdate()
		end
		local classpower = self.ClassPower
		if (classpower) and (classpower.inCombat) then
			classpower.inCombat = false
			classpower:ForceUpdate()
		end
	end
end

local UnitFrame_OnHide = function(self)
	self.inCombat = nil
end

UnitStyles["PlayerHUD"] = function(self, unit, id)

	local db = ns.Config.PlayerHUD

	self:EnableMouse(false)

	-- Cast Bar
	--------------------------------------------
	if (not IsAddOnEnabled("Quartz")) then

		local cast = self:CreateBar()
		cast:SetFrameStrata("MEDIUM")
		cast:SetPoint(unpack(db.CastBarPosition))
		cast:SetSize(unpack(db.CastBarSize))
		cast:SetStatusBarTexture(db.CastBarTexture)
		cast:SetStatusBarColor(unpack(self.colors.cast))
		cast:SetOrientation(db.CastBarOrientation)
		cast:SetSparkMap(db.CastBarSparkMap)
		cast:DisableSmoothing(true)
		cast.timeToHold = db.CastBarTimeToHoldFailed

		local castBackdrop = cast:CreateTexture(nil, "BORDER", nil, -1)
		castBackdrop:SetPoint(unpack(db.CastBarBackgroundPosition))
		castBackdrop:SetSize(unpack(db.CastBarBackgroundSize))
		castBackdrop:SetTexture(db.CastBarBackgroundTexture)
		castBackdrop:SetVertexColor(unpack(db.CastBarBackgroundColor))
		cast.Backdrop = castBackdrop

		local castSafeZone = cast:CreateTexture(nil, "ARTWORK", nil, 0)
		castSafeZone:SetTexture(db.CastBarSpellQueueTexture)
		castSafeZone:SetVertexColor(unpack(db.CastBarSpellQueueColor))
		cast.SafeZone = castSafeZone

		local castText = cast:CreateFontString(nil, "OVERLAY", nil, 0)
		castText:SetPoint(unpack(db.CastBarTextPosition))
		castText:SetFontObject(db.CastBarTextFont)
		castText:SetTextColor(unpack(db.CastBarTextColor))
		castText:SetJustifyH(db.CastBarTextJustifyH)
		castText:SetJustifyV(db.CastBarTextJustifyV)
		cast.Text = castText

		local castTime = cast:CreateFontString(nil, "OVERLAY", nil, 0)
		castTime:SetPoint(unpack(db.CastBarValuePosition))
		castTime:SetFontObject(db.CastBarValueFont)
		castTime:SetTextColor(unpack(db.CastBarValueColor))
		castTime:SetJustifyH(db.CastBarValueJustifyH)
		castTime:SetJustifyV(db.CastBarValueJustifyV)
		cast.Time = castTime

		local castDelay = cast:CreateFontString(nil, "OVERLAY", nil, 0)
		castDelay:SetFontObject(GetFont(12,true))
		castDelay:SetTextColor(unpack(self.colors.red))
		castDelay:SetPoint("LEFT", castTime, "RIGHT", 0, 0)
		castDelay:SetJustifyV("MIDDLE")
		cast.Delay = castDelay

		cast.CustomDelayText = Cast_CustomDelayText
		cast.CustomTimeText = Cast_CustomTimeText
		cast.PostCastInterruptible = Cast_UpdateInterruptible
		cast.PostCastStart = Cast_UpdateInterruptible
		--cast.PostCastStop = Cast_UpdateInterruptible -- needed?

		self.Castbar = cast

	end

	-- Class Power
	--------------------------------------------
	-- 	Supported class powers:
	-- 	- All     - Combo Points
	-- 	- Mage    - Arcane Charges
	-- 	- Monk    - Chi Orbs
	-- 	- Paladin - Holy Power
	-- 	- Warlock - Soul Shards
	--------------------------------------------
	local SCP = IsAddOnEnabled("SimpleClassPower")
	if (not SCP) then

		local classpower = CreateFrame("Frame", nil, self)
		classpower.PostUpdate = ClassPower_PostUpdate
		classpower.PostUpdateColor = ClassPower_PostUpdateColor

		local maxPoints = (ns.IsRetail) and (playerClass == "MONK" or playerClass == "ROGUE") and 6 or 5
		for i = 1,maxPoints do
			local point = ClassPower_CreatePoint(classpower, i)

			classpower[i] = point
		end

		self.ClassPower = classpower
	end

	-- Monk Stagger
	--------------------------------------------
	if (playerClass == "MONK") and (not SCP) then

		local stagger = CreateFrame("Frame", nil, self)
		stagger.PostUpdate = ClassPower_PostUpdate

		for i = 1,3 do
			local point = ClassPower_CreatePoint(stagger, i)
			stagger[i] = point
		end

		self.Stagger = stagger
	end

	-- Death Knight Runes
	--------------------------------------------
	if (playerClass == "DEATHKNIGHT") and (ns.IsWrath or (ns.IsRetail and not SCP)) then

		local runes = CreateFrame("Frame", nil, self)
		runes.sortOrder = "ASC"
		runes.PostUpdate = Runes_PostUpdate
		runes.PostUpdateColor = Runes_PostUpdateColor

		for i = 1,6 do
			local rune = ClassPower_CreatePoint(runes, i)
			runes[i] = rune
		end

		self.Runes = runes
	end

	-- Scripts & Events
	--------------------------------------------
	self.OnEvent = UnitFrame_OnEvent
	self.OnHide = UnitFrame_OnHide

	self:RegisterEvent("PLAYER_REGEN_ENABLED", self.OnEvent, true)
	self:RegisterEvent("PLAYER_REGEN_DISABLED", self.OnEvent, true)

end
