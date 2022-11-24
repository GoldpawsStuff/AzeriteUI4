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
local select = select
local unpack = unpack

-- WoW API
local GetNetStats = GetNetStats

-- Addon API
local Colors = ns.Colors
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia
local IsAddOnEnabled = ns.API.IsAddOnEnabled
local noop = ns.Noop

-- Constants
local playerClass = ns.PlayerClass

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

-- Update cast bar color and backdrop to indicate protected casts.
-- *Note that the shield icon works as an alternate backdrop here,
--  which is why we're hiding the regular backdrop on protected casts.
local Cast_Update = function(element, unit)
	if (element.notInterruptible) then
		element.Backdrop:Hide()
		element:SetStatusBarColor(unpack(Colors.red))
	else
		element.Backdrop:Show()
		element:SetStatusBarColor(unpack(Colors.cast))
	end
	-- Don't show mega tiny spell queue zones, it just looks cluttered.
	element.SafeZone:SetShown(((select(4, GetNetStats()) / 1000) / element.max) > .05)
end

-- Create a point used for classpowers, stagger and runes.
local ClassPower_CreatePoint = function(element, index)
	local db = ns.Config.PlayerHUD

	local point = element:GetParent():CreateBar(nil, element)
	point:SetOrientation(db.ClassPowerPointOrientation)
	point:SetSparkTexture(db.ClassPowerSparkTexture)
	point:SetMinMaxValues(0, 1)
	point:SetValue(1)

	local case = point:CreateTexture(nil, "BACKGROUND", nil, -2)
	case:SetPoint("CENTER")
	case:SetVertexColor(unpack(db.ClassPowerCaseColor))

	point.case = case

	local slot = point:CreateTexture(nil, "BACKGROUND", nil, -1)
	slot:SetPoint("TOPLEFT", -db.ClassPowerSlotOffset, db.ClassPowerSlotOffset)
	slot:SetPoint("BOTTOMRIGHT", db.ClassPowerSlotOffset, -db.ClassPowerSlotOffset)
	slot:SetVertexColor(unpack(db.ClassPowerSlotColor))

	point.slot = slot

	return point
end

local ClassPower_PostUpdateColor = function(element, r, g, b)
	--for i = 1, #element do
	--	local point = element[i]
	--	point:SetStatusBarColor(r, g, b) -- needed?
	--end
end

-- Update classpower layout and textures.
-- *also used for one-time setup of stagger and runes.
local ClassPower_PostUpdate = function(element, cur, max)

	local style
	if (max == 6) then
		style = "Runes"
	elseif (max == 5) then
		style = playerClass == "MONK" and "Chi" or playerClass == "WARLOCK" and "SoulShards" or "ComboPoints"
	elseif (max == 4) then
		style = "ArcaneCharges"
	elseif (max == 3) then
		style = "Stagger"
	end

	if (not style) then
		return element:Hide()
	end

	if (not element:IsShown()) then
		element:Show()
	end

	for i = 1, #element do
		local point = element[i]
		if (point:IsShown()) then
			local value = point:GetValue()
			local pmin, pmax = point:GetMinMaxValues()
			if (element.inCombat) then
				point:SetAlpha((cur == max) and 1 or (value < pmax) and .5 or 1)
			else
				point:SetAlpha((cur == max) and 0 or (value < pmax) and .5 or 1)
			end
		end
	end

	if (style ~= element.style) then

		local huddb = ns.Config.PlayerHUD
		local layoutdb = huddb.ClassPowerLayouts[style]
		if (layoutdb) then

			local id = 0
			for i,info in next,layoutdb do
				local point = element[i]
				if (point) then
					local rotation = info.PointRotation or 0

					point:ClearAllPoints()
					point:SetPoint(unpack(info.Position))
					point:SetSize(unpack(info.Size))
					point:SetStatusBarTexture(info.Texture)
					point:GetStatusBarTexture():SetRotation(rotation)

					point.case:SetSize(unpack(info.BackdropSize))
					point.case:SetTexture(info.BackdropTexture)
					point.case:SetRotation(rotation)

					point.slot:SetTexture(info.Texture)
					point.slot:SetRotation(rotation)

					id = id + 1
				end
			end
			-- Should be handled by the element,
			-- no idea why I'm adding it here.
			for i = id + 1, #element do
				element[i]:Hide()
			end
		end
		element.style = style
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
	if (rune) then
		rune:SetStatusBarColor(r, g, b)
	else
		if (not ns.IsWrath) then
			color = element.__owner.colors.power.RUNES
			r, g, b = color[1], color[2], color[3]
		end
		for i = 1, #element do
			local rune = element[i]
			if (ns.IsWrath) then
				color = element.__owner.colors.runes[rune.runeType]
				r, g, b = color[1], color[2], color[3]
			end
			rune:SetStatusBarColor(r, g, b)
		end
	end
end

local Stagger_SetStatusBarColor = function(element, r, g, b)
	for i,point in next,element do
		point:SetStatusBarColor(r, g, b)
	end
end

local Stagger_PostUpdate = function(element, amount, maxHealth)

	element[1].min = 0
	element[1].max = maxHealth * .3
	element[2].min = element[1].max
	element[2].max = maxHealth * .6
	element[3].min = element[2].max
	element[3].max = maxHealth

	for i,point in next,element do
		local value = (cur > point.max) and point.max or (cur < point.min) and point.min or cur

		point:SetMinMaxValues(point.min, point.max)
		point:SetValue(value)

		if (element.inCombat) then
			point:SetAlpha((cur == max) and 1 or (value < point.max) and .5 or 1)
		else
			point:SetAlpha((cur == 0) and 0 or (value < point.max) and .5 or 1)
		end
	end
end

-- Script Handlers
--------------------------------------------
local UnitFrame_OnEvent = function(self, event)
	if (event == "PLAYER_REGEN_DISABLED") then
		local runes = self.Runes
		if (runes and not runes.inCombat) then
			runes.inCombat = true
			runes:ForceUpdate()
		end
		local stagger = self.Stagger
		if (stagger and not stagger.inCombat) then
			stagger.inCombat = true
			stagger:ForceUpdate()
		end
		local classpower = self.ClassPower
		if (classpower and not classpower.inCombat) then
			classpower.inCombat = true
			classpower:ForceUpdate()
		end
	elseif (event == "PLAYER_REGEN_ENABLED") then
		local runes = self.Runes
		if (runes and runes.inCombat) then
			runes.inCombat = false
			runes:ForceUpdate()
		end
		local stagger = self.Stagger
		if (stagger and stagger.inCombat) then
			stagger.inCombat = false
			stagger:ForceUpdate()
		end
		local classpower = self.ClassPower
		if (classpower and classpower.inCombat) then
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
		cast.PostCastInterruptible = Cast_Update
		cast.PostCastStart = Cast_Update
		--cast.PostCastStop = Cast_Update -- needed?

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
		local maxPoints = (ns.IsRetail) and (playerClass == "MONK" or playerClass == "ROGUE") and 6 or 5
		for i = 1,maxPoints do
			classpower[i] = ClassPower_CreatePoint(classpower)
		end

		--ClassPower_PostUpdate(classpower, 0, maxPoints)

		self.ClassPower = classpower
		self.ClassPower.PostUpdate = ClassPower_PostUpdate
		self.ClassPower.PostUpdateColor = ClassPower_PostUpdateColor
	end

	-- Monk Stagger
	--------------------------------------------
	if (playerClass == "MONK") and (not SCP) then

		local stagger = CreateFrame("Frame", nil, self)
		stagger.SetValue = noop
		stagger.SetMinMaxValues = noop
		stagger.SetStatusBarColor = Stagger_SetStatusBarColor

		for i = 1,3 do
			stagger[i] = ClassPower_CreatePoint(stagger)
		end

		ClassPower_PostUpdate(stagger, 0, 3)

		self.Stagger = stagger
		self.Stagger.PostUpdate = Stagger_PostUpdate
	end

	-- Death Knight Runes
	--------------------------------------------
	if (playerClass == "DEATHKNIGHT") and (ns.IsWrath or (ns.IsRetail and not SCP)) then

		local runes = CreateFrame("Frame", nil, self)
		runes.sortOrder = "ASC"
		for i = 1,6 do
			runes[i] = ClassPower_CreatePoint(runes)
		end

		ClassPower_PostUpdate(runes, 6, 6)

		self.Runes = runes
		self.Runes.PostUpdate = Runes_PostUpdate
		self.Runes.PostUpdateColor = Runes_PostUpdateColor
	end

	-- Scripts & Events
	--------------------------------------------
	self.OnEvent = UnitFrame_OnEvent
	self.OnHide = UnitFrame_OnHide

	self:RegisterEvent("PLAYER_REGEN_ENABLED", self.OnEvent, true)
	self:RegisterEvent("PLAYER_REGEN_DISABLED", self.OnEvent, true)

end
