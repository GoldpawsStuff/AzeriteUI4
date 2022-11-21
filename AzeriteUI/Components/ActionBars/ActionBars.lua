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
local ActionBars = ns:NewModule("ActionBars", "LibMoreEvents-1.0")

-- Lua API
local next = next

-- Addon API
local noop = ns.Noop

-- Button Metamethods
local button_mt = getmetatable(CreateFrame("CheckButton")).__index

ActionBars.RegisterButtonForFading = function(self, button)
	if (self.fadeButtons[button]) then
		return
	end
	button.SetAlpha = noop
	self.fadeButtons[button] = true
	self:UpdateFadeButtons()
end

ActionBars.UnregisterButtonForFading = function(self, button)
	if (not self.fadeButtons[button]) then
		return
	end
	button.SetAlpha = nil
	self.fadeButtons[button] = nil
	self:UpdateFadeButtons()
end

ActionBars.UpdateFadeButtons = function(self)
	if (not self.inWorld) then return end
	local show = self.inCombat or self.isMouseOver > 0
	for button in next,self.fadeButtons do
		button_mt.SetAlpha(button, show and 1 or 0)
	end
end

ActionBars.OnEvent = function(self, event, ...)
	if (event == "PLAYER_ENTERING_WORLD") then
		self.isMouseOver = 0
		self.inCombat = nil
		self.inWorld = true

	elseif (event == "PLAYER_REGEN_DISABLED") then
		self.inCombat = true

	elseif (event == "PLAYER_REGEN_ENABLED") then
		self.inCombat = nil

	elseif (event == "ActionButton_FadeButton_Entering") then
		self.isMouseOver = self.isMouseOver + 1

	elseif (event == "ActionButton_FadeButton_Leaving") then
		self.isMouseOver = self.isMouseOver - 1
	end
	self:UpdateFadeButtons()
end

ActionBars.OnInitialize = function(self)
	self.fadeButtons = {}
	self.isMouseOver = 0
end

ActionBars.OnEnable = function(self)
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnEvent")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	ns.RegisterCallback(self, "ActionButton_FadeButton_Entering", "OnEvent")
	ns.RegisterCallback(self, "ActionButton_FadeButton_Leaving", "OnEvent")
end
