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
local KeyBound = LibStub("LibKeyBound-1.0")

-- Lua API
local ipairs = ipairs
local pairs = pairs
local select = select
local setmetatable = setmetatable

-- WoW API
local ClearOverrideBindings = ClearOverrideBindings
local CreateFrame = CreateFrame
local GetBindingKey = GetBindingKey
local GetNumShapeshiftForms = GetNumShapeshiftForms
local InCombatLockdown = InCombatLockdown
local RegisterStateDriver = RegisterStateDriver
local SetOverrideBindingClick = SetOverrideBindingClick
local UnregisterStateDriver = UnregisterStateDriver

-- Addon API
local GetMedia = ns.API.GetMedia

local StanceBar = CreateFrame("Button")
local StanceBar_MT = { __index = StanceBar }
ns.StanceBar = StanceBar

StanceBar.CreateButton = function(self, id, name)

	local button = ns.StanceButton:Create(id, name, self)
	button.keyBoundTarget = "SHAPESHIFTBUTTON%d"..id

	self.buttons[#self.buttons + 1] = button

	return button
end

StanceBar.ForAll = function(self, method, ...)
	for id,button in self:GetAll() do
		local func = button[method]
		if (func) then
			func(button, ...)
		end
	end
end

StanceBar.GetAll = function(self)
	return pairs(self.buttons)
end

StanceBar.UpdateBindings = function(self)
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

StanceBar.UpdateButtons = function(self)
	if (InCombatLockdown()) then
		return
	end
	local buttons = self.buttons
	local numStances = GetNumShapeshiftForms()
	for i = 1, numStances do
		buttons[i]:Show()
		buttons[i]:Update()
	end
	for i = numStances+1, #buttons do
		buttons[i]:Hide()
	end
end

StanceBar.UpdateVisibilityDriver = function(self)
	if (InCombatLockdown()) then
		return
	end

	local visdriver
	if (self.enabled) then
		visdriver = self.customVisibilityDriver or "[petbattle][possessbar][overridebar][vehicleui][target=vehicle,exists]hide;show"
	end
	self:SetAttribute("visibility-driver", visdriver)

	UnregisterStateDriver(self, "state-vis")
	self:SetAttribute("state-vis", "0")
	RegisterStateDriver(self, "vis", visdriver or "hide")
end

StanceBar.Enable = function(self)
	if (InCombatLockdown()) then
		return
	end
	self.enabled = true
	self:UpdateButtons()
	self:UpdateVisibilityDriver()
end

StanceBar.Disable = function(self)
	if (InCombatLockdown()) then
		return
	end
	self.enabled = false
	self:UpdateVisibilityDriver()
end

StanceBar.IsEnabled = function(self)
	return self.enabled
end

-- Constructor
StanceBar.Create = function(self, name, parent)
	local bar = setmetatable(CreateFrame("Frame", name, parent, "SecureHandlerStateTemplate"), StanceBar_MT)
	bar:SetFrameStrata("BACKGROUND")
	bar:SetFrameLevel(10)
	bar:SetAttribute("_onstate-vis", [[
		if not newstate then return end
		if newstate == "show" then
			self:Show()
		elseif newstate == "hide" then
			self:Hide()
		end
	]])
	bar.buttons = {}

	return bar
end
