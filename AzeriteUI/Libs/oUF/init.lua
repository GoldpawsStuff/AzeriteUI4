local _, ns = ...
ns.oUF = {}
ns.oUF.Private = {}

local patch, build, date, version = GetBuildInfo()
local major, minor = string.split(".", patch)

ns.oUF.clientVersion = version
ns.oUF.clientDate = date
ns.oUF.clientPatch = patch
ns.oUF.clientMajor = tonumber(major)
ns.oUF.clientMinor = tonumber(minor)
ns.oUF.clientBuild = tonumber(build)

ns.oUF.isRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)
ns.oUF.isClassic = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC)
ns.oUF.isTBC = (WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC)
ns.oUF.isWrath = (WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC)

ns.oUF.WoW10 = version >= 100000
