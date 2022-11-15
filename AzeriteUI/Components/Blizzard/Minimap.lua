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
local MinimapMod = ns:NewModule("Minimap", "LibMoreEvents-1.0", "AceTimer-3.0", "AceHook-3.0", "AceConsole-3.0")

-- Lua API
local ipairs = ipairs
local math_cos = math.cos
local math_floor = math.floor
local math_pi = math.pi
local half_pi = math_pi/2
local math_sin = math.sin
local pairs = pairs
local select = select
local string_format = string.format
local string_lower = string.lower
local string_match = string.match
local string_upper = string.upper
local unpack = unpack

-- WoW API
local C_Timer = C_Timer
local CreateFrame = CreateFrame
local GetBuildInfo = GetBuildInfo
local GetCVar = GetCVar
local GetLatestThreeSenders = GetLatestThreeSenders
local GetMinimapZoneText = GetMinimapZoneText
local GetNetStats = GetNetStats
local GetPlayerFacing = GetPlayerFacing
local GetRealZoneText = GetRealZoneText
local GetZonePVPInfo = GetZonePVPInfo
local HasNewMail = HasNewMail
local InCombatLockdown = InCombatLockdown
local IsAddOnLoaded = IsAddOnLoaded
local IsResting = IsResting
local PlaySound = PlaySound
local ToggleDropDownMenu = ToggleDropDownMenu

-- Addon API
local Colors = ns.Colors
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia
local SetObjectScale = ns.API.SetObjectScale
local GetTime = ns.API.GetTime
local GetLocalTime = ns.API.GetLocalTime
local GetServerTime = ns.API.GetServerTime
local IsAddOnEnabled = ns.API.IsAddOnEnabled

-- WoW Strings
local L_RESTING = TUTORIAL_TITLE30 -- "Resting"
local L_NEW = NEW -- "New"
local L_MAIL = MAIL_LABEL -- "Mail"
local L_HAVE_MAIL = HAVE_MAIL -- "You have unread mail"
local L_HAVE_MAIL_FROM = HAVE_MAIL_FROM -- "Unread mail from:"
local L_FPS = string_upper(string_match(FPS_ABBR, "^.")) -- "fps"
local L_HOME = string_upper(string_match(HOME, "^.")) -- "Home"
local L_WORLD = string_upper(string_match(WORLD, "^.")) -- "World"

-- Constants
local TORGHAST_ZONE_ID = 2162
local IN_TORGHAST = (not IsResting()) and (GetRealZoneText() == GetRealZoneText(TORGHAST_ZONE_ID))

local UIHider = ns.Hider
local noop = ns.Noop

local getTimeStrings = function(h, m, suffix, useHalfClock, abbreviateSuffix)
	if (useHalfClock) then
		return "%.0f:%02.0f |cff888888%s|r", h, m, abbreviateSuffix and string_match(suffix, "^.") or suffix
	else
		return "%02.0f:%02.0f", h, m
	end
end

local Minimap_OnMouseWheel = function(self, delta)
	if (delta > 0) then
		(Minimap.ZoomIn or MinimapZoomIn):Click()
	elseif (delta < 0) then
		(Minimap.ZoomOut or MinimapZoomOut):Click()
	end
end

local Minimap_OnMouseUp = function(self, button)
	if (button == "RightButton") then
		if (ns.IsWrath) then
			ToggleDropDownMenu(1, nil, MiniMapTrackingDropDown, "MiniMapTracking", 8, 5)
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON, "SFX")
		else
			MinimapCluster.Tracking.Button:OnMouseDown()
		end
	elseif (button == "MiddleButton" and ns.IsRetail) then
		local GLP = GarrisonLandingPageMinimapButton or ExpansionLandingPageMinimapButton
		if (GLP and GLP:IsShown()) and (not InCombatLockdown()) then
			if (GLP.ToggleLandingPage) then
				GLP:ToggleLandingPage()
			else
				GarrisonLandingPage_Toggle()
			end
		end
	else
		Minimap_OnClick(self)
	end
end

local Mail_OnEnter = function(self)
	if (GameTooltip:IsForbidden()) then return end

	GameTooltip_SetDefaultAnchor(GameTooltip, self)

	local sender1, sender2, sender3 = GetLatestThreeSenders()
	if (sender1 or sender2 or sender3) then
		GameTooltip:AddLine(L_HAVE_MAIL_FROM, unpack(Colors.highlight))
		if (sender1) then
			GameTooltip:AddLine(sender1, unpack(Colors.green))
		end
		if (sender2) then
			GameTooltip:AddLine(sender2, unpack(Colors.green))
		end
		if (sender3) then
			GameTooltip:AddLine(sender3, unpack(Colors.green))
		end
	else
		GameTooltip:AddLine(L_HAVE_MAIL, unpack(Colors.highlight))
	end

	GameTooltip:Show()
end

local Mail_OnLeave = function(self)
	if (GameTooltip:IsForbidden()) then return end
	GameTooltip:Hide()
end

local Time_UpdateTooltip = function(self)
	if (GameTooltip:IsForbidden()) then return end

	local useHalfClock = ns.db.global.minimap.useHalfClock -- the outlandish 12 hour clock the colonials seem to favor so much
	local lh, lm, lsuffix = GetLocalTime(useHalfClock) -- local computer time
	local sh, sm, ssuffix = GetServerTime(useHalfClock) -- realm time
	local r, g, b = unpack(Colors.normal)
	local rh, gh, bh = unpack(Colors.highlight)

	GameTooltip_SetDefaultAnchor(GameTooltip, self)
	GameTooltip:AddLine(TIMEMANAGER_TOOLTIP_TITLE, unpack(Colors.title))
	GameTooltip:AddDoubleLine(TIMEMANAGER_TOOLTIP_LOCALTIME, string_format(getTimeStrings(lh, lm, lsuffix, useHalfClock)), rh, gh, bh, r, g, b)
	GameTooltip:AddDoubleLine(TIMEMANAGER_TOOLTIP_REALMTIME, string_format(getTimeStrings(sh, sm, ssuffix, useHalfClock)), rh, gh, bh, r, g, b)
	GameTooltip:AddLine("<"..GAMETIME_TOOLTIP_TOGGLE_CALENDAR..">", unpack(Colors.quest.green))
	GameTooltip:Show()
end

local Time_OnEnter = function(self)
	self.UpdateTooltip = Time_UpdateTooltip
	self:UpdateTooltip()
end

local Time_OnLeave = function(self)
	self.UpdateTooltip = nil
	if (GameTooltip:IsForbidden()) then return end
	GameTooltip:Hide()
end

local Time_OnClick = function(self, mouseButton)
	if (ToggleCalendar) and (not InCombatLockdown()) then
		ToggleCalendar()
	end
end

MinimapMod.UpdateCompass = function(self)
	local compass = self.compass
	if (not compass) then
		return
	end
	if (self.rotateMinimap) then
		local radius = self.compassRadius
		if (not radius) then
			local width = compass:GetWidth()
			if (not width) then
				return
			end
			radius = width/2
		end

		local playerFacing = GetPlayerFacing()
		if (not playerFacing) or (self.supressCompass) or (IN_TORGHAST) then
			compass:SetAlpha(0)
		else
			compass:SetAlpha(1)
		end

		-- In Torghast, map is always locked. Weird.
		local angle = (IN_TORGHAST) and 0 or (self.rotateMinimap and playerFacing) and -playerFacing or 0
		compass.north:SetPoint("CENTER", radius*math_cos(angle + half_pi), radius*math_sin(angle + half_pi))

	else
		compass:SetAlpha(0)
	end
end

MinimapMod.UpdatePerformance = function(self)

	local now = GetTime()
	local fps = GetFramerate()
	local world, home, _

	if (not self.latency.nextUpdate) or (now >= self.latency.nextUpdate) then
		-- latencyHome: chat, auction house, some addon data
		-- latencyWorld: combat, data from people around you(specs, gear, enchants, etc.), NPCs, mobs, casting, professions
		_, _, home, world = GetNetStats()
		self.latency.nextUpdate = now + 30
		self.latency.latencyWorld = world
	else
		world = self.latency.latencyWorld
	end

	if (fps and fps > 0) then
		self.fps:SetFormattedText("|cff888888%.0f %s|r", fps, L_FPS)
	else
		self.fps:SetText("")
	end

	if (home and home > 0 and world and world > 0) then
		self.latency:SetFormattedText("|cff888888%s|r %.0f - |cff888888%s|r %.0f", L_HOME, home, L_WORLD, world)
	elseif (world and world > 0) then
		self.latency:SetFormattedText("|cff888888%s|r %.0f", L_WORLD, world)
	else
		self.latency:SetText("")
	end

end

MinimapMod.UpdateClock = function(self)
	local time = self.time
	if (not time) then
		return
	end
	if (ns.db.global.minimap.useServerTime) then
		if (ns.db.global.minimap.useHalfClock) then
			local h, m, suffix = GetServerTime(true)
			time:SetFormattedText("%.0f:%02d", h, m)
			time.suffix:SetFormattedText(" %s", suffix)
		else
			time:SetFormattedText("%02d:%02d", GetServerTime(false))
			time.suffix:SetText(nil)
		end
	else
		if (ns.db.global.minimap.useHalfClock) then
			local h, m, suffix = GetLocalTime(true)
			time:SetFormattedText("%.0f:%02d", h, m)
			time.suffix:SetFormattedText(" %s", suffix)
		else
			time:SetFormattedText("%02d:%02d", GetLocalTime(false))
			time.suffix:SetText(nil)
		end
	end
end

MinimapMod.UpdateMail = function(self)
	local mail = self.mail
	if (not mail) then
		return
	end
	local hasMail = HasNewMail()
	if (hasMail) then
		mail:Show()
		mail.frame:Show()
	else
		mail:Hide()
		mail.frame:Hide()
	end
end

MinimapMod.UpdateTimers = function(self)
	-- In Torghast, map is always locked. Weird.
	-- *Note that this is only in the tower, not the antechamber.
	-- *We're resting in the antechamber, and it's a sanctuary. Good indicators.
	-- *Also, we know there is an API call for it. We like ours better.
	IN_TORGHAST = (not IsResting()) and (GetRealZoneText() == GetRealZoneText(TORGHAST_ZONE_ID))

	self.rotateMinimap = GetCVar("rotateMinimap") == "1"
	if (self.rotateMinimap) then
		if (not self.compassTimer) then
			self.compassTimer = self:ScheduleRepeatingTimer("UpdateCompass", 1/60)
			self:UpdateCompass()
		end
	elseif (self.compassTimer) then
		self:CancelTimer(self.compassTimer)
		self:UpdateCompass()
	end
	if (not self.performanceTimer) then
		self.performanceTimer = self:ScheduleRepeatingTimer("UpdatePerformance", 1)
		self:UpdatePerformance()
	end
	if (not self.clockTimer) then
		self.clockTimer = self:ScheduleRepeatingTimer("UpdateClock", 1)
		self:UpdateClock()
	end
end

MinimapMod.UpdateZone = function(self)
	local zoneName = self.zoneName
	if (not zoneName) then
		return
	end
	local a = zoneName:GetAlpha() -- needed to preserve alpha after text color changes
	local minimapZoneName = GetMinimapZoneText()
	local pvpType, isSubZonePvP, factionName = GetZonePVPInfo()
	if (pvpType) then
		local color = Colors.zone[pvpType]
		if (color) then
			zoneName:SetTextColor(color[1], color[2], color[3], a)
		else
			zoneName:SetTextColor(Colors.normal[1], Colors.normal[2], Colors.normal[3], a)
		end
	else
		zoneName:SetTextColor(Colors.normal[1], Colors.normal[2], Colors.normal[3], a)
	end
	zoneName:SetText(minimapZoneName)
end

MinimapMod.UpdatePosition = function(self)
	if (InCombatLockdown()) then
		return self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	end
	-- Do we still need this at all?
end

MinimapMod.InitializeMinimap = function(self)

	local db = ns.Config.Minimap
	local Minimap = _G.Minimap
	local MinimapCluster = SetObjectScale(_G.MinimapCluster)

	-- Clear Clutter
	--------------------------------------------------------
	MinimapCluster:UnregisterAllEvents()
	MinimapBackdrop:SetParent(UIHider)
	GameTimeFrame:SetParent(UIHider)
	GameTimeFrame:UnregisterAllEvents()

	if (ns.IsRetail) then
		MinimapCluster.BorderTop:SetParent(UIHider)
		MinimapCluster.InstanceDifficulty:SetParent(UIHider)
		MinimapCluster.MailFrame:SetParent(UIHider)
		MinimapCluster.Tracking:SetParent(UIHider)
		MinimapCluster.ZoneTextButton:SetParent(UIHider)
		Minimap.ZoomIn:SetParent(UIHider)
		Minimap.ZoomOut:SetParent(UIHider)
	else
		MinimapBorderTop:SetParent(UIHider)
		MiniMapInstanceDifficulty:SetParent(UIHider)
		MiniMapInstanceDifficulty:UnregisterAllEvents()
		MiniMapMailFrame:SetParent(UIHider)
		MiniMapTracking:SetParent(UIHider)
		MinimapZoneTextButton:SetParent(UIHider)
		MinimapZoomIn:SetParent(UIHider)
		MinimapZoomOut:SetParent(UIHider)
	end

	-- Setup Main Frames
	--------------------------------------------------------
	if (ns.IsRetail) then
		local dummy = CreateFrame("Frame", nil, MinimapCluster)
		dummy:SetPoint(Minimap:GetPoint())

		-- Sourced from FrameXML/Minimap.lua#264
		dummy.defaultFramePoints = {};
		for i = 1, dummy:GetNumPoints() do
			local point, relativeTo, relativePoint, offsetX, offsetY = dummy:GetPoint(i);
			dummy.defaultFramePoints[i] = { point = point, relativeTo = relativeTo, relativePoint = relativePoint, offsetX = offsetX, offsetY = offsetY };
		end

		MinimapCluster.Minimap = dummy
	end

	local minimapHolder = CreateFrame("Frame", ns.Prefix.."MinimapAnchor", Minimap)
	minimapHolder:SetSize(unpack(db.Size))
	minimapHolder:SetPoint(unpack(db.Position))

	Minimap:SetFrameStrata("MEDIUM")
	Minimap:ClearAllPoints()
	Minimap:SetPoint("TOPRIGHT", minimapHolder, "TOPRIGHT", 0, 0)
	Minimap:SetSize(unpack(db.Size))
	Minimap:SetMaskTexture(db.MaskTexture)
	Minimap:EnableMouseWheel(true)
	Minimap:SetScript("OnMouseWheel", Minimap_OnMouseWheel)
	Minimap:SetScript("OnMouseUp", Minimap_OnMouseUp)

	-- Minimap Backdrop
	local backdrop = Minimap:CreateTexture(nil, "BACKGROUND")
	backdrop:SetPoint(unpack(db.BackdropPosition))
	backdrop:SetSize(unpack(db.BackdropSize))
	backdrop:SetTexture(db.BackdropTexture)
	backdrop:SetVertexColor(unpack(db.BackdropColor))

	self.backdrop = backdrop

	-- Minimap Border
	local border = Minimap:CreateTexture(nil, "OVERLAY", nil, 0)
	border:SetPoint(unpack(db.BorderPosition))
	border:SetSize(unpack(db.BorderSize))
	border:SetTexture(db.BorderTexture)
	border:SetVertexColor(unpack(db.BorderColor))

	self.border = border

	-- Custom Widgets
	--------------------------------------------------------
	-- Zone Text
	local zoneName = Minimap:CreateFontString(nil, "OVERLAY", nil, 1)
	zoneName:SetFontObject(db.ZoneTextFont)
	zoneName:SetAlpha(db.ZoneTextAlpha)
	zoneName:SetPoint(unpack(db.ZoneTextPosition))
	zoneName:SetJustifyH("CENTER")
	zoneName:SetJustifyV("MIDDLE")

	self.zoneName = zoneName

	-- Latency Text
	local latency = Minimap:CreateFontString(nil, "OVERLAY", nil, 1)
	latency:SetFontObject(db.LatencyFont)
	latency:SetTextColor(unpack(db.LatencyColor))
	latency:SetPoint(unpack(db.LatencyPosition))
	latency:SetJustifyH("CENTER")
	latency:SetJustifyV("MIDDLE")

	self.latency = latency

	-- Framerate Text
	local fps = Minimap:CreateFontString(nil, "OVERLAY", nil, 1)
	fps:SetFontObject(db.FrameRateFont)
	fps:SetTextColor(unpack(db.FrameRateColor))
	fps:SetPoint(unpack(db.FrameRatePosition))
	fps:SetJustifyH("CENTER")
	fps:SetJustifyV("MIDDLE")

	self.fps = fps

	-- Time Text
	local time = Minimap:CreateFontString(nil, "OVERLAY", nil, 1)
	time:SetJustifyH("CENTER")
	time:SetJustifyV("MIDDLE")
	time:SetFontObject(db.ClockFont)
	time:SetTextColor(unpack(db.ClockColor))
	time:SetPoint(unpack(db.ClockPosition))

	local timeSuffix = Minimap:CreateFontString(nil, "OVERLAY", nil, 1)
	timeSuffix:SetJustifyH("CENTER")
	timeSuffix:SetJustifyV("MIDDLE")
	timeSuffix:SetFontObject(db.ClockFont)
	timeSuffix:SetTextColor(unpack(Colors.gray))
	timeSuffix:SetAlpha(.75)
	timeSuffix:SetPoint("TOPLEFT", time, "TOPRIGHT", 0, 0)
	time.suffix = timeSuffix

	local timeFrame = CreateFrame("Button", nil, Minimap)
	timeFrame:SetScript("OnEnter", Time_OnEnter)
	timeFrame:SetScript("OnLeave", Time_OnLeave)
	timeFrame:SetScript("OnClick", Time_OnClick)
	timeFrame:RegisterForClicks("AnyUp")
	timeFrame:SetAllPoints(time)

	self.time = time

	-- Compass
	local compass = CreateFrame("Frame", nil, Minimap)
	compass:SetFrameLevel(Minimap:GetFrameLevel() + 5)
	compass:SetPoint("TOPLEFT", db.CompassInset, -db.CompassInset)
	compass:SetPoint("BOTTOMRIGHT", -db.CompassInset, db.CompassInset)

	local north = compass:CreateFontString(nil, "ARTWORK", nil, 1)
	north:SetFontObject(db.CompassFont)
	north:SetTextColor(unpack(db.CompassColor))
	north:SetText(db.CompassNorthTag)
	compass.north = north

	self.compass = compass

	-- Coordinates
	local coordinates = Minimap:CreateFontString(nil, "OVERLAY", nil, 1)
	coordinates:SetJustifyH("CENTER")
	coordinates:SetJustifyV("MIDDLE")
	coordinates:SetFontObject(db.CoordinateFont)
	coordinates:SetTextColor(unpack(db.CoordinateColor))
	coordinates:SetPoint(unpack(db.CoordinatePlace))

	self.coordinates = coordinates

	-- Mail
	local mailFrame = CreateFrame("Button", nil, Minimap)
	mailFrame:SetFrameLevel(mailFrame:GetFrameLevel() + 5)
	mailFrame:SetScript("OnEnter", Mail_OnEnter)
	mailFrame:SetScript("OnLeave", Mail_OnLeave)

	local mail = Minimap:CreateFontString(nil, "OVERLAY", nil, 1)
	mail.frame = mailFrame
	mail:SetFontObject(db.MailFont)
	mail:SetTextColor(unpack(db.MailColor))
	mail:SetJustifyH(db.MailJustifyH)
	mail:SetJustifyV(db.MailJustifyV)
	mail:SetFormattedText("%s %s", L_NEW, L_MAIL)
	mail:SetPoint(unpack(db.MailPosition))
	mailFrame:SetAllPoints(mail)

	self.mail = mail

	-- Blizzard Widgets
	--------------------------------------------------------
	-- Order Hall / Garrison / Covenant Sanctum
	local GLP = GarrisonLandingPageMinimapButton or ExpansionLandingPageMinimapButton
	if (GLP) then
		GLP:ClearAllPoints()
		GLP:SetPoint("TOP", UIParent, "TOP", 0, 200) -- off-screen

		---- They change the position of the button through a local function named "ApplyGarrisonTypeAnchor".
		---- Only way we can override it without messing with method nooping, is to hook into the global function calling it.
		if (GarrisonLandingPageMinimapButton_UpdateIcon) then
			hooksecurefunc("GarrisonLandingPageMinimapButton_UpdateIcon", function()
				GLP:ClearAllPoints()
				GLP:SetPoint("TOP", UIParent, "TOP", 0, 200)
			end)
		elseif (ExpansionLandingPageMinimapButton and ExpansionLandingPageMinimapButton.UpdateIcon) then
			hooksecurefunc(ExpansionLandingPageMinimapButton, "UpdateIcon", function()
				GLP:ClearAllPoints()
				GLP:SetPoint("TOP", UIParent, "TOP", 0, 200)
			end)
		end
	end

	-- Dungeon Eye
	local eyeFrame = CreateFrame("Frame", nil, Minimap)
	eyeFrame:SetFrameLevel(Minimap:GetFrameLevel() + 10)
	eyeFrame:SetPoint(unpack(db.EyePosition))
	eyeFrame:SetSize(unpack(db.EyeSize))
	self.eyeFrame = eyeFrame

	if (ns.IsWrath) then

		local eyeTexture = MiniMapBattlefieldFrame:CreateTexture(nil, "ARTWORK", nil, 1)
		eyeTexture:SetPoint("CENTER", 0, 0)
		eyeTexture:SetSize(unpack(db.EyeTextureSize))
		eyeTexture:SetTexture(db.EyeTexture)
		eyeTexture:SetVertexColor(unpack(db.EyeTextureColor))
		eyeTexture:SetShown(MiniMapBattlefieldFrame:IsShown())
		self.eyeTexture = eyeTexture

		MiniMapBattlefieldFrame:SetParent(eyeFrame)
		MiniMapBattlefieldFrame:ClearAllPoints()
		MiniMapBattlefieldFrame:SetPoint("CENTER", 0, 0)

		MiniMapBattlefieldFrame:SetFrameLevel(MiniMapBattlefieldFrame:GetFrameLevel() + 10)
		MiniMapBattlefieldFrame:ClearAllPoints()
		MiniMapBattlefieldFrame:SetHitRectInsets(-8, -8, -8, -8)

		MiniMapBattlefieldBorder:Hide()
		MiniMapBattlefieldIcon:SetAlpha(0)

	else

		-- This was the old retail, need to update for Shadowlands!
		if (not ns.IsRetail) then

			local eyeTexture = QueueStatusMinimapButton.Eye:CreateTexture(nil, "ARTWORK", nil, 1)
			eyeTexture:SetPoint("CENTER", 0, 0)
			eyeTexture:SetSize(unpack(db.EyeTextureSize))
			eyeTexture:SetTexture(db.EyeTexture)
			eyeTexture:SetVertexColor(unpackdb.EyeTextureColor)
			self.eyeTexture = eyeTexture

			QueueStatusMinimapButton:SetHighlightTexture("")

			QueueStatusMinimapButtonBorder:SetAlpha(0)
			QueueStatusMinimapButtonBorder:SetTexture(nil)
			QueueStatusMinimapButtonGroupSize:SetFontObject(db.EyeGroupSizeFont)
			QueueStatusMinimapButtonGroupSize:ClearAllPoints()
			QueueStatusMinimapButtonGroupSize:SetPoint(unpack(db.EyeGroupSizePosition))

			QueueStatusMinimapButton:SetParent(eyeFrame)
			QueueStatusMinimapButton:ClearAllPoints()
			QueueStatusMinimapButton:SetPoint("CENTER", 0, 0)

			QueueStatusMinimapButton.Eye:SetSize(unpack(db.EyeTextureSize))
			QueueStatusMinimapButton.Eye.texture:SetParent(UIHider)
			QueueStatusMinimapButton.Eye.texture:SetAlpha(0)

			QueueStatusMinimapButton.Highlight:SetAlpha(0)
			QueueStatusMinimapButton.Highlight:SetTexture(nil)

			QueueStatusFrame:ClearAllPoints()
			QueueStatusFrame:SetPoint(unpack(db.EyeGroupStatusFramePosition))
		end

	end

	self:UpdatePosition()
end

MinimapMod.InitializeMBB = function(self)
end

MinimapMod.InitializeNarcissus = function(self)
	local Narci_MinimapButton = SetObjectScale(Narci_MinimapButton)
	if (not Narci_MinimapButton) then
		return
	end

	Narci_MinimapButton:SetScript("OnDragStart", nil)
	Narci_MinimapButton:SetScript("OnDragStop", nil)
	Narci_MinimapButton:SetSize(56,56) -- 36,36
	Narci_MinimapButton.Color:SetVertexColor(.85, .85, .85, 1)
	Narci_MinimapButton.Background:SetScale(1)
	Narci_MinimapButton.Background:SetSize(46,46) -- 42,42
	Narci_MinimapButton.Background:SetVertexColor(.75, .75, .75, 1)
	Narci_MinimapButton.InitPosition = function(self)
		local p, a, rp, x, y = self:GetPoint()
		if (rp ~= "BOTTOM") then
			Narci_MinimapButton:ClearAllPoints()
			Narci_MinimapButton:SetPoint("CENTER", Minimap, "BOTTOM", 0, 0)
		end
	end
	Narci_MinimapButton.OnDragStart = noop
	Narci_MinimapButton.OnDragStop = noop
	Narci_MinimapButton.SetIconScale = noop
	Narci_MinimapButton:InitPosition()

	hooksecurefunc(Narci_MinimapButton, "SetPoint", Narci_MinimapButton.InitPosition)

	--Narci_SetActiveBorderTexture

end

MinimapMod.InitializeAddon = function(self, addon, ...)
	if (addon == "ADDON_LOADED") then
		addon = ...
	end
	if (not self.Addons[addon]) then
		return
	end
	local method = self["Initialize"..addon]
	if (method) then
		method(self)
	end
	self.Addons[addon] = nil
end

MinimapMod.SetClock = function(self, input)
	local args = { self:GetArgs(string_lower(input)) }
	for _,arg in ipairs(args) do
		if (arg == "24") then
			ns.db.global.minimap.useHalfClock = false
		elseif (arg == "12") then
			ns.db.global.minimap.useHalfClock = true
		elseif (arg == "realm") then
			ns.db.global.minimap.useServerTime = true
		elseif (arg == "local") then
			ns.db.global.minimap.useServerTime = false
		end
	end
end

MinimapMod.OnEvent = function(self, event)
	if (event == "PLAYER_ENTERING_WORLD") then
		self:UpdateZone()
		self:UpdateMail()
		self:UpdateTimers()
		self:UpdatePosition()

	elseif (event == "VARIABLES_LOADED") or (event == "SETTINGS_LOADED") then
		self:UpdateTimers()
		self:UpdatePosition()

	elseif (event == "PLAYER_REGEN_ENABLED") then
		if (not InCombatLockdown()) then
			self:UnregisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
			self:UpdateTimers()
			self:UpdatePosition()
		end

	elseif (event == "CVAR_UPDATE") then
		self:UpdateTimers()

	elseif (event == "UPDATE_PENDING_MAIL") then
		self:UpdateMail()

	elseif (event == "ZONE_CHANGED") or (event == "ZONE_CHANGED_INDOORS") or (event == "ZONE_CHANGED_NEW_AREA") then
		self:UpdateZone()
	end
end

MinimapMod.OnInitialize = function(self)

	self:InitializeMinimap()
	self:RegisterEvent("CVAR_UPDATE", "OnEvent")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:RegisterEvent("UPDATE_PENDING_MAIL", "OnEvent")
	self:RegisterEvent("VARIABLES_LOADED", "OnEvent")
	self:RegisterEvent("ZONE_CHANGED", "OnEvent")
	self:RegisterEvent("ZONE_CHANGED_INDOORS", "OnEvent")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "OnEvent")
	self:RegisterChatCommand("setclock", "SetClock")

	if (ns.IsRetail) then
		self:RegisterEvent("SETTINGS_LOADED", "OnEvent")
	end

	if (not SlashCmdList["CALENDAR"]) then
		self:RegisterChatCommand("calendar", function()
			if (ToggleCalendar) then
				ToggleCalendar()
			end
		end)
	end

	self.Addons = {}

	local addons, queued = { "MBB", "Narcissus" }
	for _,addon in ipairs(addons) do
		if (IsAddOnEnabled(addon)) then
			self.Addons[addon] = true
			if (IsAddOnLoaded(addon)) then
				self:InitializeAddon(addon)
			else
				-- Forcefully load addons
				-- *This helps work around an issue where
				--  Narcissus can bug out when started in combat.
				LoadAddOn(addon)
				self:InitializeAddon(addon)
			end
		end
	end

end
