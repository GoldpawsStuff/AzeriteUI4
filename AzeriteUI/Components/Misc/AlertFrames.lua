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
local AlertFrames = ns:NewModule("AlertFrames")

-- Lua API
local ipairs = ipairs
local table_remove = table.remove
local unpack = unpack

-- Addon API
local SetObjectScale = ns.API.SetObjectScale

local GroupLootContainer_PostUpdate = function(self)
	local db = ns.Config.AlertFrames
	local lastIdx = nil
	for i = 1, self.maxIndex do
		local frame = self.rollFrames[i]
		local prevFrame = self.rollFrames[i-1]
		if (frame) then
			frame:ClearAllPoints()
			if (prevFrame and prevFrame ~= frame) then
				frame:SetPoint(db.AlertFramesPoint, prevFrame, db.AlertFramesRelativePoint, 0, db.AlertFramesOffsetY)
			else
				frame:SetPoint(db.AlertFramesPoint, self, db.AlertFramesPoint, 0, 0)
			end
			lastIdx = i
		end
	end
	if (lastIdx) then
		self:SetHeight(self.reservedSize * lastIdx)
		self:Show()
	else
		self:Hide()
	end
end

local AlertSubSystem_AdjustAnchors = function(self, relativeAlert)
	local db = ns.Config.AlertFrames
	local alertFrame = self.alertFrame
	if (alertFrame and alertFrame:IsShown()) then
		alertFrame:ClearAllPoints()
		alertFrame:SetPoint(db.AlertFramesPoint, relativeAlert, db.AlertFramesRelativePoint, 0, db.AlertFramesOffsetY)
		return alertFrame
	end
	return relativeAlert
end

local AlertSubSystem_AdjustAnchorsNonAlert = function(self, relativeAlert)
	local db = ns.Config.AlertFrames
	local anchorFrame = self.anchorFrame
	if (anchorFrame and anchorFrame:IsShown()) then
		anchorFrame:ClearAllPoints()
		anchorFrame:SetPoint(db.AlertFramesPoint, relativeAlert, db.AlertFramesRelativePoint, 0, db.AlertFramesOffsetY)
		return anchorFrame
	end
	return relativeAlert
end

local AlertSubSystem_AdjustQueuedAnchors = function(self, relativeAlert)
	local db = ns.Config.AlertFrames
	for alertFrame in self.alertFramePool:EnumerateActive() do
		alertFrame:ClearAllPoints()
		alertFrame:SetPoint(db.AlertFramesPoint, relativeAlert, db.AlertFramesRelativePoint, 0, db.AlertFramesOffsetY)
		relativeAlert = alertFrame
	end
	return relativeAlert
end

local AlertSubSystem_AdjustPosition = function(alertFrame, subSystem)
	if (subSystem.alertFramePool) then --queued alert system
		subSystem.AdjustAnchors = AlertSubSystem_AdjustQueuedAnchors
	elseif (not subSystem.anchorFrame) then --simple alert system
		subSystem.AdjustAnchors = AlertSubSystem_AdjustAnchors
	elseif (subSystem.anchorFrame) then --anchor frame system
		subSystem.AdjustAnchors = AlertSubSystem_AdjustAnchorsNonAlert
	end
end

local AlertFrame_PostUpdateAnchors = function()
	local db = ns.Config.AlertFrames
	local AlertFrameHolder = _G[ns.Prefix.."AlertFrameHolder"]

	AlertFrameHolder:ClearAllPoints()
	AlertFrameHolder:SetPoint(unpack(TalkingHeadFrame and TalkingHeadFrame:IsShown() and db.AlertFramesPositionTalkingHead or db.AlertFramesPosition))

	AlertFrame:ClearAllPoints()
	AlertFrame:SetAllPoints(AlertFrameHolder)

	GroupLootContainer:ClearAllPoints()
	GroupLootContainer:SetPoint(db.AlertFramesPoint, AlertFrameHolder, db.AlertFramesRelativePoint, 0, db.AlertFramesOffsetY)

	if (GroupLootContainer:IsShown()) then
		GroupLootContainer_PostUpdate(GroupLootContainer)
	end
end

AlertFrames.OnInitialize = function(self)

	local db = ns.Config.AlertFrames

	local AlertFrameHolder = SetObjectScale(CreateFrame("Frame", ns.Prefix.."AlertFrameHolder", UIParent))
	AlertFrameHolder:SetPoint(unpack(db.AlertFramesPosition))
	AlertFrameHolder:SetSize(unpack(db.AlertFramesSize))

	local AlertFrame = SetObjectScale(AlertFrame, 1) -- might need to adjust
	AlertFrame.ignoreFramePositionManager = true
	AlertFrame:SetParent(UIParent)
	AlertFrame:OnLoad()

	for index,alertFrameSubSystem in ipairs(AlertFrame.alertFrameSubSystems) do
		AlertSubSystem_AdjustPosition(AlertFrame, alertFrameSubSystem)
		if (TalkingHeadFrame and TalkingHeadFrame == alertFrameSubSystem.anchorFrame) then
			table_remove(AlertFrame.alertFrameSubSystems, index)
		end
	end

	local GroupLootContainer = SetObjectScale(GroupLootContainer, 1) -- might need to adjust
	GroupLootContainer.ignoreFramePositionManager = true

	if (not ns.IsRetail) then
		UIPARENT_MANAGED_FRAME_POSITIONS["GroupLootContainer"] = nil
	end

	hooksecurefunc(AlertFrame, "AddAlertFrameSubSystem", AlertSubSystem_AdjustPosition)
	hooksecurefunc(AlertFrame, "UpdateAnchors", AlertFrame_PostUpdateAnchors)
	hooksecurefunc("GroupLootContainer_Update", GroupLootContainer_PostUpdate)

	if (TalkingHeadFrame) then
		TalkingHeadFrame:HookScript("OnShow", AlertFrame_PostUpdateAnchors)
		TalkingHeadFrame:HookScript("OnHide", AlertFrame_PostUpdateAnchors)
	end

end
