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
local UnitStyles = ns.UnitStyles
if (not UnitStyles) then
	return
end

-- Lua API
local getmetatable = getmetatable
local math_huge = math.huge
local pairs = pairs
local table_sort = table.sort
local unpack = unpack

-- WoW API
local CancelUnitBuff = CancelUnitBuff
local CreateFrame = CreateFrame
local HasPetUI = HasPetUI
local InCombatLockdown = InCombatLockdown
local UnitExists = UnitExists
local UnitIsUnit = UnitIsUnit

-- Addon API
local Colors = ns.Colors
local Config = ns.Config
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia
local IsAddOnEnabled = ns.API.IsAddOnEnabled

-- Constants
local _, PlayerClass = UnitClass("player")

-- Utility Functions
--------------------------------------------


-- Element Callbacks
--------------------------------------------


-- Frame Script Handlers
--------------------------------------------


-- Callbacks
--------------------------------------------


UnitStyles["Player"] = function(self, unit, id)

	self:SetSize(unpack(ns.Config.Player.Default.Size))
	self:SetPoint(unpack(ns.Config.Player.Default.Position))



end
