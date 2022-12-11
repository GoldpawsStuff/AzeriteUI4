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
local BlizzKill = ns:NewModule("BlizzKill", "LibMoreEvents-1.0", "AceHook-3.0")

-- Lua API
local ipairs = ipairs
local pairs = pairs
local string_format = string.format

-- WoW API
local C_Timer_After = C_Timer.After
local GetCVarDefault = GetCVarDefault
local GetCVarInfo = GetCVarInfo
local hooksecurefunc = hooksecurefunc
local IsAddOnLoaded = IsAddOnLoaded
local SetActionBarToggles = SetActionBarToggles

-- WoW Globals
local CHAT_FRAMES = CHAT_FRAMES

-- Addon API
local IsAddOnEnabled = ns.API.IsAddOnEnabled
local KillEditMode = ns.API.KillEditMode
local UIHider = ns.Hider
local noop = ns.Noop

-- Utility
---------------------------------------------------------
local SetCVar = function(name, value)
	local oldValue, defaultValue, account, character, param5, setcvaronly, readonly = GetCVarInfo(name)
	if (oldValue == nil) or (oldValue == value) then
		return
	end
	if (value == nil) then
		_G.SetCVar(name, GetCVarDefault(name))
	else
		_G.SetCVar(name, value)
	end
end

BlizzKill.HookBagButtons = function(self)
	if (IsAddOnEnabled("Bagnon") or IsAddOnEnabled("ArkInventory")) then
		return
	end

	-- Attempt to hook the bag bar to the bags
	-- Retrieve the first slot button and the backpack
	local backpack = ContainerFrame1
	local firstSlot = CharacterBag0Slot
	local reagentSlot = CharacterReagentBag0Slot

	-- Try to avoid the potential error with Shadowlands anima deposit animations.
	-- Just give it a simplified version of the default position it is given,
	-- it will be replaced by UpdateContainerFrameAnchors() later on anyway.
	if (backpack and not backpack:GetPoint()) then
		backpack:SetPoint("BOTTOMRIGHT", backpack:GetParent(), "BOTTOMRIGHT", -14, 93 )
	end

	-- These should always exist, but Blizz do have a way of changing things,
	-- and I prefer having functionality not be applied in a future update
	-- rather than having the UI break from nil bugs.
	if (firstSlot and backpack) then
		firstSlot:ClearAllPoints()
		firstSlot:SetPoint("TOPRIGHT", backpack, "BOTTOMRIGHT", -6, 0)

		local strata = backpack:GetFrameStrata()
		local level = backpack:GetFrameLevel()

		-- Rearrange slots
		-- *Dragonflight features a reagent bag slot
		local slotSize = reagentSlot and 24 or 30
		local previous
		for _,slotName in ipairs({
			"CharacterBag0Slot",
			"CharacterBag1Slot",
			"CharacterBag2Slot",
			"CharacterBag3Slot",
			"CharacterReagentBag0Slot"
		}) do

			-- Always check for existence,
			-- because nothing is ever guaranteed.
			local slot = _G[slotName]
			if (slot) then
				slot:SetParent(backpack)
				slot:SetSize(slotSize,slotSize)
				slot:SetFrameStrata(strata)
				slot:SetFrameLevel(level)
				if (slot.SetBarExpanded) then
					slot.SetBarExpanded = noop
				end

				-- Remove that fugly outer border
				local tex = _G[slotName.."NormalTexture"]
				if (tex) then
					tex:SetTexture("")
					tex:SetAlpha(0)
				end

				-- Re-anchor the slots to remove space
				if (not previous) then
					slot:ClearAllPoints()
					slot:SetPoint("TOPRIGHT", backpack, "BOTTOMRIGHT", -6, 4)
				else
					slot:ClearAllPoints()
					slot:SetPoint("RIGHT", previous, "LEFT", 0, 0)
				end

				previous = slot
			end
		end

		local keyring = KeyRingButton
		if (keyring) then
			keyring:SetParent(backpack)
			keyring:SetHeight(slotSize)
			keyring:SetFrameStrata(strata)
			keyring:SetFrameLevel(level)
			keyring:ClearAllPoints()
			keyring:SetPoint("RIGHT", previous, "LEFT", 0, 0)
			previous = keyring
		end
	end

end

BlizzKill.KillFloaters = function(self)

	if (AlertFrame) then
		AlertFrame:UnregisterAllEvents()
		AlertFrame:SetScript("OnEvent", nil)
		AlertFrame:SetParent(UIHider)
	end

	-- Regular minimap buffs and debuffs.
	if (BuffFrame) then
		BuffFrame:SetScript("OnLoad", nil)
		BuffFrame:SetScript("OnUpdate", nil)
		BuffFrame:SetScript("OnEvent", nil)
		BuffFrame:SetParent(UIHider)
		BuffFrame:UnregisterAllEvents()

		if (TemporaryEnchantFrame) then
			TemporaryEnchantFrame:SetScript("OnUpdate", nil)
			TemporaryEnchantFrame:SetParent(UIHider)
		end

		if (DebuffFrame) then
			DebuffFrame:SetScript("OnLoad", nil)
			DebuffFrame:SetScript("OnUpdate", nil)
			DebuffFrame:SetScript("OnEvent", nil)
			DebuffFrame:SetParent(UIHider)
			DebuffFrame:UnregisterAllEvents()
		end
	end

	-- Some shadowlands crap, possibly BfA.
	if (PlayerBuffTimerManager) then
		PlayerBuffTimerManager:SetParent(UIHider)
		PlayerBuffTimerManager:SetScript("OnEvent", nil)
		PlayerBuffTimerManager:UnregisterAllEvents()
	end

	-- Player's castbar
	--if (CastingBarFrame) then
	--	CastingBarFrame:SetScript("OnEvent", nil)
	--	CastingBarFrame:SetScript("OnUpdate", nil)
	--	CastingBarFrame:SetParent(UIHider)
	--	CastingBarFrame:UnregisterAllEvents()
	--end

	-- Player's pet's castbar
	--if (PetCastingBarFrame) then
	--	PetCastingBarFrame:SetScript("OnEvent", nil)
	--	PetCastingBarFrame:SetScript("OnUpdate", nil)
	--	PetCastingBarFrame:SetParent(UIHider)
	--	PetCastingBarFrame:UnregisterAllEvents()
	--end

	if (DurabilityFrame) then
		DurabilityFrame:UnregisterAllEvents()
		DurabilityFrame:SetScript("OnShow", nil)
		DurabilityFrame:SetScript("OnHide", nil)

		-- Prevent the durability frame size affecting other anchors
		DurabilityFrame:SetParent(UIHider)
		DurabilityFrame:Hide()
		DurabilityFrame.IsShown = function() return false end
	end

	if (LevelUpDisplay) then
		LevelUpDisplay:SetScript("OnEvent", nil)
		LevelUpDisplay:UnregisterAllEvents()
		LevelUpDisplay:StopBanner()
		LevelUpDisplay:SetParent(UIHider)
	end

	if (BossBanner) then
		if (BossBanner_Stop) then
			BossBanner_Stop(BossBanner)
		end
		--BossBanner.PlayBanner = nil
		--BossBanner.StopBanner = nil
		BossBanner:UnregisterAllEvents()
		BossBanner:SetScript("OnEvent", nil)
		BossBanner:SetScript("OnUpdate", nil)
		BossBanner:SetParent(UIHider)
	end

	if (QuestTimerFrame) then
		QuestTimerFrame:SetScript("OnLoad", nil)
		QuestTimerFrame:SetScript("OnEvent", nil)
		QuestTimerFrame:SetScript("OnUpdate", nil)
		QuestTimerFrame:SetScript("OnShow", nil)
		QuestTimerFrame:SetScript("OnHide", nil)
		QuestTimerFrame:SetParent(UIHider)
		QuestTimerFrame:Hide()
		QuestTimerFrame.numTimers = 0
		QuestTimerFrame.updating = nil
		for i = 1,MAX_QUESTS do
			_G["QuestTimer"..i]:Hide()
		end
	end

	--if (RaidBossEmoteFrame) then
	--	RaidBossEmoteFrame:SetParent(UIHider)
	--	RaidBossEmoteFrame:Hide()
	--end

	--if (RaidWarningFrame) then
	--	RaidWarningFrame:SetParent(UIHider)
	--	RaidWarningFrame:Hide()
	--end

	if (TotemFrame) then
		TotemFrame:UnregisterAllEvents()
		TotemFrame:SetScript("OnEvent", nil)
		TotemFrame:SetScript("OnShow", nil)
		TotemFrame:SetScript("OnHide", nil)
	end

	--if (TutorialFrame) then
	--	TutorialFrame:UnregisterAllEvents()
	--	TutorialFrame:Hide()
	--	TutorialFrame.Show = TutorialFrame.Hide
	--end

	if (ZoneTextFrame) then
		ZoneTextFrame:SetParent(UIHider)
		ZoneTextFrame:UnregisterAllEvents()
		ZoneTextFrame:SetScript("OnUpdate", nil)
		-- ZoneTextFrame:Hide()
	end

	if (SubZoneTextFrame) then
		SubZoneTextFrame:SetParent(UIHider)
		SubZoneTextFrame:UnregisterAllEvents()
		SubZoneTextFrame:SetScript("OnUpdate", nil)
		-- SubZoneTextFrame:Hide()
	end

	if (AutoFollowStatus) then
		AutoFollowStatus:SetParent(UIHider)
		AutoFollowStatus:UnregisterAllEvents()
		AutoFollowStatus:SetScript("OnUpdate", nil)
	end

end

BlizzKill.KillTimerBars = function(self, event, ...)
	local UIHider = UIHider
	if (event == "ADDON_LOADED") then
		local addon = ...
		if (addon == "Blizzard_UIWidgets") then
			self:UnregisterEvent("ADDON_LOADED", "KillTimerBars")
			UIWidgetPowerBarContainerFrame:SetParent(UIHider)
		end
		return
	end

	for i = 1,MIRRORTIMER_NUMTIMERS do
		local timer = _G["MirrorTimer"..i]
		if (timer) then
			timer:SetScript("OnEvent", nil)
			timer:SetScript("OnUpdate", nil)
			timer:SetParent(UIHider)
			timer:UnregisterAllEvents()
		end
	end

	if (TimerTracker) then
		TimerTracker:SetScript("OnEvent", nil)
		TimerTracker:SetScript("OnUpdate", nil)
		TimerTracker:UnregisterAllEvents()
		if (TimerTracker.timerList) then
			for _, bar in pairs(TimerTracker.timerList) do
				if (bar) then
					bar:SetScript("OnEvent", nil)
					bar:SetScript("OnUpdate", nil)
					bar:SetParent(UIHider)
					bar:UnregisterAllEvents()
				end
			end
		end
	end

	if (ns.IsRetail) then
		local bar = UIWidgetPowerBarContainerFrame
		if (bar) then
			bar:SetParent(UIHider)
		else
			return self:RegisterEvent("ADDON_LOADED", "KillTimerBars")
		end
	end
end

BlizzKill.KillTimeManager = function(self, event, ...)
	local TM = _G.TimeManagerClockButton
	if (TM) then
		if (event) then
			self:UnregisterEvent(event, "KillTimeManager")
		end
		if (TM) then
			TM:SetParent(UIHider)
			TM:UnregisterAllEvents()
		end
	else
		self:RegisterEvent("ADDON_LOADED", "KillTimeManager")
	end
end

BlizzKill.KillTutorials = function(self, event, ...)
	if (not event) then
		SetCVar("showTutorials", "0")
		self:RegisterEvent("VARIABLES_LOADED", "KillTutorials")
		self:RegisterEvent("PLAYER_ENTERING_WORLD", "KillTutorials")
		return
	else
		if (event == "VARIABLES_LOADED") then
			self:UnregisterEvent(event, "KillTutorials")
			SetCVar("showTutorials", "0")
		elseif (event == "PLAYER_ENTERING_WORLD") then
			SetCVar("showTutorials", "0")
		end
	end
end

BlizzKill.KillNPE = function(self, event, ...)
	local NPE = _G.NewPlayerExperience
	if (NPE) then
		if (event) then
			self:UnregisterEvent(event, "KillNPE")
		end
		if (NPE.GetIsActive and NPE:GetIsActive()) then
			if (NPE.Shutdown) then
				NPE:Shutdown()
			end
		end
	else
		self:RegisterEvent("ADDON_LOADED", "KillNPE")
	end
end

BlizzKill.KillHelpTip = function(self)
	local HelpTip = _G.HelpTip
	if (HelpTip) then
		local AcknowledgeTips = function()
			if (_G.HelpTip.framePool and _G.HelpTip.framePool.EnumerateActive) then
				for frame in _G.HelpTip.framePool:EnumerateActive() do
					if (frame.Acknowledge) then
						frame:Acknowledge()
					end
				end
			end
		end
		hooksecurefunc(_G.HelpTip, "Show", AcknowledgeTips)
		C_Timer_After(1, AcknowledgeTips)
	end
end

BlizzKill.OnInitialize = function(self)
	self:HookBagButtons()
	self:KillFloaters()
	self:KillTimerBars()
	self:KillTimeManager()
	self:KillTutorials()
	self:KillNPE()
	self:KillHelpTip()
end
