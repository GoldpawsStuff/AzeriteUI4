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
local VehicleExit = ActionBars:NewModule("VehicleExit", "LibMoreEvents-1.0")

-- Lua API
local unpack = unpack

-- WoW API
local InCombatLockdown = InCombatLockdown
local IsMounted = IsMounted
local IsPossessBarVisible = IsPossessBarVisible
local PetCanBeDismissed = PetCanBeDismissed
local PetDismiss = PetDismiss
local TaxiRequestEarlyLanding = TaxiRequestEarlyLanding
local UnitOnTaxi = UnitOnTaxi

-- Addon API
local Colors = ns.Colors
local SetObjectScale = ns.API.SetObjectScale

ExitButton_OnEnter = function(self)
	if (GameTooltip:IsForbidden()) then return end

	GameTooltip_SetDefaultAnchor(GameTooltip, self)

	if (UnitOnTaxi("player")) then
		GameTooltip:AddLine(TAXI_CANCEL)
		GameTooltip:AddLine(TAXI_CANCEL_DESCRIPTION, unpack(Colors.green))
	elseif (IsMounted()) then
		GameTooltip:AddLine(BINDING_NAME_DISMOUNT)
	else
		if (IsPossessBarVisible() and PetCanBeDismissed()) then
			GameTooltip:AddLine(PET_DISMISS)
			GameTooltip:AddLine(NEWBIE_TOOLTIP_UNIT_PET_DISMISS, unpack(Colors.green))
		else
			GameTooltip:AddLine(BINDING_NAME_VEHICLEEXIT)
		end
	end
	GameTooltip:Show()
end

ExitButton_OnLeave = function(self)
	if (GameTooltip:IsForbidden()) then return end
	GameTooltip:Hide()
end

ExitButton_PostClick = function(self, button)
	if (UnitOnTaxi("player") and (not InCombatLockdown())) then
		TaxiRequestEarlyLanding()
	elseif (IsPossessBarVisible() and PetCanBeDismissed()) then
		PetDismiss()
	end
end

VehicleExit.OnInitialize = function(self)

	local db = ns.Config.VehicleExit

	local button = SetObjectScale(CreateFrame("CheckButton", ns.Prefix.."VehicleExitButton", UIParent, "SecureActionButtonTemplate"))
	button:SetFrameStrata("MEDIUM")
	button:SetFrameLevel(100)
	button:SetPoint(unpack(db.VehicleExitButtonPosition))
	button:SetSize(unpack(db.VehicleExitButtonSize))
	button:SetAttribute("type", "macro")
	button:SetScript("OnEnter", ExitButton_OnEnter)
	button:SetScript("OnLeave", ExitButton_OnLeave)
	button:SetScript("PostClick", ExitButton_PostClick)

	if (ns.IsRetail) then
		button:SetAttribute("macrotext", "/leavevehicle [@vehicle,canexitvehicle]\n/dismount [mounted]")
	else
		button:SetAttribute("macrotext", "/dismount [mounted]\n/run if CanExitVehicle() then VehicleExit() end")
	end

	RegisterStateDriver(bar, "visibility", "[@vehicle,canexitvehicle][possessbar][mounted]show;hide")

	local texture = button:CreateTexture(nil, "ARTWORK", nil, 1)
	button.texture:SetPoint(unpack(db.VehicleExitButtonTexturePosition))
	button.texture:SetSize(unpack(db.VehicleExitButtonSize))
	button.texture:SetTexture(db.VehicleExitButtonTexture)

	button.Texture = texture

end
