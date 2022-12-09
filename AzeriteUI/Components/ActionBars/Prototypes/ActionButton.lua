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
local ButtonMod = ActionBars:NewModule("Buttons")
local LAB = LibStub("LibActionButton-1.0")
local LAB_Version = LibStub.minors["LibActionButton-1.0"]

-- Lua API
local next = next

-- WoW API
local IsSpellOverlayed = IsSpellOverlayed
local UnitIsDeadOrGhost = UnitIsDeadOrGhost

-- Addon API
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia
local IsAddOnEnabled = ns.API.IsAddOnEnabled
local SetObjectScale = ns.API.SetObjectScale
local RegisterCooldown = ns.Widgets.RegisterCooldown
local UIHider = ns.Hider
local noop = ns.Noop

-- Default button config
local buttonConfig = {
	outOfRangeColoring = "button",
	tooltip = "enabled",
	showGrid = false,
	colors = {
		range = { 1, .15, .15 },
		mana = { .25, .25, 1 },
		disabled = { .4, .36, .32 }
	},
	hideElements = {
		macro = true,
		hotkey = false,
		equipped = true,
		border = true,
		borderIfEmpty = true
	},
	keyBoundTarget = false,
	keyBoundClickButton = "LeftButton",
	clickOnDown = true,
	flyoutDirection = "UP"
}

local ActionButton = {}
ns.ActionButton = ActionButton
ns.ActionButtons = {}

-- Constructor
ActionButton.Create = function(self, id, name, header, config)

	local button = LAB:CreateButton(id, name, header, config or buttonConfig)

	ns.ActionButtons[button] = true

	return button
end

---------------------------------------------
-- LAB Overrides & MaxDps Integration
---------------------------------------------
local ShowMaxDps = function(self)
	if (self.SpellHighlight) then
		if (self.maxDpsGlowColor) then
			local r, g, b, a = unpack(self.maxDpsGlowColor)
			self.SpellHighlight:SetVertexColor(r, g, b, a or .75)
		else
			self.SpellHighlight:SetVertexColor(249/255, 188/255, 65/255, .75)
		end
		self.SpellHighlight:Show()
		LAB.callbacks:Fire("OnButtonShowOverlayGlow", self)
	end
end

local HideMaxDps = function(self)
	if (self.SpellHighlight) then
		if (not self.maxDpsGlowShown) then
			self.SpellHighlight:Hide()
			LAB.callbacks:Fire("OnButtonHideOverlayGlow", self)
		end
	end
end

local UpdateMaxDps = function(self)
	if (self.maxDpsGlowShown) then
		ShowMaxDps(self)
	else
		if (WoWWrath) then
			HideMaxDps(self)
		else
			local spellId = self:GetSpellId()
			if (spellId and IsSpellOverlayed(spellId)) then
				ShowMaxDps(self)
			else
				HideMaxDps(self)
			end
		end
	end
end

local UpdateUsable = function(self)

	if (UnitIsDeadOrGhost("player")) then
		self.icon:SetDesaturated(true)
		self.icon:SetVertexColor(unpack(buttonConfig.colors.disabled))

	elseif (self.outOfRange) then
		self.icon:SetDesaturated(true)
		self.icon:SetVertexColor(unpack(buttonConfig.colors.range))
	else
		local isUsable, notEnoughMana = self:IsUsable()
		if (isUsable) then
			self.icon:SetDesaturated(false)
			self.icon:SetVertexColor(1, 1, 1)

		elseif (notEnoughMana) then
			self.icon:SetDesaturated(true)
			self.icon:SetVertexColor(unpack(buttonConfig.colors.mana))
		else
			self.icon:SetDesaturated(true)
			self.icon:SetVertexColor(unpack(buttonConfig.colors.disabled))
		end
	end

	if (ns.IsRetail and self._state_type == "action") then
		local isLevelLinkLocked = C_LevelLink.IsActionLocked(self._state_action)
		if (not self.icon:IsDesaturated()) then
			self.icon:SetDesaturated(isLevelLinkLocked)
			if isLevelLinkLocked then
				self.icon:SetVertexColor(unpack(buttonConfig.colors.disabled))
			end
		end
		if (self.LevelLinkLockIcon) then
			self.LevelLinkLockIcon:SetShown(isLevelLinkLocked)
		end
	end

end

ButtonMod.HandleMaxDps = function(self)

	MaxDps:RegisterLibActionButton(LAB_Version)

	lib.MaxDps_GetTexture = lib.MaxDps_GetTexture or MaxDps.GetTexture
	lib.MaxDps_Glow = lib.MaxDps_Glow or MaxDps.Glow
	lib.MaxDps_HideGlow = lib.MaxDps_HideGlow  or MaxDps.HideGlow

	MaxDps.GetTexture = function() end

	MaxDps.Glow = function(this, button, id, texture, type, color)
		if (not ButtonRegistry[button]) then
			return lib.MaxDps_Glow(this, button, id, texture, type, color)
		end
		local col = color and { color.r, color.g, color.b, color.a } or nil
		if (not color) and (type) then
			if (type == "normal") then
				local c = this.db.global.highlightColor
				col = { c.r, c.g, c.b, c.a }

			elseif (type == "cooldown") then
				local c = this.db.global.cooldownColor
				col = { c.r, c.g, c.b, c.a }
			end
		end
		button.maxDpsGlowColor = col
		button.maxDpsGlowShown = true
		UpdateMaxDps(button)
	end

	MaxDps.HideGlow = function(this, button, id)
		if (not ButtonRegistry[button]) then
			return lib.MaxDps_HideGlow(this, button, id)
		end
		button.maxDpsGlowColor = nil
		button.maxDpsGlowShown = nil
		UpdateMaxDps(button)
	end

	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR", "OnEvent")
	self:RegisterEvent("UPDATE_SHAPESHIFT_FORM", "OnEvent")

	LAB.RegisterCallback(self, "OnButtonShowOverlayGlow", "OnEvent")
	LAB.RegisterCallback(self, "OnButtonHideOverlayGlow", "OnEvent")

	self.MaxDps = true
end

ButtonMod.OnEvent = function(self, event, ...)
	if (event == "ADDON_LOADED") then
		local addon = ...
		if (addon == "MaxDps") then
			self:UnregisterEvent("ADDON_LOADED", "OnEvent")
			self:HandleMaxDps()
		end

	elseif (event == "PLAYER_ENTERING_WORLD" or event == "UPDATE_VEHICLE_ACTIONBAR" or event == "UPDATE_SHAPESHIFT_FORM") then

		if (self.MaxDps) then
			for button in next, LAB.activeButtons do
				if (ns.ActionButtons[button]) then
					if (button.maxDpsGlowShown) then
						button.maxDpsGlowColor = nil
						button.maxDpsGlowShown = nil
						UpdateMaxDps(button)
					end
				end
			end
		end

	elseif (event == "OnButtonUsable") then
		local button = ...
		if (ns.ActionButtons[button]) then
			UpdateUsable(button)
		end

	elseif (event == "OnButtonUpdate") then
		local button = ...
		if (ns.ActionButtons[button]) then
			UpdateUsable(button)
			if (self.MaxDps) then
				if (not button:GetTexture()) then
					button.maxDpsGlowColor = nil
					button.maxDpsGlowShown = nil
				end
				UpdateMaxDps(button)
			end
		end

	elseif (event == "OnButtonHideOverlayGlow" or event == "OnButtonShowOverlayGlow") then
		local button = ...
		if (ns.ActionButtons[button]) then
			if (self.MaxDps) then
				UpdateMaxDps(button)
			end
		end
	end
end

ButtonMod.OnInitialize = function(self)

	if (MaxDps) then
		self:HandleMaxDps()
	elseif (IsAddOnEnabled("MaxDps")) then
		self:RegisterEvent("ADDON_LOADED", "OnEvent")
	end

	LAB.RegisterCallback(self, "OnButtonUsable", "OnEvent")
	LAB.RegisterCallback(self, "OnButtonUpdate", "OnEvent")
end