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
	end

	-- Monk Stagger
	--------------------------------------------
	if (playerClass == "MONK") and (not SCP) then
	end

	-- Death Knight Runes
	--------------------------------------------
	if (playerClass == "DEATHKNIGHT") and (ns.IsWrath or (ns.IsRetail and not SCP)) then
	end

end
