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
local StanceBar = ActionBars:NewModule("StanceBar", "LibMoreEvents-1.0")
local KeyBound = LibStub("LibKeyBound-1.0")

-- WoW API
local CreateFrame = CreateFrame
local GetNumShapeshiftForms = GetNumShapeshiftForms
local InCombatLockdown = InCombatLockdown
local PlaySound = PlaySound

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

local handleOnClick = function(self)
	if (self.bar:IsShown()) then
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON, "SFX")
	else
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF, "SFX")
	end
end

local handleOnEnter = function(self)
end

local handleOnLeave = function(self)
end

local style = function(button)

	local db = ns.Config.StanceBar

	-- Clean up the button template
	for _,i in next,{ "AutoCastShine", "Border", "Name", "NewActionTexture", "NormalTexture", "SpellHighlightAnim", "SpellHighlightTexture",
		--[[ WoW10 ]] "CheckedTexture", "HighlightTexture", "BottomDivider", "RightDivider", "SlotArt", "SlotBackground" } do
		if (button[i] and button[i].Stop) then button[i]:Stop() elseif button[i] then button[i]:SetParent(UIHider) end
	end

	local normalTexture2 = _G[button:GetName().."NormalTexture2"]
	if (normalTexture2) then
		normalTexture2:SetParent(UIHider)
	end

	local m = db.ButtonMaskTexture
	local b = GetMedia("blank")

	button:SetAttribute("buttonLock", true)
	button:SetSize(unpack(db.ButtonSize))
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
	button.PushedTexture = pushedTexture

	button:SetPushedTexture(button.PushedTexture)
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

	RegisterCooldown(button.cooldown, button.cooldownCount)

	hooksecurefunc(cooldown, "SetSwipeTexture", function(c,t) if t ~= m then c:SetSwipeTexture(m) end end)
	hooksecurefunc(cooldown, "SetBlingTexture", function(c,t) if t ~= b then c:SetBlingTexture(b,0,0,0,0) end end)
	hooksecurefunc(cooldown, "SetEdgeTexture", function(c,t) if t ~= b then c:SetEdgeTexture(b) end end)
	--hooksecurefunc(cooldown, "SetSwipeColor", function(c,r,g,b,a) if not a or a>.76 then c:SetSwipeColor(r,g,b,.75) end end)
	hooksecurefunc(cooldown, "SetDrawSwipe", function(c,h) if not h then c:SetDrawSwipe(true) end end)
	hooksecurefunc(cooldown, "SetDrawBling", function(c,h) if h then c:SetDrawBling(false) end end)
	hooksecurefunc(cooldown, "SetDrawEdge", function(c,h) if h then c:SetDrawEdge(false) end end)
	hooksecurefunc(cooldown, "SetHideCountdownNumbers", function(c,h) if not h then c:SetHideCountdownNumbers(true) end end)
	hooksecurefunc(cooldown, "SetCooldown", function(c) c:SetAlpha(.75) end)

	if (not ns.IsRetail) then
		hooksecurefunc(button, "SetNormalTexture", function(b,...) if(...)then b:SetNormalTexture(nil) end end)
		hooksecurefunc(button, "SetHighlightTexture", function(b,...) if(...)then b:SetHighlightTexture(nil) end end)
		hooksecurefunc(button, "SetCheckedTexture", function(b,...) if(...)then b:SetCheckedTexture(nil) end end)
	end

	-- Disable masque for our buttons,
	-- they are not compatible.
	button.AddToMasque = noop
	button.AddToButtonFacade = noop
	button.LBFSkinned = nil
	button.MasqueSkinned = nil

	return button
end

StanceBar.SpawnBar = function(self)
	if (not self.Bar) then

		-- Create stance bar
		local scale = .8
		local bar = SetObjectScale(ns.StanceBar:Create(ns.Prefix.."StanceBar", UIParent), scale)
		bar:SetFrameStrata("BACKGROUND")
		bar:SetFrameLevel(1)
		bar:SetHeight(54)
		bar.scale = scale
		bar.customVisibilityDriver = "[petbattle][possessbar][@pet,exists,nopossessbar][overridebar][vehicleui][@vehicle,exists]hide;show"

		local button
		for id = 1,10 do
			button = bar:CreateButton(id, bar:GetName().."Button"..id)
			button:SetPoint("BOTTOMLEFT", (id-1)*(54), 0)
			bar:SetFrameRef("Button"..id, button)
			style(button)
		end

		bar:SetAttribute("showStanceBar", ns.db.char.actionbars.showStanceBar)
		bar.UpdateSettings = function(self)
			ns.db.char.actionbars.showStanceBar = self:GetAttribute("showStanceBar")
		end

		local onVisibility = function(self) ns:Fire("ActionBars_StanceBar_Updated", self:IsShown() and true or false) end
		bar:HookScript("OnHide", onVisibility)
		bar:HookScript("OnShow", onVisibility)

		-- Create pull-out handle
		local handle = SetObjectScale(CreateFrame("CheckButton", bar:GetName().."Handle", UIParent, "SecureHandlerClickTemplate"))
		handle:SetSize(64,12)
		handle:SetFrameStrata("MEDIUM")
		handle:RegisterForClicks("AnyUp")
		handle:SetHitRectInsets(-20, -20, -20, 0)
		handle:HookScript("OnClick", handleOnClick)
		handle:SetScript("OnEnter", handleOnEnter)
		handle:SetScript("OnLeave", handleOnLeave)
		handle.bar = bar

		local texture = handle:CreateTexture()
		texture:SetColorTexture(.5, 0, 0, .5)
		texture:SetAllPoints()
		handle.texture = texture

		-- Handle onclick handler triggering visibility changes
		handle:SetAttribute("_onclick", [[
			local stance = self:GetFrameRef("Bar");
			if (stance:IsShown()) then
				stance:SetAttribute("showStanceBar", false);
			else
				stance:SetAttribute("showStanceBar", true);
			end
			stance:CallMethod("UpdateSettings");
			stance:RunAttribute("UpdateVisibility");
		]])

		-- Handle visibility updater
		-- This is where the actualy visibility driver is applied.
		-- Can't rely only on macros, since we don't always have stances.
		handle:SetAttribute("UpdateVisibility", [[
			local bar = self:GetFrameRef("Bar");
			local driver = self:GetAttribute("visibility-driver");
			local newstate = SecureCmdOptionParse(driver);
			local numButtons = bar:GetAttribute("numButtons");
			UnregisterStateDriver(self, "visibility");
			if (numButtons and numButtons > 0 and newstate == "show") then
				RegisterStateDriver(self, "visibility", driver);
			else
				RegisterStateDriver(self, "visibility", "hide");
			end
		]])

		-- Handle position updater
		-- Triggered by the bar's UpdateVisibility attribute
		handle:SetAttribute("UpdatePosition", [[
			self:ClearAllPoints();
			local bar = self:GetFrameRef("Bar");
			if (bar:IsShown()) then
				self:SetPoint("BOTTOM", bar, "TOP", 0, 2);
			else
				self:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", offsetX, 0);
			end
			self:RunAttribute("UpdateVisibility");
		]])

		-- The handle's state handler reacting to visibility driver suggestions.
		handle:SetAttribute("_onstate-vis", [[
			if not newstate then return end
			self:RunAttribute("UpdatePosition");
		]])

		-- Custom visibility updater
		-- Also triggers handle position change
		bar:SetAttribute("UpdateVisibility", [[
			local driver = self:GetAttribute("visibility-driver");
			if not driver then return end

			local handle = self:GetFrameRef("Handle");
			local handleDriver = handle:GetAttribute("visibility-driver");
			if not handleDriver then return end

			local enabled = self:GetAttribute("showStanceBar");
			local showStance = SecureCmdOptionParse(driver) == "show";
			local showHandle = SecureCmdOptionParse(handleDriver) == "show";

			local numButtons = 0;
			local button;
			for i = 1,10 do
				button = self:GetFrameRef("Button"..i);
				if (button:IsShown()) then
					numButtons = numButtons + 1;
				end
			end
			self:SetAttribute("numButtons", numButtons);

			if (numButtons > 0) then
				self:SetWidth(numButtons*54 + (numButtons-1));
				self:SetHeight(54);
			else
				self:SetWidth(2);
				self:SetHeight(2);
			end

			if (numButtons > 0 and enabled and showStance) then
				self:Show();
			else
				self:Hide();
			end

			handle:RunAttribute("UpdatePosition");
		]])

		-- State handler reacting to visibility driver updates.
		bar:SetAttribute("_onstate-vis", [[
			if not newstate then return end
			self:RunAttribute("UpdateVisibility");
		]])

		-- Cross reference the bar and its handle
		bar:SetFrameRef("Handle", handle)
		handle:SetFrameRef("Bar", bar)

		handle:SetAttribute("visibility-driver", "[petbattle][possessbar][overridebar][vehicleui][@vehicle,exists]hide;show")
		RegisterStateDriver(handle, "vis", handle:GetAttribute("visibility-driver"))

		self.Bar = bar
		self.Bar.Handle = handle

	end

	self:UpdatePosition()
end

StanceBar.ForAll = function(self, method, ...)
	if (self.Bar) then
		self.Bar:ForAll(method, ...)
	end
end

StanceBar.GetAll = function(self)
	if (self.Bar) then
		return self.Bar:GetAll()
	end
end

StanceBar.UpdateBindings = function(self)
	if (self.Bar) then
		self.Bar:UpdateBindings()
	end
end

StanceBar.UpdatePosition = function(self)
	if (not self.Bar) then
		return
	end
	self.Bar:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOM", 380, (84 + ActionBars:GetBarOffset()) / self.Bar.scale)
end

StanceBar.UpdateStanceButtons = function(self)
	if (InCombatLockdown()) then
		self.updateStateOnCombatLeave = true
		return self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	end
	if (self.Bar) then
		self.Bar:UpdateButtons()
		self.Bar:Execute([[ self:RunAttribute("UpdateVisibility"); ]])
		local numStances = GetNumShapeshiftForms()
		if (numStances and numStances > 0) then
			self.Bar.Handle:Show()
		else
			self.Bar.Handle:Hide()
		end
	end
end

StanceBar.OnEvent = function(self, event, ...)
	if (event == "UPDATE_SHAPESHIFT_COOLDOWN") then
		self:ForAll("Update")

	elseif (event == "PLAYER_REGEN_ENABLED") then
		if (not InCombatLockdown()) then
			self:UnregisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
			if (self.updateStateOnCombatLeave) then
				self.updateStateOnCombatLeave = nil
				self:UpdateStanceButtons()
			end
		end
	else
		if (event == "PLAYER_ENTERING_WORLD") then
			local isInitialLogin, isReloadingUi = ...
			if (isInitialLogin or isReloadingUi) then
				self.Bar:Enable()
			end
		end
		self:ForAll("Update")
		self:UpdateStanceButtons()
	end
end

StanceBar.OnInitialize = function(self)
	if (not ns.db.global.core.enableDevelopmentMode) then
		self:Disable()
		return
	end
	self:SpawnBar()
end

StanceBar.OnEnable = function(self)

	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:RegisterEvent("UPDATE_BONUS_ACTIONBAR", "OnEvent")
	self:RegisterEvent("ACTIONBAR_PAGE_CHANGED", "OnEvent")
	self:RegisterEvent("UPDATE_SHAPESHIFT_FORM", "OnEvent")
	self:RegisterEvent("UPDATE_SHAPESHIFT_FORMS", "OnEvent")
	self:RegisterEvent("UPDATE_SHAPESHIFT_USABLE", "OnEvent")
	self:RegisterEvent("UPDATE_SHAPESHIFT_COOLDOWN", "OnEvent")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	self:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR", "OnEvent")
	self:RegisterEvent("UPDATE_OVERRIDE_ACTIONBAR", "OnEvent")
	self:RegisterEvent("UPDATE_POSSESS_BAR", "OnEvent")

	self:RegisterEvent("UPDATE_BINDINGS", "UpdateBindings")
	self:UpdateBindings()

	ns.RegisterCallback(self, "ActionBars_Artwork_Updated", "UpdatePosition")

end
