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
local ExtraButtons = ActionBars:NewModule("ExtraButtons", "LibMoreEvents-1.0", "AceHook-3.0")

-- Lua API
local pairs = pairs
local string_find = string.find

-- WoW API
local GetBindingKey = GetBindingKey
local hooksecurefunc = hooksecurefunc

-- Addon API
local Colors = ns.Colors
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia
local RegisterCooldown = ns.Widgets.RegisterCooldown
local SetObjectScale = ns.API.SetObjectScale
local noop = ns.Noop

ExtraButtons.UpdateButton = function(self, button)

	local name = button:GetName()
	if (name and string_find(name, "ExtraActionButton%d+")) then
		if (not self.ExtraButtons) then
			self.ExtraButtons = {}
		end
		self.ExtraButtons[button] = true
	end

	local db = ns.Config.ExtraButtons

	local m = db.ExtraButtonMask
	local b = GetMedia("blank")


	if (button.icon or button.Icon) then (button.icon or button.Icon):SetAlpha(0) end
	if (button.NormalTexture) then button.NormalTexture:SetAlpha(0) end -- Zone
	if (button.Flash) then button.Flash:SetTexture(nil) end -- Extra
	if (button.style) then button.style:SetAlpha(0) end -- Extra

	-- Todo: Check which ones are there, this might not be needed.
	if (button.SetNormalTexture) then
		if (button:GetNormalTexture()) then button:GetNormalTexture():SetTexture(nil) end
		hooksecurefunc(button, "SetNormalTexture", function(b,...) if(...~="")then b:SetNormalTexture("") end end)
	end
	if (button.SetHighlightTexture) then
		if (button:GetHighlightTexture()) then button:GetHighlightTexture():SetTexture(nil) end
		hooksecurefunc(button, "SetHighlightTexture", function(b,...) if(...~="")then b:SetHighlightTexture("") end end)
	end
	if (button.SetCheckedTexture) then
		if (button:GetCheckedTexture()) then button:GetCheckedTexture():SetTexture(nil) end
		hooksecurefunc(button, "SetCheckedTexture", function(b,...) if(...~="")then b:SetCheckedTexture("") end end)
	end

	button:SetSize(unpack(db.ExtraButtonSize))

	-- Custom overlay frame
	local overlay = CreateFrame("Frame", nil, button)
	overlay:SetFrameLevel(button:GetFrameLevel() + 3)
	overlay:SetAllPoints()
	button.overlay = overlay

	local border = overlay:CreateTexture(nil, "BORDER", nil, 1)
	border:SetPoint(unpack(db.ExtraButtonBorderPosition))
	border:SetSize(unpack(db.ExtraButtonBorderSize))
	border:SetTexture(db.ExtraButtonBorderTexture)
	border:SetVertexColor(unpack(db.ExtraButtonBorderColor))
	button.iconBorder = border

	local cooldown = button.cooldown or button.Cooldown
	if (cooldown) then
		cooldown:SetFrameLevel(button:GetFrameLevel() + 1)
		cooldown:SetSize(unpack(db.ExtraButtonCooldownSize))
		cooldown:ClearAllPoints()
		cooldown:SetPoint(unpack(db.ExtraButtonCooldownPosition))
		cooldown:SetReverse(false)
		cooldown:SetSwipeTexture(m)
		cooldown:SetSwipeColor(unpack(db.ExtraButtonCooldownColor))
		cooldown:SetDrawSwipe(true)
		cooldown:SetBlingTexture(b, 0, 0, 0, 0)
		cooldown:SetDrawBling(false)
		cooldown:SetEdgeTexture(b)
		cooldown:SetDrawEdge(false)
		cooldown:SetHideCountdownNumbers(true)

		-- Custom cooldown count
		local cooldownCount = overlay:CreateFontString(nil, "OVERLAY", nil, 1)
		cooldownCount:SetPoint(unpack(db.ExtraButtonCooldownCountPosition))
		cooldownCount:SetJustifyH(db.ExtraButtonCooldownCountJustifyH)
		cooldownCount:SetJustifyV(db.ExtraButtonCooldownCountJustifyV)
		cooldownCount:SetFontObject(db.ExtraButtonCooldownCountFont)
		cooldownCount:SetTextColor(unpack(db.ExtraButtonCooldownCountColor))
		button.cooldownCount = cooldownCount

		RegisterCooldown(cooldown, cooldownCount)

		hooksecurefunc(cooldown, "SetSwipeTexture", function(c,t) if t ~= m then c:SetSwipeTexture(m) end end)
		hooksecurefunc(cooldown, "SetBlingTexture", function(c,t) if t ~= b then c:SetBlingTexture(b,0,0,0,0) end end)
		hooksecurefunc(cooldown, "SetEdgeTexture", function(c,t) if t ~= b then c:SetEdgeTexture(b) end end)
		hooksecurefunc(cooldown, "SetSwipeColor", function(c,r,g,b,a) if not a or a>.76 then c:SetSwipeColor(r,g,b,.75) end end)
		hooksecurefunc(cooldown, "SetDrawSwipe", function(c,h) if not h then c:SetDrawSwipe(true) end end)
		hooksecurefunc(cooldown, "SetDrawBling", function(c,h) if h then c:SetDrawBling(false) end end)
		hooksecurefunc(cooldown, "SetDrawEdge", function(c,h) if h then c:SetDrawEdge(false) end end)
		hooksecurefunc(cooldown, "SetHideCountdownNumbers", function(c,h) if not h then c:SetHideCountdownNumbers(true) end end)
		hooksecurefunc(cooldown, "SetCooldown", function(c) c:SetAlpha(.75) end)
	end

	local count = button.Count
	if (count) then
		count:SetParent(overlay)
		count:ClearAllPoints()
		count:SetPoint(unpack(db.ExtraButtonCountPosition))
		count:SetJustifyH(db.ExtraButtonCountJustifyH)
		count:SetJustifyV(db.ExtraButtonCountJustifyV)
		count:SetFontObject(db.ExtraButtonCountFont)
		count:SetTextColor(unpack(db.ExtraButtonCountColor))
	end

	local keybind = button.HotKey
	if (keybind) then
		keybind:SetParent(overlay)
		keybind:ClearAllPoints()
		keybind:SetPoint(unpack(db.ExtraButtonBindPosition))
		keybind:SetFontObject(db.ExtraButtonBindFont)
		keybind:SetJustifyH(db.ExtraButtonBindJustifyH)
		keybind:SetJustifyV(db.ExtraButtonBindJustifyV)
		keybind:SetShadowOffset(0, 0)
		keybind:SetShadowColor(0, 0, 0, 1)
		keybind:SetTextColor(unpack(db.ExtraButtonBindColor))
		keybind:SetText(GetBindingKey(button:GetName()))
	end

	if (not button.__GP_Icon) then
		local newIcon = button:CreateTexture(nil, "BACKGROUND", nil, 1)
		newIcon:SetPoint(unpack(db.ExtraButtonIconPosition))
		newIcon:SetSize(unpack(db.ExtraButtonIconSize))
		newIcon:SetMask(m)

		button.__GP_Icon = newIcon

		local oldIcon = button.icon or button.Icon
		button.__UpdateGPIcon = function() button.__GP_Icon:SetTexture(oldIcon:GetTexture()) end
		button:__UpdateGPIcon() -- Fix the empty border on reload problem.

		hooksecurefunc(oldIcon, "SetTexture", button.__UpdateGPIcon)
		hooksecurefunc(oldIcon, "Show", button.__UpdateGPIcon)
	end

	if (not button.__GP_Highlight) then
		local highlightTexture = button:CreateTexture(nil, "BACKGROUND", nil, 2)
		highlightTexture:SetAllPoints(button.__GP_Icon)
		highlightTexture:SetTexture(m)
		highlightTexture:SetVertexColor(1, 1, 1, .1)

		button.__GP_Highlight = highlightTexture

		button:SetHighlightTexture(button.__GP_Highlight)
	end

	if (not button.__GP_Border) then
		local border = button:CreateTexture(nil, "BORDER", nil, 1)
		border:SetPoint(unpack(db.ExtraButtonBorderPosition))
		border:SetSize(unpack(db.ExtraButtonBorderSize))
		border:SetTexture(db.ExtraButtonBorderTexture)
		border:SetVertexColor(unpack(db.ExtraButtonBorderColor))

		button.__GP_Border = border
	end

end

ExtraButtons.UpdateExtraButtons = function(self)
	local frame = ExtraActionBarFrame
	if (not frame) then
		return
	end
	for i = 1, frame:GetNumChildren() do
		local button = _G["ExtraActionButton"..i]
		if (button) then
			self:UpdateButton(button)
		end
	end
end

ExtraButtons.UpdateZoneButtons = function(self)
	local frame = ZoneAbilityFrame
	if (not frame) then
		return
	end
	if (frame.Style) then
		frame.Style:SetAlpha(0)
	end
	if (frame.SpellButtonContainer) then
		for button in frame.SpellButtonContainer:EnumerateActive() do
			if (button) then
				self:UpdateButton(button)
			end
		end
	end
end

ExtraButtons.UpdateBindings = function(self)
	if (self.ExtraButtons) then
		for button in pairs(self.ExtraButtons) do
			if (button.HotKey) then
				button.HotKey:SetText(GetBindingKey(button:GetName()))
			end
		end
	end
end

ExtraButtons.OnInitialize = function(self)
	local db = ns.Config.ExtraButtons

	local ExtraAbilityContainer, ExtraActionBarFrame = SetObjectScale(ExtraAbilityContainer), SetObjectScale(ExtraActionBarFrame)
	if (ExtraAbilityContainer and ExtraActionBarFrame) then
		local extraScaffold = SetObjectScale(CreateFrame("Frame", nil, UIParent))
		extraScaffold:SetFrameStrata("LOW")
		extraScaffold:SetFrameLevel(10)
		extraScaffold:SetPoint(unpack(db.ExtraActionButtonsPosition))
		extraScaffold:SetSize(unpack(db.ExtraButtonSize))

		-- This might go away in Dragonflight,
		-- as it's moved to a filed called UIParentOld.lua
		if (UIPARENT_MANAGED_FRAME_POSITIONS) then
			UIPARENT_MANAGED_FRAME_POSITIONS.ExtraAbilityContainer = nil
		end
		ExtraAbilityContainer.SetSize = noop
		ExtraAbilityContainer:SetFrameStrata("LOW")
		ExtraAbilityContainer:SetFrameLevel(10)
		ExtraActionBarFrame:SetParent(extraScaffold)
		ExtraActionBarFrame:ClearAllPoints()
		ExtraActionBarFrame:SetAllPoints()
		ExtraActionBarFrame:EnableMouse(false)
		ExtraActionBarFrame.ignoreInLayout = true
		ExtraActionBarFrame.ignoreFramePositionManager = true

		self.ExtraScaffold = extraScaffold
	end

	local ZoneAbilityFrame = SetObjectScale(ZoneAbilityFrame)
	if (ZoneAbilityFrame) then
		local zoneScaffold = SetObjectScale(CreateFrame("Frame", nil, UIParent))
		zoneScaffold:SetFrameStrata("LOW")
		zoneScaffold:SetFrameLevel(10)
		zoneScaffold:SetPoint(unpack(db.ZoneAbilityButtonsPosition))
		zoneScaffold:SetSize(unpack(db.ExtraButtonSize))

		ZoneAbilityFrame.SpellButtonContainer.holder = zoneScaffold
		ZoneAbilityFrame.SpellButtonContainer:SetFrameStrata("LOW")
		ZoneAbilityFrame:SetParent(zoneScaffold)
		ZoneAbilityFrame:ClearAllPoints()
		ZoneAbilityFrame:SetAllPoints()
		ZoneAbilityFrame:EnableMouse(false)
		ZoneAbilityFrame.ignoreInLayout = true
		ZoneAbilityFrame.ignoreFramePositionManager = true

		self.ZoneScaffold = zoneScaffold
		self:SecureHook(ZoneAbilityFrame, "UpdateDisplayedZoneAbilities", "UpdateZoneButtons")
	end

	if (not self.ExtraScaffold) and (not self.ZoneScaffold) then
		self:Disable()
	end
end

ExtraButtons.OnEnable = function(self)
	if (not self.ExtraScaffold) and (not self.ZoneScaffold) then
		return
	end
	self:UpdateExtraButtons()
	self:UpdateZoneButtons()
	self:UpdateBindings()
	self:RegisterEvent("UPDATE_BINDINGS", "UpdateBindings")
end
