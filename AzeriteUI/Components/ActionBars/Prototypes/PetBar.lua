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

local PetBar = {}
local PetBar_MT = { __index = PetBar }
ns.PetBar = PetBar

PetBar.GetAll = function(self)
	return pairs(self.buttons)
end

PetBar.ForAll = function(self, method, ...)
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

PetBar.Create = function(self, name, parent)
	local bar = setmetatable(CreateFrame("Frame", name, parent, "SecureHandlerStateTemplate"), Bar_MT)
	local buttons = {}
	for id = 1,10 do
		buttons[id] = ActionBars:CreatePetButton(id, name.."Button"..id, bar)
	end
	bar.buttons = buttons

	return bar
end

