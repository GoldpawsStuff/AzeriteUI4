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
local LAB10GE = LibStub("LibActionButton-1.0-GoldpawEdition")

-- Addon API
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia
local SetObjectScale = ns.API.SetObjectScale
local RegisterCooldown = ns.Widgets.RegisterCooldown
local UIHider = ns.Hider
local noop = ns.Noop

local ActionButton = {}
ns.ActionButton = ActionButton
ns.ActionButtons = {}

-- Constructor
ActionButton.Create = function(self, id, name, header, config)

	local button = LAB10GE:CreateButton(id, name, header, config)
	button.icon = button.icon
	button.autoCastable = button.AutoCastable
	button.autoCastShine = button.AutoCastShine
	button.border = button.Border
	button.cooldown = button.cooldown
	button.count = button.Count
	button.flash = button.Flash
	button.flyoutArrowContainer = button.FlyoutArrowContainer -- WoW10
	button.flyoutBorder = button.FlyoutBorder
	button.flyoutBorderShadow = button.FlyoutBorderShadow
	button.hotkey = button.HotKey
	button.levelLinkLockIcon = button.LevelLinkLockIcon -- Retail
	button.macro = button.Name
	button.newActionTexture = button.NewActionTexture
	button.normalTexture = button.NormalTexture
	button.spellHighlightAnim = button.SpellHighlightAnim
	button.spellHighlightTexture = button.SpellHighlightTexture

	if (ns.WoW10) then
		button.checkedTexture = button.CheckedTexture
		button.highlightTexture = button.HighlightTexture
		button.pushedTexture = button.PushedTexture
	else
		button.checkedTexture = button:GetCheckedTexture()
		button.highlightTexture = button:GetHighlightTexture()
		button.pushedTexture = button:GetPushedTexture()
	end

	if (ns.WoW10) then
		button.bottomDivider = button.BottomDivider
		button.rightDivider = button.RightDivider
		button.slotArt = button.SlotArt
		button.slotBackground = button.SlotBackground
	end

	ns.ActionButtons[button] = true

	return button
end
