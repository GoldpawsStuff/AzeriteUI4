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
if (not ns.IsRetail) then
	return
end

local EditMode = ns:NewModule("EditMode")

local IgnoreFrames = {
	MinimapCluster = true, -- header underneath and rotate minimap (will need to add the setting)
	GameTooltipDefaultContainer = true,

	-- UnitFrames
	--PartyFrame = true,
	PlayerFrame = true,
	TargetFrame = true,
	FocusFrame = true,
	PlayerCastingBarFrame = true,
	--ArenaEnemyFramesContainer = true,
	--CompactRaidFrameContainer = true,
	--BossTargetFrameContainer = true,

	-- Auras
	BuffFrame = true,
	DebuffFrame = true,

	-- ActionBars
	StanceBar = true,
	EncounterBar = true,
	PetActionBar = true,
	PossessActionBar = true,
	MainMenuBarVehicleLeaveButton = true,
	MultiBarBottomLeft = true,
	MultiBarBottomRight = true,
	MultiBarLeft = true,
	MultiBarRight = true,
	MultiBar5 = true,
	MultiBar6 = true,
	MultiBar7 = true
}

local ShutdownMode = {
	'OnEditModeEnter',
	'OnEditModeExit',
	'HasActiveChanges',
	'HighlightSystem',
	'SelectSystem',
	-- These not running will taint the default bars on spec switch
	--- 'IsInDefaultPosition',
	--- 'UpdateSystem',
}

EditMode.OnInitialize = function(self)
	local editMode = _G.EditModeManagerFrame

	-- Remove the initial registers
	local registered = editMode.registeredSystemFrames
	for i = #registered, 1, -1 do
		local frame = registered[i]
		local ignore = IgnoreFrames[frame:GetName()]
		if ignore and ignore() then
			for _, key in next, ShutdownMode do
				frame[key] = noop
			end
		end
	end

	-- Account settings will be tainted
	local mixin = editMode.AccountSettings
	mixin.RefreshCastBar = noop
	mixin.RefreshAuraFrame = noop
	mixin.RefreshBossFrames = noop
	--mixin.RefreshArenaFrames = noop

	-- RaidFrames
	--mixin.RefreshRaidFrames = noop
	--mixin.ResetRaidFrames = noop

	-- PartyFrames
	mixin.RefreshPartyFrames = noop
	mixin.ResetPartyFrames = noop

	-- Target and Focus Frames
	mixin.RefreshTargetAndFocus = noop
	mixin.ResetTargetAndFocus = noop

	-- ActionBars
	mixin.RefreshVehicleLeaveButton = noop
	mixin.RefreshActionBarShown = noop
	mixin.RefreshEncounterBar = noop

end
