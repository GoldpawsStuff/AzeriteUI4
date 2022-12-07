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
if (ns.IsRetail) then
	return
end

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

local UpdateWatchFrameLinkButtons = function()
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

local UpdateWatchFrameLine = function(line)
	if (not Handled[line]) then
		line.text:SetFontObject(GetFont(12,true)) -- default size is 12
		line.text:SetWordWrap(false)
		line.dash:SetParent(UIHider)
		Handled[line] = true
	end
end

local UpdateWatchFrameLines = function()
	for _, timerLine in pairs(WATCHFRAME_TIMERLINES) do
		UpdateWatchFrameLine(timerLine)
	end
	for _, achievementLine in pairs(WATCHFRAME_ACHIEVEMENTLINES) do
		UpdateWatchFrameLine(achievementLine)
	end
	for _, questLine in pairs(WATCHFRAME_QUESTLINES) do
		UpdateWatchFrameLine(questLine)
	end
end

local UpdateQuestItemButtons = function()
	local i,item = 1,WatchFrameItem1
	while (item) do
		UpdateQuestItemButton(item)
		i = i + 1
		item = _G["WatchFrameItem" .. i]
	end
end

Tracker.InitializeWatchFrame = function(self)

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
	UpdateWatchFrameLinkButtons()

	hooksecurefunc("WatchFrame_Update", UpdateWatchFrameLines)
	hooksecurefunc("WatchFrame_DisplayTrackedAchievements", UpdateWatchFrameLinkButtons)
	hooksecurefunc("WatchFrame_DisplayTrackedQuests", UpdateWatchFrameLinkButtons)
	hooksecurefunc("WatchFrameItem_OnShow", UpdateQuestItemButton)

	self:UpdateWatchFrame()
end

Tracker.UpdateWatchFrame = function(self)

	SetCVar("watchFrameWidth", "1") -- 306 or 204

	WatchFrame:SetFrameStrata("LOW")
	WatchFrame:SetFrameLevel(50)
	WatchFrame:SetClampedToScreen(false)
	WatchFrame:ClearAllPoints()
	WatchFrame:SetPoint("TOP", self.holder, "TOP")
	WatchFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, ns.Config.Tracker.BottomOffset)

	UpdateQuestItemButtons()
	UpdateWatchFrameLines()

end

Tracker.OnEvent = function(self, event, ...)
	if (event == "PLAYER_ENTERING_WORLD") then
		WatchFrame:SetAlpha(.9)
		if (self.queueImmersionHook) then
			local frame = ImmersionFrame
			if (frame) then
				self.queueImmersionHook = nil
				ImmersionFrame:HookScript("OnShow", function() WatchFrame:SetAlpha(0) end)
				ImmersionFrame:HookScript("OnHide", function() WatchFrame:SetAlpha(.9) end)
			end
		end
	elseif (event == "PLAYER_REGEN_ENABLED") then
		if (InCombatLockdown()) then return end
		self:UnregisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	end
	self:UpdateWatchFrame()
end

Tracker.OnInitialize = function(self)
	self.queueImmersionHook = IsAddOnEnabled("Immersion")
	self:InitializeWatchFrame()
	self:RegisterEvent("VARIABLES_LOADED", "OnEvent")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
end