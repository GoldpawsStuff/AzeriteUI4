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
local Clutter = ns:NewModule("Clutter", "LibMoreEvents-1.0")

-- Lua API
local _G = _G

-- WoW API
local CreateFrame = CreateFrame
local GetCVarBool = GetCVarBool
local hooksecurefunc = hooksecurefunc
local PlaySoundKitID = PlaySound -- or PlaySoundKitID
local PlayVocalErrorSoundID = PlayVocalErrorSoundID
local UnitExists = UnitExists

-- Addon API
local GetFont = ns.API.GetFont
local SetObjectScale = ns.API.SetObjectScale

-- We're not curretnly using a blacklist for on-screen messages,
-- leaving it here for referece though, as I might need it later.
local blackList = {
	msgTypes = {
		[LE_GAME_ERR_ABILITY_COOLDOWN] = true,
		[LE_GAME_ERR_SPELL_COOLDOWN] = true,
		[LE_GAME_ERR_SPELL_FAILED_ANOTHER_IN_PROGRESS] = true,
		[LE_GAME_ERR_OUT_OF_SOUL_SHARDS] = true,
		[LE_GAME_ERR_OUT_OF_FOCUS] = true,
		[LE_GAME_ERR_OUT_OF_COMBO_POINTS] = true,
		[LE_GAME_ERR_OUT_OF_HEALTH] = true,
		[LE_GAME_ERR_OUT_OF_RAGE] = true,
		[LE_GAME_ERR_OUT_OF_RANGE] = true,
		[LE_GAME_ERR_OUT_OF_ENERGY] = true
	},
	[ ERR_ABILITY_COOLDOWN ] = true, 						-- Ability is not ready yet.
	[ ERR_ATTACK_CHARMED ] = true, 							-- Can't attack while charmed.
	[ ERR_ATTACK_CONFUSED ] = true, 						-- Can't attack while confused.
	[ ERR_ATTACK_DEAD ] = true, 							-- Can't attack while dead.
	[ ERR_ATTACK_FLEEING ] = true, 							-- Can't attack while fleeing.
	[ ERR_ATTACK_PACIFIED ] = true, 						-- Can't attack while pacified.
	[ ERR_ATTACK_STUNNED ] = true, 							-- Can't attack while stunned.
	[ ERR_AUTOFOLLOW_TOO_FAR ] = true, 						-- Target is too far away.
	[ ERR_BADATTACKFACING ] = true, 						-- You are facing the wrong way!
	[ ERR_BADATTACKPOS ] = true, 							-- You are too far away!
	[ ERR_CLIENT_LOCKED_OUT ] = true, 						-- You can't do that right now.
	[ ERR_ITEM_COOLDOWN ] = true, 							-- Item is not ready yet.
	[ ERR_OUT_OF_ENERGY ] = true, 							-- Not enough energy
	[ ERR_OUT_OF_FOCUS ] = true, 							-- Not enough focus
	[ ERR_OUT_OF_HEALTH ] = true, 							-- Not enough health
	[ ERR_OUT_OF_MANA ] = true, 							-- Not enough mana
	[ ERR_OUT_OF_RAGE ] = true, 							-- Not enough rage
	[ ERR_OUT_OF_RANGE ] = true, 							-- Out of range.
	[ ERR_SPELL_COOLDOWN ] = true, 							-- Spell is not ready yet.
	[ ERR_SPELL_FAILED_ALREADY_AT_FULL_HEALTH ] = true, 	-- You are already at full health.
	[ ERR_SPELL_OUT_OF_RANGE ] = true, 						-- Out of range.
	[ ERR_USE_TOO_FAR ] = true, 							-- You are too far away.
	[ SPELL_FAILED_CANT_DO_THAT_RIGHT_NOW ] = true, 		-- You can't do that right now.
	[ SPELL_FAILED_CASTER_AURASTATE ] = true, 				-- You can't do that yet
	[ SPELL_FAILED_CASTER_DEAD ] = true, 					-- You are dead
	[ SPELL_FAILED_CASTER_DEAD_FEMALE ] = true, 			-- You are dead
	[ SPELL_FAILED_CHARMED ] = true, 						-- Can't do that while charmed
	[ SPELL_FAILED_CONFUSED ] = true, 						-- Can't do that while confused
	[ SPELL_FAILED_FLEEING ] = true, 						-- Can't do that while fleeing
	[ SPELL_FAILED_ITEM_NOT_READY ] = true, 				-- Item is not ready yet
	[ SPELL_FAILED_NO_COMBO_POINTS ] = true, 				-- That ability requires combo points
	[ SPELL_FAILED_NOT_BEHIND ] = true, 					-- You must be behind your target.
	[ SPELL_FAILED_NOT_INFRONT ] = true, 					-- You must be in front of your target.
	[ SPELL_FAILED_OUT_OF_RANGE ] = true, 					-- Out of range
	[ SPELL_FAILED_PACIFIED ] = true, 						-- Can't use that ability while pacified
	[ SPELL_FAILED_SPELL_IN_PROGRESS ] = true, 				-- Another action is in progress
	[ SPELL_FAILED_STUNNED ] = true, 						-- Can't do that while stunned
	[ SPELL_FAILED_UNIT_NOT_INFRONT ] = true, 				-- Target needs to be in front of you.
	[ SPELL_FAILED_UNIT_NOT_BEHIND ] = true, 				-- Target needs to be behind you.
}

-- API workaround. Copied from AzeriteUI.
local PlayVocalErrorByMessageType = function(messageType)
	local errorStringId, soundKitID, voiceID = GetGameMessageInfo(messageType)
	if (voiceID) then
		-- No idea what channel this ends up in.
		-- *Edit: Seems to be Dialog by default for this one.
		PlayVocalErrorSoundID(voiceID)
	elseif (soundKitID) then
		-- Blizzard sends this to the Master channel. We won't.
		PlaySoundKitID(soundKitID, "Dialog")
	end
end

Clutter.HandleTopCenterWidgets = function(self)
	local container = _G.UIWidgetTopCenterContainerFrame
	if (not container) then
		return
	end

	local db = ns.Config.Clutter

	local scaffold = SetObjectScale(CreateFrame("Frame", ns.Prefix.."TopCenterWidgets", UIParent), 14/12)
	scaffold:SetFrameStrata("BACKGROUND")
	scaffold:SetFrameLevel(10)
	scaffold:SetPoint(unpack(db.TopCenterWidgetsPosition))
	scaffold:SetSize(10,58)

	container:SetParent(scaffold)
	container:SetFrameStrata("BACKGROUND")
	container:ClearAllPoints()
	container:SetPoint("TOP", scaffold)

	hooksecurefunc(container, "SetPoint", function(_, _, anchor)
		if (anchor) and (anchor ~= scaffold) then
			container:SetParent(scaffold)
			container:ClearAllPoints()
			container:SetPoint("TOP", scaffold)
		end
	end)

	--local Update = function()
	--	if (UnitExists("target")) then
	--		scaffold:Hide()
	--	else
	--		scaffold:Show()
	--	end
	--end

	--self:RegisterEvent("PLAYER_TARGET_CHANGED", Update)
	--self:RegisterEvent("PLAYER_ENTERING_WORLD", Update)

end

Clutter.HandleBelowMinimapWidgets = function(self)
	local container = _G.UIWidgetBelowMinimapContainerFrame
	if (not container) then
		return
	end

	local db = ns.Config.Clutter

	-- Hack to prevent UIWidgetBelowMinimapContainerFrame moving in UIParent.lua#2987
	container.GetNumWidgetsShowing = function() return 0 end
	container:SetFrameStrata("BACKGROUND")

	local scaffold = CreateFrame("Frame", nil, UIParent)
	scaffold:SetFrameStrata("BACKGROUND")
	scaffold:SetFrameLevel(10)
	scaffold:SetSize(128, 40)
	scaffold:SetPoint(unpack(db.BelowMinimapWidgetsPosition))

	hooksecurefunc(container, "SetPoint", function(self, _, anchor)
		if (anchor) and (anchor ~= scaffold) then
			self:SetParent(scaffold)
			self:ClearAllPoints()
			self:SetPoint("TOP", scaffold)
		end
	end)

	--local driver = CreateFrame("Frame", nil, UIParent, "SecureHandlerAttributeTemplate")
	--driver.EnableBoss = function() end
	--driver.DisableBoss = function() end
	--driver:SetAttribute("_onattributechanged", [=[
	--	if (name == "state-pos") then
	--		if (value == "boss") then
	--			self:CallMethod("EnableBoss");
	--		elseif (value == "normal") then
	--			self:CallMethod("DisableBoss");
	--		end
	--	end
	--]=])
	--RegisterAttributeDriver(driver, "state-pos", "[@boss1,exists][@boss2,exists][@boss3,exists][@boss4,exists]boss;normal")

end

Clutter.HandleMessageFrames = function(self)

	local db = ns.Config.Clutter

	local UIErrorsFrame = SetObjectScale(_G.UIErrorsFrame)
	UIErrorsFrame:SetFrameStrata("LOW")
	UIErrorsFrame:SetHeight(db.UIErrorsFrameHeight)
	UIErrorsFrame:SetAlpha(db.UIErrorsFrameAlpha)
	UIErrorsFrame:SetFontObject(db.UIErrorsFrameFont)
	UIErrorsFrame:SetShadowColor(unpack(db.UIErrorsFrameFontShadow))
	UIErrorsFrame:UnregisterEvent("UI_ERROR_MESSAGE")
	UIErrorsFrame:UnregisterEvent("UI_INFO_MESSAGE")
	UIErrorsFrame.RegisterEvent = function() end

	-- The RaidWarnings have a tendency to look really weird,
	-- as the SetTextHeight method scales the text after it already
	-- has been turned into a bitmap and turned into a texture.
	-- So I'm just going to turn it off. Completely.
	local RaidWarningFrame = SetObjectScale(_G.RaidWarningFrame)
	RaidWarningFrame:SetAlpha(db.RaidWarningFrameAlpha)
	RaidWarningFrame:SetHeight(db.RaidWarningFrameHeight)

	RaidWarningFrame.timings.RAID_NOTICE_MIN_HEIGHT = db.RaidWarningFrameFontSize
	RaidWarningFrame.timings.RAID_NOTICE_MAX_HEIGHT = db.RaidWarningFrameFontSize
	RaidWarningFrame.timings.RAID_NOTICE_SCALE_UP_TIME = 0
	RaidWarningFrame.timings.RAID_NOTICE_SCALE_DOWN_TIME = 0

	RaidWarningFrame.Slot1 = _G.RaidWarningFrameSlot1
	RaidWarningFrame.Slot1:SetFontObject(db.RaidWarningFrameFont)
	RaidWarningFrame.Slot1:SetShadowColor(unpack(db.RaidWarningFrameFontShadow))
	RaidWarningFrame.Slot1:SetWidth(db.RaidWarningFrameSlotWidth)
	RaidWarningFrame.Slot1.SetTextHeight = function() end

	RaidWarningFrame.Slot2 = _G.RaidWarningFrameSlot2
	RaidWarningFrame.Slot2:SetFontObject(db.RaidWarningFrameFont)
	RaidWarningFrame.Slot2:SetShadowColor(unpack(db.RaidWarningFrameFontShadow))
	RaidWarningFrame.Slot2:SetWidth(db.RaidWarningFrameSlotWidth)
	RaidWarningFrame.Slot2.SetTextHeight = function() end

	local RaidBossEmoteFrame = SetObjectScale(_G.RaidBossEmoteFrame)
	RaidBossEmoteFrame:SetAlpha(db.RaidBossEmoteFrameAlpha)
	RaidBossEmoteFrame:SetHeight(db.RaidBossEmoteFrameHeight)

	RaidBossEmoteFrame.timings.RAID_NOTICE_MIN_HEIGHT = db.RaidBossEmoteFrameFontSize
	RaidBossEmoteFrame.timings.RAID_NOTICE_MAX_HEIGHT = db.RaidBossEmoteFrameFontSize
	RaidBossEmoteFrame.timings.RAID_NOTICE_SCALE_UP_TIME = 0
	RaidBossEmoteFrame.timings.RAID_NOTICE_SCALE_DOWN_TIME = 0

	RaidBossEmoteFrame.Slot1 = _G.RaidBossEmoteFrameSlot1
	RaidBossEmoteFrame.Slot1:SetFontObject(db.RaidBossEmoteFrameFont)
	RaidBossEmoteFrame.Slot1:SetShadowColor(unpack(db.RaidBossEmoteFrameFontShadow))
	RaidBossEmoteFrame.Slot1:SetWidth(db.RaidBossEmoteFrameSlotWidth)
	RaidBossEmoteFrame.Slot1.SetTextHeight = function() end

	RaidBossEmoteFrame.Slot2 = _G.RaidBossEmoteFrameSlot2
	RaidBossEmoteFrame.Slot2:SetFontObject(db.RaidBossEmoteFrameFont)
	RaidBossEmoteFrame.Slot2:SetShadowColor(unpack(db.RaidBossEmoteFrameFontShadow))
	RaidBossEmoteFrame.Slot2:SetWidth(db.RaidBossEmoteFrameSlotWidth)
	RaidBossEmoteFrame.Slot2.SetTextHeight = function() end

	-- Just a little in-game test for dev purposes!
	-- /run RaidNotice_AddMessage(RaidWarningFrame, "Testing how texts will be displayed with my changes! Testing how texts will be displayed with my changes!", ChatTypeInfo["RAID_WARNING"])
	-- /run RaidNotice_AddMessage(RaidBossEmoteFrame, "Testing how texts will be displayed with my changes! Testing how texts will be displayed with my changes!", ChatTypeInfo["RAID_WARNING"])

	RaidWarningFrame:ClearAllPoints()
	RaidBossEmoteFrame:ClearAllPoints()
	UIErrorsFrame:ClearAllPoints()

	RaidWarningFrame:SetPoint(unpack(db.RaidWarningFramePosition))
	RaidBossEmoteFrame:SetPoint(unpack(db.RaidBossEmoteFramePosition))
	UIErrorsFrame:SetPoint(unpack(db.UIErrorsFramePosition))

	self:RegisterEvent("UI_ERROR_MESSAGE", "OnEvent")
	self:RegisterEvent("UI_INFO_MESSAGE", "OnEvent")

end

Clutter.HandleArcheologyBar = function(self, event, ...)
	-- Archeology was added in Cataclysm.
	if (not ns.IsRetail) then
		return
	end

	if (event == "ADDON_LOADED") then
		local addon = ...
		if (addon ~= "Blizzard_ArchaeologyUI") then
			return
		end
		self:UnregisterEvent("ADDON_LOADED", "HandleArcheologyBar")
	end

	local bar = ArcheologyDigsiteProgressBar
	if (not bar) then
		return self:RegisterEvent("ADDON_LOADED", "HandleArcheologyBar")
	end

	local db = ns.Config.Clutter

	bar:ClearAllPoints()
	bar:SetPoint(unpack(db.ArcheologyDigsiteProgressBarPosition))
end

Clutter.HandleVehicleSeatIndicator = function(self)
	-- No vehicle seat indicator in Wrath yet,
	-- or at least not under this name.
	if (not ns.IsRetail) then
		return
	end

	local db = ns.Config.Clutter

	local VehicleSeatIndicator = SetObjectScale(_G.VehicleSeatIndicator)
	VehicleSeatIndicator:SetParent(UIParent)
	VehicleSeatIndicator:SetFrameStrata("BACKGROUND")
	VehicleSeatIndicator:ClearAllPoints()
	VehicleSeatIndicator:SetPoint(unpack(db.VehicleSeatIndicatorPosition))

	-- This will block UIParent_ManageFramePositions() from being executed
	VehicleSeatIndicator.IsShown = function() return false end
end

Clutter.OnEvent = function(self, event, ...)
	if (event == "UI_ERROR_MESSAGE") then
		local messageType, msg = ...
		if (not msg) then
			return
		end
		--if (not msg) or (blackList.msgTypes[messageType]) or (blackList[msg]) then
		--	return
		--end
		-- This fairly new Blizzard system throttles messages. Let's use it.
		local UIErrorsFrame = _G.UIErrorsFrame
		if (UIErrorsFrame.TryDisplayMessage) then
			UIErrorsFrame:TryDisplayMessage(messageType, msg, 1, 0, 0, 1)
		else
			UIErrorsFrame:AddMessage(msg, 1, 0, 0, 1)
		end

		-- Play an error sound if the appropriate cvars allows it.
		-- Blizzard plays these sound too, but they don't slave it to the error speech setting. We do.
		if (GetCVarBool("Sound_EnableDialog")) and (GetCVarBool("Sound_EnableErrorSpeech")) then
			PlayVocalErrorByMessageType(messageType)
		end

	elseif (event == "UI_INFO_MESSAGE") then
		local messageType, msg = ...
		if (not msg) then
			return
		end
		-- This fairly new Blizzard system throttles messages. Let's use it.
		local UIErrorsFrame = UIErrorsFrame
		if (UIErrorsFrame.TryDisplayMessage) then
			UIErrorsFrame:TryDisplayMessage(messageType, msg, 1, .82, 0, 1)
		else
			UIErrorsFrame:AddMessage(msg, 1, .82, 0, 1)
		end
	end
end

Clutter.OnInitialize = function(self)
	self:HandleBelowMinimapWidgets()
	self:HandleTopCenterWidgets()
	self:HandleArcheologyBar()
	self:HandleVehicleSeatIndicator()
	self:HandleMessageFrames()
end
