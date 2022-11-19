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

-- Lua API
local ipairs = ipairs
local pairs = pairs
local select = select
local setmetatable = setmetatable
local string_format = string.format
local tostring = tostring

-- WoW API
local ClearOverrideBindings = ClearOverrideBindings
local CreateFrame = CreateFrame
local GetBindingKey = GetBindingKey
local InCombatLockdown = InCombatLockdown
local RegisterStateDriver = RegisterStateDriver

-- Addon API
local SetObjectScale = ns.API.SetObjectScale

-- Constants
local playerClass = ns.PlayerClass
local BOTTOMLEFT_ACTIONBAR_PAGE = BOTTOMLEFT_ACTIONBAR_PAGE -- 6
local BOTTOMRIGHT_ACTIONBAR_PAGE = BOTTOMRIGHT_ACTIONBAR_PAGE -- 5
local RIGHT_ACTIONBAR_PAGE = RIGHT_ACTIONBAR_PAGE -- 3
local LEFT_ACTIONBAR_PAGE = LEFT_ACTIONBAR_PAGE -- 4

ns.ActionBars = {}

local ActionBar = CreateFrame("Button")
local ActionBar_MT = { __index = ActionBar }
ns.ActionBar = ActionBar

ActionBar.CreateButton = function(self, id)

	local button = ns.ActionButton:Create(id, self:GetName().."Button"..(#self.buttons + 1), self)
	for k = 1,14 do
		button:SetState(k, "action", (k - 1) * 12 + id)
	end
	button:SetState(0, "action", (self.id - 1) * 12 + id)
	button:Show()
	button:SetAttribute("statehidden", nil)
	button:UpdateAction()

	self:SetFrameRef("Button"..(#self.buttons + 1), button)

	if (self.id == 1) then
		button.keyBoundTarget = string_format("ACTIONBUTTON%d", id)
	elseif (self.id == BOTTOMLEFT_ACTIONBAR_PAGE) then
		button.keyBoundTarget = string_format("MULTIACTIONBAR1BUTTON%d", id)
	elseif (self.id == BOTTOMRIGHT_ACTIONBAR_PAGE) then
		button.keyBoundTarget = string_format("MULTIACTIONBAR2BUTTON%d", id)
	elseif (self.id == RIGHT_ACTIONBAR_PAGE) then
		button.keyBoundTarget = string_format("MULTIACTIONBAR3BUTTON%d", id)
	elseif (self.id == LEFT_ACTIONBAR_PAGE) then
		button.keyBoundTarget = string_format("MULTIACTIONBAR4BUTTON%d", id)
	end

	local config = button.config or {}
	config.keyBoundTarget = button.keyBoundTarget

	button:UpdateConfig(config)

	self.buttons[#self.buttons + 1] = button

	return button
end

ActionBar.ForAll = function(self, method, ...)
	if (not self.buttons) then
		return
	end
	for _,button in self:GetAll() do
		local func = button[method]
		if (func) then
			func(button, ...)
		end
	end
end

ActionBar.GetAll = function(self)
	return pairs(self.buttons)
end

ActionBar.UpdateBindings = function(self)
	if (InCombatLockdown()) then
		return
	end
	if (not self.buttons) then
		return
	end
	ClearOverrideBindings(self)
	for id,button in ipairs(self.buttons) do
		local bindingAction = button.keyBoundTarget
		if (bindingAction) then

			-- iterate through the registered keys for the action
			local buttonName = button:GetName()
			for keyNumber = 1,select("#", GetBindingKey(bindingAction)) do

				-- get a key for the action
				local key = select(keyNumber, GetBindingKey(bindingAction))
				if (key and (key ~= "")) then

					-- this is why we need named buttons
					SetOverrideBindingClick(self, false, key, buttonName) -- assign the key to our own button
				end
			end
		end
	end
end

ActionBar.UpdateStateDriver = function(self)
	if (InCombatLockdown()) then
		return
	end

	local statedriver
	if (self.id == 1) then
		statedriver = "[overridebar][possessbar][shapeshift][bonusbar:5]possess; [form,noform] 0; [bar:2]2; [bar:3]3; [bar:4]4; [bar:5]5; [bar:6]6"

		if (playerClass == "DRUID") then
			statedriver = statedriver .. "; [bonusbar:1] 7; [bonusbar:2] 8; [bonusbar:3] 9; [bonusbar:4] 10"

		elseif (playerClass == "MONK") then
			statedriver = statedriver .. "; [bonusbar:1] 7; [bonusbar:2] 8; [bonusbar:3] 9"

		elseif (playerClass == "PRIEST") then
			if (not ns.IsRetail) then
				statedriver = statedriver .. "; [bonusbar:1] 7" -- Shadowform
			end
		elseif (playerClass == "ROGUE") then
			if (ns.IsWrath) then
				statedriver = statedriver .. "; [bonusbar:1] 7 [bonusbar:2] 8" -- Shadowdance
			else
				statedriver = statedriver .. "; [bonusbar:1] 7"
			end
		elseif (playerClass == "WARRIOR") then
			if (not ns.IsRetail) then
				statedriver = statedriver .. "; [bonusbar:1] 7; [bonusbar:2] 8; [bonusbar:3] 9"
			end
		end

		statedriver = statedriver .. "; 1"
	else
		statedriver = tostring(self.id)
	end

	UnregisterStateDriver(self, "page")
	self:SetAttribute("state-page", "0")
	RegisterStateDriver(self, "page", statedriver or "0")
end

ActionBar.UpdateVisibilityDriver = function(self)
	if (InCombatLockdown()) then
		return
	end

	local visdriver
	if (self.enabled) then
		if (self.id == 1) then
			visdriver = "[petbattle]hide;show"
		else
			visdriver = "[petbattle][possessbar][overridebar][vehicleui][@vehicle,exists]hide;show"
		end
	end

	UnregisterStateDriver(self, "vis")
	self:SetAttribute("state-vis", "0")
	RegisterStateDriver(self, "vis", visdriver or "hide")
end

ActionBar.Enable = function(self)
	if (InCombatLockdown()) then
		return
	end
	self.enabled = true
	self:UpdateStateDriver()
	self:UpdateVisibilityDriver()
end

ActionBar.Disable = function(self)
	if (InCombatLockdown()) then
		return
	end
	self.enabled = false
	self:UpdateVisibilityDriver()
end

ActionBar.IsEnabled = function(self)
	return self.enabled
end

-- Constructor
ActionBar.Create = function(self, id, name, parent)

	local bar = setmetatable(CreateFrame("Frame", name, parent, "SecureHandlerStateTemplate"), ActionBar_MT)
	bar:SetFrameStrata("BACKGROUND")
	bar:SetFrameLevel(10)
	bar:SetID(id)
	bar.id = id
	bar.buttons = {}

	bar:SetAttribute("UpdateVisibility", [[
		local visibility = self:GetAttribute("visibility");
		local userhidden = self:GetAttribute("userhidden");
		if (visibility == "show") then
			if (userhidden) then
				self:Hide();
			else
				self:Show();
			end
		elseif (visibility == "hide") then
			self:Hide();
		end
	]])

	bar:SetAttribute("_onstate-vis", [[
		if (not newstate) then
			return
		end
		self:SetAttribute("visibility", newstate);
		self:RunAttribute("UpdateVisibility");
	]])

	bar:SetAttribute("_onstate-page", [[
		if (newstate == "possess" or newstate == "11") then
			if (HasVehicleActionBar()) then
				newstate = GetVehicleBarIndex()
			elseif (HasOverrideActionBar()) then
				newstate = GetOverrideBarIndex()
			elseif (HasTempShapeshiftActionBar()) then
				newstate = GetTempShapeshiftBarIndex()
			elseif (HasBonusActionBar() and GetActionBarPage() == 1) then
				newstate = GetBonusBarIndex()
			else
				-- Is it a good idea to use this fallback?
				newstate = GetActionBarPage()
			end
			if not newstate then
				newstate = 12
			end
		end
		self:SetAttribute("state", newstate)
		control:ChildUpdate("state", newstate)
	]])

	-- Intended for external access by plugins
	ns.ActionBars[#ns.ActionBars + 1] = bar

	return bar
end
