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
local MicroMenu = ActionBars:NewModule("MicroMenu", "LibMoreEvents-1.0", "AceHook-3.0")

-- Lua API
local ipairs = ipairs
local table_insert = table.insert

-- WoW API
local C_PetBattles = C_PetBattles
local CreateFrame = CreateFrame
local InCombatLockdown = InCombatLockdown
local IsAddOnLoaded = IsAddOnLoaded

-- Addon API
local SetObjectScale = ns.API.SetObjectScale
local IsAddOnEnabled = ns.API.IsAddOnEnabled

MicroMenu.UpdateButtonLayout = function(self, event)
	if (InCombatLockdown()) then
		return self:RegisterEvent("PLAYER_REGEN_ENABLED", "UpdateButtonLayout")
	end
	if (event == "PLAYER_REGEN_ENABLED") then
		if (InCombatLockdown()) then
			return
		else
			self:UnregisterEvent(event, "UpdateButtonLayout")
		end
	end

	local db = ns.Config.MicroMenu

	local bar, custom, buttons = self.bar, self.bar.custom, self.bar.buttons
	local visible, first, last = 0

	for i,v in ipairs(buttons) do

		local b = custom[v]
		if (v and v:IsShown()) then

			local position = { unpack(db.MicroMenuPosition) }
			position[#position] = position[#position] + (i-1)*db.MicroMenuButtonSize[2]

			b:SetPoint(unpack(position))

			visible = visible + 1
			if (not first) then
				first = b
			end
			last = b
		end

	end

	local backdrop = bar.backdrop
	backdrop:SetPoint("RIGHT", custom[buttons[1]], "RIGHT", db.MicroMenuBackdropOffsetRight, 0)
	backdrop:SetPoint("BOTTOM", custom[buttons[1]], "BOTTOM", 0, db.MicroMenuBackdropOffsetBottom)
	backdrop:SetPoint("LEFT", custom[buttons[1]], "LEFT", db.MicroMenuBackdropOffsetLeft, 0)
	backdrop:SetPoint("TOP", custom[buttons[#buttons]], "TOP", 0, db.MicroMenuBackdropOffsetTop)

end

MicroMenu.UpdateMicroButtonsParent = function(self, parent)
	if (parent == self.bar) then
		self.ownedByUI = false
		return
	end
	if parent and (parent == (PetBattleFrame and PetBattleFrame.BottomFrame.MicroButtonFrame)) then
		self.ownedByUI = true
		self:BlizzardBarShow()
		return
	end
	self.ownedByUI = false
	self:MicroMenuBarShow()
end

MicroMenu.MicroMenuBarShow = function(self, event)
	if (InCombatLockdown()) then
		return self:RegisterEvent("PLAYER_REGEN_ENABLED", "MicroMenuBarShow")
	end
	if (event == "PLAYER_REGEN_ENABLED") then
		self:UnregisterEvent(event, "MicroMenuBarShow")
	end
	if (not self.ownedByUI) then

		local bar = self.bar

		UpdateMicroButtonsParent(bar)

		for i,v in ipairs(bar.buttons) do

			-- Show our layers
			local b = bar.custom[v]

			-- Hide blizzard layers
			SetObjectScale(v)
			v:SetAlpha(0)
			v:SetSize(b:GetSize())
			v:SetHitRectInsets(0,0,0,0)

			-- Update button layout
			v:ClearAllPoints()
			v:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 0, 0)
		end

		self:UpdateButtonLayout()
	end
end

MicroMenu.BlizzardBarShow = function(self)

	local bar = self.bar

	-- Only reset button positions not set in MoveMicroButtons()
	for i,v in pairs(bar.buttons) do
		if (v ~= CharacterMicroButton) and (v ~= LFDMicroButton) then

			-- Restore blizzard button layout
			v:SetIgnoreParentScale(false)
			v:SetScale(1)
			v:SetSize(28,36)
			v:SetHitRectInsets(0,0,0,0)
			v:ClearAllPoints()
			v:SetPoint(unpack(bar.anchors[i]))

			-- Show Blizzard style
			v:SetAlpha(1)

			-- Hide our style
			--self.bar.custom[v]:SetAlpha(0)
		end
	end
end

MicroMenu.ActionBarController_UpdateAll = function(self)
	if (self.ownedByUI) and ActionBarController_GetCurrentActionBarState() == LE_ACTIONBAR_STATE_MAIN and not (C_PetBattles and C_PetBattles.IsInBattle()) then
		UpdateMicroButtonsParent(self.bar)
		self:MicroMenuBarShow()
	end
end

MicroMenu.InitializeMicroMenu = function(self)

	if (not self.bar) then

		local db = ns.Config.MicroMenu
		local buttons, anchors, custom = {}, {}, {}

		local bar = CreateFrame("Frame", ns.Prefix.."MicroMenu", UIParent, "SecureHandlerStateTemplate")
		bar:SetFrameStrata("HIGH")
		bar:Hide()

		local backdrop = CreateFrame("Frame", nil, bar, ns.BackdropTemplate)
		backdrop:SetFrameLevel(bar:GetFrameLevel())
		backdrop:SetBackdrop(db.MicroMenuBackdrop)
		backdrop:SetBackdropColor(unpack(db.MicroMenuBackdropColor))
		bar:SetAllPoints(backdrop)

		for i,name in ipairs({
			"CharacterMicroButton",
			"SpellbookMicroButton",
			"TalentMicroButton",
			"AchievementMicroButton",
			"QuestLogMicroButton",
			"SocialsMicroButton",
			"PVPMicroButton",
			"LFGMicroButton",
			"WorldMapMicroButton",
			"GuildMicroButton",
			"LFDMicroButton",
			"CollectionsMicroButton",
			"EJMicroButton",
			"StoreMicroButton",
			"MainMenuMicroButton",
			"HelpMicroButton"
		}) do
			local button = _G[name]
			if (button) then
				table_insert(buttons, button)
			end
		end

		if (buttons[1]:GetParent() ~= MainMenuBarArtFrame) then
			self.ownedByUI = true
		end

		local labels = {
			CharacterMicroButton = CHARACTER_BUTTON,
			SpellbookMicroButton = SPELLBOOK_ABILITIES_BUTTON,
			TalentMicroButton = TALENTS_BUTTON,
			AchievementMicroButton = ACHIEVEMENT_BUTTON,
			QuestLogMicroButton = QUESTLOG_BUTTON,
			SocialsMicroButton = SOCIALS,
			PVPMicroButton = PLAYER_V_PLAYER,
			LFGMicroButton = DUNGEONS_BUTTON,
			WorldMapMicroButton = WORLD_MAP,
			GuildMicroButton = LOOKINGFORGUILD,
			LFDMicroButton = DUNGEONS_BUTTON,
			CollectionsMicroButton = COLLECTIONS,
			EJMicroButton = ADVENTURE_JOURNAL or ENCOUNTER_JOURNAL,
			StoreMicroButton = BLIZZARD_STORE,
			MainMenuMicroButton = MAINMENU_BUTTON,
			HelpMicroButton = HELP_BUTTON
		}

		for i,v in ipairs(buttons) do
			anchors[i] = { v:GetPoint() }

			v.OnEnter = v:GetScript("OnEnter")
			v.OnLeave = v:GetScript("OnLeave")
			v:SetScript("OnEnter", nil)
			v:SetScript("OnLeave", nil)
			v:SetFrameLevel(bar:GetFrameLevel() + 1)

			local b = CreateFrame("Frame", nil, v, "SecureHandlerStateTemplate")
			b:SetMouseMotionEnabled(true)
			b:SetMouseClickEnabled(false)
			b:SetIgnoreParentAlpha(true)
			b:SetAlpha(1)
			b:SetFrameLevel(v:GetFrameLevel() - 1)
			b:SetSize(unpack(db.MicroMenuButtonSize))

			local position = { unpack(db.MicroMenuPosition) }
			position[#position] = position[#position] + (i-1)*db.MicroMenuButtonSize[2]
			b:SetPoint(unpack(position))

			local c = b:CreateTexture(nil, "ARTWORK")
			c:SetPoint("TOPLEFT", 1,-1)
			c:SetPoint("BOTTOMRIGHT", -1,1)
			c:SetColorTexture(1,1,1,.9)

			v:SetScript("OnEnter", function() c:SetVertexColor(.75,.75,.75) end)
			v:SetScript("OnLeave", function() c:SetVertexColor(.1,.1,.1) end)
			v:GetScript("OnLeave")(v)

			local d = b:CreateFontString(nil, "OVERLAY")
			d:SetFontObject(db.MicroMenuButtonFont)
			d:SetText(labels[v:GetName()])
			d:SetJustifyH("CENTER")
			d:SetJustifyV("MIDDLE")
			d:SetPoint("CENTER")

			custom[v] = b
		end

		backdrop:ClearAllPoints()
		backdrop:SetPoint("RIGHT", custom[buttons[1]], "RIGHT", db.MicroMenuBackdropOffsetRight, 0)
		backdrop:SetPoint("BOTTOM", custom[buttons[1]], "BOTTOM", 0, db.MicroMenuBackdropOffsetBottom)
		backdrop:SetPoint("LEFT", custom[buttons[1]], "LEFT", db.MicroMenuBackdropOffsetLeft, 0)
		backdrop:SetPoint("TOP", custom[buttons[#buttons]], "TOP", 0, db.MicroMenuBackdropOffsetTop)

		bar.backdrop = backdrop
		bar.buttons = buttons
		bar.anchors = anchors
		bar.custom = custom

		self.bar = bar

		local toggle = SetObjectScale(CreateFrame("CheckButton", nil, UIParent, "SecureHandlerClickTemplate"))
		toggle:SetSize(unpack(db.MicroMenuToggleButtonSize))
		toggle:SetPoint(unpack(db.MicroMenuToggleButtonPosition))
		toggle:RegisterForClicks("AnyUp")
		toggle:SetFrameRef("Bar", bar)

		for i,v in ipairs(buttons) do
			toggle:SetFrameRef("Button"..i, custom[v])
		end

		toggle:SetAttribute("_onclick", [[
			local bar = self:GetFrameRef("Bar");
			if (bar:IsShown()) then
				bar:Hide();
			else
				bar:Show();
			end

			bar:UnregisterAutoHide();

			if (bar:IsShown()) then
				bar:RegisterAutoHide(.75);
				bar:AddToAutoHide(self);

				local i = 1;
				local button = self:GetFrameRef("Button"..i);
				while (button) do
					i = i + 1;
					bar:AddToAutoHide(button);
					button = self:GetFrameRef("Button"..i);
				end
			end
		]])

		local texture = toggle:CreateTexture(nil, "ARTWORK", nil, 0)
		texture:SetSize(unpack(db.MicroMenuToggleButtonTextureSize))
		texture:SetPoint(unpack(db.MicroMenuToggleButtonTexturePosition))
		texture:SetTexture(db.MicroMenuToggleButtonTexture)
		texture:SetVertexColor(unpack(db.MicroMenuToggleButtonColor))

		RegisterStateDriver(toggle, "visibility", "[petbattle]hide;show")

	end

	self:SecureHook("UpdateMicroButtons", "MicroMenuBarShow")
	self:SecureHook("UpdateMicroButtonsParent")
	self:SecureHook("ActionBarController_UpdateAll")

	if (C_PetBattles) then
		self:RegisterEvent("PET_BATTLE_CLOSE", "OnEvent")
	end

	self:MicroMenuBarShow()

end

MicroMenu.OnEvent = function(self, event, ...)
	if (event == "PET_BATTLE_CLOSE") then
		UpdateMicroButtonsParent(self.bar)
		self:MicroMenuBarShow()
	end
end

MicroMenu.OnInitialize = function(self)
	if (IsAddOnEnabled("ConsolePort")) then
		return self:Disable()
	end
	if (IsAddOnEnabled("Bartender4") and not ns.BartenderHandled) then
		ns.RegisterCallback(self, "Bartender_Handled", "InitializeMicroMenu")
	else
		self:InitializeMicroMenu()
	end
end
