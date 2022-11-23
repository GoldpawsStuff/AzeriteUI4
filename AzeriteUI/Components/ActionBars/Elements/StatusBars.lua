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
local ActionBars = ns:GetModule("ActionBars")
local StatusBars = ActionBars:NewModule("StatusBars", "LibMoreEvents-1.0")
local LibSpinBar = LibStub("LibSpinBar-1.0")

local L = LibStub("AceLocale-3.0"):GetLocale(Addon)

-- Lua API
local math_floor = math.floor
local math_min = math.min
local string_format = string.format
local unpack = unpack

-- WoW API
local GetFactionInfo = GetFactionInfo
local GetFactionParagonInfo = C_Reputation and C_Reputation.GetFactionParagonInfo
local C_GossipInfo_GetFriendshipReputation = C_GossipInfo and C_GossipInfo.GetFriendshipReputation
local GetNumFactions = GetNumFactions
local GetRestState = GetRestState
local GetTimeToWellRested = GetTimeToWellRested
local GetWatchedFactionInfo = GetWatchedFactionInfo
local GetXPExhaustion = GetXPExhaustion
local IsFactionParagon = C_Reputation and C_Reputation.IsFactionParagon
local IsPlayerAtEffectiveMaxLevel = IsPlayerAtEffectiveMaxLevel
local IsResting = IsResting
local IsXPUserDisabled = IsXPUserDisabled
local UnitLevel = UnitLevel
local UnitSex = UnitSex
local UnitXP = UnitXP
local UnitXPMax = UnitXPMax

-- Addon API
local Colors = ns.Colors
local AbbreviateNumber = ns.API.AbbreviateNumber
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia
local SetObjectScale = ns.API.SetObjectScale

local playerLevel = UnitLevel("player")

-- Full clear of any cancelled fade-ins
local Button_Clear = function(button)
	button.Frame:Hide()
	button.Frame:SetAlpha(0)
	button.Frame.isMouseOver = nil
	button:SetScript("OnUpdate", nil)
	button.fading = nil
	button.fadeDirection = nil
	button.fadeDuration = 0
	button.fadeDelay = 0
	button.timeFading = 0
end

local Button_OnUpdate = function(button, elapsed)
	if (button.fadeDelay > 0) then
		local fadeDelay = button.fadeDelay - elapsed
		if (fadeDelay > 0) then
			button.fadeDelay = fadeDelay
			return
		end
		button.fadeDelay = 0
		button.timeFading = 0
	end

	button.timeFading = button.timeFading + elapsed

	if (button.fadeDirection == "OUT") then
		local alpha = 1 - (button.timeFading / button.fadeDuration)
		if (alpha > 0) then
			button.Frame:SetAlpha(alpha)
		else
			button:SetScript("OnUpdate", nil)
			button.Frame:Hide()
			button.Frame:SetAlpha(0)
			button.fading = nil
			button.fadeDirection = nil
			button.fadeDuration = 0
			button.timeFading = 0
		end

	elseif (button.fadeDirection == "IN") then
		local alpha = button.timeFading / button.fadeDuration
		if (alpha < 1) then
			button.Frame:SetAlpha(alpha)
		else
			button:SetScript("OnUpdate", nil)
			button.Frame:SetAlpha(1)
			button.fading = nil
			button.fadeDirection = nil
			button.fadeDuration = 0
			button.timeFading = 0
		end
	end
end

-- This method is called upon entering or leaving
-- either the toggle button or the visible ring frame.
-- Its purpose should be to decide ring frame visibility.
local Button_UpdateFrame = function(button)

	-- Move towards full visibility if we're over the toggle or the visible frame
	if (button.isMouseOver) then

		-- If we entered while fading, it's most likely a fade-out that needs to be reversed.
		if (button.fading) then

			-- Reverse the fade-out.
			if (button.fadeDirection == "OUT") then
				button.fadeDirection = "IN"
				button.fadeDuration = .25
				button.fadeDelay = 0
				button.timeFading = 0
				if (not button:GetScript("OnUpdate")) then
					button:SetScript("OnUpdate", Button_OnUpdate)
				end
			else
				-- this is a fade-in we wish to keep running.
			end

		-- If it's not fading it's either because it's hidden, at full alpha,
		-- or because sticky bars just got disabled and it's still fully visible.
		else
			-- Inititate a fade-in delay, but only if the frame is hidden.
			if (not button.Frame:IsShown()) then
				button.Frame:SetAlpha(0)
				button.Frame:Show()
				button.fadeDirection = "IN"
				button.fadeDuration = .25
				button.fadeDelay = .5
				button.timeFading = 0
				button.fading = true
				if (not button:GetScript("OnUpdate")) then
					button:SetScript("OnUpdate", Button_OnUpdate)
				end
			else
				-- The frame is shown, just keep showing it and do nothing.
			end
		end

	elseif (button.Frame.isMouseOver) then
		-- This happens when we've quickly left the toggle button,
		-- like when the mouse accidentally passes it on its way somewhere else.
		if (not button.isMouseOver) and (button.fading) and (button.fadeDelay > 0) and (button.Frame:IsShown() and button.Frame.isMouseOver) then
			return Button_Clear(button)
		end

	-- We're not above the toggle or a visible frame,
	-- so we should initiate a fade-out or cancel pending fade-ins.
	else
		-- if the frame is visible, this should be a fade-out.
		if (button.Frame:IsShown()) then
			-- Only initiate the fade delay if the frame previously was fully shown,
			-- do not start a delay if we moved back into a fading frame then out again
			-- before it could reach its full alpha, or the frame will appear to be "stuck"
			-- in a semi-transparent state for a few seconds. Ewwww.
			if (button.fading) then
				-- This was a queued fade-in that now will be cancelled,
				-- because the mouse is not above the toggle button anymore.
				if (button.fadeDirection == "IN") and (button.fadeDelay > 0) then
					return Button_Clear(button)
				else
					-- This is a semi-visible frame,
					-- that needs to get its fade-out initiated or updated.
					button.fadeDirection = "OUT"
					button.fadeDelay = 0
					button.fadeDuration = (.25 - (button.timeFading or 0))
					button.timeFading = button.timeFading or 0
				end
			else
				-- Most likely a fully visible frame we just left.
				-- Now we initiate the delay and a following fade-out.
				button.fadeDirection = "OUT"
				button.fadeDelay = .5
				button.fadeDuration = .25
				button.timeFading = 0
				button.fading = true
			end
			if (not button:GetScript("OnUpdate")) then
				button:SetScript("OnUpdate", Button_OnUpdate)
			end
		end
	end

end

local Button_UpdateTooltip = function(button)
	if (GameTooltip:IsForbidden()) then return end

	local bar = button.Frame.Bar
	if (bar.currentType == "xp") then
		local r, g, b = unpack(Colors.highlight)

		local exhaustionCountdown = GetTimeToWellRested() and (GetTimeToWellRested() / 60)
		local exhaustionStateID, exhaustionStateName, exhaustionStateMultiplier = GetRestState()
		local tooltipText = string_format(EXHAUST_TOOLTIP1, exhaustionStateName, exhaustionStateMultiplier * 100)

		if (exhaustionCountdown and GetXPExhaustion() and IsResting()) then
			tooltipText = tooltipText..string_format(EXHAUST_TOOLTIP4, exhaustionCountdown)
		elseif (exhaustionStateID == 4 or exhaustionStateID == 5) then
			tooltipText = tooltipText..EXHAUST_TOOLTIP2
		end

		GameTooltip_SetDefaultAnchor(GameTooltip, button)
		GameTooltip:AddDoubleLine(COMBAT_XP_GAIN, string_format(UNIT_LEVEL_TEMPLATE, UnitLevel("player")), r, g, b, unpack(Colors.gray))
		GameTooltip:AddLine("\n"..tooltipText)
		GameTooltip:Show()

	elseif (bar.currentType == "reputation") then
		local r, g, b = unpack(Colors[bar.isFriend and "friendship" or "reaction"][bar.standingID])

		GameTooltip_SetDefaultAnchor(GameTooltip, bar)
		GameTooltip:AddDoubleLine(bar.name, bar.standingLabel, r, g, b, unpack(Colors.gray))
		GameTooltip:Show()
	end

end

local Button_OnMouseUp = function(button)
	Button_UpdateFrame(button)
end

local Button_OnEnter = function(button)
	button.UpdateTooltip = Button_UpdateTooltip
	button.isMouseOver = true

	Button_UpdateFrame(button)

	button:UpdateTooltip()
end

local Button_OnLeave = function(button)
	button.isMouseOver = nil

	-- Update this to avoid a flicker or delay
	-- when moving directly from the toggle button to the ringframe.
	button.Frame.isMouseOver = MouseIsOver(button.Frame)

	Button_UpdateFrame(button)

	if (GameTooltip:IsForbidden()) then return end
	if not(button.Frame.isMouseOver and button.Frame:IsShown()) then
		GameTooltip:Hide()
	end
end

local RingFrame_UpdateTooltip = function(frame)
	Button_UpdateTooltip(frame.Button)
end

local RingFrame_OnEnter = function(frame)
	frame.isMouseOver = frame:IsShown()

	Button_UpdateFrame(frame.Button)

	if (not frame:IsShown()) then
		frame.Button.fading = nil
		frame.Button.fadeDirection = nil
		frame.Button.fadeDuration = 0
		frame.Button.fadeDelay = 0
		frame.Button.timeFading = 0
	end

	-- The above method can actually hide this frame,
	-- trigger the OnLeave handler, and remove UpdateTooltip.
	-- We need to check if it still exists before running it.
	if (frame:IsShown()) and (frame.UpdateTooltip) then
		frame:UpdateTooltip()
	end
end

local RingFrame_OnLeave = function(frame)
	-- Update this to avoid a flicker or delay
	-- when moving directly from the ringframe to the toggle button.
	frame.Button.isMouseOver = MouseIsOver(frame.Button)
	frame.isMouseOver = nil

	Button_UpdateFrame(frame.Button)

	if (GameTooltip:IsForbidden()) then return end
	if (not frame.isMouseOver) then
		GameTooltip:Hide()
	end
end

StatusBars.UpdateBars = function(self, event, ...)
	if (not self.Bar) then
		return
	end

	local bar, bonus = self.Bar, self.Bonus
	local bonusShown = bonus:IsShown()
	local showButton

	local name, reaction, min, max, current, factionID = GetWatchedFactionInfo()
	if (name) then
		local forced = bar.currentType ~= "reputation"
		local gender = UnitSex("player")

		-- Check for retail paragon factions
		if (ns.IsRetail) then
			if (factionID and IsFactionParagon(factionID)) then
				local currentValue, threshold, _, hasRewardPending = GetFactionParagonInfo(factionID)
				if (currentValue and threshold) then
					min, max = 0, threshold
					current = currentValue % threshold
					if (hasRewardPending) then
						current = current + threshold
					end
				end
			end
		end

		-- Figure out the standingID of the watched faction
		local standingID, standingLabel, standingDescription, isFriend, friendText
		for i = 1, GetNumFactions() do
			local factionName, description, standingId, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild, factionID, hasBonusRepGain, canBeLFGBonus = GetFactionInfo(i)
			if (factionName == name) then

				-- Check if the watched faction is a retail friendship
				if (ns.IsRetail) then
					local repInfo = C_GossipInfo_GetFriendshipReputation(factionID)
					if (repInfo and repInfo.friendshipFactionID > 0) then
						if (repInfo.friendshipFactionID) then
							isFriend = true
							if (repInfo.nextThreshold) then
								min = repInfo.reactionThreshold
								max = repInfo.nextThreshold
								current = repInfo.standing
							else
								-- Make maxed friendships appear as a full bar.
								min = 0
								max = 1
								current = 1
							end
							standingLabel = repInfo.reaction
						end
					end
				end

				standingDescription = description
				standingID = standingId
				break
			end
		end

		if (standingID) then
			local barMax = max - min
			local barValue = current - min
			if (barMax == 0) then
				bar:SetMinMaxValues(0,1)
				bar:SetValue(1)
			else
				bar:SetMinMaxValues(0, max-min)
				bar:SetValue(current-min)
			end

			local r, g, b = unpack(Colors[isFriend and "friendship" or "reaction"][standingID])
			bar:SetStatusBarColor(r, g, b)
			bar.currentType = "reputation"

			if (not isFriend) then
				standingLabel = GetText("FACTION_STANDING_LABEL"..standingID, gender)
			end

			bar.name = name
			bar.isFriend = isFriend
			bar.standingID, bar.standingLabel = standingID, standingLabel

			bar.Value:SetFormattedText("%s", AbbreviateNumber(barMax-barValue))

			local nextStanding = standingID and _G["FACTION_STANDING_LABEL"..(standingID + 1)] and GetText("FACTION_STANDING_LABEL"..standingID + 1, gender)
			if (nextStanding) then
				bar.Description:SetFormattedText(L["to %s"], nextStanding)
			else
				bar.Description:SetText("")
			end

			bar.Value:SetTextColor(r, g, b)
			bar.Percent:SetTextColor(r, g, b)

			local perc = math_floor(barValue/barMax)
			if (perc > 0) then
				bar.Percent:SetFormattedText("%.0f", perc)
			else
				bar.Percent:SetText("*")
			end

			bar:Show()

			showButton = true

		else
			bar:Hide()
		end

		if (bonusShown) then
			bonus:Hide()
			bonus:SetValue(0, true)
			bonus:SetMinMaxValues(0, 1, true)
		end
	else
		if (IsPlayerAtEffectiveMaxLevel() or IsXPUserDisabled()) then
			bar.currentType = nil
			bar:Hide()
			bonus:Hide()
			bar.Value:SetText("")
			bar.Description:SetText("")
			bar.Percent:SetText("")
		else
			if (event == "PLAYER_LEVEL_UP") then
				playerLevel = ...
			end

			local forced = bar.currentType ~= "xp"
			local resting = IsResting()
			local restState, restedName, mult = GetRestState()
			local restedLeft, restedTimeLeft = GetXPExhaustion(), GetTimeToWellRested()
			local min = UnitXP("player") or 0
			local max = UnitXPMax("player") or 0
			local r, g, b = unpack(Colors[restedLeft and "rested" or "xp"])

			bar:SetMinMaxValues(0, max, forced)
			bar:SetValue(min, forced)
			bar:SetStatusBarColor(r, g, b)
			bar.currentType = "xp"

			if (restedLeft) then
				bonus:SetMinMaxValues(0, max, not bonusShown)
				bonus:SetValue(math_min(max, min + restedLeft), not bonusShown)
				if (not bonusShown) then
					bonus:Show()
				end
			elseif (bonusShown) then
				bonus:Hide()
				bonus:SetValue(0, true)
				bonus:SetMinMaxValues(0, 1, true)
			end

			bar.Value:SetFormattedText("%s", AbbreviateNumber(max-min))
			bar.Description:SetFormattedText(L["to level %s"], playerLevel + 1)
			bar.Value:SetTextColor(r, g, b)
			bar.Percent:SetTextColor(r, g, b)

			local perc = math_floor(min/max)
			if (perc > 0) then
				bar.Percent:SetFormattedText("%.0f", perc)
			else
				bar.Percent:SetText(XP)
			end

			bar:Show()

			showButton = true
		end
	end

	if (showButton and not self.Button:IsShown()) then
		self.Button:Show()
	elseif (not showButton and self.Button:IsShown()) then
		self.Button:Hide()
	end
end

StatusBars.CreateBars = function(self)

	local db = ns.Config.StatusBars

	local button = SetObjectScale(CreateFrame("Frame", nil, Minimap))
	button:Hide()
	button:SetFrameStrata("MEDIUM")
	button:SetFrameLevel(60)
	button:SetPoint(unpack(db.ButtonPosition))
	button:SetSize(unpack(db.ButtonSize))
	button:EnableMouse(true)
	button:SetScript("OnEnter", Button_OnEnter)
	button:SetScript("OnLeave", Button_OnLeave)
	button:SetScript("OnMouseUp", Button_OnMouseUp)

	local texture = button:CreateTexture(nil, "BACKGROUND", nil, 1)
	texture:SetSize(unpack(db.ButtonTextureSize))
	texture:SetPoint(unpack(db.ButtonTexturePosition))
	texture:SetTexture(db.ButtonTexturePath)
	texture:SetVertexColor(unpack(db.ButtonTextureColor))

	button.Texture = texture

	local frame = CreateFrame("Frame", nil, button)
	frame:Hide()
	frame:SetFrameLevel(button:GetFrameLevel() - 10)
	frame:SetPoint(unpack(db.RingFramePosition))
	frame:SetSize(unpack(db.RingFrameSize))
	frame:EnableMouse(true)
	frame:SetScript("OnEnter", RingFrame_OnEnter)
	frame:SetScript("OnLeave", RingFrame_OnLeave)

	frame.Button = button
	button.Frame = frame

	local backdrop = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
	backdrop:SetPoint(unpack(db.RingFrameBackdropPosition))
	backdrop:SetSize(unpack(db.RingFrameBackdropSize))
	backdrop:SetTexture(db.RingFrameBackdropTexture)
	backdrop:SetVertexColor(unpack(db.RingFrameBackdropColor))

	frame.Bg = backdrop

	local ring = LibSpinBar:CreateSpinBar(ns.Prefix.."StatusTrackingBar", frame)
	ring:SetFrameLevel(frame:GetFrameLevel() + 5)
	ring:SetPoint(unpack(db.RingPosition))
	ring:SetSize(unpack(db.RingSize))
	ring:SetSparkOffset(db.RingSparkOffset)
	ring:SetSparkFlash(unpack(db.RingSparkFlash))
	ring:SetSparkBlendMode("ADD")
	ring:SetClockwise(true)
	ring:SetDegreeOffset(db.RingDegreeOffset)
	ring:SetDegreeSpan(db.RingDegreeSpan)
	ring:SetStatusBarTexture(db.RingTexture)

	frame.Bar = ring

	local bonus = LibSpinBar:CreateSpinBar(ns.Prefix.."StatusTrackingBarBonusBar", frame)
	bonus:Hide() -- for some reason this is required. will look into it later.
	bonus:SetFrameLevel(frame:GetFrameLevel() + 2)
	bonus:SetPoint(unpack(db.RingPosition))
	bonus:SetSize(unpack(db.RingSize))
	bonus:SetSparkOffset(db.RingSparkOffset)
	bonus:SetSparkFlash(unpack(db.RingSparkFlash))
	bonus:SetSparkBlendMode("ADD")
	bonus:SetClockwise(true)
	bonus:SetDegreeOffset(db.RingDegreeOffset)
	bonus:SetDegreeSpan(db.RingDegreeSpan)
	bonus:SetStatusBarTexture(db.RingTexture)
	bonus:SetStatusBarColor(unpack(Colors.restedBonus))

	ring.Bonus = bonus

	-- Ring Value Text
	local value = ring:CreateFontString(nil, "OVERLAY", nil, 1)
	value:SetPoint(unpack(db.RingValuePosition))
	value:SetJustifyH(db.RingValueJustifyH)
	value:SetJustifyV(db.RingValueJustifyV)
	value:SetFontObject(db.RingValueFont)
	value.showDeficit = true

	ring.Value = value

	-- Ring Description Text
	local description = ring:CreateFontString(nil, "OVERLAY", nil, 1)
	description:SetPoint(unpack(db.RingValueDescriptionPosition))
	description:SetWidth(db.RingValueDescriptionWidth)
	description:SetTextColor(unpack(db.RingValueDescriptionColor))
	description:SetJustifyH(db.RingValueDescriptionJustifyH)
	description:SetJustifyV(db.RingValueDescriptionJustifyV)
	description:SetFontObject(db.RingValueDescriptionFont)
	description:SetIndentedWordWrap(false)
	description:SetWordWrap(true)
	description:SetNonSpaceWrap(false)

	ring.Description = description

	-- Button Percentage Text
	local perc = button:CreateFontString(nil, "OVERLAY", nil, 1)
	perc:SetJustifyH(db.RingPercentJustifyH)
	perc:SetJustifyV(db.RingPercentJustifyV)
	perc:SetFontObject(db.RingPercentFont)
	perc:SetPoint(unpack(db.RingPercentPosition))

	ring.Percent = perc

	self.Button = button
	self.Frame = frame
	self.Bar = ring
	self.Bonus = bonus

	ns:Fire("StatusTrackingBar_Created", self.Bar:GetName())

end

StatusBars.OnInitialize = function(self)
	self:CreateBars()
end

StatusBars.OnEnable = function(self)
	self:UpdateBars()
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateBars")
	self:RegisterEvent("PLAYER_LOGIN", "UpdateBars")
	self:RegisterEvent("PLAYER_ALIVE", "UpdateBars")
	self:RegisterEvent("PLAYER_LEVEL_UP", "UpdateBars")
	self:RegisterEvent("PLAYER_XP_UPDATE", "UpdateBars")
	self:RegisterEvent("PLAYER_FLAGS_CHANGED", "UpdateBars")
	self:RegisterEvent("DISABLE_XP_GAIN", "UpdateBars")
	self:RegisterEvent("ENABLE_XP_GAIN", "UpdateBars")
	self:RegisterEvent("PLAYER_UPDATE_RESTING", "UpdateBars")
	self:RegisterEvent("UPDATE_EXHAUSTION", "UpdateBars")
	self:RegisterEvent("UPDATE_FACTION", "UpdateBars")
end