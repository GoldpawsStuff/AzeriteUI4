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
local Tooltips = ns:NewModule("Tooltips", "LibMoreEvents-1.0", "AceHook-3.0")

-- Lua API
local _G = _G
local ipairs = ipairs
local select = select
local string_find = string.find
local string_format = string.format
local string_lower = string.lower

-- WoW API
local GameTooltip_ClearMoney = GameTooltip_ClearMoney
local GetBestMapForUnit = C_Map.GetBestMapForUnit
local GetGuildInfo = GetGuildInfo
local GetLocale = GetLocale
local GetMouseFocus = GetMouseFocus
local GetTooltipUnit = GetTooltipUnit
local SetTooltipMoney = SetTooltipMoney
local SharedTooltip_ClearInsertedFrames = SharedTooltip_ClearInsertedFrames
local UnitClass = UnitClass
local UnitClassification = UnitClassification
local UnitCreatureFamily = UnitCreatureFamily
local UnitCreatureType = UnitCreatureType
local UnitEffectiveLevel = UnitEffectiveLevel or UnitLevel
local UnitFactionGroup = UnitFactionGroup
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitInParty = UnitInParty
local UnitInRaid = UnitInRaid
local UnitIsAFK = UnitIsAFK
local UnitIsConnected = UnitIsConnected
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitIsDND = UnitIsDND
local UnitIsPVP = UnitIsPVP
local UnitIsPVPFreeForAll = UnitIsPVPFreeForAll
local UnitLevel = UnitLevel
local UnitName = UnitName
local UnitPVPName = UnitPVPName
local UnitRace = UnitRace
local UnitReaction = UnitReaction

-- Addon API
local Colors = ns.Colors
local AbbreviateNumber = ns.API.AbbreviateNumber
local AbbreviateNumberBalanced = ns.API.AbbreviateNumberBalanced
local GetDifficultyColorByLevel = ns.API.GetDifficultyColorByLevel
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia
local GetUnitColor = ns.API.GetUnitColor
local SetObjectScale = ns.API.SetObjectScale

local UIHider = ns.Hider
local noop = ns.Noop

-- Localized Search Patterns
local LEVEL1 = string_lower(_G.TOOLTIP_UNIT_LEVEL:gsub("%s?%%s%s?%-?",""))
local LEVEL2 = string_lower(_G.TOOLTIP_UNIT_LEVEL_CLASS:gsub("^%%2$s%s?(.-)%s?%%1$s","%1"):gsub("^%-?г?о?%s?",""):gsub("%s?%%s%s?%-?",""))

local NOT_SPECIFIED = setmetatable({
	["frFR"] = "Non spécifié",
	["deDE"] = "Nicht spezifiziert",
	["koKR"] = "기타",
	["ruRU"] = "Не указано",
	["zhCN"] = "未指定",
	["zhTW"] = "不明",
	["esES"] = "No especificado",
	["esMX"] = "Sin especificar",
	["ptBR"] = "Não especificado",
	["itIT"] = "Non Specificato"
}, { __index = function(t,k) return "Not specified" end })[(GetLocale())]

-- Localized PvP rank names for both factions (Classic)
-- [RankNum] = { Horde Name, Alliance Name, TextureID }
local PVP_RANKS = {
	[1] = { _G.PVP_RANK_5_0, _G.PVP_RANK_5_1, 136766 },
	[2] = { _G.PVP_RANK_6_0, _G.PVP_RANK_6_1, 136767 },
	[3] = { _G.PVP_RANK_7_0, _G.PVP_RANK_7_1, 136768 },
	[4] = { _G.PVP_RANK_8_0, _G.PVP_RANK_8_1, 136769 },
	[5] = { _G.PVP_RANK_9_0, _G.PVP_RANK_9_1, 136770 },
	[6] = { _G.PVP_RANK_10_0, _G.PVP_RANK_10_1, 136771 },
	[7] = { _G.PVP_RANK_11_0, _G.PVP_RANK_11_1, 136772 },
	[8] = { _G.PVP_RANK_12_0, _G.PVP_RANK_12_1, 136773 },
	[9] = { _G.PVP_RANK_13_0, _G.PVP_RANK_13_1, 136774 },
	[10] = { _G.PVP_RANK_14_0, _G.PVP_RANK_14_1, 136775 },
	[11] = { _G.PVP_RANK_15_0, _G.PVP_RANK_15_1, 136776 },
	[12] = { _G.PVP_RANK_16_0, _G.PVP_RANK_16_1, 136777 },
	[13] = { _G.PVP_RANK_17_0, _G.PVP_RANK_17_1, 136778 },
	[14] = { _G.PVP_RANK_18_0, _G.PVP_RANK_18_1, 136779 },
	[15] = { _G.PVP_RANK_19_0, _G.PVP_RANK_19_1, 136780 }
}

-- WoW Textures
local BOSS_TEXTURE = [[|TInterface\TargetingFrame\UI-TargetingFrame-Skull:14:14:-2:1|t]]

-- Custom Backdrop Cache
local Backdrops = setmetatable({}, { __index = function(t,k)
	local bg = CreateFrame("Frame", nil, k, ns.BackdropTemplate)
	bg:SetAllPoints()
	bg:SetFrameLevel(k:GetFrameLevel())
	-- Hook into tooltip framelevel changes.
	-- Might help with some of the conflicts experienced with Silverdragon and Raider.IO
	hooksecurefunc(k, "SetFrameLevel", function(self) bg:SetFrameLevel(self:GetFrameLevel()) end)
	rawset(t,k,bg)
	return bg
end })

Tooltips.SetBackdropStyle = function(self, tooltip)
	if (not tooltip) or (tooltip.IsEmbedded) or (tooltip:IsForbidden()) then return end

	SetObjectScale(tooltip, 1.1)

	tooltip:DisableDrawLayer("BACKGROUND")
	tooltip:DisableDrawLayer("BORDER")
	tooltip.SetIgnoreParentScale = noop
	tooltip.SetScale = noop

	-- Don't want or need the extra padding here,
	-- as our current borders do not require them.
	if (tooltip == NarciGameTooltip) then

		-- Note that the WorldMap uses this to fit extra embedded stuff in,
		-- so we can't randomly just remove it from all tooltips, or stuff will break.
		-- Currently the only one we know of that needs tweaking, is the aforementioned.
		if (tooltip.SetPadding) then
			tooltip:SetPadding(0, 0, 0, 0)
			tooltip.SetPadding = noop
		end
	end

	-- Glorious 9.1.5 crap
	-- They decided to move the entire backdrop into its own hashed frame.
	-- We like this, because it makes it easier to kill. Kill. Kill. Kill. Kill.
	if (tooltip.NineSlice) then
		tooltip.NineSlice:SetParent(UIHider)
	end

	-- Textures in the combat pet tooltips
	for _,texName in ipairs({
		"BorderTopLeft",
		"BorderTopRight",
		"BorderBottomRight",
		"BorderBottomLeft",
		"BorderTop",
		"BorderRight",
		"BorderBottom",
		"BorderLeft",
		"Background"
	}) do
		local region = self[texName]
		if (region) then
			region:SetTexture(nil)
			local drawLayer, subLevel = region:GetDrawLayer()
			if (drawLayer) then
				tooltip:DisableDrawLayer(drawLayer)
			end
		end
	end

	-- Region names sourced from SharedXML\NineSlice.lua
	-- *Majority of this, if not all, was moved into frame.NineSlice in 9.1.5
	for _,pieceName in ipairs({
		"TopLeftCorner",
		"TopRightCorner",
		"BottomLeftCorner",
		"BottomRightCorner",
		"TopEdge",
		"BottomEdge",
		"LeftEdge",
		"RightEdge",
		"Center"
	}) do
		local region = tooltip[pieceName]
		if (region) then
			region:SetTexture(nil)
			local drawLayer, subLevel = region:GetDrawLayer()
			if (drawLayer) then
				tooltip:DisableDrawLayer(drawLayer)
			end
		end
	end

	local backdrop = Backdrops[tooltip]
	backdrop.offsetLeft = ns.Config.Tooltips.BackdropOffsetLeft
	backdrop.offsetRight = ns.Config.Tooltips.BackdropOffsetRight
	backdrop.offsetTop = ns.Config.Tooltips.BackdropOffsetTop
	backdrop.offsetBottom = ns.Config.Tooltips.BackdropOffsetBottom
	backdrop.offsetBar = ns.Config.Tooltips.BackdropOffsetBar
	backdrop.offsetBarBottom = ns.Config.Tooltips.BackdropOffsetBarBottom
	backdrop:SetBackdrop(nil)
	backdrop:SetBackdrop(ns.Config.Tooltips.Backdrop)
	backdrop:ClearAllPoints()
	backdrop:SetPoint( "LEFT", backdrop.offsetLeft, 0 )
	backdrop:SetPoint( "RIGHT", backdrop.offsetRight, 0 )
	backdrop:SetPoint( "TOP", 0, backdrop.offsetTop )
	backdrop:SetPoint( "BOTTOM", 0, backdrop.offsetBottom )
	backdrop:SetBackdropColor(unpack(ns.Config.Tooltips.BackdropColor))

end

Tooltips.StyleTooltips = function(self, event, ...)

	if (event == "PLAYER_ENTERING_WORLD") then
		self:UnregisterEvent("PLAYER_ENTERING_WORLD", "StyleTooltips")
	end

	for _,tooltip in pairs({
		_G.ItemRefTooltip,
		_G.ItemRefShoppingTooltip1,
		_G.ItemRefShoppingTooltip2,
		_G.FriendsTooltip,
		_G.WarCampaignTooltip,
		_G.EmbeddedItemTooltip,
		_G.ReputationParagonTooltip,
		_G.GameTooltip,
		_G.ShoppingTooltip1,
		_G.ShoppingTooltip2,
		_G.QuickKeybindTooltip,
		_G.QuestScrollFrame and _G.QuestScrollFrame.StoryTooltip,
		_G.QuestScrollFrame and _G.QuestScrollFrame.CampaignTooltip,
		_G.NarciGameTooltip
	}) do
		self:SetBackdropStyle(tooltip)
	end

end

Tooltips.StyleStatusBar = function(self)

	GameTooltip.StatusBar = GameTooltipStatusBar
	GameTooltip.StatusBar:SetScript("OnValueChanged", nil)
	GameTooltip.StatusBar:SetStatusBarTexture(ns.Config.Tooltips.StatusBarTexture)
	GameTooltip.StatusBar:ClearAllPoints()
	GameTooltip.StatusBar:SetPoint("BOTTOMLEFT", GameTooltip.StatusBar:GetParent(), "BOTTOMLEFT", -ns.Config.Tooltips.StatusBarOffsetV, -ns.Config.Tooltips.StatusBarOffsetH)
	GameTooltip.StatusBar:SetPoint("BOTTOMRIGHT", GameTooltip.StatusBar:GetParent(), "BOTTOMRIGHT", ns.Config.Tooltips.StatusBarOffsetV, -ns.Config.Tooltips.StatusBarOffsetH)
	GameTooltip.StatusBar:SetHeight(ns.Config.Tooltips.StatusBarSize)

	GameTooltip.StatusBar:HookScript("OnShow", function(self)
		local tooltip = self:GetParent()
		if (tooltip) then
			local backdrop = Backdrops[tooltip]
			if (backdrop) then
				backdrop:SetPoint("BOTTOM", 0, backdrop.offsetBottom + backdrop.offsetBarBottom)
			end
		end
	end)

	GameTooltip.StatusBar:HookScript("OnHide", function(self)
		local tooltip = self:GetParent()
		if (tooltip) then
			local backdrop = Backdrops[tooltip]
			if (backdrop) then
				backdrop:SetPoint("BOTTOM", 0, backdrop.offsetBottom)
			end
		end
	end)

	GameTooltip.StatusBar.Text = GameTooltip.StatusBar:CreateFontString(nil, "OVERLAY")
	GameTooltip.StatusBar.Text:SetPoint(unpack(ns.Config.Tooltips.StatusBarTextPosition))
	GameTooltip.StatusBar.Text:SetFontObject(ns.Config.Tooltips.StatusBarTextFont)
	GameTooltip.StatusBar.Text:SetTextColor(unpack(ns.Config.Tooltips.StatusBarTextColor))

end

Tooltips.SetHealthValue = function(self, unit)
	if (UnitIsDeadOrGhost(unit)) then
		if (GameTooltip.StatusBar:IsShown()) then
			GameTooltip.StatusBar:Hide()
		end
	else
		local msg
		local min,max = UnitHealth(unit), UnitHealthMax(unit)
		if (min and max) then
			if (min == max) then
				msg = string_format("%s", AbbreviateNumberBalanced(min))
			else
				msg = string_format("%s / %s", AbbreviateNumber(min), AbbreviateNumber(max))
			end
		else
			msg = NOT_APPLICABLE
		end
		GameTooltip.StatusBar.Text:SetText(msg)
		if (not GameTooltip.StatusBar.Text:IsShown()) then
			GameTooltip.StatusBar.Text:Show()
		end
		if (not GameTooltip.StatusBar:IsShown()) then
			GameTooltip.StatusBar:Show()
		end
	end
end

Tooltips.OnValueChanged = function(self)
	local unit = select(2, GameTooltip.StatusBar:GetParent():GetUnit())
	if (not unit) then
		local GMF = GetMouseFocus()
		if (GMF and GMF.GetAttribute and GMF:GetAttribute("unit")) then
			unit = GMF:GetAttribute("unit")
		end
	end
	if (not unit) then
		if (GameTooltip.StatusBar:IsShown()) then
			GameTooltip.StatusBar:Hide()
		end
		return
	end
	self:SetHealthValue(unit)
end

Tooltips.OnTooltipCleared = function(self, tooltip)
	if (not tooltip) or (tooltip:IsForbidden()) then return end
	if (GameTooltip.StatusBar:IsShown()) then
		GameTooltip.StatusBar:Hide()
	end
end

Tooltips.OnTooltipSetSpell = function(self, tooltip)
	if (not tooltip) or (tooltip:IsForbidden()) then return end

end

Tooltips.OnTooltipSetItem = function(self, tooltip)
	if (not tooltip) or (tooltip:IsForbidden()) then return end

end

Tooltips.OnCompareItemShow = function(self, tooltip)
	if (not tooltip) or (tooltip:IsForbidden()) then return end
	local frameLevel = GameTooltip:GetFrameLevel()
	for i = 1, 2 do
		local tooltip = _G["ShoppingTooltip"..i]
		if (tooltip:IsShown()) then
			if (frameLevel == tooltip:GetFrameLevel()) then
				tooltip:SetFrameLevel(i+1)
			end
		end
	end
end

Tooltips.OnTooltipSetUnit = function(self, tooltip)
	if (not tooltip) or (tooltip:IsForbidden()) then return end

	local _, unit = tooltip:GetUnit()
	if (not unit) then
		local focus = GetMouseFocus()
		if (focus) and (focus.GetAttribute) then
			unit = focus:GetAttribute("unit")
		end
	end
	if (not unit) and (UnitExists("mouseover")) then
		unit = "mouseover"
	end
	if (unit) and UnitIsUnit(unit, "mouseover") then
		unit = "mouseover"
	end
	unit = UnitExists(unit) and unit
	if (not unit) then
		tooltip:Hide()
		return
	end

	GameTooltip_ClearMoney(self)
	SharedTooltip_ClearInsertedFrames(self)

	for i = 3, tooltip:NumLines() do
		local tiptext = _G["GameTooltipTextLeft"..i]
		local linetext = tiptext:GetText()
		if (linetext == _G.PVP) or (linetext == _G.FACTION_ALLIANCE) or (linetext == _G.FACTION_HORDE) then
			tiptext:SetText("")
			tiptext:Hide()
		end
	end

	local levelLine, infoText
	for i = 2, tooltip:NumLines() do
		local tipLine = _G["GameTooltipTextLeft"..i]
		local tipText = tipLine and tipLine:GetText() and string_lower(tipLine:GetText())
		if (tipText) and (string_find(tipText, LEVEL1) or string_find(tipText, LEVEL2)) then
			levelLine = tipLine
			break
		end
	end

	local isPlayer = UnitIsPlayer(unit)
	local unitEffectiveLevel = UnitEffectiveLevel(unit)
	local unitName, unitRealm = UnitName(unit)
	local isDead = UnitIsDeadOrGhost(unit)

	local displayName = unitName

	local color = GetUnitColor(unit)
	if (color) then
		displayName = color.colorCode..displayName.."|r"
	end

	-- Gather data
	if (isPlayer) then
		local classDisplayName, class, classID = UnitClass(unit)
		local englishFaction, localizedFaction = UnitFactionGroup(unit)
		local guildName, guildRankName, guildRankIndex, guildRealm = GetGuildInfo(unit)
		local raceDisplayName, raceID = UnitRace(unit)
		local isAFK = UnitIsAFK(unit)
		local isDND = UnitIsDND(unit)
		local isDisconnected = not UnitIsConnected(unit)
		local isPVP = UnitIsPVP(unit)
		local isFFA = UnitIsPVPFreeForAll(unit)
		local pvpName = UnitPVPName(unit)
		local inParty = UnitInParty(unit)
		local inRaid = UnitInRaid(unit)
		local uiMapID = (inParty or inRaid) and GetBestMapForUnit and GetBestMapForUnit(unit)
		local pvpRankName, pvpRankNumber

		if (GetPVPRankInfo) and (UnitPVPRank) then
			pvpRankName, pvpRankNumber = GetPVPRankInfo(UnitPVPRank(unit))
		end

		-- Correct the rank names according to faction,
		-- as the above function only returns the names
		-- of your own faction's PvP ranks.
		if (pvpRankNumber and PVP_RANKS[pvpRankNumber]) then
			if (englishFaction == "Horde") then
				pvpRankName = PVP_RANKS[pvpRankNumber][1]
			elseif (englishFaction == "Alliance") then
				pvpRankName = PVP_RANKS[pvpRankNumber][2]
			end
		end

		if (pvpRankName) then
			displayName = displayName .. ns.Colors.quest.gray.colorCode.. " (" .. pvpRankName .. ")|r"
		end

		if (levelLine) then
			if (raceDisplayName) then
				infoText = (infoText and infoText.." " or "") .. raceDisplayName
			end
			if (classDisplayName and class) then
				infoText = (infoText and infoText.." " or "") .. classDisplayName
			end
			if (infoText) then
				levelLine:SetText(infoText)
			else
				levelLine:SetText("")
				levelLine:Hide()
			end
		end

		if (guildName) then
			_G.GameTooltipTextLeft2:SetText(ns.Colors.artifact.colorCode..guildName.."|r")
		end

		if (unitRealm) then
			tooltip:AddLine(" ")
			tooltip:AddLine(_G.FRIENDS_LIST_REALM..unitRealm, ns.Colors.quest.gray[1], ns.Colors.quest.gray[2], ns.Colors.quest.gray[3])
		end

		local levelText
		if (unitEffectiveLevel and unitEffectiveLevel > 0) then
			local r, g, b, colorCode = GetDifficultyColorByLevel(unitEffectiveLevel)
			levelText = colorCode .. unitEffectiveLevel .. "|r"
		end
		if (not levelText) then
			displayName = BOSS_TEXTURE .. " " .. displayName
		end

		if (levelText) then
			_G.GameTooltipTextLeft1:SetText(levelText .. ns.Colors.quest.gray.colorCode .. ": |r" .. displayName)
		else
			_G.GameTooltipTextLeft1:SetText(displayName)
		end

	else
		local englishFaction, localizedFaction = UnitFactionGroup(unit)
		local reaction = UnitReaction(unit, "player")
		local classification = UnitClassification(unit)
		if (unitEffectiveLevel < 0) then
			classification = "worldboss"
		end
		local creatureFamily = UnitCreatureFamily(unit)
		local creatureType = UnitCreatureType(unit)
		if (creatureType == NOT_SPECIFIED) then
			creatureType = nil
		end
		local isBoss = classification == "worldboss"
		if (isBoss) then
			displayName = BOSS_TEXTURE .. " " .. displayName
		elseif (classification == "rare") or (classification == "rareelite") then
			displayName = displayName .. ns.Colors.quality[3].colorCode .. " (" .. _G.ITEM_QUALITY3_DESC .. ")|r"
		elseif (classification == "elite") then
			displayName = displayName .. ns.Colors.title.colorCode .. " (" .. _G.ELITE .. ")|r"
		end

		if (levelLine) then
			if (creatureFamily) then
				infoText = (infoText and infoText.." " or "") .. creatureFamily
			elseif (creatureType) then
				infoText = (infoText and infoText.." " or "") .. creatureType
			end
			if (infoText) then
				levelLine:SetText(infoText)
			else
				levelLine:SetText("")
				levelLine:Hide()
			end
		end

		local levelText
		if (unitEffectiveLevel and unitEffectiveLevel > 0) then
			local r, g, b, colorCode = GetDifficultyColorByLevel(unitEffectiveLevel)
			levelText = colorCode .. unitEffectiveLevel .. "|r"
		end

		-- Add a skull icon for non-classified boss mobs with undetermined unitlevel
		if (not isBoss) and (not levelText) then
			displayName = BOSS_TEXTURE .. " " .. displayName
		end

		if (levelText) then
			_G.GameTooltipTextLeft1:SetText(levelText .. ns.Colors.quest.gray.colorCode .. ": |r" .. displayName)
		else
			_G.GameTooltipTextLeft1:SetText(displayName)
		end

	end

	self:SetHealthValue(unit)

end

Tooltips.SetDefaultAnchor = function(self, tooltip, parent)
	if (not tooltip) or (tooltip:IsForbidden()) then return end

	tooltip:SetOwner(parent, "ANCHOR_NONE")
	tooltip:SetPoint(unpack(ns.Config.Tooltips.Position))
end

Tooltips.SetUnitColor = function(self, unit)
	local color = GetUnitColor(unit) or Colors.reaction[5]
	if (color) then
		GameTooltip.StatusBar:SetStatusBarColor(color[1], color[2], color[3])
	end
end

Tooltips.SetFonts = function(self)

	local header = GetFont(15,true)
	local normal = GetFont(13,true)
	local small = GetFont(12,true)

	_G.GameTooltipHeaderText:SetFontObject(header)
	_G.GameTooltipTextSmall:SetFontObject(small)
	_G.GameTooltipText:SetFontObject(normal)

	if (not GameTooltip.hasMoney) then
		SetTooltipMoney(GameTooltip, 1, nil, "", "")
		SetTooltipMoney(GameTooltip, 1, nil, "", "")
		GameTooltip_ClearMoney(GameTooltip)
	end
	if (GameTooltip.hasMoney) then
		for i = 1, GameTooltip.numMoneyFrames do
			_G["GameTooltipMoneyFrame"..i.."PrefixText"]:SetFontObject(normal)
			_G["GameTooltipMoneyFrame"..i.."SuffixText"]:SetFontObject(normal)
			_G["GameTooltipMoneyFrame"..i.."GoldButtonText"]:SetFontObject(normal)
			_G["GameTooltipMoneyFrame"..i.."SilverButtonText"]:SetFontObject(normal)
			_G["GameTooltipMoneyFrame"..i.."CopperButtonText"]:SetFontObject(normal)
		end
	end

	if (_G.DatatextTooltip) then
		_G.DatatextTooltipTextLeft1:SetFontObject(normal)
		_G.DatatextTooltipTextRight1:SetFontObject(normal)
	end

	for _,tooltip in ipairs(GameTooltip.shoppingTooltips) do
		for i = 1,tooltip:GetNumRegions() do
			local region = select(i, tooltip:GetRegions())
			if (region:IsObjectType("FontString")) then
				region:SetFontObject(small)
			end
		end
	end

end

Tooltips.SetHooks = function(self)

	if (_G.SharedTooltip_SetBackdropStyle) then
		self:SecureHook("SharedTooltip_SetBackdropStyle", "SetBackdropStyle")
	else
		self:SecureHook("GameTooltip_SetBackdropStyle", "SetBackdropStyle")
	end

	self:SecureHook("GameTooltip_UnitColor", "SetUnitColor")
	self:SecureHook("GameTooltip_ShowCompareItem", "OnCompareItemShow")
	self:SecureHook("GameTooltip_SetDefaultAnchor", "SetDefaultAnchor")

	self:SecureHookScript(GameTooltip, "OnTooltipCleared", "OnTooltipCleared")

	if (not ns.IsRetail) then
		self:SecureHookScript(GameTooltip, "OnTooltipSetSpell", "OnTooltipSetSpell")
		self:SecureHookScript(GameTooltip, "OnTooltipSetItem", "OnTooltipSetItem")
		self:SecureHookScript(GameTooltip, "OnTooltipSetUnit", "OnTooltipSetUnit")
	end

	self:SecureHookScript(GameTooltip.StatusBar, "OnValueChanged", "OnValueChanged")

end

Tooltips.OnInitialize = function(self)

	self:StyleStatusBar()
	self:StyleTooltips()

	--self:SetFonts()
	self:SetHooks()
end

Tooltips.OnEnable = function(self)
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "StyleTooltips")
end