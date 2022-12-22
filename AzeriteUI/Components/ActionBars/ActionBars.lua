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
local ActionBars = ns:NewModule("ActionBars", "AceConsole-3.0", "LibMoreEvents-1.0")

-- Lua API
local next = next
local string_lower = string.lower
local string_gsub = string.gsub
local string_split = string.split
local tonumber = tonumber

-- Addon API
local noop = ns.Noop

-- Button Metamethods
local button_mt = getmetatable(CreateFrame("CheckButton")).__index

ActionBars.RegisterButtonForFading = function(self, button, fadeGroup)
	if (self.fadeButtons[button]) then
		return
	end

	fadeGroup = fadeGroup or "default"

	if (not self.hoverCount[fadeGroup]) then
		self.hoverCount[fadeGroup] = 0
	end

	local methods = { OnEnter = button.OnEnter, OnLeave = button.OnLeave }

	button.SetAlpha = noop
	button.OnEnter = function(button)
		if (methods.OnEnter) then methods.OnEnter(button) end
		ns:Fire("ActionButton_FadeButton_Entering", button, self.fadeGroups[button])
	end
	button.OnLeave = function(button)
		if (methods.OnLeave) then methods.OnLeave(button) end
		ns:Fire("ActionButton_FadeButton_Leaving", button, self.fadeGroups[button])
	end

	self.fadeGroups[button] = fadeGroup
	self.fadeButtons[button] = methods
	self:UpdateFadeButtons()
end

ActionBars.UnregisterButtonForFading = function(self, button)
	if (not self.fadeButtons[button]) then
		return
	end

	button.SetAlpha = nil
	for method,func in next,self.fadeButtons[button] do
		button[method] = func
	end

	self.fadeGroups[button] = nil
	self.fadeButtons[button] = nil
	self:UpdateFadeButtons()
end

ActionBars.UpdateFadeButtons = function(self)
	if (not self.inWorld) then return end

	-- Something is forcing the buttons to be shown,
	-- like an item currently on the cursor.
	if (self.gridCounter >= 1) then
		for button in next,self.fadeButtons do
			button_mt.SetAlpha(button, 1)
		end

	-- Bar fading is disabled, just copying the default settings here.
	elseif (not self.enableBarFading) then
		for button in next,self.fadeButtons do

			-- The button has an action or grid set to visible.
			if (button:HasAction()) or (button.config and button.config.showGrid) or (button.parent and button.parent.config.showGrid) then
				button_mt.SetAlpha(button, 1)
			else
				button_mt.SetAlpha(button, 0)
			end
		end
	else
		-- Bar fading is enabled.
		for button in next,self.fadeButtons do

			-- The group is visible.
			if (self.hoverCount[self.fadeGroups[button]] > 0) then

				-- The button has an action or grid set to visible.
				if (button:HasAction()) or (button.config and button.config.showGrid) or (button.parent and button.parent.config.showGrid) then
					button_mt.SetAlpha(button, 1)
				else
					button_mt.SetAlpha(button, 0)
				end
			else
				-- Group is hidden, hide this.
				button_mt.SetAlpha(button, 0)
			end
		end
	end
end

ActionBars.SetButtons = function(self, input)
	if (InCombatLockdown()) then return end
	if (not input) then return end

	input = string_gsub(input, "%s+", " ")

	local args = { string_split(" ", input) }
	local barModName = args[1] == "1" and "Bar1" or args[1] == "2" and "Bar2"
	local barMod = barModName and self:GetModule(barModName, true)

	if (not barMod) then return end

	args[2] = tonumber(args[2])

	if (args[2] > 12) then
		args[2] = 12
	end

	if (args[1] == "1") then
		if (args[2] < 7) then
			args[2] = 7
		end
	elseif (args[1] == "2") then
		if (args[2] < 1) then
			args[2] = 1
		end
	end

	ns.db.global.actionbars["numButtons"..barModName] = args[2]

	barMod:UpdateSettings()
end

ActionBars.EnableBar = function(self, input)
	if (InCombatLockdown()) then return end

	local id = self:GetArgs(string_lower(input))
	local barModName = id == "1" and "Bar1" or id == "2" and "Bar2"
	local barMod = barModName and self:GetModule(barModName, true)

	if (not barMod) then return end

	ns.db.global.actionbars["enable"..barModName] = true

	barMod:UpdateSettings()
end

ActionBars.DisableBar = function(self, input)
	if (InCombatLockdown()) then return end

	local id = self:GetArgs(string_lower(input))
	local barModName = id == "1" and "Bar1" or id == "2" and "Bar2"
	local barMod = barModName and self:GetModule(barModName, true)

	if (not barMod) then return end

	ns.db.global.actionbars["enable"..barModName] = false

	barMod:UpdateSettings()
end

ActionBars.EnablePetBar = function(self)
	if (InCombatLockdown()) then return end

	local barMod = self:GetModule("PetBar", true)
	if (not barMod) then return end

	ns.db.global.actionbars.enablePetBar = true

	barMod:UpdateSettings()
end

ActionBars.DisablePetBar = function(self)
	if (InCombatLockdown()) then return end

	local barMod = self:GetModule("PetBar", true)
	if (not barMod) then return end

	ns.db.global.actionbars.enablePetBar = false

	barMod:UpdateSettings()
end

ActionBars.EnableStanceBar = function(self)
	if (InCombatLockdown()) then return end

	local barMod = self:GetModule("StanceBar", true)
	if (not barMod) then return end

	ns.db.global.actionbars.enableStanceBar = true

	barMod:UpdateSettings()
end

ActionBars.DisableStanceBar = function(self)
	if (InCombatLockdown()) then return end

	local barMod = self:GetModule("StanceBar", true)
	if (not barMod) then return end

	ns.db.global.actionbars.enableStanceBar = false

	barMod:UpdateSettings()
end

ActionBars.EnableBarFading = function(self)
	ns.db.global.actionbars.enableBarFading = true
	self.enableBarFading = true
	self:UpdateFadeButtons()
end

ActionBars.DisableBarFading = function(self)
	ns.db.global.actionbars.enableBarFading = false
	self.enableBarFading = false
	self:UpdateFadeButtons()
end

ActionBars.OnEvent = function(self, event, ...)
	if (event == "PLAYER_ENTERING_WORLD") then
		self.inWorld = true
		self.inCombat = nil

		for fadeGroup in next,self.hoverCount do
			self.hoverCount[fadeGroup] = 0
		end

	elseif (event == "PLAYER_REGEN_DISABLED") then
		self.inCombat = true

	elseif (event == "PLAYER_REGEN_ENABLED") then
		self.inCombat = nil

	elseif (event == "ACTIONBAR_SHOWGRID") then
		self.gridCounter = self.gridCounter + 1
		if (self.gridCounter >= 1) then
			return self:UpdateFadeButtons()
		end

	elseif (event == "ACTIONBAR_HIDEGRID") then
		if (self.gridCounter > 0) then
			self.gridCounter = self.gridCounter - 1
		end
		if (self.gridCounter == 0) then
			return self:UpdateFadeButtons()
		end

	elseif (event == "ActionButton_FadeButton_Entering") then
		local button, fadeGroup = ...
		self.hoverCount[fadeGroup] = self.hoverCount[fadeGroup] + 1

	elseif (event == "ActionButton_FadeButton_Leaving") then
		local button, fadeGroup = ...
		self.hoverCount[fadeGroup] = self.hoverCount[fadeGroup] - 1
	end
	self:UpdateFadeButtons()
end

ActionBars.OnInitialize = function(self)
	self.fadeButtons = {}
	self.fadeGroups = {}
	self.gridCounter = 0
	self.hoverCount = { default = 0 }
	self.enableBarFading = ns.db.global.actionbars.enableBarFading

	self:RegisterChatCommand("enablebar", "EnableBar")
	self:RegisterChatCommand("enablebarfade", "EnableBarFading")
	self:RegisterChatCommand("enablepetbar", "EnablePetBar")
	self:RegisterChatCommand("enablestancebar", "EnableStanceBar")

	self:RegisterChatCommand("disablebar", "DisableBar")
	self:RegisterChatCommand("disablebarfade", "DisableBarFading")
	self:RegisterChatCommand("disablepetbar", "DisablePetBar")
	self:RegisterChatCommand("disablestancebar", "DisableStanceBar")

	self:RegisterChatCommand("setbuttons", "SetButtons")

end

ActionBars.OnEnable = function(self)

	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnEvent")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	self:RegisterEvent("ACTIONBAR_SHOWGRID", "OnEvent")
	self:RegisterEvent("ACTIONBAR_HIDEGRID", "OnEvent")

	ns.RegisterCallback(self, "ActionButton_FadeButton_Entering", "OnEvent")
	ns.RegisterCallback(self, "ActionButton_FadeButton_Leaving", "OnEvent")
end
