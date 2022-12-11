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
local API = ns.API or {}
ns.API = API

if (not EditModeManagerFrame) then
	API.KillEditMode = function() end
	return
end

local noop = function() end

API.KillEditMode = function(frame)
	frame.HighlightSystem = noop
	frame.ClearHighlight = noop
end

EditModeManagerFrame:UnregisterAllEvents()
EditModeManagerFrame:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
--hooksecurefunc(EditModeManagerFrame, "EnterEditMode", function() HideUIPanel(EditModeManagerFrame) end)

-- These will get tainted on ExitEditMode
local mixin = _G.EditModeManagerFrame.AccountSettings
mixin.RefreshTargetAndFocus = noop
mixin.RefreshPartyFrames = noop
mixin.RefreshRaidFrames = noop
mixin.RefreshActionBarShown = noop
mixin.RefreshCastBar = noop
mixin.RefreshEncounterBar = noop
mixin.RefreshExtraAbilities = noop
mixin.RefreshAuraFrame = noop
mixin.RefreshTalkingHeadFrame = noop
mixin.RefreshVehicleLeaveButton = noop
mixin.RefreshBossFrames = noop
mixin.RefreshArenaFrames = noop
mixin.RefreshLootFrame = noop
mixin.RefreshHudTooltip = noop
