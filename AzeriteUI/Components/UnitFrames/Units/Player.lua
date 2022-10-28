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
local string_gsub = string.gsub
local type = type
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
local IsLoveFestival = ns.API.IsLoveFestival()
local IsWinterVeil = ns.API.IsWinterVeil()
local playerClass = select(2, UnitClass("player"))
local playerLevel = UnitLevel("player")
local playerXPDisabled = IsXPUserDisabled()
local hardenedLevel = ns.IsRetail and 10 or ns.IsClassic and 40 or 30

-- Utility Functions
--------------------------------------------
-- Simplify the tagging process a little.
local prefix = function(msg)
	return string_gsub(msg, "*", ns.Prefix)
end

-- Element Callbacks
--------------------------------------------
-- Forceupdate health prediction on health updates,
-- to assure our smoothed elements are properly aligned.
local Health_PostUpdate = function(element, unit, cur, max)
	local predict = element.__owner.HealthPrediction
	if (predict) then
		predict:ForceUpdate()
	end
end

-- Update the health preview color on health color updates.
local Health_PostUpdateColor = function(element, unit, r, g, b)
	local preview = element.Preview
	if (preview) then
		preview:SetStatusBarColor(r * .7, g * .7, b * .7)
	end
end

-- Align our custom health prediction texture
-- based on the plugins provided values.
local HealPredict_PostUpdate = function(element, unit, myIncomingHeal, otherIncomingHeal, absorb, healAbsorb, hasOverAbsorb, hasOverHealAbsorb, curHealth, maxHealth)

	local allIncomingHeal = myIncomingHeal + otherIncomingHeal
	local allNegativeHeals = healAbsorb
	local showPrediction, change

	if ((allIncomingHeal > 0) or (allNegativeHeals > 0)) and (maxHealth > 0) then
		local startPoint = curHealth/maxHealth

		-- Dev switch to test absorbs with normal healing
		--allIncomingHeal, allNegativeHeals = allNegativeHeals, allIncomingHeal

		-- Hide elementions if the change is very small, or if the unit is at max health.
		change = (allIncomingHeal - allNegativeHeals)/maxHealth
		if ((curHealth < maxHealth) and (change > (element.health.predictThreshold or .05))) then
			local endPoint = startPoint + change

			-- Crop heal elemention overflows
			if (endPoint > 1) then
				endPoint = 1
				change = endPoint - startPoint
			end

			-- Crop heal absorb overflows
			if (endPoint < 0) then
				endPoint = 0
				change = -startPoint
			end

			-- This shouldn't happen, but let's do it anyway.
			if (startPoint ~= endPoint) then
				showPrediction = true
			end
		end
	end

	if (showPrediction) then

		local preview = element.preview
		local growth = preview:GetGrowth()
		local min,max = preview:GetMinMaxValues()
		local value = preview:GetValue() / max
		local previewTexture = preview:GetStatusBarTexture()
		local previewWidth, previewHeight = preview:GetSize()
		local left, right, top, bottom = preview:GetTexCoord()

		if (growth == "RIGHT") then

			local texValue, texChange = value, change
			local rangeH, rangeV

			rangeH = right - left
			rangeV = bottom - top
			texChange = change*value
			texValue = left + value*rangeH

			if (change > 0) then
				element:ClearAllPoints()
				element:SetPoint("BOTTOMLEFT", previewTexture, "BOTTOMRIGHT", 0, 0)
				element:SetSize(change*previewWidth, previewHeight)
				element:SetTexCoord(texValue, texValue + texChange, top, bottom)
				element:SetVertexColor(0, .7, 0, .25)
				element:Show()

			elseif (change < 0) then
				element:ClearAllPoints()
				element:SetPoint("BOTTOMRIGHT", previewTexture, "BOTTOMRIGHT", 0, 0)
				element:SetSize((-change)*previewWidth, previewHeight)
				element:SetTexCoord(texValue + texChange, texValue, top, bottom)
				element:SetVertexColor(.5, 0, 0, .75)
				element:Show()

			else
				element:Hide()
			end

		elseif (growth == "LEFT") then
			local texValue, texChange = value, change
			local rangeH, rangeV
			rangeH = right - left
			rangeV = bottom - top
			texChange = change*value
			texValue = left + value*rangeH

			if (change > 0) then
				element:ClearAllPoints()
				element:SetPoint("BOTTOMRIGHT", previewTexture, "BOTTOMLEFT", 0, 0)
				element:SetSize(change*previewWidth, previewHeight)
				element:SetTexCoord(texValue + texChange, texValue, top, bottom)
				element:SetVertexColor(0, .7, 0, .25)
				element:Show()

			elseif (change < 0) then
				element:ClearAllPoints()
				element:SetPoint("BOTTOMLEFT", previewTexture, "BOTTOMLEFT", 0, 0)
				element:SetSize((-change)*previewWidth, previewHeight)
				element:SetTexCoord(texValue, texValue + texChange, top, bottom)
				element:SetVertexColor(.5, 0, 0, .75)
				element:Show()

			else
				element:Hide()
			end
		end
	else
		element:Hide()
	end

	local absorb = self.Absorb
	if (absorb) then
		local fraction = absorb/maxHealth
		if (fraction > .6) then
			absorb = maxHealth * .6
		end
		absorb:SetMinMaxValues(0, maxHealth)
		absorb:SetValue(absorb)
	end

end

-- Only show mana orb when mana is the primary resource.
local Mana_UpdateVisibility = function(self, event, unit)
	local element = self.AdditionalPower

	local shouldEnable = not UnitHasVehicleUI("player") and UnitPowerType(unit) == Enum.PowerType.Mana
	local isEnabled = element.__isEnabled

	if (shouldEnable and not isEnabled) then

		if (element.frequentUpdates) then
			self:RegisterEvent("UNIT_POWER_FREQUENT", element.Override)
		else
			self:RegisterEvent("UNIT_POWER_UPDATE", element.Override)
		end

		self:RegisterEvent("UNIT_MAXPOWER", element.Override)

		element:Show()

		element.__isEnabled = true
		element.Override(self, "ElementEnable", "player", "MANA")

		--[[ Callback: AdditionalPower:PostVisibility(isVisible)
		Called after the element's visibility has been changed.

		* self      - the AdditionalPower element
		* isVisible - the current visibility state of the element (boolean)
		--]]
		if (element.PostVisibility) then
			element:PostVisibility(true)
		end

	elseif (not shouldEnable and (isEnabled or isEnabled == nil)) then

		self:UnregisterEvent("UNIT_MAXPOWER", element.Override)
		self:UnregisterEvent("UNIT_POWER_FREQUENT", element.Override)
		self:UnregisterEvent("UNIT_POWER_UPDATE", element.Override)

		element:Hide()

		element.__isEnabled = false
		element.Override(self, "ElementDisable", "player", "MANA")

		if (element.PostVisibility) then
			element:PostVisibility(false)
		end

	elseif (shouldEnable and isEnabled) then
		element.Override(self, event, unit, "MANA")
	end
end

-- Hide power crystal when mana is the primary resource.
local Power_UpdateVisibility = function(element, unit, cur, min, max)
	local powerType = UnitPowerType(unit)
	if (powerType == Enum.PowerType.Mana) then
		element:Hide()
	else
		element:Show()
	end
end

-- Use custom colors for our power crystal. Does not apply to Wrath.
local Power_UpdateColor = function(self, event, unit)
	if (self.unit ~= unit) then
		return
	end
	local element = self.Power
	local pType, pToken, altR, altG, altB = UnitPowerType(unit)
	if (pToken) then
		local color = ns.Config.Player.PowerBarColors[pToken]
		element:SetStatusBarColor(unpack(color))
	end
end

-- Update player frame based on player level.
local UnitFrame_UpdateTextures = function(self)
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

	local healthPreview = self.Health.Preview
	healthPreview:SetStatusBarTexture(db.HealthBarTexture)

	local healthBackdrop = self.Health.Backdrop
	healthBackdrop:ClearAllPoints()
	healthBackdrop:SetPoint(unpack(db.HealthBackdropPosition))
	healthBackdrop:SetSize(unpack(db.HealthBackdropSize))
	healthBackdrop:SetTexture(db.HealthBackdropTexture)
	healthBackdrop:SetVertexColor(unpack(db.HealthBackdropColor))

	local healthValue = self.Health.Value
	healthValue:SetPoint(unpack(db.HealthValuePosition))
	healthValue:SetFontObject(db.HealthValueFont)
	healthValue:SetTextColor(unpack(db.HealthValueColor))
	healthValue:SetJustifyH(db.HealthValueJustifyH)
	healthValue:SetJustifyV(db.HealthValueJustifyV)

	local healPredict = self.HealthPrediction
	healPredict:SetTexture(db.HealthBarTexture)

	local absorb = self.Health.Absorb
	if (absorb) then
		absorb:SetStatusBarTexture(db.HealthBarTexture)
		absorb:SetStatusBarColor(db.HealthAbsorbColor)
		local orientation
		if (db.HealthBarOrientation == "UP") then
			orientation = "DOWN"
		elseif (db.HealthBarOrientation == "DOWN") then
			orientation = "UP"
		elseif (db.HealthBarOrientation == "LEFT") then
			orientation = "RIGHT"
		else
			orientation = "LEFT"
		end
		absorb:SetOrientation(orientation)
		absorb:SetSparkMap(db.HealthBarSparkMap)
	end

	local power = self.Power
	power:ClearAllPoints()
	power:SetPoint(unpack(db.PowerBarPosition))
	power:SetSize(unpack(db.PowerBarSize))
	power:SetStatusBarTexture(db.PowerBarTexture)
	power:SetTexCoord(unpack(db.PowerBarTexCoord))
	power:SetOrientation(db.PowerBarOrientation)
	power:SetSparkMap(db.PowerBarSparkMap)

	local powerBackdrop = self.Power.Backdrop
	powerBackdrop:ClearAllPoints()
	powerBackdrop:SetPoint(unpack(db.PowerBackdropPosition))
	powerBackdrop:SetSize(unpack(db.PowerBackdropSize))
	powerBackdrop:SetTexture(db.PowerBackdropTexture)

	local powerCase = self.Power.Case
	powerCase:ClearAllPoints()
	powerCase:SetPoint(unpack(db.PowerBarForegroundPosition))
	powerCase:SetSize(unpack(db.PowerBarForegroundSize))
	powerCase:SetTexture(db.PowerBarForegroundTexture)
	powerCase:SetVertexColor(unpack(db.PowerBarForegroundColor))

	local powerValue = self.Power.Value
	powerValue:SetPoint(unpack(db.PowerValuePosition))
	powerValue:SetFontObject(db.PowerValueFont)
	powerValue:SetTextColor(unpack(db.PowerValueColor))
	powerValue:SetJustifyH(db.PowerValueJustifyH)
	powerValue:SetJustifyV(db.PowerValueJustifyV)

	local mana = self.AdditionalPower
	mana:ClearAllPoints()
	mana:SetPoint(unpack(db.ManaOrbPosition))
	mana:SetSize(unpack(db.ManaOrbSize))
	if (type(db.ManaOrbTexture) == "table") then
		mana:SetStatusBarTexture(unpack(db.ManaOrbTexture))
	else
		mana:SetStatusBarTexture(db.ManaOrbTexture)
	end
	mana:SetStatusBarColor(unpack(ns.Config.Player.ManaOrbColor))

	local manaBackdrop = self.AdditionalPower.Backdrop
	manaBackdrop:ClearAllPoints()
	manaBackdrop:SetPoint(unpack(db.ManaOrbBackdropPosition))
	manaBackdrop:SetSize(unpack(db.ManaOrbBackdropSize))
	manaBackdrop:SetTexture(db.ManaOrbBackdropTexture)
	manaBackdrop:SetVertexColor(unpack(db.ManaOrbBackdropColor))

	local manaShade = self.AdditionalPower.Shade
	manaShade:ClearAllPoints()
	manaShade:SetPoint(unpack(db.ManaOrbShadePosition))
	manaShade:SetSize(unpack(db.ManaOrbShadeSize))
	manaShade:SetTexture(db.ManaOrbShadeTexture)
	manaShade:SetVertexColor(unpack(db.ManaOrbShadeColor))

	local manaCase = self.AdditionalPower.Case
	manaCase:ClearAllPoints()
	manaCase:SetPoint(unpack(db.ManaOrbForegroundPosition))
	manaCase:SetSize(unpack(db.ManaOrbForegroundSize))
	manaCase:SetTexture(db.ManaOrbForegroundTexture)
	manaCase:SetVertexColor(unpack(db.ManaOrbForegroundColor))

	local cast = self.Castbar
	cast:ClearAllPoints()
	cast:SetPoint(unpack(db.HealthBarPosition))
	cast:SetSize(unpack(db.HealthBarSize))
	cast:SetStatusBarTexture(db.HealthBarTexture)
	cast:SetStatusBarColor(unpack(db.HealthCastOverlayColor))
	cast:SetOrientation(db.HealthBarOrientation)
	cast:SetSparkMap(db.HealthBarSparkMap)

	local feedbackText = self.CombatFeedback
	feedbackText:ClearAllPoints()
	feedbackText:SetPoint(db.CombatFeedbackPosition[1], self[db.CombatFeedbackAnchorElement], unpack(db.CombatFeedbackPosition))
	feedbackText:SetFontObject(db.CombatFeedbackFont)
	feedbackText.feedbackFont = db.CombatFeedbackFont
	feedbackText.feedbackFontLarge = db.CombatFeedbackFontLarge
	feedbackText.feedbackFontSmall = db.CombatFeedbackFontSmall

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

	UnitFrame_UpdateTextures(self)
end

UnitStyles["Player"] = function(self, unit, id)

	self:SetSize(unpack(ns.Config.Player.Size))
	self:SetPoint(unpack(ns.Config.Player.Position))
	self:SetHitRectInsets(unpack(ns.Config.Player.HitRectInsets))

	-- Overlay for icons and text
	--------------------------------------------
	local overlay = CreateFrame("Frame", nil, self)
	overlay:SetFrameLevel(self:GetFrameLevel() + 5)
	overlay:SetAllPoints()

	self.Overlay = overlay

	-- Health
	--------------------------------------------
	local health = self:CreateBar()
	health:SetFrameLevel(health:GetFrameLevel() + 2)
	health.predictThreshold = .01

	self.Health = health
	self.Health.Override = ns.API.UpdateHealth
	self.Health.PostUpdate = Health_PostUpdate

	local healthBackdrop = self:CreateTexture(nil, "BACKGROUND", nil, -1)

	self.Health.Backdrop = healthBackdrop

	local healthPreview = self:CreateBar(nil, health)
	healthPreview:SetAllPoints(health)
	healthPreview:SetFrameLevel(health:GetFrameLevel() - 1)
	healthPreview:DisableSmoothing(true)
	healthPreview:SetSparkTexture("")
	healthPreview:SetAlpha(.5)

	self.Health.Preview = healthPreview

	-- Health Prediction
	--------------------------------------------
	local healPredictFrame = CreateFrame("Frame", nil, health)
	healPredictFrame:SetFrameLevel(health:GetFrameLevel() + 2)

	local healPredict = healPredictFrame:CreateTexture(nil, "OVERLAY", nil, 1)
	healPredict.health = health
	healPredict.preview = preview
	healPredict.maxOverflow = 1

	self.HealthPrediction = healPredict
	self.HealthPrediction.PostUpdate = HealPredict_PostUpdate

	-- Health Cast Overlay
	--------------------------------------------
	local castbar = self:CreateBar()
	castbar:SetFrameLevel(self:GetFrameLevel() + 5)
	castbar:DisableSmoothing()

	self.Castbar = castbar

	-- Health Value
	--------------------------------------------
	local healthValue = overlay:CreateFontString(nil, "OVERLAY", nil, 1)

	if (ns.IsRetail) then
		self:Tag(healthValue, prefix("[*:Health:Big]  [*:Absorb]"))
	else
		self:Tag(healthValue, prefix("[*:Health:Big]"))
	end

	self.Health.Value = healthValue

	-- Health Percentage
	-- *we also add dead/offline flags here.
	--------------------------------------------
	--local healthPerc = overlay:CreateFontString(health:GetName().."PercentText", "OVERLAY", nil, 1)
	--self:Tag(healthPerc, prefix("[*:Health:Percent][*:Dead][*:Offline]"))
	--
	--self.Health.ValuePercent = healthPerc

	-- Absorb Bar (Retail)
	--------------------------------------------
	if (ns.IsRetail) then
		local absorb = self:CreateBar()
		absorb:SetAllPoints(health)
		absorb:SetFrameLevel(health:GetFrameLevel() + 3)

		self.Absorb = absorb
	end

	-- Power Crystal
	--------------------------------------------
	local power = self:CreateBar()
	power.frequentUpdates = true
	power.displayAltPower = true

	self.Power = power
	self.Power.Override = ns.API.UpdatePower
	self.Power.PostUpdate = Power_UpdateVisibility
	self.Power.UpdateColor = ns.Retail and Power_UpdateColor

	local powerBackdrop = power:CreateTexture(nil, "BACKGROUND", nil, -2)

	self.Power.Backdrop = powerBackdrop

	local powerCase = power:CreateTexture(nil, "ARTWORK", nil, 1)

	self.Power.Case = powerCase

	-- Power Value
	--------------------------------------------
	local powerValue = overlay:CreateFontString(nil, "OVERLAY", nil, 1)
	self:Tag(powerValue, prefix("[*:Power:Full]"))

	self.Power.Value = powerValue

	-- Mana Orb
	--------------------------------------------
	local mana = self:CreateOrb()
	mana.displayPairs = {}
	mana.frequentUpdates = true

	self.AdditionalPower = mana
	self.AdditionalPower.Override = ns.API.UpdateAdditionalPower
	self.AdditionalPower.OverrideVisibility = Mana_UpdateVisibility

	local manaBackdrop = mana:CreateTexture(nil, "BACKGROUND", nil, -2)

	self.AdditionalPower.Backdrop = manaBackdrop

	local manaCaseFrame = CreateFrame("Frame", nil, mana)
	manaCaseFrame:SetFrameLevel(mana:GetFrameLevel() + 2)
	manaCaseFrame:SetAllPoints()

	local manaShade = manaCaseFrame:CreateTexture(nil, "ARTWORK", nil, 1)

	self.AdditionalPower.Shade = manaShade

	local manaCase = manaCaseFrame:CreateTexture(nil, "ARTWORK", nil, 2)

	self.AdditionalPower.Case = manaCase

	-- CombatFeedback Text
	--------------------------------------------
	local feedbackText = overlay:CreateFontString(nil, "OVERLAY")

	self.CombatFeedback = feedbackText




	-- Seasonal Flavors
	--------------------------------------------
	-- Feast of Winter Veil
	if (IsWinterVeil) then
		local db = ns.Config.Player.Seasonal

		local winterVeilPower = power:CreateTexture(nil, "OVERLAY", nil, 0)
		winterVeilPower:SetSize(unpack(db.WinterVeilPowerSize))
		winterVeilPower:SetPoint(unpack(db.WinterVeilPowerPlace))
		winterVeilPower:SetTexture(db.WinterVeilPowerTexture)

		self.Power.WinterVeil = winterVeilPower

		local winterVeilMana = manaCaseFrame:CreateTexture(nil, "OVERLAY", nil, 0)
		winterVeilMana:SetSize(unpack(db.WinterVeilManaSize))
		winterVeilMana:SetPoint(unpack(db.WinterVeilManaPlace))
		winterVeilMana:SetTexture(db.WinterVeilManaTexture)

		self.AdditionalPower.WinterVeil = winterVeilMana
	end

	-- Love is in the Air
	if (IsLoveFestival) then
	end

	-- Add a callback for external style overriders
	self:AddForceUpdate(UnitFrame_UpdateTextures)

	self:RegisterEvent("PLAYER_ALIVE", OnEvent, true)
	self:RegisterEvent("PLAYER_ENTERING_WORLD", OnEvent, true)
	self:RegisterEvent("DISABLE_XP_GAIN", OnEvent, true)
	self:RegisterEvent("ENABLE_XP_GAIN", OnEvent, true)
	self:RegisterEvent("PLAYER_LEVEL_UP", OnEvent, true)
	self:RegisterEvent("PLAYER_XP_UPDATE", OnEvent, true)

end
