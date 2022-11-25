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
local ChatFrames = ns:NewModule("ChatFrames", "LibMoreEvents-1.0", "AceHook-3.0", "AceConsole-3.0")

-- Lua API
local _G = _G
local ipairs = ipairs
local math_floor = math.floor
local pairs = pairs
local string_format = string.format
local string_lower = string.lower

-- WoW API
local FCF_DockFrame = FCF_DockFrame
local FCF_GetChatWindowInfo = FCF_GetChatWindowInfo
local FCF_SetButtonSide = FCF_SetButtonSide
local FCF_SetLocked = FCF_SetLocked
local FCF_SetTabPosition = FCF_SetTabPosition
local FCF_SetWindowAlpha = FCF_SetWindowAlpha
local FCF_SetWindowColor = FCF_SetWindowColor
local FCF_UpdateButtonSide = FCF_UpdateButtonSide
local FCFDock_GetChatFrames = FCFDock_GetChatFrames
local FCFDock_GetInsertIndex = FCFDock_GetInsertIndex
local FCFDock_HideInsertHighlight = FCFDock_HideInsertHighlight
local FCFDock_PlaceInsertHighlight = FCFDock_PlaceInsertHighlight
local GetCursorPosition = GetCursorPosition
local hooksecurefunc = hooksecurefunc
local IsMouseButtonDown = IsMouseButtonDown
local UIFrameFadeRemoveFrame = UIFrameFadeRemoveFrame

-- Addon API
local GetFont = ns.API.GetFont
local GetPosition = ns.API.GetPosition
local SetObjectScale = ns.API.SetObjectScale
local UIHider = ns.Hider

-- Global buttons not unique to any frame
local GLOBAL_BUTTONS = {
	"ChatFrameMenuButton",
	"ChatFrameChannelButton",
	"ChatFrameToggleVoiceDeafenButton",
	"ChatFrameToggleVoiceMuteButton",
	"ChatMenu"
}

-- ChatFrame Texture Suffixes
local TEXTURES = {
	Frame = {
		"Background",
		"TopLeftTexture", "TopRightTexture",
		"BottomLeftTexture", "BottomRightTexture",
		"LeftTexture", "RightTexture",
		"BottomTexture", "TopTexture"
	},
	ButtonFrame = {
		"Background",
		"TopLeftTexture", "TopRightTexture",
		"BottomLeftTexture", "BottomRightTexture",
		"LeftTexture", "RightTexture",
		"BottomTexture", "TopTexture"
	},
	EditBox = {
		"Left", "Mid", "Right",
		"FocusLeft", "FocusMid", "FocusRight",
		"ConversationIcon"
	},
	Tab = {
		"Left", "Middle", "Right",
		"SelectedLeft", "SelectedMiddle", "SelectedRight",
		"HighlightLeft", "HighlightMiddle", "HighlightRight",
		"ActiveLeft", "ActiveMiddle", "ActiveRight" -- 10.0
	}
}

-- Local element cache for lookups without member properties
local Elements = setmetatable({}, { __index = function(t,k) rawset(t,k,{}) return rawget(t,k) end })

-------------------------------------------------------
-- Rewritten Blizzard API
-------------------------------------------------------
local Tab_OnDragStop = function(tab, dragButton)

	local id = tab:GetID()
	local frame = _G["ChatFrame"..id]
	frame:StopMovingOrSizing()
	tab:UnlockHighlight()

	FCFDock_HideInsertHighlight(GENERAL_CHAT_DOCK)

	if (GENERAL_CHAT_DOCK:IsMouseOver(10, -10, 0, 10)) then
		local mouseX, mouseY = GetCursorPosition()
		mouseX, mouseY = mouseX / UIParent:GetScale(), mouseY / UIParent:GetScale()
		FCF_DockFrame(frame, FCFDock_GetInsertIndex(GENERAL_CHAT_DOCK, frame, mouseX, mouseY), true)
	else
		FCF_SetTabPosition(frame, 0)
	end

	ChatFrames:StoreFrame(frame)

	MOVING_CHATFRAME = nil
end

local Tab_OnUpdate = function(tab, elapsed)

	local cursorX, cursorY = GetCursorPosition()
	cursorX, cursorY = cursorX / UIParent:GetScale(), cursorY / UIParent:GetScale()

	local frame = _G["ChatFrame"..tab:GetID()]
	if (frame ~= GENERAL_CHAT_DOCK.primary and GENERAL_CHAT_DOCK:IsMouseOver(10, -10, 0, 10)) then
		FCFDock_PlaceInsertHighlight(GENERAL_CHAT_DOCK, frame, cursorX, cursorY)
	else
		FCFDock_HideInsertHighlight(GENERAL_CHAT_DOCK)
	end

	FCF_UpdateButtonSide(frame)

	if (frame == GENERAL_CHAT_DOCK.primary or not frame.isLocked) then
		for _, frame in pairs(FCFDock_GetChatFrames(GENERAL_CHAT_DOCK)) do
			FCF_SetButtonSide(frame, FCF_GetButtonSide(GENERAL_CHAT_DOCK.primary))
		end
	end

	if (not IsMouseButtonDown(tab.dragButton)) then
		Tab_OnDragStop(tab, tab.dragButton)
		tab.dragButton = nil
		tab:SetScript("OnUpdate", nil)
	end

end

local Tab_OnDragStart = function(tab, button)

	local frame = _G["ChatFrame"..tab:GetID()]
	if (frame == DEFAULT_CHAT_FRAME) then
		if (frame.isLocked) then
			return
		end

		frame:StartMoving()
		frame:SetUserPlaced(false)

		MOVING_CHATFRAME = frame

	elseif (frame.isDocked) then

		FCF_UnDockFrame(frame)
		FCF_SetLocked(frame, false)

		local chatTab = _G[frame:GetName().."Tab"]
		local x,y = chatTab:GetCenter()
		x = x - (chatTab:GetWidth()/2)
		y = y - (chatTab:GetHeight()/2)

		chatTab:ClearAllPoints()
		frame:ClearAllPoints()
		frame:SetPoint("TOPLEFT", "UIParent", "BOTTOMLEFT", x, y)

		FCF_SetTabPosition(frame, 0)

		frame:StartMoving()
		frame:SetUserPlaced(false)

		MOVING_CHATFRAME = frame
		SELECTED_CHAT_FRAME = frame

		if (Blizzard_CombatLog_Update_QuickButtons) then
			Blizzard_CombatLog_Update_QuickButtons()
		end

	else
		if (frame.isLocked) then
			return
		end
		frame:StartMoving()
		frame:SetUserPlaced(false)

		SELECTED_CHAT_FRAME = frame
		MOVING_CHATFRAME = frame
	end

	tab:LockHighlight()

	-- OnUpdate simulates OnDragStop
	-- This is a hack fix we need to do because when SetParent is called,
	-- the OnDragStop never fires for the matching OnDragStart.
	tab.dragButton = button
	tab:SetScript("OnUpdate", Tab_OnUpdate)

end

local Tab_PostEnter = function(tab)
	local frame = _G["ChatFrame"..tab:GetID()]
	Elements[frame].isMouseOverTab = true
	ChatFrames:UpdateClutter()
end

local Tab_PostLeave = function(tab)
	local frame = _G["ChatFrame"..tab:GetID()]
	Elements[frame].isMouseOverTab = false
	ChatFrames:UpdateClutter()
end

-------------------------------------------------------
-- Custom ChatFrame API
-------------------------------------------------------
local ChatFrame = {}

-- Getters
-------------------------------------------------------
ChatFrame.GetEditBox = function(self)
	if (not Elements[self].editBox) then
		Elements[self].editBox = _G[self:GetName().."EditBox"]
	end
	return Elements[self].editBox
end

ChatFrame.GetButtonFrame = function(self)
	if (not Elements[self].buttonFrame) then
		Elements[self].buttonFrame = _G[self:GetName().."ButtonFrame"]
	end
	return Elements[self].buttonFrame
end

ChatFrame.GetMinimizeButton = function(self)
	if (not Elements[self].minimizeButton) then
		Elements[self].minimizeButton = _G[self:GetName().."ButtonFrameMinimizeButton"]
	end
	return Elements[self].minimizeButton
end

ChatFrame.GetUpButton = function(self)
	if (not Elements[self].upButton) then
		Elements[self].upButton = _G[self:GetName().."ButtonFrameUpButton"]
	end
	return Elements[self].upButton
end

ChatFrame.GetDownButton = function(self)
	if (not Elements[self].downButton) then
		Elements[self].downButton = _G[self:GetName().."ButtonFrameDownButton"]
	end
	return Elements[self].downButton
end

ChatFrame.GetToBottomButton = function(self)
	if (not Elements[self].scrollToBottomButton) then
		Elements[self].scrollToBottomButton = _G[self:GetName().."ButtonFrameBottomButton"]
	end
	return Elements[self].scrollToBottomButton
end

ChatFrame.GetScrollBar = function(self)
	if (not Elements[self].scrollBar) then
		Elements[self].scrollBar = self.ScrollBar
	end
	return Elements[self].scrollBar
end

ChatFrame.GetScrollBarThumbTexture = function(self)
	if (not Elements[self].scrollBarThumbTexture) then
		Elements[self].scrollBarThumbTexture = self.ScrollBar and self.ScrollBar.ThumbTexture
	end
	return Elements[self].scrollBarThumbTexture
end

ChatFrame.GetTab = function(self)
	if (not Elements[self].tab) then
		Elements[self].tab = self.tab or _G[self:GetName() .. "Tab"]
	end
	return Elements[self].tab
end

ChatFrame.GetTabIcon = function(self)
	if (not Elements[self].tabIcon) then
		Elements[self].tabIcon = _G[self:GetName().."TabConversationIcon"]
	end
	return Elements[self].tabIcon
end

ChatFrame.GetTabText = function(self)
	if (not Elements[self].tabText) then
		Elements[self].tabText = _G[self:GetName().."TabText"] or _G[self:GetName().."Tab"].Text -- 10.0.0
	end
	return Elements[self].tabText
end

-- Iterators
-------------------------------------------------------
-- Returns an iterator for the chatframe textures
ChatFrame.GetFrameTextures = function(self)
	local editBox = ChatFrame.GetEditBox(self)
	if (editBox) then
		local counter = 0
		local numEntries = #TEXTURES.Frame
		local name = self:GetName()
		return function()
			local tex
			while (numEntries > counter) do
				counter = counter + 1
				tex = _G[name..TEXTURES.Frame[counter]]
				if (tex) then
					break
				end
			end
			if (counter <= numEntries) then
				return tex
			end
		end
	end
end

-- Returns an iterator for the buttonframe textures
ChatFrame.GetButtonFrameTextures = function(self)
	local buttonFrame = ChatFrame.GetButtonFrame(self)
	if (buttonFrame) then
		local counter = 0
		local numEntries = #TEXTURES.ButtonFrame
		local name = buttonFrame:GetName()
		return function()
			local tex
			while (numEntries > counter) do
				counter = counter + 1
				tex = _G[name..TEXTURES.ButtonFrame[counter]]
				if (tex) then
					break
				end
			end
			if (counter <= numEntries) then
				return tex
			end
		end
	end
end

-- Returns an iterator for the editbox textures
ChatFrame.GetEditBoxTextures = function(self)
	local editBox = ChatFrame.GetEditBox(self)
	if (editBox) then
		local counter = 0
		local numEntries = #TEXTURES.EditBox
		local name = editBox:GetName()
		return function()
			local tex
			while (numEntries > counter) do
				counter = counter + 1
				tex = _G[name..TEXTURES.EditBox[counter]]
				if (tex) then
					break
				end
			end
			if (counter <= numEntries) then
				return tex
			end
		end
	end
end

-- Returns an iterator for the tab textures
ChatFrame.GetTabTextures = function(self)
	local tab = ChatFrame.GetTab(self)
	if (tab) then
		local counter = 0
		local numEntries = #TEXTURES.Tab
		local name = tab:GetName()
		return function()
			local tex
			while (numEntries > counter) do
				counter = counter + 1
				tex = _G[name..TEXTURES.Tab[counter]] or tab[TEXTURES.Tab[counter]] -- 10.0
				if (tex) then
					break
				end
			end
			if (counter <= numEntries) then
				return tex
			end
		end
	end
end

-- Post Updates
-------------------------------------------------------
-- Apply our own font family and style, keep size.
ChatFrame.PostUpdateFont = function(self)
	if (self._templock) then
		return
	end
	self._templock = true

	local fontObject = self:GetFontObject()
	local font, size, style = fontObject:GetFont()
	fontObject:SetFont(font, size, "OUTLINE")
	fontObject:SetShadowColor(0,0,0,.5)
	fontObject:SetShadowOffset(-.75, -.75)
	--fontObject:SetFont(font, size, "")
	--fontObject:SetShadowColor(0,0,0,.75)

	self._templock = nil
end

-------------------------------------------------------
-- Module API
-------------------------------------------------------
ChatFrames.StyleChat = function(self, frame)
	local name = frame:GetName()
	local id = frame:GetID()

	frame:SetFrameStrata("MEDIUM")
	frame:SetClampedToScreen(true)
	--frame:SetClampRectInsets(-54, -54, -54, -310)
	frame:SetClampRectInsets(-54, -54, -54, -54)
	frame:SetFading(5)
	frame:SetTimeVisible(25)
	frame:SetIndentedWordWrap(false)
	frame.ignoreFramePositionManager = true

	SetObjectScale(frame)

	FCF_SetWindowColor(frame, 0, 0, 0, 0)
	FCF_SetWindowAlpha(frame, 0, 1)
	FCFTab_UpdateAlpha(frame)

	if (Elements[frame].styled) then
		return
	end

	local editBox = ChatFrame.GetEditBox(frame)
	local buttonFrame = ChatFrame.GetButtonFrame(frame)
	local minimizeButton = ChatFrame.GetMinimizeButton(frame)
	local bottomButton = ChatFrame.GetToBottomButton(frame)
	local scrollBar = ChatFrame.GetScrollBar(frame)
	local scrollTexture = ChatFrame.GetScrollBarThumbTexture(frame)
	local tab = ChatFrame.GetTab(frame)

	for tex in ChatFrame.GetFrameTextures(frame) do
		tex:SetTexture(nil)
		tex:SetAlpha(0)
	end

	if (buttonFrame) then
		-- Take control of the tab's alpha changes
		-- and disable blizzard's own fading.
		buttonFrame:SetAlpha(1)
		buttonFrame.SetAlpha = UIFrameFadeRemoveFrame

		--buttonFrame:SetParent(UIHider)
		for tex in ChatFrame.GetButtonFrameTextures(frame) do
			tex:SetTexture(nil)
			tex:SetAlpha(0)
		end
	end

	if (tab) then

		local fontObject = GetFont(13,true,"Chat")

		-- Take control of the tab's alpha changes
		-- and disable blizzard's own fading.
		tab:SetNormalFontObject(fontObject)
		tab:SetAlpha(1)
		tab.SetAlpha = UIFrameFadeRemoveFrame

		-- kill the tab textures
		for tex in ChatFrame.GetTabTextures(frame) do
			tex:SetTexture(nil)
			tex:SetAlpha(0)
		end

		local tabText = ChatFrame.GetTabText(frame)
		if (tabText) then
			tabText:Hide()
			tabText:SetAlpha(.5)
			tabText:SetFontObject(fontObject)
		end

		local tabIcon = ChatFrame.GetTabIcon(frame)
		if (tabIcon) then
			tabIcon:Hide()
		end

		-- Replace the drag handler with one supporting our scale
		-- This taints the editmode, have to redo this whole system for WoW10.
		if (not ns.IsRetail) then
			tab:SetScript("OnDragStart", Tab_OnDragStart)
		end

		-- Toggle tab text visibility on hover
		tab:HookScript("OnEnter", Tab_PostEnter)
		tab:HookScript("OnLeave", Tab_PostLeave)
	end

	if (editBox) then
		for tex in ChatFrame.GetEditBoxTextures(frame) do
			tex:SetTexture(nil)
			tex:SetAlpha(0)
		end

		editBox:Hide()
		editBox:SetAltArrowKeyMode(false)
		editBox:SetHeight(45)
		editBox:ClearAllPoints()
		editBox:SetPoint("LEFT", frame, "LEFT", -15, 0)
		editBox:SetPoint("RIGHT", frame, "RIGHT", 15, 0)
		editBox:SetPoint("TOP", frame, "BOTTOM", 0, -1)
	end

	ChatFrames:UpdateChatFont(frame)

	hooksecurefunc(frame, "SetFont", function(...) ChatFrames:UpdateChatFont(...) end) -- blizzard use this
	hooksecurefunc(frame, "SetFontObject", function(...) ChatFrames:UpdateChatFont(...) end) -- not blizzard

	Elements[frame].styled = true

	for _,frameName in pairs(_G.CHAT_FRAMES) do
		local frame = _G[frameName]
		if (frame) then


			-- Replace the frame's drag handler,
			-- as we're using our own system to handle our own scale.
			local tab = frame.tab or _G[frameName .. "Tab"]
			if (tab) then
			end
		end
	end

	if (self.PostSetupChatFrames) then
		self:PostSetupChatFrames()
	end
end

ChatFrames.SetupChatFrames = function(self)
	for _,frameName in pairs(_G.CHAT_FRAMES) do
		local frame = _G[frameName]
		if (frame) then
			self:StyleChat(frame)
		end
	end
	if (self.PostUpdateChatFrames) then
		self:PostUpdateChatFrames()
	end
end

ChatFrames.SetupChatDefaults = function(self)

	-- Need to set this to avoid frame popping back up
	CHAT_FRAME_BUTTON_FRAME_MIN_ALPHA = 0

	-- Chat window chat heights
	if (CHAT_FONT_HEIGHTS) then
		for i = #CHAT_FONT_HEIGHTS, 1, -1 do
			CHAT_FONT_HEIGHTS[i] = nil
		end
		-- Ensure we have bigger fonts for Wrath!
		for i,v in ipairs({ 12, 14, 16, 18, 20, 22, 24, 28, 32 }) do
			CHAT_FONT_HEIGHTS[i] = v
		end
	end

end

ChatFrames.SetupChatHover = function(self)
	self.frame.elapsed = 0
	self.frame:SetScript("OnUpdate", function(frame, elapsed)
		frame.elapsed = frame.elapsed - elapsed
		if (frame.elapsed > 0) then
			return
		end
		frame.elapsed = 1/60
		self:UpdateClutter()
	end)
end

ChatFrames.SetupDockingLocks = function(self)
	--if (self.OverrideDockingLocks) then
	--	self:OverrideDockingLocks()
	--else
	--	FCF_SetLocked(ChatFrame1, true)
	--	hooksecurefunc("FCF_ToggleLockOnDockedFrame", function()
	--		for _, frame in pairs(FCFDock_GetChatFrames(_G.GENERAL_CHAT_DOCK)) do
	--			FCF_SetLocked(frame, true)
	--		end
	--	end)
	--end
end

ChatFrames.UpdateChatPositions = function(self)

	-- Put the primary frame in its default position
	-- if no saved position is found for it.
	if (not ns.db.global.chat.storedFrames[1]) then
		local frame = _G.ChatFrame1
		frame:SetUserPlaced(false)
		frame:ClearAllPoints()
		frame:SetSize(self:GetDefaultChatFrameSize())
		frame:SetPoint(self:GetDefaultChatFramePosition())
		frame.ignoreFramePositionManager = true
		FCF_SetLocked(frame, true)
		FCF_UpdateButtonSide(frame)
	end

	-- Attach the scaffold to the primary frame
	local scaffold = self.frame
	scaffold:ClearAllPoints()
	scaffold:SetAllPoints(ChatFrame1)

	-- Restore all saved frames
	ChatFrames:RestoreAllFrames()
end

ChatFrames.UpdateChatFont = function(self, ...)
	if (self.OverrideChatFont) then
		self:OverrideChatFont(...)
	else
		ChatFrame.PostUpdateFont(...)
	end
end

ChatFrames.UpdateDockedChatTabs = function(self)
	local frame = ChatFrame1
	if (self.frame:IsMouseOver(30,0,-30,30)) then
		for _,frameName in pairs(_G.CHAT_FRAMES) do
			local frame = _G[frameName]
			if (frame) then
				local name, fontSize, r, g, b, a, shown, locked, docked, uninteractable = FCF_GetChatWindowInfo(frame:GetID())
				if (docked and not frame.minimized) then
					local tabText = ChatFrame.GetTabText(frame)
					if (tabText) then
						tabText:Show()
						if (shown) then
							tabText:SetAlpha(.9)
						else
							tabText:SetAlpha(.5)
						end
					end
				end
			end
		end

	else
		for _,frameName in pairs(_G.CHAT_FRAMES) do
			local frame = _G[frameName]
			if (frame) then
				local name, fontSize, r, g, b, a, shown, locked, docked, uninteractable = FCF_GetChatWindowInfo(frame:GetID())
				if (docked and not frame.minimized) then
					local tabText = ChatFrame.GetTabText(frame)
					if (tabText) then tabText:Hide() end
				end
			end
		end

	end
end

ChatFrames.UpdateButtons = function(self, event, ...)

	local atDock
	for _,frameName in pairs(_G.CHAT_FRAMES) do
		local frame = _G[frameName]
		if (frame) then
			local name, fontSize, r, g, b, a, shown, locked, docked, uninteractable = FCF_GetChatWindowInfo(frame:GetID())
			local isMouseOver

			if (frame == ChatFrame2) then
				isMouseOver = frame:IsMouseOver(60,0,-30,30)
			else
				isMouseOver = frame:IsMouseOver(30,0,-30,30)
			end

			if (isMouseOver) and (shown and shown ~= 0) and (not frame.minimized) then
				if (docked or frame == ChatFrame1) then -- dock position or nil
					atDock = true
				end

				if (not Elements[frame].isMouseOver) then

					local buttonFrame = ChatFrame.GetButtonFrame(frame)
					local up = ChatFrame.GetUpButton(frame)
					local down = ChatFrame.GetDownButton(frame)
					local bottom = ChatFrame.GetToBottomButton(frame)

					if (up) then up:SetParent(buttonFrame) end
					if (down) then down:SetParent(buttonFrame) end
					if (bottom) then bottom:SetParent(buttonFrame) end

					local tabText = ChatFrame.GetTabText(frame)
					tabText:Show()

					if (ChatFrame.GetTab(frame):IsMouseOver()) then
						tabText:SetAlpha(.9)
					else
						tabText:SetAlpha(.5)
					end

					Elements[frame].isMouseOver = true
				end
			else
				-- Todo: check out what happens when minimized.
				if (event == "PLAYER_ENTERING_WORLD") or (Elements[frame].isMouseOver) then

					local up = ChatFrame.GetUpButton(frame)
					local down = ChatFrame.GetDownButton(frame)
					local bottom = ChatFrame.GetToBottomButton(frame)

					if (up) then up:SetParent(UIHider) end
					if (down) then down:SetParent(UIHider) end
					if (bottom) then bottom:SetParent(UIHider) end

					ChatFrame.GetTabText(frame):Hide()

					Elements[frame].isMouseOver = false
				end
			end
		end
	end

	if (atDock) then
		for button in self:GetGlobalButtons() do
			button:SetAlpha(1)
		end
	else
		for button in self:GetGlobalButtons() do
			button:SetAlpha(0)
		end
	end

end

ChatFrames.UpdateClutter = function(self, event, ...)
	self:UpdateDockedChatTabs()
	self:UpdateButtons(event, ...)
end

ChatFrames.KillToastButton = function(self)
	if (QuickJoinToastButton) then
		QuickJoinToastButton:SetParent(UIHider)
	end
end

-- Returns an iterator for the global buttons
ChatFrames.GetGlobalButtons = function(self)
	local counter = 0
	local numEntries = #GLOBAL_BUTTONS
	return function()
		local button
		while (numEntries > counter) do
			counter = counter + 1
			button = _G[GLOBAL_BUTTONS[counter]]
			if (button) then
				break
			end
		end
		if (counter <= numEntries) then
			return button
		end
	end
end

-- Movable Frames
-------------------------------------------------------
ChatFrames.StoreFrame = function(self, frame, ...)
	local id = frame:GetID()
	local db = ns.db.global.chat.storedFrames[id]
	if (not db) then
		db = {
			Place = nil,
			Size = nil,
			FontFamily = nil,
			FontSize = nil
		}
		ns.db.global.chat.storedFrames[id] = db
	end
	db.Place = { GetPosition(frame) }
	db.Size = { frame:GetSize() }
	db.Scale = { frame:GetEffectiveScale() }
end

ChatFrames.RestoreFrame = function(self, frame, ...)
	local id = frame:GetID()
	local db = ns.db.global.chat.storedFrames[id]
	if (not db) then
		return
	end
	frame:SetUserPlaced(false)
	frame:ClearAllPoints()
	frame:SetPoint(unpack(db.Place))
	frame:SetSize(unpack(db.Size))
	FCF_UpdateButtonSide(frame)
end

ChatFrames.RestoreAllFrames = function(self)
	local frame
	for id,db in pairs(ns.db.global.chat.storedFrames) do
		frame = _G["ChatFrame"..id]
		if (frame and frame:IsShown()) then
			self:RestoreFrame(frame)
		end
	end
	-- Dock any floating frames not currently saved in the addon.
	for _,frameName in pairs(_G.CHAT_FRAMES) do
		local frame = _G[frameName]
		if (frame and frame:IsShown()) then
			local id = frame:GetID()
			if (not ns.db.global.chat.storedFrames[id]) then
				local name, fontSize, r, g, b, a, shown, locked, docked, uninteractable = FCF_GetChatWindowInfo(id)
				if (id ~= 1 and not docked and not frame.minimized) then
					FCF_DockFrame(frame)
				end
			end
		end
	end
end

ChatFrames.ResetChat = function(self, input)
	local all
	local args = { self:GetArgs(string_lower(input)) }
	for _,arg in ipairs(args) do
		if (arg == "all") then
			all = true
		end
	end
	local needsUpdate
	if (all) then
		for id in pairs(ns.db.global.chat.storedFrames) do
			ns.db.global.chat.storedFrames[id] = nil
			needsUpdate = true
		end
	else
		if (ns.db.global.chat.storedFrames[1]) then
			ns.db.global.chat.storedFrames[1] = nil
			needsUpdate = true
		end
	end
	if (needsUpdate) then
		ChatFrames:UpdateChatPositions()
	end
end

-- Module Core
-------------------------------------------------------
ChatFrames.OnEvent = function(self, event, ...)
	if (event == "PLAYER_ENTERING_WORLD") then
		local isInitialLogin, isReloadingUi = ...
		if (isInitialLogin or isReloadingUi) then
			self:SetupChatFrames()
			self:SetupChatHover()
			self:SetupDockingLocks()
			self:UpdateChatPositions()
			self:UpdateClutter(event, ...)
			self:RegisterEvent("UPDATE_CHAT_WINDOWS", "OnEvent")
			self:RegisterEvent("UPDATE_FLOATING_CHAT_WINDOWS", "OnEvent")
			self:SecureHook("FCF_OpenTemporaryWindow", "SetupChatFrames")
			self:SecureHook("FCF_DockUpdate","UpdateClutter")
			ChatFrame1:Clear()
		end
		self:KillToastButton()

	elseif (event == "UPDATE_CHAT_WINDOWS" or event == "UPDATE_FLOATING_CHAT_WINDOWS") then
		self:SetupChatFrames()
		self:UpdateChatPositions()
		self:UpdateClutter(event, ...)
	end
end

ChatFrames.GetDefaultChatFrameSize = function(self)
	return unpack(ns.Config.Chat.Default.Size)
end

ChatFrames.GetDefaultChatFramePosition = function(self)
	return unpack(ns.Config.Chat.Default.Position)
end

ChatFrames.OnInitialize = function(self)

	local scaffold = SetObjectScale(CreateFrame("Frame", nil, UIParent))
	scaffold:SetSize(self:GetDefaultChatFrameSize())
	scaffold:SetPoint(self:GetDefaultChatFramePosition())
	self.frame = scaffold
	self:SetupChatDefaults()
	self:RegisterChatCommand("resetchat", "ResetChat")

end

ChatFrames.OnEnable = function(self)
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
end
