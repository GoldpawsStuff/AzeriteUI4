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

-- Doing this. We don't want tutorials, at all.
--NPE_LoadUI = function() end
--NPE_CheckTutorials = function() end

-- Global hider frame
local UIHider = ns.Hider

-- Utility
---------------------------------------------------------
-- Wrapper to avoid bugs
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

-- Callbacks
---------------------------------------------------------
BlizzKill.HandleActionBar = function(self, frame, clearEvents, reanchor, noAnchorChanges)
	if (frame) then
		if (clearEvents) then
			frame:UnregisterAllEvents()
		end
		frame:Hide()
		frame:SetParent(UIHider)

		-- Setup faux anchors so the frame position data returns valid
		if (reanchor) and (not noAnchorChanges) then
			local left, right, top, bottom = frame:GetLeft(), frame:GetRight(), frame:GetTop(), frame:GetBottom()
			frame:ClearAllPoints()
			if (left) and (right) and (top) and (bottom) then
				frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
				frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMLEFT", right, bottom)
			else
				frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", 10, 10)
				frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMLEFT", 20, 20)
			end
		elseif (not noAnchorChanges) then
			frame:ClearAllPoints()
		end
	end
end

BlizzKill.HandleFrame = function(self, frame)
	if (not frame) then
		return
	end
	if (frame) then
		frame:UnregisterAllEvents()
		frame:SetParent(UIHider)
	else
		frame.Show = frame.Hide
	end
	frame:Hide()
end

-- Removes a frame from the Dragonflight layout system
BlizzKill.HandleManagedFrame = function(self, frame)
	if (frame and frame.layoutParent) then
		frame:SetScript("OnShow", nil) -- prevents the frame from being added
		frame:OnHide() -- calls the script to remove the frame
		-- The following is called by the method above,
		-- with a little luck, this will be true for all managed frames.
		--frame.layoutParent:RemoveManagedFrame(frame)
	end
end

BlizzKill.HandleMenuOption = function(self, option_shrink, option_name)
	local option = _G[option_name]
	if not(option) or not(option.IsObjectType) or not(option:IsObjectType("Frame")) then
		return
	end
	option:SetParent(UIHider)
	if (option.UnregisterAllEvents) then
		option:UnregisterAllEvents()
	end
	if (option_shrink) then
		option:SetHeight(0.00001)
		-- Needed for the options to shrink properly.
		-- Will mess up alignment for indented options,
		-- so only use this when the following options is
		-- horizontally aligned with the removed one.
		if (option_shrink == true) then
			option:SetScale(0.00001)
		end
	end
	option.cvar = ""
	option.uvar = ""
	option.value = nil
	option.oldValue = nil
	option.defaultValue = nil
	option.setFunc = function() end
end

BlizzKill.HandleMenuPage = function(self, panel_id, panel_name)
	local button,window
	-- remove an entire blizzard options panel,
	-- and disable its automatic cancel/okay functionality
	-- this is needed, or the option will be reset when the menu closes
	-- it is also a major source of taint related to the Compact group frames!
	if (panel_id) then
		local category = _G["InterfaceOptionsFrameCategoriesButton" .. panel_id]
		if (category and category.SetScale) then
			category:SetScale(0.00001)
			category:SetAlpha(0)
			button = true
		end
	end
	if (panel_name) then
		local panel = _G[panel_name]
		if (panel) then
			panel:SetParent(UIHider)
			if (panel.UnregisterAllEvents) then
				panel:UnregisterAllEvents()
			end
			panel.cancel = function() end
			panel.okay = function() end
			panel.refresh = function() end
			window = true
		end
	end
	-- By removing the menu panels above we're preventing the blizzard UI from calling it,
	-- and for some reason it is required to be called at least once,
	-- or the game won't fire off the events that tell the UI that the player has an active pet out.
	-- In other words: without it both the pet bar and pet unitframe will fail after a /reload
	if (panel_id == 5) or (panel_name == "InterfaceOptionsActionBarsPanel") then
		if (SetActionBarToggles) then
			SetActionBarToggles(nil, nil, nil, nil, nil)
		end
	end
end

BlizzKill.HandleTooltip = function(self, method, tooltip)
	if (method == "OnTooltipSetUnit") then
		if (tooltip.IsForbidden) and (tooltip:IsForbidden()) then
			return
		end
		return tooltip:Hide()
	end
end

BlizzKill.HandleUnitFrame = function(self, baseName, doNotReparent)
	local frame
	if (type(baseName) == "string") then
		frame = _G[baseName]
	else
		frame = baseName
	end
	if (frame) then
		frame:UnregisterAllEvents()
		frame:Hide()

		if (not doNotReparent) then
			frame:SetParent(hiddenParent)
		end

		local health = frame.healthBar or frame.healthbar
		if (health) then
			health:UnregisterAllEvents()
		end

		local power = frame.manabar
		if (power) then
			power:UnregisterAllEvents()
		end

		local spell = frame.castBar or frame.spellbar
		if (spell) then
			spell:UnregisterAllEvents()
		end

		local altpowerbar = frame.powerBarAlt
		if (altpowerbar) then
			altpowerbar:UnregisterAllEvents()
		end

		local buffFrame = frame.BuffFrame
		if (buffFrame) then
			buffFrame:UnregisterAllEvents()
		end
	end
end

BlizzKill.NPE_LoadUI = function(self)
	if not (Tutorials and Tutorials.AddSpellToActionBar) then return end

	-- Action Bar drag tutorials
	Tutorials.AddSpellToActionBar:Disable()
	Tutorials.AddClassSpellToActionBar:Disable()

	-- these tutorials rely on finding valid action bar buttons, and error otherwise
	Tutorials.Intro_CombatTactics:Disable()

	-- enable spell pushing because the drag tutorial is turned off
	Tutorials.AutoPushSpellWatcher:Complete()
end

-- Kill
---------------------------------------------------------
BlizzKill.KillActionBars = function(self)

	-- Dragonflight
	if (ns.WoW10) then

		self:HandleActionBar(MultiBarBottomLeft, true)
		self:HandleActionBar(MultiBarBottomRight, true)
		self:HandleActionBar(MultiBarLeft, true)
		self:HandleActionBar(MultiBarRight, true)

		-- Hide MultiBar Buttons, but keep the bars alive
		for i=1,12 do
			_G["ActionButton" .. i]:Hide()
			_G["ActionButton" .. i]:UnregisterAllEvents()
			_G["ActionButton" .. i]:SetAttribute("statehidden", true)

			_G["MultiBarBottomLeftButton" .. i]:Hide()
			_G["MultiBarBottomLeftButton" .. i]:UnregisterAllEvents()
			_G["MultiBarBottomLeftButton" .. i]:SetAttribute("statehidden", true)

			_G["MultiBarBottomRightButton" .. i]:Hide()
			_G["MultiBarBottomRightButton" .. i]:UnregisterAllEvents()
			_G["MultiBarBottomRightButton" .. i]:SetAttribute("statehidden", true)

			_G["MultiBarRightButton" .. i]:Hide()
			_G["MultiBarRightButton" .. i]:UnregisterAllEvents()
			_G["MultiBarRightButton" .. i]:SetAttribute("statehidden", true)

			_G["MultiBarLeftButton" .. i]:Hide()
			_G["MultiBarLeftButton" .. i]:UnregisterAllEvents()
			_G["MultiBarLeftButton" .. i]:SetAttribute("statehidden", true)
		end

		--MainMenuBar:UnregisterAllEvents()
		MainMenuBar:SetParent(UIHider)
		MainMenuBar:Hide()
		--MainMenuBar:EnableMouse(false)

		self:HandleActionBar(MicroButtonAndBagsBar, false, false, true)
		self:HandleActionBar(StanceBar, true)
		self:HandleActionBar(PossessActionBar, true)
		self:HandleActionBar(MultiCastActionBarFrame, false, false, true)
		self:HandleActionBar(PetActionBar, true)
		self:HandleActionBar(StatusTrackingBarManager, false)

		if (IsAddOnLoaded("Blizzard_NewPlayerExperience")) then
			self:NPE_LoadUI()
		elseif (NPE_LoadUI ~= nil) then
			self:SecureHook("NPE_LoadUI")
		end
	end

	-- Shadowlands, Wrath, Vanilla
	if (not ns.WoW10) then

		MultiBarBottomLeft:SetParent(UIHider)
		MultiBarBottomRight:SetParent(UIHider)
		MultiBarLeft:SetParent(UIHider)
		MultiBarRight:SetParent(UIHider)

		-- Hide MultiBar Buttons, but keep the bars alive
		for i=1,12 do
			_G["ActionButton" .. i]:Hide()
			_G["ActionButton" .. i]:UnregisterAllEvents()
			_G["ActionButton" .. i]:SetAttribute("statehidden", true)

			_G["MultiBarBottomLeftButton" .. i]:Hide()
			_G["MultiBarBottomLeftButton" .. i]:UnregisterAllEvents()
			_G["MultiBarBottomLeftButton" .. i]:SetAttribute("statehidden", true)

			_G["MultiBarBottomRightButton" .. i]:Hide()
			_G["MultiBarBottomRightButton" .. i]:UnregisterAllEvents()
			_G["MultiBarBottomRightButton" .. i]:SetAttribute("statehidden", true)

			_G["MultiBarRightButton" .. i]:Hide()
			_G["MultiBarRightButton" .. i]:UnregisterAllEvents()
			_G["MultiBarRightButton" .. i]:SetAttribute("statehidden", true)

			_G["MultiBarLeftButton" .. i]:Hide()
			_G["MultiBarLeftButton" .. i]:UnregisterAllEvents()
			_G["MultiBarLeftButton" .. i]:SetAttribute("statehidden", true)
		end
		UIPARENT_MANAGED_FRAME_POSITIONS["MainMenuBar"] = nil
		UIPARENT_MANAGED_FRAME_POSITIONS["StanceBarFrame"] = nil
		UIPARENT_MANAGED_FRAME_POSITIONS["PossessBarFrame"] = nil
		UIPARENT_MANAGED_FRAME_POSITIONS["MultiCastActionBarFrame"] = nil
		UIPARENT_MANAGED_FRAME_POSITIONS["PETACTIONBAR_YPOS"] = nil
		UIPARENT_MANAGED_FRAME_POSITIONS["ExtraAbilityContainer"] = nil

		--MainMenuBar:UnregisterAllEvents()
		--MainMenuBar:SetParent(UIHider)
		--MainMenuBar:Hide()
		MainMenuBar:EnableMouse(false)
		MainMenuBar:UnregisterEvent("DISPLAY_SIZE_CHANGED")
		MainMenuBar:UnregisterEvent("UI_SCALE_CHANGED")

		local animations = {MainMenuBar.slideOut:GetAnimations()}
		animations[1]:SetOffset(0,0)

		if (OverrideActionBar) then -- classic doesn't have this
			animations = {OverrideActionBar.slideOut:GetAnimations()}
			animations[1]:SetOffset(0,0)
		end

		self:HandleActionBar(MainMenuBarArtFrame, false, true)
		self:HandleActionBar(MainMenuBarArtFrameBackground)
		self:HandleActionBar(MicroButtonAndBagsBar, false, false, true)

		if StatusTrackingBarManager then
			StatusTrackingBarManager:Hide()
			--StatusTrackingBarManager:SetParent(UIHider)
		end

		self:HandleActionBar(StanceBarFrame, true, true)
		self:HandleActionBar(PossessBarFrame, false, true)
		self:HandleActionBar(MultiCastActionBarFrame, false, false, true)
		self:HandleActionBar(PetActionBarFrame, true, true)
		self:HandleActionBar(OverrideActionBar, true)
		ShowPetActionBar = function() end

		--BonusActionBarFrame:UnregisterAllEvents()
		--BonusActionBarFrame:Hide()
		--BonusActionBarFrame:SetParent(UIHider)

		if (not ns.IsClassic) then
			if (PlayerTalentFrame) then
				PlayerTalentFrame:UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
			else
				hooksecurefunc("TalentFrame_LoadUI", function() PlayerTalentFrame:UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED") end)
			end
		end

		self:HandleActionBar(MainMenuBarVehicleLeaveButton, true)
		self:HandleActionBar(MainMenuBarPerformanceBarFrame, false, false, true)
		self:HandleActionBar(MainMenuExpBar, false, false, true)
		self:HandleActionBar(ReputationWatchBar, false, false, true)
		self:HandleActionBar(MainMenuBarMaxLevelBar, false, false, true)

		if (IsAddOnLoaded("Blizzard_NewPlayerExperience")) then
			self:NPE_LoadUI()
		elseif (NPE_LoadUI ~= nil) then
			self:SecureHook("NPE_LoadUI")
		end

		-- Attempt to hook the bag bar to the bags
		-- Retrieve the first slot button and the backpack
		local backpack = ContainerFrame1
		local firstSlot = CharacterBag0Slot
		local reagentSlot = CharacterReagentBag0Slot

		-- Try to avoid the potential error with Shadowlands anima deposit animations.
		-- Just give it a simplified version of the default position it is given,
		-- it will be replaced by UpdateContainerFrameAnchors() later on anyway.
		if (not backpack:GetPoint()) then
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

	-- Disable annoying yellow popup alerts.
	if (MainMenuMicroButton_ShowAlert) then
		local HideAlerts = function()
			if (HelpTip) then
				HelpTip:HideAllSystem("MicroButtons")
			end
		end
		hooksecurefunc("MainMenuMicroButton_ShowAlert", HideAlerts)
	end

end

BlizzKill.KillChatFrames = function(self, event, ...)
	-- If no event was fired, we assume this is the initial call,
	-- and thus we register the relevant events and bail out.
	if (not event) then
		self:RegisterEvent("VARIABLES_LOADED", "KillChatFrames")
		self:RegisterEvent("PLAYER_ENTERING_WORLD", "KillChatFrames")
		return
	else
		local shouldSet
		self:UnregisterEvent(event, "KillChatFrames")
		if (event == "VARIABLES_LOADED") then
			-- This is when CVars and Keybinds are loaded,
			-- but it can occur before our ADDON_LOADED event, thus not being registered,
			-- or even after the PLAYER_ENTERING_WORLD event, overwriting anything we did there.
			-- So we need it both places.
			if (not self.isVariablesLoaded) then
				self.isVariablesLoaded = true
				shouldSet = true
			end
		elseif (event == "PLAYER_ENTERING_WORLD") then
			-- We need this, since VARIABLES_LOADED might have fired before our init events.
			if (not self.hasEnteredWorld) then
				self.hasEnteredWorld = true
				shouldSet = true
			end
		end
		if (shouldSet) then
			SetCVar("showToastBroadcast", "0")
			SetCVar("showToastConversation", "0")
			SetCVar("showToastFriendRequest", "0")
			SetCVar("showToastOffline", "0")
			SetCVar("showToastOnline", "0")
			SetCVar("showToastWindow", "0")
		end
	end

	local UIHider = UIHider
	for _,frameName in pairs(CHAT_FRAMES) do
		local frame = _G[frameName]
		if (frame) then
			frame:SetParent(UIHider)

			for _,elementName in next,{
				"ButtonFrame",
				"EditBox",
				"ClickAnywhereButton",
				"ButtonFrameMinimizeButton"
			} do
				local element = _G[frameName..elementName]
				if (element and element.SetParent) then
					element:SetParent(UIHider)
				end
			end

		end
	end
	if (GeneralDockManager and GeneralDockManager.SetParent) then
		GeneralDockManager:SetParent(UIHider)
	end

	self:HandleFrame(ChatFrameMenuButton)
	self:HandleFrame(ChatFrameChannelButton)
	self:HandleFrame(ChatFrameToggleVoiceDeafenButton)
	self:HandleFrame(ChatFrameToggleVoiceMuteButton)
	self:HandleFrame(GetChatWindowFriendsButton)
	self:HandleFrame(ChatFrameMenuButton)

	-- This was called FriendsMicroButton pre-Legion.
	-- *Note that the classics are using this new name.
	if (QuickJoinToastButton) then
		local killQuickToast = function(self, event, ...)
			QuickJoinToastButton:UnregisterAllEvents()
			QuickJoinToastButton:Hide()
			QuickJoinToastButton:SetAlpha(0)
			QuickJoinToastButton:EnableMouse(false)
			QuickJoinToastButton:SetParent(UIHider)
		end
		killQuickToast()

		-- This pops back up on zoning sometimes, so keep removing it
		self:RegisterEvent("PLAYER_ENTERING_WORLD", killQuickToast)
	end

end

BlizzKill.KillFloaters = function(self)
	local UIHider = UIHider

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
	if (CastingBarFrame) then
		self:HandleManagedFrame(CastingBarFrame)
		CastingBarFrame:SetScript("OnEvent", nil)
		CastingBarFrame:SetScript("OnUpdate", nil)
		CastingBarFrame:SetParent(UIHider)
		CastingBarFrame:UnregisterAllEvents()
	end

	-- Player's pet's castbar
	if (PetCastingBarFrame) then
		PetCastingBarFrame:SetScript("OnEvent", nil)
		PetCastingBarFrame:SetScript("OnUpdate", nil)
		PetCastingBarFrame:SetParent(UIHider)
		PetCastingBarFrame:UnregisterAllEvents()
	end

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

	if (PlayerPowerBarAlt) then
		self:HandleManagedFrame(PlayerPowerBarAlt)
		PlayerPowerBarAlt.ignoreFramePositionManager = true
		PlayerPowerBarAlt:UnregisterAllEvents()
		PlayerPowerBarAlt:SetParent(UIHider)
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

	if (TutorialFrame) then
		TutorialFrame:UnregisterAllEvents()
		TutorialFrame:Hide()
		TutorialFrame.Show = TutorialFrame.Hide
	end

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

BlizzKill.KillMenuOptions = function(self)
	if (ns.WoW10) then
		return
	end
	self:HandleMenuPage(5, "InterfaceOptionsActionBarsPanel")
	self:HandleMenuOption((not ns.IsWrath), "InterfaceOptionsCombatPanelTargetOfTarget")
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
		if (not bar) then
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

	self:KillActionBars()
	self:KillFloaters()
	self:KillTimerBars()
	self:KillTimeManager()
	self:KillTutorials()
	self:KillNPE()
	self:KillHelpTip()
	self:KillMenuOptions()

end
