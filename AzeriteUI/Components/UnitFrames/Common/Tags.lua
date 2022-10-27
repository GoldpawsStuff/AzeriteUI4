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
local oUF = ns.oUF
local Events = oUF.Tags.Events
local Methods = oUF.Tags.Methods

-- Lua API
local math_max = math.max
local string_find = string.find

-- WoW API
local UnitBattlePetLevel = UnitBattlePetLevel
local UnitClassification = UnitClassification
local UnitGetIncomingHeals = UnitGetIncomingHeals
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitIsBattlePetCompanion = UnitIsBattlePetCompanion
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitIsWildBattlePet = UnitIsWildBattlePet
local UnitLevel = UnitLevel
local UnitName = UnitName
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax

-- Addon API
local Colors = ns.Colors
local AbbreviateName = ns.API.AbbreviateName
local AbbreviateNumber = ns.API.AbbreviateNumber
local AbbreviateNumberBalanced = ns.API.AbbreviateNumberBalanced
local GetDifficultyColorByLevel = ns.API.GetDifficultyColorByLevel

-- Colors
local c_gray = Colors.gray.colorCode
local c_normal = Colors.normal.colorCode
local c_rare = Colors.quality.Rare.colorCode
local c_red = Colors.red.colorCode
local r = "|r"

-- Strings
local L_DEAD = DEAD
local L_RARE = ITEM_QUALITY3_DESC

-- Textures
local T_BOSS = "|TInterface\\TargetingFrame\\UI-TargetingFrame-Skull:14:14:-2:1|t"

-- Tags
---------------------------------------------------------------------
Events[ns.Prefix..":Absorb"] = "UNIT_ABSORB_AMOUNT_CHANGED"
Methods[ns.Prefix..":Absorb"] = function(unit)
	if (UnitIsDeadOrGhost(unit)) then
		return
	else
		local absorb = UnitGetTotalAbsorbs(unit) or 0
		if (absorb > 0) then
			return c_gray.." ("..r..c_normal..absorb..r..c_gray..")"..r
		end
	end
end

Events[ns.Prefix..":Classification"] = "UNIT_LEVEL PLAYER_LEVEL_UP UNIT_CLASSIFICATION_CHANGED"
if (oUF.isClassic or oUF.isTBC or oUF.isWrath) then
	Methods[ns.Prefix..":Classification"] = function(unit)
		local l = UnitLevel(unit)
		local c = UnitClassification(unit)
		if (c == "worldboss" or (not l) or (l < 1)) then
			return
		end
		if (c == "elite" or c == "rareelite") then
			return c_red.."+"..r.." "
		end
		return " "
	end
else
	Methods[ns.Prefix..":Classification"] = function(unit)
		local l = UnitLevel(unit)
		if (UnitIsWildBattlePet(unit) or UnitIsBattlePetCompanion(unit)) then
			l = UnitBattlePetLevel(unit)
		end
		local c = UnitClassification(unit)
		if (c == "worldboss" or (not l) or (l < 1)) then
			return
		end
		if (c == "elite" or c == "rareelite") then
			return c_red.."+"..r.." "
		end
		return " "
	end
end

Events[ns.Prefix..":Health"] = "UNIT_HEALTH UNIT_MAXHEALTH"
Methods[ns.Prefix..":Health"] = function(unit)
	if (UnitIsDeadOrGhost(unit)) then
		return L_DEAD
	else
		local health = UnitHealth(unit)
		if (health > 0) then
			return AbbreviateNumber(health)
		end
	end
end

Events[ns.Prefix..":Health:Full"] = "UNIT_HEALTH UNIT_MAXHEALTH"
Methods[ns.Prefix..":Health:Full"] = function(unit)
	if (UnitIsDeadOrGhost(unit)) then
		return
	else
		local health, maxHealth = UnitHealth(unit), UnitHealthMax(unit)
		if (maxHealth > 0) then
			return health..c_gray.."/"..r..maxHealth
		end
	end
end

Events[ns.Prefix..":Health:Smart"] = "UNIT_HEALTH UNIT_MAXHEALTH"
Methods[ns.Prefix..":Health:Smart"] = function(unit)
	if (UnitIsDeadOrGhost(unit)) then
		return L_DEAD
	else
		local health, maxHealth = UnitHealth(unit), UnitHealthMax(unit)
		if (maxHealth > 0) then
			if (health == maxHealth) then
				return AbbreviateNumber(health)
			else
				local displayValue = health / maxHealth * 100 + .5
				return displayValue - displayValue%1
			end
		end
	end
end

Events[ns.Prefix..":Level"] = "UNIT_LEVEL PLAYER_LEVEL_UP UNIT_CLASSIFICATION_CHANGED"
if (oUF.isClassic or oUF.isTBC or oUF.isWrath) then
	Methods[ns.Prefix..":Level"] = function(unit, asPrefix)
		local l = UnitLevel(unit)
		local c = UnitClassification(unit)
		if (c == "worldboss" or (not l) or (l < 1)) then
			return T_BOSS
		end
		local _,_,_,colorCode = GetDifficultyColorByLevel(l)
		if (c == "elite" or c == "rareelite") then
			return colorCode..l..r..c_red.."+"..r
		end
		if (asPrefix) then
			return colorCode..l..r..c_gray..":"..r
		else
			return colorCode..l..r
		end
	end
else
	Methods[ns.Prefix..":Level"] = function(unit, asPrefix)
		local l = UnitLevel(unit)
		if (UnitIsWildBattlePet(unit) or UnitIsBattlePetCompanion(unit)) then
			l = UnitBattlePetLevel(unit)
		end
		local c = UnitClassification(unit)
		if (c == "worldboss" or (not l) or (l < 1)) then
			return T_BOSS
		end
		local _,_,_,colorCode = GetDifficultyColorByLevel(l)
		if (c == "elite" or c == "rareelite") then
			return colorCode..l..r..c_red.."+"..r
		end
		if (asPrefix) then
			return colorCode..l..r..c_gray..":"..r
		else
			return colorCode..l..r
		end
	end
end

Events[ns.Prefix..":Level:Prefix"] = "UNIT_LEVEL PLAYER_LEVEL_UP UNIT_CLASSIFICATION_CHANGED"
Methods[ns.Prefix..":Level:Prefix"] = function(unit)
	local l = Methods[ns.Prefix..":Level"](unit, true)
	return (l and l ~= T_BOSS) and l.." " or l
end

Events[ns.Prefix..":Name"] = "UNIT_NAME_UPDATE"
Methods[ns.Prefix..":Name"] = function(unit, realUnit)
	local name = UnitName(realUnit or unit)
	if (name and string_find(name, "%s")) then
		name = AbbreviateName(name)
	end
	return name
end

Events[ns.Prefix..":Power:Full"] = "UNIT_POWER_FREQUENT UNIT_MAXPOWER"
Methods[ns.Prefix..":Power:Full"] = function(unit)
	if (UnitIsDeadOrGhost(unit)) then
		return
	else
		local current, total = UnitPower(unit), UnitPowerMax(unit)
		if (total > 0) then
			return current..c_gray.."/"..r..total
		end
	end
end

Events[ns.Prefix..":Rare"] = "UNIT_CLASSIFICATION_CHANGED"
Methods[ns.Prefix..":Rare"] = function(unit)
	local classification = UnitClassification(unit)
	local rare = classification == "rare" or classification == "rareelite"
	if (rare) then
		return c_rare.."("..L_RARE..")"..r
	end
end

Events[ns.Prefix..":Rare:Suffix"] = "UNIT_CLASSIFICATION_CHANGED"
Methods[ns.Prefix..":Rare:Suffix"] = function(unit)
	local r = Methods[ns.Prefix..":Rare"](unit)
	return r and " "..r
end
