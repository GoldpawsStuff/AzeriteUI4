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
local Tracker = ns:NewModule("Tracker", "LibMoreEvents-1.0", "AceHook-3.0")

-- WoW API
local hooksecurefunc = hooksecurefunc
local IsAddOnLoaded = IsAddOnLoaded
local SetOverrideBindingClick = SetOverrideBindingClick

-- Addon API
local Colors = ns.Colors
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia
local SetObjectScale = ns.API.SetObjectScale
local IsAddOnEnabled = ns.API.IsAddOnEnabled
local UIHider = ns.Hider
local noop = ns.Noop

-- Cache of handled elements
local Handled = {}

local UpdateObjectiveTracker = function()
	local frame = ObjectiveTrackerFrame.MODULES
	if (frame) then
		for i = 1,#frame do
			local module = frame[i]
			if (module) then

				local header = module.Header

				local background = header.Background
				background:SetAtlas(nil)

				local msg = header.Text
				msg:SetFontObject(GetFont(16,true))
				msg:SetTextColor(unpack(ns.Colors.title))
				msg:SetShadowColor(0,0,0,0)
				msg:SetDrawLayer("OVERLAY", 7)
				msg:SetParent(header)

				local blocks = module:GetActiveBlocks()
				for id,block in pairs(blocks) do
					-- Quest/Objective title
					if (block.HeaderText) then
						block.HeaderText:SetFontObject(GetFont(13,true))
						block.HeaderText:SetSpacing(2)
					end
					-- Quest/Objective text/objectives
					for objectiveKey,line in pairs(block.lines) do
						line.Text:SetFontObject(GetFont(13,true))
						line.Text:SetSpacing(2)
						if (line.Dash) then
							line.Dash:SetParent(UIHider)
						end
					end
				end

				if (not Handled[module]) then
					local minimize = header.MinimizeButton
					minimize.SetCollapsed = function() return end
					minimize:GetNormalTexture():SetTexture(nil)
					minimize:GetPushedTexture():SetTexture(nil)
					minimize:GetHighlightTexture():SetTexture(nil)
					minimize:DisableDrawLayer(minimize:GetNormalTexture():GetDrawLayer())
					minimize:DisableDrawLayer(minimize:GetPushedTexture():GetDrawLayer())
					minimize:DisableDrawLayer(minimize:GetHighlightTexture():GetDrawLayer())
					minimize:ClearAllPoints()
					minimize:SetAllPoints(header)

					Handled[module] = true
				end
			end
		end
	end
end

local UpdateProgressBar = function(_, _, line)

	local progress = line.ProgressBar
	local bar = progress.Bar

	if (bar) then
		local label = bar.Label
		local icon = bar.Icon
		local iconBG = bar.IconBG
		local barBG = bar.BarBG
		local glow = bar.BarGlow
		local sheen = bar.Sheen
		local frame = bar.BarFrame
		local frame2 = bar.BarFrame2
		local frame3 = bar.BarFrame3
		local borderLeft = bar.BorderLeft
		local borderRight = bar.BorderRight
		local borderMid = bar.BorderMid

		-- Some of these tend to pop back up, so let's just always hide them.
		if (barBG) then barBG:Hide(); barBG:SetAlpha(0) end
		if (iconBG) then iconBG:Hide(); iconBG:SetAlpha(0) end
		if (glow) then glow:Hide() end
		if (sheen) then sheen:Hide() end
		if (frame) then frame:Hide() end
		if (frame2) then frame2:Hide() end
		if (frame3) then frame3:Hide() end
		if (borderLeft) then borderLeft:SetAlpha(0) end
		if (borderRight) then borderRight:SetAlpha(0) end
		if (borderMid) then borderMid:SetAlpha(0) end

		-- This will fix "stuck" animations?
		if (progress.AnimatableFrames) then
			BonusObjectiveTrackerProgressBar_ResetAnimations(progress)
		end

		if (not Handled[bar]) then

			bar:SetStatusBarTexture(GetMedia("bar-progress"))
			bar:GetStatusBarTexture():SetDrawLayer("BORDER", 0)
			bar:DisableDrawLayer("BACKGROUND")
			bar:SetHeight(18)

			local backdrop = bar:CreateTexture(nil, "BORDER", nil, -1)
			backdrop:SetPoint("TOPLEFT", 0, 0)
			backdrop:SetPoint("BOTTOMRIGHT", 0, 0)
			backdrop:SetColorTexture(.6, .6, .6, .05)

			local border = bar:CreateTexture(nil, "BORDER", nil, -2)
			border:SetPoint("TOPLEFT", -2, 2)
			border:SetPoint("BOTTOMRIGHT", 2, -2)
			border:SetColorTexture(0, 0, 0, .75)

			if (label) then
				label:ClearAllPoints()
				label:SetPoint("CENTER", bar, 0,0)
				label:SetFontObject(GetFont(12,true))
			end

			if (icon) then
				icon:SetSize(20,20)
				icon:SetMask("")
				icon:SetMask(GetMedia("actionbutton-mask-square-rounded"))
				icon:ClearAllPoints()
				icon:SetPoint("RIGHT", bar, 26, 0)
			end

			Handled[bar] = true

		elseif (icon) and (bar.NewBorder) then
			bar.NewBorder:SetShown(icon:IsShown())
		end
	end
end

-- Something is tainting the Wrath WatchFrame,
-- let's just work around it for now.
local LinkButton_OnClick = function(self, ...)
	if (not InCombatLockdown()) then
		WatchFrameLinkButtonTemplate_OnClick(self:GetParent(), ...)
	end
end

local UpdateQuestItemButton = function(button)
	local name = button:GetName()
	local icon = button.icon or _G[name.."IconTexture"]
	local count = button.Count or _G[name.."Count"]
	local hotKey = button.HotKey or _G[name.."HotKey"]

	if (not Handled[button]) then
		button:SetNormalTexture("")

		if (icon) then
			icon:SetDrawLayer("BACKGROUND",0)
			icon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
			icon:ClearAllPoints()
			icon:SetPoint("TOPLEFT", 2, -2)
			icon:SetPoint("BOTTOMRIGHT", -2, 2)

			local backdrop = button:CreateTexture(nil, "BACKGROUND", nil, -7)
			backdrop:SetPoint("TOPLEFT", icon, -2, 2)
			backdrop:SetPoint("BOTTOMRIGHT", icon, 2, -2)
			backdrop:SetColorTexture(0, 0, 0, .75)
		end

		if (count) then
			count:ClearAllPoints()
			count:SetPoint("BOTTOMRIGHT", button, 0, 3)
			count:SetFontObject(GetFont(12,true))
		end

		if (hotKey) then
			hotKey:SetText("")
			hotKey:SetAlpha(0)
		end

		if (button.SetHighlightTexture and not button.Highlight) then
			local Highlight = button:CreateTexture()

			Highlight:SetColorTexture(1, 1, 1, 0.3)
			Highlight:SetAllPoints(icon)

			button.Highlight = Highlight
			button:SetHighlightTexture(Highlight)
		end

		if (button.SetPushedTexture and not button.Pushed) then
			local Pushed = button:CreateTexture()

			Pushed:SetColorTexture(0.9, 0.8, 0.1, 0.3)
			Pushed:SetAllPoints(icon)

			button.Pushed = Pushed
			button:SetPushedTexture(Pushed)
		end

		if (button.SetCheckedTexture and not button.Checked) then
			local Checked = button:CreateTexture()

			Checked:SetColorTexture(0, 1, 0, 0.3)
			Checked:SetAllPoints(icon)

			button.Checked = Checked
			button:SetCheckedTexture(Checked)
		end

		Handled[button] = true
	end
end

local UpdateQuestItem = function(_, block)
	local button = block.itemButton
	if (button) then
		UpdateQuestItemButton(button)
	end
end

local UpdateWrathTrackerLinkButtons = function()
	for i,linkButton in pairs(WATCHFRAME_LINKBUTTONS) do
		if (linkButton and not Handled[linkButton]) then
			local clickFrame = CreateFrame("Button", nil, linkButton)
			clickFrame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			clickFrame:SetAllPoints()
			clickFrame:SetScript("OnClick", LinkButton_OnClick)
			Handled[linkButton] = true
		end
	end
end

local UpdateWrathWatchFrameLine = function(line)
	if (not Handled[line]) then
		line.text:SetFontObject(GetFont(12,true)) -- default size is 12
		line.text:SetWordWrap(false)
		line.dash:SetParent(UIHider)
		Handled[line] = true
	end
end

local UpdateWrathTrackerLines = function()
	for _, timerLine in pairs(WATCHFRAME_TIMERLINES) do
		UpdateWrathWatchFrameLine(timerLine)
	end
	for _, achievementLine in pairs(WATCHFRAME_ACHIEVEMENTLINES) do
		UpdateWrathWatchFrameLine(achievementLine)
	end
	for _, questLine in pairs(WATCHFRAME_QUESTLINES) do
		UpdateWrathWatchFrameLine(questLine)
	end
end

local UpdateWrathQuestItemButtons = function()
	local i,item = 1,WatchFrameItem1
	while (item) do
		UpdateQuestItemButton(item)
		i = i + 1
		item = _G["WatchFrameItem" .. i]
	end
end

local AutoHider_OnHide = function()
	if (ns.IsRetail) then
		if (not ObjectiveTrackerFrame.collapsed) then
			ObjectiveTracker_Collapse()
		end
	end
end

local AutoHider_OnShow = function()
	if (ns.IsRetail) then
		if (ObjectiveTrackerFrame.collapsed) then
			ObjectiveTracker_Expand()
		end
	end
end

Tracker.InitializeAutoHider = function(self)
	if (not ns.IsRetail) then return end

	local tracker = ObjectiveTrackerFrame or WatchFrame

	tracker.autoHider = CreateFrame("Frame", nil, tracker, "SecureHandlerStateTemplate")
	tracker.autoHider:SetAttribute("_onstate-vis", [[ if (newstate == "hide") then self:Hide() else self:Show() end ]])
	tracker.autoHider:SetScript("OnHide", AutoHider_OnHide)
	tracker.autoHider:SetScript("OnShow", AutoHider_OnShow)

	local driver = "hide;show"
	driver = "[@arena1,exists][@arena2,exists][@arena3,exists][@arena4,exists][@arena5,exists]" .. driver
	driver = "[@boss1,exists][@boss2,exists][@boss3,exists][@boss4,exists][@boss5,exists]" .. driver

	RegisterStateDriver(tracker.autoHider, "vis", driver)
end

Tracker.InitializeTracker = function(self, event, addon)
	if (event == "ADDON_LOADED") then
		if (addon ~= "Blizzard_ObjectiveTracker") then
			return
		end
		self:UnregisterEvent("ADDON_LOADED", "OnEvent")
	end

	local db = ns.Config.Tracker

	self.holder = SetObjectScale(CreateFrame("Frame", ns.Prefix.."WatchFrameAnchor", WatchFrame))
	self.holder:SetPoint(unpack(db.Position))
	self.holder:SetSize(unpack(db.Size))

	local ObjectiveTrackerFrame = SetObjectScale(ObjectiveTrackerFrame, 1.1)
	ObjectiveTrackerFrame:SetHeight(480 / 1.1)
	ObjectiveTrackerFrame:SetAlpha(.9)

	-- Prevent managed frame system from repositioning
	--ObjectiveTrackerFrame.IsInDefaultPosition = noop

	ObjectiveTrackerUIWidgetContainer:SetFrameStrata("BACKGROUND")
	ObjectiveTrackerFrame:SetFrameStrata("BACKGROUND")

	hooksecurefunc("ObjectiveTracker_Update", UpdateObjectiveTracker)

	hooksecurefunc(QUEST_TRACKER_MODULE, "SetBlockHeader", UpdateQuestItem)
	hooksecurefunc(WORLD_QUEST_TRACKER_MODULE, "AddObjective", UpdateQuestItem)
	hooksecurefunc(CAMPAIGN_QUEST_TRACKER_MODULE, "AddObjective", UpdateQuestItem)

	hooksecurefunc(CAMPAIGN_QUEST_TRACKER_MODULE, "AddProgressBar", UpdateProgressBar)
	hooksecurefunc(QUEST_TRACKER_MODULE, "AddProgressBar", UpdateProgressBar)
	hooksecurefunc(DEFAULT_OBJECTIVE_TRACKER_MODULE, "AddProgressBar", UpdateProgressBar)
	hooksecurefunc(BONUS_OBJECTIVE_TRACKER_MODULE, "AddProgressBar", UpdateProgressBar)
	hooksecurefunc(WORLD_QUEST_TRACKER_MODULE, "AddProgressBar", UpdateProgressBar)
	hooksecurefunc(SCENARIO_TRACKER_MODULE, "AddProgressBar", UpdateProgressBar)

	local toggleButton = CreateFrame("Button", ns.Prefix.."_ObjectiveTrackerToggleButton", UIParent, "SecureActionButtonTemplate")
	toggleButton:SetScript("OnClick", function()
		if (ObjectiveTrackerFrame:IsVisible()) then
			ObjectiveTrackerFrame:Hide()
		else
			ObjectiveTrackerFrame:Show()
		end
	end)
	SetOverrideBindingClick(toggleButton, true, "SHIFT-O", toggleButton:GetName())

	self:InitializeAutoHider()
	self:UpdatePosition()
end

Tracker.InitializeWrathTracker = function(self)
	if (not ns.IsWrath) then
		return
	end

	local db = ns.Config.Tracker

	self.holder = SetObjectScale(CreateFrame("Frame", ns.Prefix.."WatchFrameAnchor", WatchFrame))
	self.holder:SetPoint(unpack(db.Position))
	self.holder:SetSize(unpack(db.Size))

	SetObjectScale(WatchFrame, db.WrathScale)

	-- UIParent.lua overrides the position if this is false
	WatchFrame.IsUserPlaced = function() return true end
	WatchFrame:SetAlpha(.9)
	WatchFrameTitle:SetFontObject(db.WrathTitleFont)

	-- The local function WatchFrame_GetLinkButton creates the buttons,
	-- and it's only ever called from these two global functions.
	UpdateWrathTrackerLinkButtons()
	hooksecurefunc("WatchFrame_Update", UpdateWrathTrackerLines)
	hooksecurefunc("WatchFrame_DisplayTrackedAchievements", UpdateWrathTrackerLinkButtons)
	hooksecurefunc("WatchFrame_DisplayTrackedQuests", UpdateWrathTrackerLinkButtons)
	hooksecurefunc("WatchFrameItem_OnShow", UpdateQuestItemButton)

	local toggleButton = CreateFrame("Button", ns.Prefix.."_ObjectiveTrackerToggleButton", UIParent, "SecureActionButtonTemplate")
	toggleButton:SetScript("OnClick", function()
		if (WatchFrame:IsVisible()) then
			WatchFrame:Hide()
		else
			WatchFrame:Show()
		end
	end)
	SetOverrideBindingClick(toggleButton, true, "SHIFT-O", toggleButton:GetName())

	self:InitializeAutoHider()
	self:UpdateWrathTracker()
end

Tracker.UpdateWrathTracker = function(self)
	if (not ns.IsWrath) then
		return
	end

	SetCVar("watchFrameWidth", "1") -- 306 or 204

	WatchFrame:SetFrameStrata("LOW")
	WatchFrame:SetFrameLevel(50)
	WatchFrame:SetClampedToScreen(false)
	WatchFrame:ClearAllPoints()
	WatchFrame:SetPoint("TOP", self.holder, "TOP")
	WatchFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, ns.Config.Tracker.BottomOffset)
	--WatchFrame:SetPoint("TOP", UIParent, "TOP", 0, ns.Config.Tracker.TopOffset)
	--WatchFrame:SetPoint("BOTTOMRIGHT", self.holder, "BOTTOMRIGHT")

	UpdateWrathQuestItemButtons()
	UpdateWrathTrackerLines()

end

Tracker.UpdatePositionBase = function(self)
	ObjectiveTrackerFrame:ClearAllPoints()
	ObjectiveTrackerFrame:SetPointBase("TOP", self.holder)
end

Tracker.UpdatePosition = function(self)
	if (InCombatLockdown()) then
		return self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	end

	-- Opt out of the movement system
	--ObjectiveTrackerFrame.layoutParent = nil
	--ObjectiveTrackerFrame.isRightManagedFrame = nil
	--ObjectiveTrackerFrame.ignoreFramePositionManager = true
	--UIParentRightManagedFrameContainer:RemoveManagedFrame(ObjectiveTrackerFrame)

	--ObjectiveTrackerFrame.IsInDefaultPosition = noop -- taint?

	local db = ns.Config.Tracker

	ObjectiveTrackerFrame:SetFrameStrata("LOW")
	ObjectiveTrackerFrame:SetFrameLevel(50)
	ObjectiveTrackerFrame:SetClampedToScreen(false)
	ObjectiveTrackerFrame:ClearAllPoints()
	ObjectiveTrackerFrame:SetPoint("TOP", self.holder, "TOP")
	ObjectiveTrackerFrame:SetHeight(db.TrackerHeight)

	if (not self:IsHooked(ObjectiveTrackerFrame, "SetPoint")) then
		self:SecureHook(ObjectiveTrackerFrame, "SetPoint", "UpdatePositionBase")
	end

	--ObjectiveTrackerFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, db.BottomOffset)
	--ObjectiveTrackerFrame:SetPoint("TOP", UIParent, "TOP", 0, ns.Config.Tracker.TopOffset)
	--ObjectiveTrackerFrame:SetPoint("BOTTOMRIGHT", self.holder, "BOTTOMRIGHT")

end

Tracker.OnEvent = function(self, event, ...)
	if (event == "PLAYER_ENTERING_WORLD") then

		local tracker = ObjectiveTrackerFrame or WatchFrame
		if (tracker) then tracker:SetAlpha(.9) end

		if (self.queueImmersionHook) then
			local frame = ImmersionFrame
			if (frame) then
				self.queueImmersionHook = nil
				ImmersionFrame:HookScript("OnShow", function() (ObjectiveTrackerFrame or WatchFrame):SetAlpha(0) end)
				ImmersionFrame:HookScript("OnHide", function() (ObjectiveTrackerFrame or WatchFrame):SetAlpha(.9) end)
			end
		end

		if (ns.IsWrath) then
			self:UpdateWrathTracker()
		else
			self:UpdatePosition()
		end

	elseif (event == "VARIABLES_LOADED") or (event == "SETTINGS_LOADED") then
		if (ns.IsWrath) then
			self:UpdateWrathTracker()
		else
			self:UpdatePosition()
		end

	elseif (event == "PLAYER_REGEN_ENABLED") then
		if (not InCombatLockdown()) then
			self:UnregisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
			if (ns.IsWrath) then
				self:UpdateWrathTracker()
			else
				self:UpdatePosition()
			end
		end
	end
end

Tracker.OnInitialize = function(self)
	self.queueImmersionHook = IsAddOnEnabled("Immersion")

	if (ns.IsWrath) then
		self:InitializeWrathTracker()
		self:RegisterEvent("VARIABLES_LOADED", "OnEvent")
	else
		if (IsAddOnLoaded("Blizzard_ObjectiveTracker")) then
			self:InitializeTracker()
		else
			self:RegisterEvent("ADDON_LOADED", "InitializeTracker")
		end
	end

	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")

	if (ns.IsRetail) then
		self:RegisterEvent("SETTINGS_LOADED", "OnEvent")
	end
end