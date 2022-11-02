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
local Widgets = ns.Private.Widgets or {}
ns.Private.Widgets = Widgets

-- Lua API
local math_abs = math.abs
local next = next
local setmetatable = setmetatable
local string_format = string.format
local unpack = unpack

-- WoW API
local CreateFrame = CreateFrame
local InCombatLockdown = InCombatLockdown

-- Addon API
local Colors = ns.Colors
local GetFont = ns.API.GetFont
local GetPosition = ns.API.GetPosition
local GetScale = ns.API.GetScale
local SetObjectScale = ns.API.SetObjectScale
local UIHider = ns.Hider

-- Caches
local Anchors = {}

-- Compare two inprecise floats.
local compare = function(point, x, y, point2, x2, y2)
	return point == point and math_abs(x - x2) < 0.01 and math_abs(y - y2) < 0.01
end

-- Anchor Template
local Anchor = CreateFrame("Frame")
local Anchor_MT = { __index = Anchor }

-- Anchor API
--------------------------------------
-- Constructor
Anchor.Create = function(self, frame, savedPosition)

	local anchor = setmetatable(CreateFrame("Frame", nil, frame), Anchor_MT)
	anchor:Hide()
	anchor:SetIgnoreParentAlpha(true)
	anchor.frame = frame
	anchor.savedPosition = savedPosition or {}
	anchor.defaultPosition = { GetPosition(frame) }

	local overlay = anchor:CreateTexture(nil, "ARTWORK", nil, 1)
	overlay:SetAllPoints()
	overlay:SetColorTexture(.25, .5, 1, .5)
	anchor.Overlay = overlay

	local positionText = anchor:CreateFontString(nil, "OVERLAY", nil, 1)
	positionText:SetFontObject(GetFont(15,true))
	positionText:SetTextColor(unpack(Colors.highlight))
	positionText:SetIgnoreParentScale(true)
	positionText:SetScale(GetScale())
	positionText:SetPoint("CENTER")
	anchor.Text = positionText

	anchor:RegisterForClicks("RightButton")
	anchor:RegisterForDrag("LeftButton")
	anchor:SetScript("OnDragStart", Anchor.OnDragStart)
	anchor:SetScript("OnDragStop", Anchor.OnDragStop)
	anchor:SetScript("OnClick", Anchor.OnClick)
	anchor:SetScript("OnShow", Anchor.OnShow)
	anchor:SetScript("OnHide", Anchor.OnHide)
	anchor:SetScript("OnEnter", Anchor.OnEnter)
	anchor:SetScript("OnLeave", Anchor.OnLeave)

	Frame:RegisterEvent("PLAYER_REGEN_DISABLED")

	Anchors[#Anchors + 1] = anchor

	return anchor
end

-- 'true' if the frame has moved since last showing the anchor.
Anchor.HasMoved = function(self)
	local point, x, y = unpack(self.currentPosition)
	local point2, x2, y2 = unpack(self.lastPosition)
	return not compare(point, x, y, point2, x2, y2)
end

-- 'true' if the frame is in its default position.
Anchor.IsInDefaultPosition = function(self)
	local point, x, y = GetPosition(self)
	local point2, x2, y2 = unpack(self.defaultPosition)
	return compare(point, x, y, point2, x2, y2)
end

-- Reset to initial position after last showing the anchor.
Anchor.ResetLastChange = function(self)
	local point, x, y = unpack(self.lastPosition)

	-- Always reuse saved table, or it stops saving.
	self.savedPosition[1] = point
	self.savedPosition[2] = x
	self.savedPosition[3] = y

	self.currentPosition = { point, x, y }

	self.frame:ClearAllPoints()
	self.frame:SetPoint(point, UIParent, point, x, y)

	self:ClearAllPoints()
	self:SetPoint(point, UIParent, point, x, y)
	self:SetSize(width, height)
	self:UpdateText()
end

-- Reset to default position.
Anchor.ResetToDefault = function(self)
	local point, x, y = unpack(self.defaultPosition)

	-- Always reuse saved table, or it stops saving.
	self.savedPosition[1] = point
	self.savedPosition[2] = x
	self.savedPosition[3] = y

	self.currentPosition = { point, x, y }
	self.lastPosition = { point, x, y }

	self.frame:ClearAllPoints()
	self.frame:SetPoint(point, UIParent, point, x, y)

	self:ClearAllPoints()
	self:SetPoint(point, UIParent, point, x, y)
	self:SetSize(width, height)
	self:UpdateText()
end

-- Update display text on the anchor.
Anchor.UpdateText = function(self)
	local msg = string_format("%s, %.0f, %.0f", unpack(self.currentPosition))
	if (self:IsMouseOver()) then
		if (not self:IsInDefaultPosition()) then
			if (self:HasMoved()) then
				msg = msg .. Colors.green.colorCode.."\n<Right-Click to undo last change>|r"
			end
			msg = msg .. Colors.green.colorCode.."\n<Shift-Click to reset to default>|r"
		end
	end
	self.Text:Text(msg)
	if (self:IsDragging()) then
		self.Text:SetTextColor(unpack(Colors.normal))
	else
		self.Text:SetTextColor(unpack(Colors.highlight))
	end
end

-- Anchor Script Handlers
--------------------------------------
Anchor.OnClick = function(self, button)
	if (IsShiftKeyDown() and not self:IsInDefaultPosition()) then
		self:ResetToDefault()
	elseif (self:HasMoved()) then
		self:ResetLastChange()
	end
end

Anchor.OnDragStart = function(self, button)
	self:StartMoving()
	self:SetUserPlaced(false)
	self.elapsed = 0
	self:SetScript("OnUpdate", self.OnUpdate)
end

Anchor.OnDragStop = function(self)
	self:StopMovingOrSizing()
	self:SetScript("OnUpdate", nil)

	local point, x, y = GetPosition(self)
	self.currentPosition = { point, x, y }
	self:ClearAllPoints()
	self:SetPoint(point, UIParent, point, x, y)

	self.frame:ClearAllPoints()
	self.frame:SetPoint(point, UIParent, point, x, y)
end

Anchor.OnEnter = function(self)
	self:UpdateText()
end

Anchor.OnLeave = function(self)
	self:UpdateText()
end

Anchor.OnShow = function(self)
	local width, height = self.frame:GetSize()
	local point, x, y = GetPosition(self.frame)

	self.lastPosition = { point, x, y }
	self.currentPosition = { point, x, y }

	self:ClearAllPoints()
	self:SetPoint(point, UIParent, point, x, y)
	self:SetSize(width, height)
	self:UpdateText()
end

Anchor.OnHide = function(self)
	self:SetScript("OnUpdate", nil)
	self.elapsed = 0
end

Anchor.OnUpdate = function(self, elapsed)
	self.elapsed = self.elapsed + elapsed
	if (self.elapsed < 0.02) then
		return
	end
	self.elapsed = 0

	local point, x, y = GetPosition(self)

	-- Reuse old table here,
	-- or we'll spam the garbage handler.
	self.currentPosition[1] = point
	self.currentPosition[2] = x
	self.currentPosition[3] = y

	self:UpdateText()
end

-- Public API
--------------------------------------
Widgets.RegisterFrameForMovement = function(frame, db)
	return Anchor:Create(frame, db).savedPosition
end

Widgets.ShowMovableFrameAnchors = function()
	if (InCombatLockdown()) then return end
	for i,anchor in next,Anchors do
		anchor:Show()
	end
end

Widgets.HideMovableFrameAnchors = function()
	for i,anchor in next,Anchors do
		anchor:Hide()
	end
end

-- Keep anchors hidden in combat.
CreateFrame("Frame"):SetScript("OnEvent", function(self, event, ...)
	if (event == "PLAYER_REGEN_DISABLED") then
		Widgets:HideMovableFrameAnchors()
	end
end)
