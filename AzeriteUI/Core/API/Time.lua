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

-- Lua API
local _G = _G
local assert = assert
local date = date
local debugstack = debugstack
local error = error
local pairs = pairs
local select = select
local string_format = string.format
local string_join = string.join
local string_match = string.match
local tonumber = tonumber
local type = type

-- WoW API
local GetGameTime = GetGameTime

-- WoW Strings
local S_AM = TIMEMANAGER_AM
local S_PM = TIMEMANAGER_PM


-- This. Is. The. Worst. 
local dateInRange = function(day1, month1, year1, day2, month2, year2)
	local currentDay = tonumber(date("%d"))
	local currentMonth = tonumber(date("%m"))
	local currentYear = tonumber(date("%Y")) -- full 4 digit year

	-- Wrong year, no match.
	if (currentYear < year1) or (currentYear > year2) then
		return false
	end

	-- Same year and first date passed?
	if (currentYear == year1) and (currentMonth >= month1) and (currentDay >= day1) then

		-- It expires this or next year?
		if (year2 > currentYear) then
			return true -- next year, so still in the range.
		
		-- It expires this year, but not this month.
		elseif (currentMonth < month2) then
			return true -- haven't reached end month, so still in the range.

		-- We've passed the expiration date.
		elseif (currentMonth > month2) then
			return false -- we passed the end month, not in range.

		-- Same month, let's compare days.
		else
			return (currentDay <= day2)
		end
	end
end

-- Calculates standard hours from a give 24-hour time
-- Keep this systematic to the point of moronic, or I'll mess it up again. 
local ComputeStandardHours = function(hour)
	if 		(hour == 0) then 					return 12, S_AM 		-- 0 is 12 AM
	elseif 	(hour > 0) and (hour < 12) then 	return hour, S_AM 		-- 01-11 is 01-11 AM
	elseif 	(hour == 12) then 					return 12, S_PM 		-- 12 is 12 PM
	elseif 	(hour > 12) then 					return hour - 12, S_PM 	-- 13-24 is 01-12 PM
	end
end

-- Calculates military time, but assumes the given time is standard (12 hour)
local ComputeMilitaryHours = function(hour, am)
	if (am and hour == 12) then
		return 0
	elseif (not am and hour < 12) then
		return hour + 12
	else
		return hour
	end
end

-- Retrieve the local client computer time
local GetLocalTime = function(useStandardTime)
	local hour, minute = tonumber(date("%H")), tonumber(date("%M"))
	if useStandardTime then 
		local hour, suffix = ComputeStandardHours(hour)
		return hour, minute, suffix
	else 
		return hour, minute
	end 
end

-- Retrieve the server time
local GetServerTime = function(useStandardTime)
	local hour, minute = GetGameTime()
	if useStandardTime then 
		local hour, suffix = ComputeStandardHours(hour)
		return hour, minute, suffix
	else 
		return hour, minute
	end
end

local GetTime = function(useStandardTime, useServerTime)
    if (useServerTime) then
        return GetServerTime(useStandardTime)
    else
        return GetLocalTime(useStandardTime)
    end
end

-- 2022 Retail Winter Veil.
local IsWinterVeil = function()
	return dateInRange(16,12,2022,2,1,2023)
end

-- 2022 Retail Love is in the Air.
local IsLoveFestival = function()
	return dateInRange(7,2,2022,21,2,2022)
end

-- Global API
---------------------------------------------------------
API.ComputeMilitaryHours = ComputeMilitaryHours
API.ComputeStandardHours = ComputeStandardHours
API.GetTime = GetTime
API.GetLocalTime = GetLocalTime
API.GetServerTime = GetServerTime
API.IsWinterVeil = IsWinterVeil
API.IsLoveFestival = IsLoveFestival
