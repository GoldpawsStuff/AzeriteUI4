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
local PetBar = ActionBars:NewModule("PetBar", "LibMoreEvents-1.0")

-- Lua API
local pairs = pairs
local select = select
local setmetatable = setmetatable

-- WoW API
local ClearOverrideBindings = ClearOverrideBindings
local CreateFrame = CreateFrame
local GetBindingKey = GetBindingKey
local InCombatLockdown = InCombatLockdown
local PlaySound = PlaySound
local SetOverrideBindingClick = SetOverrideBindingClick

-- Addon API
local Colors = ns.Colors
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia
local RegisterCooldown = ns.Widgets.RegisterCooldown
local SetObjectScale = ns.API.SetObjectScale
local UIHider = ns.Hider
local noop = ns.Noop

local buttonOnEnter = function(self)
	self.icon.darken:SetAlpha(0)
	if (self.OnEnter) then
		self:OnEnter()
	end
end

local buttonOnLeave = function(self)
	self.icon.darken:SetAlpha(.1)
	if (self.OnLeave) then
		self:OnLeave()
	end
end

local style = function(button)

	local db = ns.Config.PetBar

	-- Clean up the button template
	for _,i in next,{ --[["AutoCastShine",]] "Border", "Name", "NewActionTexture", "NormalTexture", "SpellHighlightAnim", "SpellHighlightTexture",
		--[[ WoW10 ]] "CheckedTexture", "HighlightTexture", "BottomDivider", "RightDivider", "SlotArt", "SlotBackground" } do
		if (button[i] and button[i].Stop) then button[i]:Stop() elseif button[i] then button[i]:SetParent(UIHider) end
	end

	-- Wrath overwrites the default texture
	if (not ns.IsRetail) then
		button.AutoCastable = _G[button:GetName().."AutoCastable"]
		button.AutoCastShine = _G[button:GetName().."Shine"]
	end

	local m = db.ButtonMaskTexture
	local b = GetMedia("blank")

	button:SetAttribute("buttonLock", true)
	button:SetSize(unpack(db.ButtonSize))
	button:SetHitRectInsets(unpack(db.ButtonHitRects))
	button:SetNormalTexture("")
	button:SetHighlightTexture("")
	button:SetCheckedTexture("")

	-- Custom slot texture
	local backdrop = button:CreateTexture(nil, "BACKGROUND", nil, -7)
	backdrop:SetSize(unpack(db.ButtonBackdropSize))
	backdrop:SetPoint(unpack(db.ButtonBackdropPosition))
	backdrop:SetTexture(db.ButtonBackdropTexture)
	backdrop:SetVertexColor(unpack(db.ButtonBackdropColor))
	button.backdrop = backdrop

	-- Icon
	local icon = button.icon
	icon:SetDrawLayer("BACKGROUND", 1)
	icon:ClearAllPoints()
	icon:SetPoint(unpack(db.ButtonIconPosition))
	icon:SetSize(unpack(db.ButtonIconSize))
	if (ns.IsRetail) then icon:RemoveMaskTexture(button.IconMask) end
	icon:SetMask(m)

	-- Custom icon darkener
	local darken = button:CreateTexture(nil, "BACKGROUND", nil, 2)
	darken:SetAllPoints(button.icon)
	darken:SetTexture(m)
	darken:SetVertexColor(0, 0, 0, .1)
	button.icon.darken = darken

	button:SetScript("OnEnter", buttonOnEnter)
	button:SetScript("OnLeave", buttonOnLeave)

	-- Button is pushed
	-- Responds to mouse and keybinds
	-- if we allow blizzard to handle it.
	local pushedTexture = button:CreateTexture(nil, "ARTWORK", nil, 1)
	pushedTexture:SetVertexColor(1, 1, 1, .05)
	pushedTexture:SetTexture(m)
	pushedTexture:SetAllPoints(button.icon)
	button.pushedTexture = pushedTexture

	button:SetPushedTexture(button.pushedTexture)
	button:GetPushedTexture():SetBlendMode("ADD")
	button:GetPushedTexture():SetDrawLayer("ARTWORK", 1)

	-- Autoattack flash
	local flash = button.Flash
	flash:SetDrawLayer("ARTWORK", 2)
	flash:SetAllPoints(icon)
	flash:SetVertexColor(1, 0, 0, .25)
	flash:SetTexture(m)
	flash:Hide()

	-- Button cooldown frame
	local cooldown = button.cooldown
	cooldown:SetFrameLevel(button:GetFrameLevel() + 1)
	cooldown:ClearAllPoints()
	cooldown:SetAllPoints(button.icon)
	cooldown:SetReverse(false)
	cooldown:SetSwipeTexture(m)
	cooldown:SetDrawSwipe(true)
	cooldown:SetBlingTexture(b, 0, 0, 0, 0)
	cooldown:SetDrawBling(false)
	cooldown:SetEdgeTexture(b)
	cooldown:SetDrawEdge(false)
	cooldown:SetHideCountdownNumbers(true)

	-- Custom overlay frame
	local overlay = CreateFrame("Frame", nil, button)
	overlay:SetFrameLevel(button:GetFrameLevel() + 3)
	overlay:SetAllPoints()
	button.overlay = overlay

	local border = overlay:CreateTexture(nil, "BORDER", nil, 1)
	border:SetPoint(unpack(db.ButtonBorderPosition))
	border:SetSize(unpack(db.ButtonBorderSize))
	border:SetTexture(db.ButtonBorderTexture)
	border:SetVertexColor(unpack(db.ButtonBorderColor))
	button.iconBorder = border

	-- Custom spell highlight
	local spellHighlight = overlay:CreateTexture(nil, "ARTWORK", nil, -7)
	spellHighlight:SetTexture(db.ButtonSpellHighlightTexture)
	spellHighlight:SetSize(unpack(db.ButtonSpellHighlightSize))
	spellHighlight:SetPoint(unpack(db.ButtonSpellHighlightPosition))
	spellHighlight:Hide()
	button.spellHighlight = spellHighlight

	-- Custom cooldown count
	local cooldownCount = overlay:CreateFontString(nil, "ARTWORK", nil, 1)
	cooldownCount:SetPoint(unpack(db.ButtonCooldownCountPosition))
	cooldownCount:SetFontObject(db.ButtonCooldownCountFont)
	cooldownCount:SetJustifyH(db.ButtonCooldownCountJustifyH)
	cooldownCount:SetJustifyV(db.ButtonCooldownCountJustifyV)
	cooldownCount:SetTextColor(unpack(db.ButtonCooldownCountColor))
	button.cooldownCount = cooldownCount

	-- Button charge/stack count
	local count = button.Count
	count:SetParent(overlay)
	count:SetDrawLayer("OVERLAY", 1)
	count:ClearAllPoints()
	count:SetPoint(unpack(db.ButtonCountPosition))
	count:SetFontObject(db.ButtonCountFont)
	count:SetJustifyH(db.ButtonCountJustifyH)
	count:SetJustifyV(db.ButtonCountJustifyV)

	-- Button keybind
	local hotkey = button.HotKey
	hotkey:SetParent(overlay)
	hotkey:SetDrawLayer("OVERLAY", 1)
	hotkey:ClearAllPoints()
	hotkey:SetPoint(unpack(db.ButtonKeybindPosition))
	hotkey:SetJustifyH(db.ButtonKeybindJustifyH)
	hotkey:SetJustifyV(db.ButtonKeybindJustifyV)
	hotkey:SetFontObject(db.ButtonKeybindFont)
	hotkey:SetTextColor(unpack(db.ButtonKeybindColor))

	-- Todo: Adjust size of this.
	local autoCastable = button.AutoCastable
	autoCastable:SetParent(overlay)
	autoCastable:ClearAllPoints()
	autoCastable:SetPoint(unpack(db.ButtonAutoCastablePosition))
	autoCastable:SetSize(unpack(db.ButtonAutoCastableSize))

	-- Todo: Check if I should add a round texture here
	local autoCastShine = button.AutoCastShine
	autoCastShine:SetParent(overlay)
	autoCastShine:ClearAllPoints()
	autoCastShine:SetPoint(unpack(db.ButtonAutoCastShinePosition))
	autoCastShine:SetSize(unpack(db.ButtonAutoCastShineSize))

	RegisterCooldown(button.cooldown, button.cooldownCount)

	hooksecurefunc(cooldown, "SetSwipeTexture", function(c,t) if t ~= m then c:SetSwipeTexture(m) end end)
	hooksecurefunc(cooldown, "SetBlingTexture", function(c,t) if t ~= b then c:SetBlingTexture(b,0,0,0,0) end end)
	hooksecurefunc(cooldown, "SetEdgeTexture", function(c,t) if t ~= b then c:SetEdgeTexture(b) end end)
	hooksecurefunc(cooldown, "SetSwipeColor", function(c,r,g,b,a) if not a or a>.76 then c:SetSwipeColor(r,g,b,.75) end end)
	hooksecurefunc(cooldown, "SetDrawSwipe", function(c,h) if not h then c:SetDrawSwipe(true) end end)
	hooksecurefunc(cooldown, "SetDrawBling", function(c,h) if h then c:SetDrawBling(false) end end)
	hooksecurefunc(cooldown, "SetDrawEdge", function(c,h) if h then c:SetDrawEdge(false) end end)
	hooksecurefunc(cooldown, "SetHideCountdownNumbers", function(c,h) if not h then c:SetHideCountdownNumbers(true) end end)
	hooksecurefunc(cooldown, "SetCooldown", function(c) c:SetAlpha(.75) end)

	if (not ns.IsRetail) then
		hooksecurefunc(button, "SetNormalTexture", function(b,...) if(...~="")then b:SetNormalTexture("") end end)
		hooksecurefunc(button, "SetHighlightTexture", function(b,...) if(...~="")then b:SetHighlightTexture("") end end)
		hooksecurefunc(button, "SetCheckedTexture", function(b,...) if(...~="")then b:SetCheckedTexture("") end end)
	end

	-- Disable masque for our buttons,
	-- they are not compatible.
	button.AddToMasque = noop
	button.AddToButtonFacade = noop
	button.LBFSkinned = nil
	button.MasqueSkinned = nil

	return button
end

PetBar.SpawnBar = function(self)
	if (not self.Bar) then

		local db = ns.Config.PetBar

		local bar = SetObjectScale(ns.PetBar:Create(ns.Prefix.."PetActionBar", UIParent))
		bar:SetPoint(unpack(db.Position))
		bar:SetSize(unpack(db.Size))

		local button
		for id = 1,10 do
			button = bar:CreateButton(id, bar:GetName().."Button"..id)
			button:SetPoint(unpack(db.ButtonPositions[id]))
			bar:SetFrameRef("Button"..id, button)
			style(button)
		end

		local onVisibility = function(self) ns:Fire("ActionBars_PetBar_Updated", self:IsShown() and true or false) end
		bar:HookScript("OnHide", onVisibility)
		bar:HookScript("OnShow", onVisibility)

		self.Bar = bar
	end
end

PetBar.ForAll = function(self, method, ...)
	if (self.Bar) then
		self.Bar:ForAll(method, ...)
	end
end

PetBar.GetAll = function(self)
	if (self.Bar) then
		return self.Bar:GetAll()
	end
end

PetBar.UpdateBindings = function(self)
	if (self.Bar) then
		self.Bar:UpdateBindings()
	end
end

PetBar.UpdateSettings = function(self, event)
	if (not self.Bar) then
		return
	end
	if (ns.db.global.actionbars.enablePetBar) then
		self.Bar:Enable()

		for i,button in next,self.Bar.buttons do
			button:Show()
			button:SetAttribute("statehidden", nil)
			ActionBars:RegisterButtonForFading(button, "pet")
		end
	else
		self.Bar:Disable()
	end
end

PetBar.OnEvent = function(self, event, ...)

	if event == "PET_BAR_UPDATE" or event == "PET_BAR_UPDATE_USABLE" or event == "PET_SPECIALIZATION_CHANGED" or
	  (event == "UNIT_PET" and arg1 == "player") or
	 ((event == "UNIT_FLAGS" or event == "UNIT_AURA") and arg1 == "pet") or
	   event == "PLAYER_CONTROL_LOST" or event == "PLAYER_CONTROL_GAINED" or event == "PLAYER_FARSIGHT_FOCUS_CHANGED" or
	   event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_MOUNT_DISPLAY_CHANGED"
	then
		self:ForAll("Update")

	elseif (event == "PET_BAR_UPDATE_COOLDOWN") then
		self:ForAll("UpdateCooldown")

	elseif (event == "PET_BAR_SHOWGRID") then
		self:ForAll("ShowGrid")

	elseif (event == "PET_BAR_HIDEGRID") then
		self:ForAll("HideGrid")

	elseif (event == "PLAYER_ENTERING_WORLD") then
		local isInitialLogin, isReloadingUi = ...
		if (isInitialLogin or isReloadingUi) then
			self:UpdateSettings()
		end
	end
end

PetBar.OnInitialize = function(self)
	if (not ns.db.global.core.enableDevelopmentMode) then
		self:Disable()
		return
	end
	self:SpawnBar()
end

PetBar.OnEnable = function(self)

	self:RegisterEvent("PLAYER_CONTROL_LOST", "OnEvent")
	self:RegisterEvent("PLAYER_CONTROL_GAINED", "OnEvent")
	self:RegisterEvent("PLAYER_FARSIGHT_FOCUS_CHANGED", "OnEvent")
	self:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED", "OnEvent")
	self:RegisterEvent("PLAYER_TARGET_CHANGED", "OnEvent")
	self:RegisterEvent("UNIT_PET", "OnEvent")
	self:RegisterEvent("UNIT_FLAGS", "OnEvent")
	self:RegisterEvent("UNIT_AURA", "OnEvent")
	self:RegisterEvent("PET_BAR_UPDATE", "OnEvent")
	self:RegisterEvent("PET_BAR_UPDATE_COOLDOWN", "OnEvent")
	self:RegisterEvent("PET_BAR_UPDATE_USABLE", "OnEvent")
	self:RegisterEvent("PET_BAR_SHOWGRID", "OnEvent")
	self:RegisterEvent("PET_BAR_HIDEGRID", "OnEvent")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")

	if (ns.IsRetail) then
		self:RegisterEvent("PET_SPECIALIZATION_CHANGED", "OnEvent")
	end

	self:RegisterEvent("UPDATE_BINDINGS", "UpdateBindings")
	self:UpdateBindings()

end
