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
if (ns.WoW10) then
	return
end
ns.AuraFilters = ns.AuraFilters or {}

ns.AuraFilters.PlayerBuffFilter = function(element, unit, button, name, texture,
	count, debuffType, duration, expiration, caster, isStealable, nameplateShowSelf, spellID,
	canApply, isBossDebuff, casterIsPlayer, nameplateShowAll,timeMod, effect1, effect2, effect3)

	--button.unitIsCaster = unit and caster and UnitIsUnit(unit, caster)
	button.spell = name
	button.timeLeft = expiration and (expiration - GetTime())
	button.expiration = expiration
	button.duration = duration
	button.noDuration = (not duration or duration == 0)
	button.isPlayer = caster == "player" or caster == "vehicle"

	if (isBossDebuff) then
		return true
	end

	return (not button.noDuration and duration < 301) or (button.timeLeft and button.timeLeft > 0 and button.timeLeft < 31) or (count > 1)
end

ns.AuraFilters.PlayerDebuffFilter = function(element, unit, button, name, texture,
	count, debuffType, duration, expiration, caster, isStealable, nameplateShowSelf, spellID,
	canApply, isBossDebuff, casterIsPlayer, nameplateShowAll,timeMod, effect1, effect2, effect3)

	--button.unitIsCaster = unit and caster and UnitIsUnit(unit, caster)
	button.spell = name
	button.timeLeft = expiration and (expiration - GetTime())
	button.expiration = expiration
	button.duration = duration
	button.noDuration = (not duration or duration == 0)
	button.isPlayer = caster == "player" or caster == "vehicle"

	if (isBossDebuff) then
		return true
	end

	return true
end

ns.AuraFilters.TargetAuraFilter = function(element, unit, button, name, texture,
	count, debuffType, duration, expiration, caster, isStealable, nameplateShowSelf, spellID,
	canApply, isBossDebuff, casterIsPlayer, nameplateShowAll,timeMod, effect1, effect2, effect3)

	--button.unitIsCaster = unit and caster and UnitIsUnit(unit, caster)
	button.spell = name
	button.timeLeft = expiration and (expiration - GetTime())
	button.expiration = expiration
	button.duration = duration
	button.noDuration = (not duration or duration == 0)
	button.isPlayer = caster == "player" or caster == "vehicle"

	if (isBossDebuff) then
		return true
	end

	return (not button.noDuration and duration < 301) or (count > 1)
end

ns.AuraFilters.NameplateAuraFilter = function(element, unit, button, name, texture,
	count, debuffType, duration, expiration, caster, isStealable, nameplateShowSelf, spellID,
	canApply, isBossDebuff, casterIsPlayer, nameplateShowAll, timeMod, effect1, effect2, effect3)

	button.spell = name
	button.timeLeft = expiration and (expiration - GetTime())
	button.expiration = expiration
	button.duration = duration
	button.noDuration = (not duration or duration == 0)
	button.isPlayer = caster == "player" or caster == "vehicle"

	if (isBossDebuff) then
		return true
	elseif (isStealable) then
		return true
	elseif (caster == "player" or caster == "pet" or caster == "vehicle") then
		if (button.isDebuff) then
			return (not button.noDuration and duration < 301) -- Faerie Fire is 5 mins
		else
			return (not button.noDuration and duration < 31) -- show short buffs, like HoTs
		end
	end
end

-- Temporary overrides for Shadowlands "Classic" below
-- This is just in the transition period before 10.0.
if (ns.ClientMajor <= 3) then
	return
end

ns.AuraFilters.NameplateAuraFilter = function(element, unit, button, name, texture,
	count, debuffType, duration, expiration, caster, isStealable, nameplateShowSelf, spellID,
	canApply, isBossDebuff, casterIsPlayer, nameplateShowAll, timeMod, effect1, effect2, effect3)

	button.spell = name
	button.expiration = expiration
	button.duration = duration
	button.noDuration = (not duration or duration == 0)
	button.isPlayer = caster == "player" or caster == "vehicle"

	if (isBossDebuff) then
		return true
	elseif (isStealable) then
		return true
	elseif (nameplateShowAll) then
		return true
	elseif (nameplateShowSelf and (caster == "player" or caster == "pet" or caster == "vehicle")) then
		return true
	elseif (caster == "player" or caster == "pet" or caster == "vehicle") then
		if (button.isDebuff) then
			return (not button.noDuration and duration < 61) -- show most ticking DoTs
		else
			return (not button.noDuration and duration < 31) -- show short buffs, like HoTs
		end
	end
end
