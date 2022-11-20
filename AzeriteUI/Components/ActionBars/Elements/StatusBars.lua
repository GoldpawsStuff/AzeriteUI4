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
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia
local SetObjectScale = ns.API.SetObjectScale

local playerLevel = UnitLevel("player")

-- Local bar registry
local Bars = {}

local Reputation_OnEnter = function(self)
	if (GameTooltip:IsForbidden()) then return end

	local r, g, b = unpack(Colors[self.isFriend and "friendship" or "reaction"][self.standingID])

	GameTooltip_SetDefaultAnchor(GameTooltip, self)
	GameTooltip:AddDoubleLine(self.name, self.standingLabel, r, g, b, unpack(Colors.gray))
	GameTooltip:Show()
end

local Reputation_OnLeave = function(self)
	if (GameTooltip:IsForbidden()) then return end
	GameTooltip:Hide()
end

local XP_OnEnter = function(self)
	if (GameTooltip:IsForbidden()) then return end

	local r, g, b = unpack(Colors.highlight)

	local exhaustionCountdown = GetTimeToWellRested() and (GetTimeToWellRested() / 60)
	local exhaustionStateID, exhaustionStateName, exhaustionStateMultiplier = GetRestState()
	local tooltipText = string_format(EXHAUST_TOOLTIP1, exhaustionStateName, exhaustionStateMultiplier * 100)

	if (exhaustionCountdown and GetXPExhaustion() and IsResting()) then
		tooltipText = tooltipText..string_format(EXHAUST_TOOLTIP4, exhaustionCountdown)
	elseif (exhaustionStateID == 4 or exhaustionStateID == 5) then
		tooltipText = tooltipText..EXHAUST_TOOLTIP2
	end

	GameTooltip_SetDefaultAnchor(GameTooltip, self)
	GameTooltip:AddDoubleLine(COMBAT_XP_GAIN, string_format(UNIT_LEVEL_TEMPLATE, UnitLevel("player")), r, g, b, unpack(Colors.gray))
	GameTooltip:AddLine("\n"..tooltipText)
	GameTooltip:Show()
end

local XP_OnLeave = function(self)
	if (GameTooltip:IsForbidden()) then return end
	GameTooltip:Hide()
end

-- Full clear of any cancelled fade-ins
local Toggle_Clear = function(toggle)
	toggle.Frame:Hide()
	toggle.Frame:SetAlpha(0)
	toggle.Frame.isMouseOver = nil
	toggle:SetScript("OnUpdate", nil)
	toggle.fading = nil
	toggle.fadeDirection = nil
	toggle.fadeDuration = 0
	toggle.fadeDelay = 0
	toggle.timeFading = 0
end

local Toggle_OnUpdate = function(toggle, elapsed)
	if (toggle.fadeDelay > 0) then
		local fadeDelay = toggle.fadeDelay - elapsed
		if (fadeDelay > 0) then
			toggle.fadeDelay = fadeDelay
			return
		end
		toggle.fadeDelay = 0
		toggle.timeFading = 0
	end

	toggle.timeFading = toggle.timeFading + elapsed

	if (toggle.fadeDirection == "OUT") then
		local alpha = 1 - (toggle.timeFading / toggle.fadeDuration)
		if (alpha > 0) then
			toggle.Frame:SetAlpha(alpha)
		else
			toggle:SetScript("OnUpdate", nil)
			toggle.Frame:Hide()
			toggle.Frame:SetAlpha(0)
			toggle.fading = nil
			toggle.fadeDirection = nil
			toggle.fadeDuration = 0
			toggle.timeFading = 0
		end

	elseif (toggle.fadeDirection == "IN") then
		local alpha = toggle.timeFading / toggle.fadeDuration
		if (alpha < 1) then
			toggle.Frame:SetAlpha(alpha)
		else
			toggle:SetScript("OnUpdate", nil)
			toggle.Frame:SetAlpha(1)
			toggle.fading = nil
			toggle.fadeDirection = nil
			toggle.fadeDuration = 0
			toggle.timeFading = 0
		end
	end
end

-- This method is called upon entering or leaving
-- either the toggle button, the visible ring frame,
-- or by clicking the toggle button.
-- Its purpose should be to decide ring frame visibility.
local Toggle_UpdateFrame = function(toggle)

	-- Move towards full visibility if we're over the toggle or the visible frame
	if (toggle.isMouseOver) then

		-- If we entered while fading, it's most likely a fade-out that needs to be reversed.
		if (toggle.fading) then

			-- Reverse the fade-out.
			if (toggle.fadeDirection == "OUT") then
				toggle.fadeDirection = "IN"
				toggle.fadeDuration = .25
				toggle.fadeDelay = 0
				toggle.timeFading = 0
				if (not toggle:GetScript("OnUpdate")) then
					toggle:SetScript("OnUpdate", Toggle_OnUpdate)
				end
			else
				-- this is a fade-in we wish to keep running.
			end

		-- If it's not fading it's either because it's hidden, at full alpha,
		-- or because sticky bars just got disabled and it's still fully visible.
		else
			-- Inititate a fade-in delay, but only if the frame is hidden.
			if (not frameIsShown) then
				frame:SetAlpha(0)
				frame:Show()
				toggle.fadeDirection = "IN"
				toggle.fadeDuration = .25
				toggle.fadeDelay = .5
				toggle.timeFading = 0
				toggle.fading = true
				if not toggle:GetScript("OnUpdate") then
					toggle:SetScript("OnUpdate", Toggle_OnUpdate)
				end
			else
				-- The frame is shown, just keep showing it and do nothing.
			end
		end

	elseif (frame.isMouseOver) then
		-- This happens when we've quickly left the toggle button,
		-- like when the mouse accidentally passes it on its way somewhere else.
		if (not toggle.isMouseOver) and (toggle.fading) and (toggle.fadeDelay > 0) and (frameIsShown and frame.isMouseOver) then
			return Toggle_Clear(toggle)
		end

	-- We're not above the toggle or a visible frame,
	-- so we should initiate a fade-out or cancel pending fade-ins.
	else
		-- if the frame is visible, this should be a fade-out.
		if (frameIsShown) then
			-- Only initiate the fade delay if the frame previously was fully shown,
			-- do not start a delay if we moved back into a fading frame then out again
			-- before it could reach its full alpha, or the frame will appear to be "stuck"
			-- in a semi-transparent state for a few seconds. Ewwww.
			if (toggle.fading) then
				-- This was a queued fade-in that now will be cancelled,
				-- because the mouse is not above the toggle button anymore.
				if (toggle.fadeDirection == "IN") and (toggle.fadeDelay > 0) then
					return Toggle_Clear(toggle)
				else
					-- This is a semi-visible frame,
					-- that needs to get its fade-out initiated or updated.
					toggle.fadeDirection = "OUT"
					toggle.fadeDelay = 0
					toggle.fadeDuration = (.25 - (toggle.timeFading or 0))
					toggle.timeFading = toggle.timeFading or 0
				end
			else
				-- Most likely a fully visible frame we just left.
				-- Now we initiate the delay and a following fade-out.
				toggle.fadeDirection = "OUT"
				toggle.fadeDelay = .5
				toggle.fadeDuration = .25
				toggle.timeFading = 0
				toggle.fading = true
			end
			if (not toggle:GetScript("OnUpdate")) then
				toggle:SetScript("OnUpdate", Toggle_OnUpdate)
			end
		end
	end

end

local Toggle_OnMouseUp = function(toggle, button)
	Toggle_UpdateFrame(toggle)
end

local Toggle_OnEnter = function(toggle)
	toggle.isMouseOver = true
	Toggle_UpdateFrame(toggle)
end

local Toggle_OnLeave = function(toggle)
	toggle.isMouseOver = nil

	-- Update this to avoid a flicker or delay
	-- when moving directly from the toggle button to the ringframe.
	toggle.Frame.isMouseOver = MouseIsOver(toggle.Frame)

	Toggle_UpdateFrame(toggle)
end

local RingFrame_OnEnter = function(frame)
	local toggle = frame._owner
	local isShown = frame:IsShown()

	frame.isMouseOver = isShown and true

	Toggle_UpdateFrame(toggle)

	isShown = frame:IsShown()

	local toggle = frame._owner
	if (not isShown) then
		toggle.fading = nil
		toggle.fadeDirection = nil
		toggle.fadeDuration = 0
		toggle.fadeDelay = 0
		toggle.timeFading = 0
	end

end

local RingFrame_OnLeave = function(frame)
	local toggle = frame._owner

	frame.isMouseOver = nil
	frame.UpdateTooltip = nil

	-- Update this to avoid a flicker or delay
	-- when moving directly from the ringframe to the toggle button.
	toggle.isMouseOver = MouseIsOver(toggle)

	Toggle_UpdateFrame(toggle)
end

StatusBars.CreateBars = function(self)

	local button = SetObjectScale(CreateFrame("Frame", nil, Minimap))
	button:SetFrameStrata("MEDIUM")
	button:SetFrameLevel(60)
	button:SetPoint(unpack(db.ButtonPosition))
	button:SetSize(unpack(db.ButtonSize))
	button:EnableMouse(true)
	button:SetScript("OnEnter", Toggle_OnEnter)
	button:SetScript("OnLeave", Toggle_OnLeave)
	button:SetScript("OnMouseUp", Toggle_OnMouseUp)

	local texture = button:CreateTexture(nil, "BACKGROUND", nil, 1)
	toggleBackdrop:SetSize(unpack(db.ButtonTextureSize))
	toggleBackdrop:SetPoint(unpack(db.ButtonTexturePosition))
	toggleBackdrop:SetTexture(db.ButtonTexturePath)
	toggleBackdrop:SetVertexColor(unpack(db.ButtonTextureColor))

	button.Texture = texture

	local frame = CreateFrame("Frame", nil, button)
	frame:Hide()
	frame:SetFrameLevel(button:GetFrameLevel() - 10)
	frame:SetPoint(unpack(db.RingFramePosition))
	frame:SetSize(unpack(db.RingFrameSize))
	frame:EnableMouse(true)
	frame:SetScript("OnEnter", RingFrame_OnEnter)
	frame:SetScript("OnLeave", RingFrame_OnLeave)

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

	frame.Bar = ring

	local bonus = LibSpinBar:CreateSpinBar(ns.Prefix.."StatusTrackingBar", frame)
	bonus:SetFrameLevel(frame:GetFrameLevel() + 1)
	bonus:SetPoint(unpack(db.RingPosition))
	bonus:SetSize(unpack(db.RingSize))
	bonus:SetSparkOffset(db.RingSparkOffset)
	bonus:SetSparkFlash(unpack(db.RingSparkFlash))
	bonus:SetSparkBlendMode("ADD")
	bonus:SetClockwise(true)
	bonus:SetDegreeOffset(db.RingDegreeOffset)
	bonus:SetDegreeSpan(db.RingDegreeSpan)

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
	perc:SetJustifyH(db.RingPercentJustify)
	perc:SetJustifyV(db.RingPercentJustify)
	perc:SetFontObject(db.RingPercentFont)
	perc:SetPoint(unpack(db.RingPercentPosition))

	ring.Percent = perc

	Bars[1] = bar
	Bars[2] = bonus

	ns:Fire("StatusTrackingBar_Created", Bars[1]:GetName())

end

StatusBars.UpdateBars = function(self, event, ...)
	if (not Bars) then
		return
	end
	local bar,bonus = Bars[1],Bars[2]
	local bonusShown = bonus:IsShown()

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
			bar:SetStatusBarColor(unpack(Colors[isFriend and "friendship" or "reaction"][standingID]))
			bar.currentType = "reputation"

			if (not isFriend) then
				standingLabel = GetText("FACTION_STANDING_LABEL"..standingID, gender)
			end

			bar.name = name
			bar.isFriend = isFriend
			bar.standingID, bar.standingLabel = standingID, standingLabel

			bar.Value:SetFormattedText("%.0f", (current-min)/(max-min))

			local nextStanding = standingID and _G["FACTION_STANDING_LABEL"..(standingID + 1)] and GetText("FACTION_STANDING_LABEL"..standingID + 1, gender)
			if (nextStanding) then
				bar.Description:SetFormattedText(L["to %s"], nextStanding)
			else
				bar.Description:SetText("")
			end

			bar:SetScript("OnEnter", Reputation_OnEnter)
			bar:SetScript("OnLeave", Reputation_OnLeave)
			bar:SetMouseClickEnabled(false)
			bar:Show()

		else
			-- this can happen?
			bar:SetScript("OnEnter", nil)
			bar:SetScript("OnLeave", nil)
			bar:SetMouseClickEnabled(false)
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
			bar:SetScript("OnEnter", nil)
			bar:SetScript("OnLeave", nil)
			bar:SetMouseClickEnabled(false)
			bar.Value:SetText("")
			bar.Description:SetText("")
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

			bar:SetMinMaxValues(0, max, forced)
			bar:SetValue(min, forced)
			bar:SetStatusBarColor(unpack(Colors[restedLeft and "rested" or "xp"]))
			bar.currentType = "xp"

			if (restedLeft) then
				bonus:SetMinMaxValues(0, max, not bonusShown)
				bonus:SetValue(math_min(max, min + (restedLeft or 0)), not bonusShown)
				if (not bonusShown) then
					bonus:Show()
				end
			elseif (bonusShown) then
				bonus:Hide()
				bonus:SetValue(0, true)
				bonus:SetMinMaxValues(0, 1, true)
			end

			bar.Value:SetFormattedText("%.0f", (max-min)/max)
			bar.Description:SetFormattedText(L["to level %s"], playerLevel + 1)

			bar:SetScript("OnEnter", XP_OnEnter)
			bar:SetScript("OnLeave", XP_OnLeave)
			bar:SetMouseClickEnabled(false)
			bar:Show()
		end
	end

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