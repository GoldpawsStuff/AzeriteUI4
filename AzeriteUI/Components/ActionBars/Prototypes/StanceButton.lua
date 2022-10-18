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
local KeyBound = LibStub("LibKeyBound-1.0")

-- Lua API
local getmetatable = getmetatable
local pairs = pairs
local setmetatable = setmetatable
local type = type

-- WoW API
local CreateFrame = CreateFrame
local GameTooltip_SetDefaultAnchor = GameTooltip_SetDefaultAnchor
local GetBindingKey = GetBindingKey
local GetShapeshiftFormCooldown = GetShapeshiftFormCooldown
local GetShapeshiftFormInfo = GetShapeshiftFormInfo

-- StanceButton Template
local Button = CreateFrame("CheckButton")
local Button_MT = {__index = Button}

ns.StanceButtons = {}
ns.StanceButton = Button

Button.Create = function(self, id, parent)

	local name = ns.Prefix.."StanceButton"..id
	local button = setmetatable(CreateFrame("CheckButton", name, parent, "StanceButtonTemplate"), Button_MT)

	button:Hide()
	button:SetID(id)
	button.id = id
	button.parent = parent

	button.icon = button.icon
	button.autoCastShine = button.AutoCastShine
	button.border = button.Border
	button.cooldown = button.cooldown
	button.count = button.Count
	button.flash = button.Flash
	button.flyoutArrowContainer = button.FlyoutArrowContainer -- WoW10
	button.flyoutBorder = button.FlyoutBorder
	button.flyoutBorderShadow = button.FlyoutBorderShadow
	button.hotkey = button.HotKey
	button.levelLinkLockIcon = button.LevelLinkLockIcon -- Retail
	button.macro = button.Name
	button.newActionTexture = button.NewActionTexture
	button.normalTexture = button.NormalTexture
	button.normalTexture2 = _G[name.."NormalTexture2"]
	button.spellHighlightAnim = button.SpellHighlightAnim
	button.spellHighlightTexture = button.SpellHighlightTexture

	if (ns.WoW10) then
		button.checkedTexture = button.CheckedTexture
		button.highlightTexture = button.HighlightTexture
		button.pushedTexture = button.PushedTexture
	else
		button.checkedTexture = button:GetCheckedTexture()
		button.highlightTexture = button:GetHighlightTexture()
		button.pushedTexture = button:GetPushedTexture()
	end

	if (ns.WoW10) then
		button.bottomDivider = button.BottomDivider
		button.rightDivider = button.RightDivider
		button.slotArt = button.SlotArt
		button.slotBackground = button.SlotBackground
	end

	button:SetScript("OnEnter", Button.OnEnter)
	button:SetScript("OnLeave", Button.OnLeave)

	ns.StanceButtons[button] = true

	return button
end

Button.OnEnter = function(self)
	if (GameTooltip:IsForbidden()) then
		return
	end
	GameTooltip_SetDefaultAnchor(GameTooltip, self)
	GameTooltip:SetShapeshift(self:GetID())
	self.UpdateTooltip = self.OnEnter
end

Button.OnLeave = function(self)
	if (GameTooltip:IsForbidden()) then
		return
	end
	self.UpdateTooltip = nil
	GameTooltip:Hide()
end

Button.Update = function(self)
	if (not self:IsShown()) then
		return
	end
	local id = self:GetID()
	local texture, isActive, isCastable, spellID = GetShapeshiftFormInfo(id)

	self.icon:SetTexture(texture)

	if (texture) then
		self.cooldown:Show()
	else
		self.cooldown:Hide()
	end

	local start, duration, enable = GetShapeshiftFormCooldown(id)
	self.cooldown:SetCooldown(start, duration)

	if (isActive) then
		self:SetChecked(true)
	else
		self:SetChecked(false)
	end

	if (isCastable) then
		self.icon:SetVertexColor(1, 1, 1)
	else
		self.icon:SetVertexColor(.4, .4, .4)
	end

	self:UpdateHotkeys()

end

Button.UpdateHotkeys = function(self)
end

Button.UpdateHotkeys = function(self)
	local key = self:GetHotkey() or ""
	local hotkey = self.hotkey

	if key == "" or self.hidehotkey then
		hotkey:Hide()
	else
		hotkey:SetText(key)
		hotkey:Show()
	end
end

Button.GetHotkey = function(self)
	local key = GetBindingKey(format("SHAPESHIFTBUTTON%d", self:GetID()))
	return key and KeyBound:ToShortKey(key)
end

