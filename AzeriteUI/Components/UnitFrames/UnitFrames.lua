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
local UnitFrames = ns:NewModule("UnitFrames", "LibMoreEvents-1.0")
local oUF = ns.oUF

-- Globally available registries
ns.NamePlates = {}
ns.ActiveNamePlates = {}
ns.UnitStyles = {}
ns.UnitFrames = {}
ns.UnitFramesByName = {}

-- Lua API
local string_format = string.format
local string_match = string.match
local table_insert = table.insert
local table_remove = table.remove

-- WoW API
local C_NamePlate = C_NamePlate
local CreateFrame = CreateFrame
local hooksecurefunc = hooksecurefunc
local InCombatLockdown = InCombatLockdown
local IsInInstance = IsInInstance
local SetCVar = SetCVar
local UnitIsUnit = UnitIsUnit

-- Addon API
local IsAddOnEnabled = ns.API.IsAddOnEnabled
local SetObjectScale = ns.API.SetObjectScale
local SetEffectiveObjectScale = ns.API.SetEffectiveObjectScale

-- Utility
-----------------------------------------------------
local Spawn = function(unit, name)
	local fullName = ns.Prefix.."UnitFrame"..name
	local frame = oUF:Spawn(unit, fullName)

	-- Vehicle switching is currently broken in Wrath.
	if (ns.IsWrath) then
		if (unit == "player") then

			local enable = frame.Enable
			frame.Enable = function(self)
				enable(self)
				frame:SetAttribute("toggleForVehicle", false)
				RegisterAttributeDriver(frame, "unit", "[vehicleui] vehicle; player")
			end

			local disable = frame.Disable
			frame.Disable = function(self)
				disable(self)
				UnregisterAttributeDriver(self, "unit")
			end

			frame:SetAttribute("toggleForVehicle", false)
			RegisterAttributeDriver(frame, "unit", "[vehicleui] vehicle; player")

		elseif (unit == "pet") then

			local enable = frame.Enable
			frame.Enable = function(self)
				enable(self)
				frame:SetAttribute("toggleForVehicle", false)
				RegisterAttributeDriver(frame, "unit", "[vehicleui] player; pet")
			end

			local disable = frame.Disable
			frame.Disable = function(self)
				disable(self)
				UnregisterAttributeDriver(self, "unit")
			end

			frame:SetAttribute("toggleForVehicle", false)
			RegisterAttributeDriver(frame, "unit", "[vehicleui] player; pet")
		end
	end

	-- Add to our registries.
	ns.UnitFramesByName[name] = frame
	ns.UnitFrames[#ns.UnitFrames + 1] = frame

	-- Inform the environment it was created.
	ns:Fire("UnitFrame_Created", unit, fullName)

	return frame
end

-- Styling
-----------------------------------------------------
local UnitSpecific = function(self, unit)
	local id, style
	if (unit == "player") then
		style = self:GetName():find("HUD") and "PlayerHUD" or "Player"

	elseif (unit == "target") then
		style = "Target"

	elseif (unit == "targettarget") then
		style = "ToT"

	elseif (unit == "pet") then
		style = "Pet"

	elseif (unit == "focus") then
		style = "Focus"

	elseif (unit == "focustarget") then
		style = "FocusTarget"

	elseif (string_match(unit, "party%d?$")) then
		id = string_match(unit, "party(%d)")
		style = "Party"

	elseif (string_match(unit, "raid%d+$")) then
		id = string_match(unit, "raid(%d+)")
		style = "Raid"

	elseif (string_match(unit, "boss%d?$")) then
		id = string_match(unit, "boss(%d)")
		style = "Boss"

	elseif (string_match(unit, "arena%d?$")) then
		id = string_match(unit, "arena(%d)")
		style = "Arena"

	elseif (string_match(unit, "nameplate%d+$")) then
		id = string_match(unit, "nameplate(%d+)")
		style = "NamePlate"
	end

	if (style and ns.UnitStyles[style]) then
		return ns.UnitStyles[style](self, unit, id)
	end
end

-- UnitFrame Callbacks
-----------------------------------------------------
local OnEnter = function(self, ...)
	self.isMouseOver = true
	if (self.OnEnter) then
		self:OnEnter(...)
	end
	if (self.isUnitFrame) then
		return _G.UnitFrame_OnEnter(self, ...)
	end
end

local OnLeave = function(self, ...)
	self.isMouseOver = nil
	if (self.OnLeave) then
		self:OnLeave(...)
	end
	if (self.isUnitFrame) then
		return _G.UnitFrame_OnLeave(self, ...)
	end
end

local OnHide = function(self, ...)
	self.isMouseOver = nil
	if (self.OnHide) then
		self:OnHide(...)
	end
end

local AddForceUpdate = function(self, func)
	if (not self._forceUpdates) then
		self._forceUpdates = {}
	end
	table_insert(self._forceUpdates, func)
end

local RemoveForceUpdate = function(self, func)
	if (not self._forceUpdates) then
		return
	end
	for i,updateFunc in next,self._forceUpdates do
		if (updateFunc == func) then
			table_remove(self._forceUpdates, i)
			break
		end
	end
end

local ForceUpdate = function(self)
	if (self._forceUpdates) then
		for _,updateFunc in next,self._forceUpdates do
			updateFunc(self)
		end
	end
	self:UpdateAllElements("ForceUpdate")
end

-- NamePlates
-----------------------------------------------------
local NamePlate_Cvars = {
	-- If these are enabled the GameTooltip will become protected,
	-- and all sort of taints and bugs will occur.
	-- This happens on specs that can dispel when hovering over nameplate auras.
	-- We create our own auras anyway, so we don't need these.
	["nameplateShowDebuffsOnFriendly"] = 0,

	["nameplateLargeTopInset"] = .15, -- default .1
	["nameplateOtherTopInset"] = .15, -- default .08
	["nameplateLargeBottomInset"] = .15, -- default .15
	["nameplateOtherBottomInset"] = .15, -- default .1
	["nameplateClassResourceTopInset"] = 0,

	-- new CVar July 14th 2020. Wohoo! Thanks torhaala for telling me! :)
	-- *has no effect in retail. probably for the classics only.
	["clampTargetNameplateToScreen"] = 1,

	-- Nameplate scale
	["nameplateMinScale"] = .6, -- .8
	["nameplateMaxScale"] = 1,
	["nameplateLargerScale"] = 1, -- Scale modifier for large plates, used for important monsters
	["nameplateGlobalScale"] = 1,
	["NamePlateHorizontalScale"] = 1,
	["NamePlateVerticalScale"] = 1,

	["nameplateOccludedAlphaMult"] = .15, -- .4
	["nameplateSelectedAlpha"] = 1, -- 1

	-- The maximum distance from the camera where plates will still have max scale and alpha
	["nameplateMaxScaleDistance"] = 10, -- 10

	-- The distance from the max distance that nameplates will reach their minimum scale.
	-- *seems to be a limit on how big this can be, too big resets to 1 it seems?
	["nameplateMinScaleDistance"] = 10, -- 10

	-- The minimum alpha of nameplates.
	["nameplateMinAlpha"] = .4, -- 0.6

	-- The distance from the max distance that nameplates will reach their minimum alpha.
	["nameplateMinAlphaDistance"] = 10, -- 10

	-- 	The max alpha of nameplates.
	["nameplateMaxAlpha"] = 1, -- 1

	-- The distance from the camera that nameplates will reach their maximum alpha.
	["nameplateMaxAlphaDistance"] = 30, -- 40

	-- Show nameplates above heads or at the base (0 or 2,
	["nameplateOtherAtBase"] = 0,

	-- Scale and Alpha of the selected nameplate (current target,
	["nameplateSelectedScale"] = 1, -- 1.2

	-- The max distance to show nameplates.
	--["nameplateMaxDistance"] = 60, -- 20 is classic upper limit, 60 is BfA default

	-- The max distance to show the target nameplate when the target is behind the camera.
	["nameplateTargetBehindMaxDistance"] = 15 -- 15
}

local NamePlate_Callback = function(self, event, unit)
	if (event == "PLAYER_TARGET_CHANGED") then
	elseif (event == "NAME_PLATE_UNIT_ADDED") then
		self.isPRD = UnitIsUnit(unit, "player")
		ns.NamePlates[self] = true
		ns.ActiveNamePlates[self] = true
	elseif (event == "NAME_PLATE_UNIT_REMOVED") then
		self.isPRD = nil
		ns.ActiveNamePlates[self] = nil
	end
end

-- Module API
-----------------------------------------------------
UnitFrames.RegisterStyles = function(self)

	oUF:RegisterStyle(ns.Prefix, function(self, unit)

		SetObjectScale(self)

		self.isUnitFrame = true
		self.colors = ns.Colors

		self:RegisterForClicks("LeftButtonDown", "RightButtonDown")
		self:SetScript("OnEnter", OnEnter)
		self:SetScript("OnLeave", OnLeave)
		self:SetScript("OnHide", OnHide)

		self.ForceUpdate = ForceUpdate
		self.AddForceUpdate = AddForceUpdate
		self.RemoveForceUpdate = RemoveForceUpdate

		return UnitSpecific(self, unit)
	end)

	oUF:RegisterStyle(ns.Prefix.."NamePlates", function(self, unit)

		SetEffectiveObjectScale(self)

		self.isNamePlate = true
		self.colors = ns.Colors

		self:SetPoint("CENTER",0,0)

		--self:SetScript("OnEnter", OnEnter)
		--self:SetScript("OnLeave", OnLeave)
		self:SetScript("OnHide", OnHide)

		--self:SetMouseMotionEnabled(true)
		--self:SetMouseClickEnabled(false)

		self.ForceUpdate = ForceUpdate
		self.AddForceUpdate = AddForceUpdate
		self.RemoveForceUpdate = RemoveForceUpdate

		return UnitSpecific(self, unit)
	end)

end

UnitFrames.RegisterMetaFunctions = function(self)
	local LibSmoothBar = LibStub("LibSmoothBar-1.0")
	local LibOrb = LibStub("LibOrb-1.0")

	oUF:RegisterMetaFunction("CreateBar", function(self, name, parent, ...)
		return LibSmoothBar:CreateSmoothBar(name, parent or self, ...)
	end)

	oUF:RegisterMetaFunction("CreateOrb", function(self, name, parent, ...)
		return LibOrb:CreateOrb(name, parent or self, ...)
	end)
end

UnitFrames.SpawnUnitFrames = function(self)
	oUF:Factory(function(oUF)
		oUF:SetActiveStyle(ns.Prefix)

		Spawn("player", "Player")
		Spawn("player", "PlayerHUD")
		Spawn("target", "Target")
		Spawn("targettarget", "TargetOfTarget")
		Spawn("pet", "Pet")
		Spawn("focus", "Focus")
	end)
end

UnitFrames.SpawnGroupFrames = function(self)
	oUF:Factory(function(oUF)
		oUF:SetActiveStyle(ns.Prefix)

		-- oUF:SpawnHeader(overrideName, overrideTemplate, visibility, attributes ...)
		--local party = oUF:SpawnHeader(nil, nil, "raid,party,solo",
		--		-- http://wowprogramming.com/docs/secure_template/Group_Headers
		--		-- Set header attributes
		--		"showParty", true,
		--		"showPlayer", true,
		--		"yOffset", -20
		--)
		--party:SetPoint("TOPLEFT", 30, -30)
	end)
end

UnitFrames.SpawnNamePlates = function(self)
	-- Bail out if any known nameplate addon is enabled.
	for addon in pairs({
		["Kui_Nameplates"] = true,
		["NamePlateKAI"] = true,
		["NeatPlates"] = true,
		["Plater"] = true,
		["SimplePlates"] = true,
		["TidyPlates"] = true,
		["TidyPlates_ThreatPlates"] = true,
		["TidyPlatesContinued"] = true
	}) do
		if (IsAddOnEnabled(addon)) then
			return
		end
	end
	oUF:Factory(function(oUF)
		oUF:SetActiveStyle(ns.Prefix.."NamePlates")
		oUF:SpawnNamePlates(ns.Prefix, NamePlate_Callback, NamePlate_Cvars)
		self:KillNamePlateClutter()

		local current

		local next = next
		local OnLeave, OnEnter = OnLeave, OnEnter
		local UnitExists, UnitIsUnit = UnitExists, UnitIsUnit

		local frame = CreateFrame("Frame")
		frame.elapsed = 0
		frame:SetScript("OnUpdate", function(self, elapsed)
			self.elapsed = self.elapsed - elapsed
			if (self.elapsed > 0) then return end
			self.elapsed = .05

			local hasMouseOver = UnitExists("mouseover")
			if (hasMouseOver) then
				if (current) then
					if (UnitIsUnit(current.unit, "mouseover")) then
						return
					end
					OnLeave(current)
					current = nil
				end
				local isMouseOver
				for frame in next,ns.ActiveNamePlates do
					isMouseOver = UnitIsUnit(frame.unit, "mouseover")
					if (isMouseOver) then
						current = frame
						return OnEnter(frame)
					end
				end
			elseif (current) then
				OnLeave(current)
				current = nil
			end

		end)

	end)
end

UnitFrames.SetNamePlateSizes = function()
	if (InCombatLockdown()) then return end

	local w,h = unpack(ns.Config.NamePlates.Size)
	C_NamePlate.SetNamePlateFriendlySize(w,h)
	C_NamePlate.SetNamePlateEnemySize(w,h)
	C_NamePlate.SetNamePlateSelfSize(w,h)
end

UnitFrames.SetNamePlateScales = function(self)
	for namePlate in pairs(ns.NamePlates) do
		SetEffectiveObjectScale(namePlate)
	end
end

UnitFrames.KillNamePlateClutter = function(self)
	local NamePlateDriverFrame = _G.NamePlateDriverFrame
	if (not NamePlateDriverFrame) then
		return
	end

	local BlizzPlateManaBar = ClassNameplateManaBarFrame -- NamePlateDriverFrame.classNamePlatePowerBar
	if (BlizzPlateManaBar) then
		BlizzPlateManaBar:SetAlpha(0)
	end

	if (NamePlateDriverFrame.UpdateNamePlateOptions) then
		hooksecurefunc(NamePlateDriverFrame, "UpdateNamePlateOptions", self.SetNamePlateSizes)
	end

end

UnitFrames.UpdateSettings = function(self)
	if (InCombatLockdown()) then return end

	local db = ns.db.global.unitframes

	local Player = ns.UnitFramesByName.Player
	if (db.enablePlayer and not Player:IsEnabled()) then
		Player:Enable()
	elseif (not db.enablePlayer and Player:IsEnabled()) then
		Player:Disable()
	end

	local PlayerHUD = ns.UnitFramesByName.PlayerHUD
	if (db.enablePlayerHUD and not PlayerHUD:IsEnabled()) then
		PlayerHUD:Enable()
	elseif (not db.enablePlayerHUD and PlayerHUD:IsEnabled()) then
		PlayerHUD:Disable()
	end

	local Target = ns.UnitFramesByName.Target
	if (db.enableTarget and not Target:IsEnabled()) then
		Target:Enable()
	elseif (not db.enableTarget and Target:IsEnabled()) then
		Target:Disable()
	end

	local ToT = ns.UnitFramesByName.ToT
	if (db.enableToT and not ToT:IsEnabled()) then
		ToT:Enable()
	elseif (not db.enableToT and ToT:IsEnabled()) then
		ToT:Disable()
	end

	local Focus = ns.UnitFramesByName.Focus
	if (db.enableFocus and not Focus:IsEnabled()) then
		Focus:Enable()
	elseif (not db.enableFocus and Focus:IsEnabled()) then
		Focus:Disable()
	end

	local Pet = ns.UnitFramesByName.Pet
	if (db.enablePet and not Pet:IsEnabled()) then
		Pet:Enable()
	elseif (not db.enablePet and Pet:IsEnabled()) then
		Pet:Disable()
	end

end

UnitFrames.ForceUpdate = function(self)
end

UnitFrames.OnEvent = function(self, event, ...)
	if (event == "PLAYER_ENTERING_WORLD") then
		local isInitialLogin, isReloadingUi = ...
		if (isInitialLogin or isReloadingUi) then
			self:UpdateSettings()
		end
		self:SetNamePlateScales()
	elseif (event == "VARIABLES_LOADED") then
		self:SetNamePlateScales()
	elseif (event == "UI_SCALE_CHANGED") or (event == "DISPLAY_SIZE_CHANGED") then
		self:SetNamePlateScales()
	end
end

UnitFrames.OnInitialize = function(self)
	self:RegisterMetaFunctions()
	self:RegisterStyles()
	self:SpawnUnitFrames()
	self:SpawnGroupFrames()
	self:SpawnNamePlates()
end

UnitFrames.OnEnable = function(self)
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:RegisterEvent("DISPLAY_SIZE_CHANGED", "OnEvent")
	self:RegisterEvent("UI_SCALE_CHANGED", "OnEvent")
	self:RegisterEvent("VARIABLES_LOADED", "OnEvent")
end
