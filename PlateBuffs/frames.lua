local folder, core = ...

if not core.LibNameplates then
	return
end

local MSQ, Group = core.MSQ or LibStub("LibButtonFacade", true) or LibStub("Masque", true)
core.MSQ = MSQ

local LSM = core.LSM or LibStub("LibSharedMedia-3.0", true)
core.LSM = LSM

local Testreversepos = false

local pairs = pairs
local GetTime = GetTime
local CreateFrame = CreateFrame
local table_remove = table.remove
local table_sort = table.sort
local table_getn = table.getn
local select = select
local string_match = string.match
local math_min = math.min
local math_max = math.max
local math_ceil = math.ceil
local UnitExists = UnitExists
local string_format = string.format

local P = {}
local nametoGUIDs = core.nametoGUIDs
local buffBars = core.buffBars
local buffFrames = core.buffFrames
local guidBuffs = core.guidBuffs

core.unknownIcon = "Inv_misc_questionmark"
local unknownIconPath = "Interface\\Icons\\" .. core.unknownIcon

local defaultSettings = core.defaultSettings
defaultSettings.profile.skin_SkinID = "Blizzard"
defaultSettings.profile.skin_Gloss = false
defaultSettings.profile.skin_Backdrop = false
defaultSettings.profile.skin_Colors = {}

-- NEW API ---------

local GetPlateName = core.GetPlateName
local GetPlateGUID = core.GetPlateGUID

-------------------

do
	local OnEnable = core.OnEnable
	function core:OnEnable()
		OnEnable(self)
		P = self.db.profile --this can change on profile change.
		MSQ = core.MSQ or LibStub("LibButtonFacade", true) or LibStub("Masque", true)
		if MSQ and MSQ.RegisterSkinCallback then -- LibButtonFacade-specific
			MSQ:RegisterSkinCallback(folder, self.SkinCallback, self)
			MSQ:Group(folder):Skin(self.db.profile.skin_SkinID, self.db.profile.skin_Gloss, self.db.profile.skin_Backdrop, self.db.profile.skin_Colors)
		elseif MSQ then -- Masque-specific
			Group = MSQ:Group(folder)
		end
	end
end

local function GetTexCoordFromSize(frame, width, height)
	local gap = P.textureSize or 0.1

	local arg = width / height
	local abj
	if arg > 1 then
		abj = 1 / width * ((width - height) / 2)

		frame:SetTexCoord(0 + gap, 1 - gap, (0 + abj + gap), (1 - abj - gap))
	elseif arg < 1 then
		abj = 1 / height * ((height - width) / 2)

		frame:SetTexCoord((0 + abj + gap), (1 - abj - gap), 0 + gap, 1 - gap)
	else
		frame:SetTexCoord(0 + gap, 1 - gap, 0 + gap, 1 - gap)
	end
	return false
end

-- Update a spell frame's texture size.
local function UpdateIconSize(frame, width, height)
	width, height = width or 24, height or 24

	local d = (width * frame.msqborder.bordersize) / frame.msqborder.normalsize
	local d2 = (height * frame.msqborder.bordersize) / frame.msqborder.normalsize
	frame.msqborder:SetSize(d, d2)

	frame.icon:SetSize(width, height)
	GetTexCoordFromSize(frame.texture, width, height)
	frame:SetWidth(width + (P.intervalX or 12))
	frame:SetHeight(height + (P.intervalY or 12))
end

-- Set cooldown text size.
local function UpdateDurationFont(buffFrame, increase)
	local font = P.cooldownFont and LSM:Fetch("font", P.cooldownFont) or "Fonts\\FRIZQT__.TTF"
	local size = P.cooldownSize * increase
	if buffFrame.cdFont ~= font or buffFrame.cdSize ~= size then
		buffFrame.cdFont, buffFrame.cdSize = font, size
		buffFrame.durationText:SetFont(font, size, "OUTLINE")
	end
end

-- Set the duration text anchor
local function SetDurationAnchor(frame)
	local anchor = P.cdAnchor
	frame.durationText:ClearAllPoints()
	if anchor == "TOP" then
		frame.durationText:SetPoint("BOTTOM", frame.icon, "TOP", P.cdOffsetX, P.cdOffsetY + 3)
	elseif anchor == "CENTER" then
		frame.durationText:SetPoint("CENTER", frame.icon, "CENTER", P.cdOffsetX, P.cdOffsetY)
	elseif anchor == "BOTTOM" then
		frame.durationText:SetPoint("TOP", frame.icon, "BOTTOM", P.cdOffsetX, P.cdOffsetY -3)
	end
end

-- Set alt. cooldown text size.
local function UpdateDuration2Font(buffFrame, increase)
	local font = P.cooldown2Font and LSM:Fetch("font", P.cooldown2Font) or "Fonts\\FRIZQT__.TTF"
	local size = P.cd2Scaled and (P.cooldown2Size * increase) or P.cooldown2Size
	if buffFrame.cd2Font ~= font or buffFrame.cd2Size ~= size then
		buffFrame.cd2Font, buffFrame.cd2Size = font, size
		buffFrame.durationText2:SetFont(font, size, "NORMAL")
	end
end

-- Set the stack text size.
local function UpdateStackSize(buffFrame, size)
	if buffFrame.stackFontSize ~= size then
		buffFrame.stackFontSize = size
		buffFrame.stack:SetFont("Fonts\\FRIZQT__.TTF", size, "OUTLINE")
	end
end

local secondsFormat = { [0] = "%.0f", [1] = "%.1f", [2] = "%.2f" }
local secondsMult   = { [0] = 1,      [1] = 10,     [2] = 100 }

-- Returns the largest non-zero unit in a readable string format: "2h", "33m", "9.5"
-- decimals only applies to the seconds case (0, 1 or 2)
local function SecondsToString(seconds, decimals)
	if seconds <= 0 then return "" end
	if seconds <= 60 then
		decimals = decimals or 0
		local mult = secondsMult[decimals] or 10 ^ decimals
		return string_format(secondsFormat[decimals] or ("%." .. decimals .. "f"), math_ceil(seconds * mult) / mult)
	end
	if seconds <= 3600 then return math_ceil(seconds / 60) .. "m" end
	if seconds <= 86400 then return math_ceil(seconds / 3600) .. "h" end
	if seconds <= 2592000 then return math_ceil(seconds / 86400) .. "d" end
	if seconds <= 31536000 then return math_ceil(seconds / 2592000) .. "mo" end
	return math_ceil(seconds / 31536000) .. "y"
end

local function RedToGreen(current)
	if current >= 7 then return 1, 1, 0 end
	if current >= 3 then return 1, (current - 2) / 4, 0 end
	return 1, 0, 0
end

-- Show or hide the duration texts, honoring their duration limits.
local function UpdateDurationVisibility(frame)
	local active = frame.expirationTime > 0
	if active and not frame.overLimit and P.showCooldown then
		frame.durationText:Show()
	else
		frame.durationText:Hide()
	end
	if active and not frame.overLimit2 and P.showCooldown2 then
		frame.durationText2Bg:Show()
		frame.durationText2:Show()
	else
		frame.durationText2Bg:Hide()
		frame.durationText2:Hide()
	end
end

-- Called when spell frames are shown.
local function iconOnShow(self)
	self:SetAlpha(1)
	self.clockOverlay:Hide()
	self.stack:Hide()
	self.skin:Hide()
	self.msqborder:Hide()

	local borderTexture = P.borderTexture
	if not self.isDebuff then
		borderTexture = P.borderTextureBuff
	end

	if borderTexture == "Masque" and MSQ then
		Group = Group or MSQ:Group(folder)
		if Group then
			local skinID = Group.SkinID or Group.db and Group.db.SkinID
			local SkinData = skinID and MSQ:GetSkin(skinID)
			if SkinData then
				local bordersize, normalsize, borderoffsetX, borderoffsetY
				local ntexture = SkinData.Normal.Texture
				local btcoord, itcoord = nil, nil
				if SkinData.Template then
					bordersize = MSQ:GetSkin(SkinData.Template).Border.Height
					normalsize = MSQ:GetSkin(SkinData.Template).Icon.Height
				else
					bordersize = SkinData.Border.Height
					normalsize = SkinData.Icon.Height
				end
				self.msqborder.bgtexture = ntexture
				self.msqborder.bordersize = bordersize
				self.msqborder.normalsize = normalsize
				self.skin:SetTexture(ntexture)
			end
		end
	else
		self.msqborder.bgtexture = borderTexture
		self.msqborder.bordersize = 42
		self.msqborder.normalsize = 36
		self.skin:SetTexture(borderTexture)
	end

	local timeLeft = self.expirationTime - GetTime()
	self.overLimit = P.durationLimit > 0 and timeLeft > P.durationLimit
	self.overLimit2 = P.durationLimit2 > 0 and timeLeft > P.durationLimit2
	UpdateDurationVisibility(self)

	if self.expirationTime > 0 then
		if P.showCooldownTexture then
			self.clockOverlay:Show()
			if P.legacyCooldownTexture and self.clockOverlay.SetCooldown then
				self.clockOverlay:SetCooldown(self.startTime or GetTime(), self.duration)
			end
		end
	end

	local increase = P.increase
	if self.debuffType == "Interrupt" then
		increase = P.interruptsScale
	else
		local spellOpts = core:HaveSpellOpts(self.spellName, self.sID)
		if spellOpts then
			increase = spellOpts.increase or increase
		end
	end

	if self.playerCast and P.biggerSelfSpells then
		UpdateIconSize(self, (P.iconSize * increase * 1.2), (P.iconSize2 * increase * 1.2))
	else
		UpdateIconSize(self, P.iconSize * increase, P.iconSize2 * increase)
	end

	UpdateDurationFont(self, increase)
	UpdateDuration2Font(self, increase)
	
	if self.stackCount and self.stackCount > 1 then
		self.stack:SetText(self.stackCount)
		self.stack:Show()
		UpdateStackSize(self, P.stackSize * increase)
	end

	if self.isDebuff then
		local color = self.debuffType or ""
		if color then
			if P.colorByType then
				if color == "none" or color == "" then
					color = P.color1
				elseif color == "Magic" then 
					color = P.color2
				elseif color == "Curse" then
					color = P.color3
				elseif color == "Disease" then
					color = P.color4
				elseif color == "Poison" then
					color = P.color5
				elseif color == "Interrupt" then
					color = P.color7
				end
				self.skin:SetVertexColor(color[1], color[2], color[3], color[4])
				self.skin:Show()
				self.msqborder:Show()
			else
				self.skin:SetVertexColor(P.color1[1], P.color1[2], P.color1[3], P.color1[4])
				self.skin:Show()
				self.msqborder:Show()
			end
		end
	else
		self.skin:SetVertexColor(P.color6[1], P.color6[2], P.color6[3], P.color6[4])
		self.skin:Show()
		self.msqborder:Show()
	end
end

-- Called when spell frames are shown.
local function iconOnHide(self)
	self:SetAlpha(1)
	self.durationText:Hide()
	self.clockOverlay:Hide()
	if not P.legacyCooldownTexture then
		self.clockOverlay:SetHeight(0.00001)
	end
	self.durationText2Bg:Hide()
	self.durationText2:Hide()
	self.stack:Hide()
	self.skin:Hide()
	self.msqborder:Hide()
	UpdateIconSize(self, P.iconSize, P.iconSize2)
end

-- Fires for spell frames.
local function iconOnUpdate(self, elapsed)
	self.lastUpdate = self.lastUpdate + elapsed
	if self.lastUpdate > P.UpdateRate then
		self.lastUpdate = 0
		if self.expirationTime > 0 then
			local rawTimeLeft = self.expirationTime - GetTime()

			local overLimit = P.durationLimit > 0 and rawTimeLeft > P.durationLimit
			local overLimit2 = P.durationLimit2 > 0 and rawTimeLeft > P.durationLimit2
			if overLimit ~= self.overLimit or overLimit2 ~= self.overLimit2 then
				self.overLimit, self.overLimit2 = overLimit, overLimit2
				UpdateDurationVisibility(self)
			end

			if P.showCooldown and not overLimit then
				local decimals = (rawTimeLeft < P.decimalThreshold or P.decimalThreshold == 0) and P.digitsnumber or 0
				self.durationText:SetText(SecondsToString(rawTimeLeft, decimals))
				self.durationText:SetTextColor(RedToGreen(rawTimeLeft))
			end

			if P.showCooldown2 and not overLimit2 then
				local decimals = (rawTimeLeft < P.decimalThreshold2 or P.decimalThreshold2 == 0) and P.digitsnumber2 or 0
				self.durationText2:SetText(SecondsToString(rawTimeLeft, decimals))
				self.durationText2:SetTextColor(RedToGreen(rawTimeLeft))
			end

			if P.showCooldownTexture and not P.legacyCooldownTexture then
				if not self.clockOverlay.SetCooldown then
					self.clockOverlay:SetHeight(math_max(0.00001, (1 - rawTimeLeft / self.duration) * self.icon:GetHeight()))
				end
			end

			if P.enableBlinkFade and self.duration > P.blinkFadeMinDuration then
				local bth, fth = 1, 1
				local blinkAllowed = not P.blinkTargetOnly
				local fadeAllowed = not P.fadeTargetOnly
				if P.blinkTargetOnly or P.fadeTargetOnly then
					local isTarget = UnitExists("target") and (self.realPlate:GetAlpha() == 1)
					if P.blinkTargetOnly then
						blinkAllowed = isTarget
					end
					if P.fadeTargetOnly then
						fadeAllowed = isTarget
					end
				end
				if blinkAllowed and rawTimeLeft < (P.blinkThreshold + 1/3) then
					bth = rawTimeLeft % 1 
					if bth > 0.5 then
						bth = 1 - bth
					end
					bth = math_min(math_max(bth * 3, 0), 1)
				end
				if fadeAllowed and rawTimeLeft < P.fadeThreshold then
					fth = (rawTimeLeft / P.fadeThreshold) * 0.7 + 0.3
				end
				self:SetAlpha(bth * fth)
			end

			if rawTimeLeft < 0 then
				self:Hide()
				local GUID = GetPlateGUID(self.realPlate)
				if GUID then
					core:RemoveOldSpells(GUID)
					core:AddBuffsToPlate(self.realPlate, GUID)
				else
					local plateName = GetPlateName(self.realPlate)
					if plateName and nametoGUIDs[plateName] then
						core:RemoveOldSpells(nametoGUIDs[plateName])
						core:AddBuffsToPlate(self.realPlate, nametoGUIDs[plateName])
					end
				end
			end
		end
	end
end

function core:RemoveOldSpells(GUID)
	local t = guidBuffs[GUID]
	if not t then return end
	local currentTime = GetTime()
	local expirationTime
	for i = #t, 1, -1 do
		expirationTime = t[i].expirationTime
		if expirationTime and expirationTime > 0 and currentTime > expirationTime then
			table_remove(t, i)
		end
	end
end

local function CreateBuffFrame(parentFrame, realPlate)
	local f = CreateFrame("Frame", nil, parentFrame)
	f.realPlate = realPlate

	f.icon = CreateFrame("Frame", nil, f)
	f.icon:SetPoint("TOP", f)

	f.texture = f.icon:CreateTexture(nil, "BACKGROUND")
	f.texture:SetAllPoints(true)

	f.durationText = f.icon:CreateFontString(nil, "ARTWORK", "ChatFontNormal")
	f.durationText:SetText("")
	SetDurationAnchor(f)

	f.durationText2 = f.icon:CreateFontString(nil, "ARTWORK", "ChatFontNormal")
	f.durationText2:SetText("")
	f.durationText2:SetPoint("TOP", f.icon, "BOTTOM", 0, P.cd2OffsetY - 1)

	f.durationText2Bg = f.icon:CreateTexture(nil,"BACKGROUND")
	f.durationText2Bg:SetTexture(0,0,0)
	f.durationText2Bg:SetAlpha(P.cd2BgAlpha)
	f.durationText2Bg:SetPoint("TOPLEFT", f.durationText2, -1, 0)
	f.durationText2Bg:SetPoint("BOTTOMRIGHT", f.durationText2, 1, -1)

	if P.legacyCooldownTexture then
		f.clockOverlay = CreateFrame("Cooldown", nil, f.icon, "CooldownFrameTemplate")
		f.clockOverlay:SetAllPoints(true)
		f.clockOverlay:SetReverse(true)
	else
		f.clockOverlay = f.icon:CreateTexture(nil, "BORDER")
		f.clockOverlay:SetPoint("TOPLEFT")
		f.clockOverlay:SetPoint("TOPRIGHT")
		f.clockOverlay:SetHeight(0.00001)
		f.clockOverlay:SetTexture([[Interface\Buttons\WHITE8X8]])
		f.clockOverlay:SetVertexColor(0, 0, 0, 0.65)
	end

	core:SetFrameLevel(f)

	f.stack = f.icon:CreateFontString(nil, "OVERLAY", "ChatFontNormal")
	f.stack:SetText("")
	f.stack:SetPoint("BOTTOMRIGHT", f.icon, "BOTTOMRIGHT", -1, 3)

	f.lastUpdate = 0
	f.expirationTime = 0
	f.duration = 0
	f:SetScript("OnShow", iconOnShow)
	f:SetScript("OnHide", iconOnHide)

	f:SetScript("OnUpdate", iconOnUpdate)
	f.stackCount = 0

	f.durationText2Bg:Hide()
	f.durationText2:Hide()	
	f.durationText:Hide()
	f.clockOverlay:Hide()
	f.stack:Hide()

	f.msqborder = CreateFrame("Frame", nil, f.icon)
	f.msqborder:SetPoint("CENTER", f.icon, "CENTER")
	f.msqborder:SetFrameLevel(f.icon:GetFrameLevel())
	f.skin = f.msqborder:CreateTexture(nil, "BORDER")
	f.skin:SetAllPoints(f.msqborder)

	--f.skin:SetBlendMode("ADD")
	f.skin:Hide()

	f.msqborder.bordersize = 1
	f.msqborder.normalsize = 1

	f.msqborder.bgtexture = nil
	f.msqborder:Hide()

	return f
end

-- Show/Hide bar background texture.
function core:UpdateBarsBackground()
	for plate in pairs(buffBars) do
		for b in pairs(buffBars[plate]) do
			if P.showBarBackground == true then
				buffBars[plate][b].barBG:Show()
			else
				buffBars[plate][b].barBG:Hide()
			end
		end
	end
end

-- Create and return a bar frame.
local function CreateBarFrame(parentFrame, realPlate)
	local f = CreateFrame("frame", nil, parentFrame)
	f.realPlate = realPlate
	--f:SetFrameStrata("BACKGROUND")

	f:SetWidth(1)
	f:SetHeight(1)

	--Make the text easier to see.
	f.barBG = f:CreateTexture(nil, "BACKGROUND")
	f.barBG:SetAllPoints(true)

	f.barBG:SetTexture(1, 1, 1, 0.3)
	if P.showBarBackground == true then
		f.barBG:Show()
	else
		f.barBG:Hide()
	end

	f:Show()
	return f
end

-- Points used to stack bar r onto bar r-1: honours Row Growth and keeps
-- the horizontal alignment (LEFT/RIGHT/centre) of the user's bar anchor.
local function GetStackPoints()
	local side = string_match(P.barAnchorPoint, "LEFT$") or string_match(P.barAnchorPoint, "RIGHT$") or ""
	if P.barGrowth == 1 then -- up
		return "BOTTOM" .. side, "TOP" .. side
	end
	return "TOP" .. side, "BOTTOM" .. side
end

-- Build all our bar frames for a plate.
-- We anchor these to the plate and our spell frames to the bar.
local function BuildPlateBars(plate, visibleFrame)
	buffBars[plate] = buffBars[plate] or {}
	if not buffBars[plate][1] then
		buffBars[plate][1] = CreateBarFrame(visibleFrame, plate)
	end
	buffBars[plate][1]:ClearAllPoints()
	buffBars[plate][1]:SetPoint(P.barAnchorPoint, visibleFrame, P.plateAnchorPoint, P.barOffsetX, P.barOffsetY)
	buffBars[plate][1]:SetParent(visibleFrame)

	local barPoint, parentPoint = GetStackPoints()
	for r = 2, P.numBars do
		if not buffBars[plate][r] then
			buffBars[plate][r] = CreateBarFrame(visibleFrame, plate)
		end
		buffBars[plate][r]:ClearAllPoints()
		buffBars[plate][r]:SetPoint(barPoint, buffBars[plate][r - 1], parentPoint, 0, 0)
		buffBars[plate][r]:SetParent(visibleFrame)
	end
end

local function GetBarChildrenSize(n, ...)
	local frame
	local totalWidth = 1
	local totalHeight = 1
	if n > P.iconsPerBar then
		n = P.iconsPerBar
	end
	for i = 1, n do
		frame = select(i, ...)
		if P.shrinkBar == true then
			if frame:IsShown() then
				totalWidth = totalWidth + frame:GetWidth()

				if frame:GetHeight() > totalHeight then
					totalHeight = frame:GetHeight()
				end
			end
		else
			totalWidth = totalWidth + frame:GetWidth()

			if frame:GetHeight() > totalHeight then
				totalHeight = frame:GetHeight()
			end
		end
	end
	return totalWidth, totalHeight
end

-- Update a bar's size taking into account all the spell frame's height and width.
local function UpdateBarSize(barFrame)
	if barFrame:GetNumChildren() == 0 then return end

	local totalWidth, totalHeight = GetBarChildrenSize(barFrame:GetNumChildren(), barFrame:GetChildren())

	barFrame:SetWidth(totalWidth)
	barFrame:SetHeight(totalHeight)
end

local function UpdateAllBarSizes(plate)
	for r = 1, P.numBars do
		UpdateBarSize(buffBars[plate][r])
	end
end

function core:UpdateAllPlateBarSizes()
	for plate in pairs(buffBars) do
		UpdateAllBarSizes(plate)
	end
end

local function SortFunc(a, b)
	if a and b then
		if a.playerCast ~= b.playerCast then
			return (a.playerCast or 0) > (b.playerCast or 0)
		elseif a.scale and b.scale and a.scale ~= b.scale then
			return a.scale < b.scale
		elseif a.isDebuff ~= b.isDebuff then
			return (a.isDebuff and 1 or 0) > (b.isDebuff and 1 or 0)
		end
	end
end

-- Show spells on a plate linked to a GUID.
function core:AddBuffsToPlate(plate, GUID)
	if not buffFrames[plate] or not buffFrames[plate][P.iconsPerBar] then
		self:BuildBuffFrame(plate)
	end
	local t = guidBuffs[GUID]
	if not t then return end
	table_sort(t, SortFunc)
	local frames = buffFrames[plate]
	local f, rec
	for i = 1, P.numBars * P.iconsPerBar do
		f = frames[i]
		if f then
			rec = t[i]
			if rec then
				f.spellName = rec.name or ""
				f.sID = rec.sID or ""
				f.expirationTime = rec.expirationTime or 0
				f.duration = rec.duration
				f.startTime = rec.startTime or GetTime()
				f.stackCount = rec.stackCount or 0
				f.isDebuff = rec.isDebuff
				f.debuffType = rec.debuffType
				f.playerCast = rec.playerCast
				f.scale = rec.scale or 1
				if f.iconPath ~= rec.icon then
					f.iconPath = rec.icon
					f.texture:SetTexture(rec.icon)
				end
				-- Show() only fires OnShow on a hidden frame; call it directly otherwise.
				if f:IsShown() then
					iconOnShow(f)
				else
					f:Show()
				end
				iconOnUpdate(f, 1)
			else
				f:Hide()
			end
		end
	end
	UpdateAllBarSizes(plate)
end

-- Display a question mark icon since we don't know the GUID of the plate/mob.
function core:AddUnknownIcon(plate)
	if not buffFrames[plate] then
		self:BuildBuffFrame(plate, nil, true)
	end

	buffFrames[plate][1].spellName = false
	buffFrames[plate][1].expirationTime = 0
	buffFrames[plate][1].duration = 0
	buffFrames[plate][1].stackCount = 0
	buffFrames[plate][1].isDebuff = false
	buffFrames[plate][1].debuffType = false
	buffFrames[plate][1].playerCast = false

	buffFrames[plate][1].iconPath = unknownIconPath
	buffFrames[plate][1].texture:SetTexture(unknownIconPath)

	if buffFrames[plate][1]:IsShown() then
		buffFrames[plate][1]:Hide()
	end
	buffFrames[plate][1]:Show()

	UpdateAllBarSizes(plate)
end

function core:SetFrameLevel(frame)
    local plate = frame.realPlate
    if plate and plate:GetFrameLevel() then
        frame:SetFrameLevel(plate:GetFrameLevel())
    end
end

function core:UpdateAllFrameLevel()
	for _, frames in pairs(buffFrames) do
		for i = 1, #frames do
			self:SetFrameLevel(frames[i])
		end
	end
end

function core:UpdateAllDurationAnchors()
	local frame
    for _, frames in pairs(buffFrames) do
        for i = 1, #frames do
            frame = frames[i]
            if frame and frame.durationText then
                SetDurationAnchor(frame)
            end
        end
    end
end

function core:UpdateAllDuration2()
	local frame, increase, spellOpts
	for _, frames in pairs(buffFrames) do
		for i = 1, #frames do
			frame = frames[i]
			if frame and frame.durationText2 then
				increase = P.increase
				if frame.debuffType == "Interrupt" then
					increase = P.interruptsScale
				else
					spellOpts = self:HaveSpellOpts(frame.spellName, frame.sID)
					if spellOpts then
						increase = spellOpts.increase or increase
					end
				end
				UpdateDuration2Font(frame, increase)
				frame.durationText2:SetPoint("TOP", frame.icon, "BOTTOM", 0, P.cd2OffsetY - 1)
				frame.durationText2Bg:SetAlpha(P.cd2BgAlpha)
				UpdateDurationVisibility(frame)
			end
		end
	end
end

-- This will reset all the anchors on the spell frames.
function core:ResetAllPlateIcons()
	for plate in pairs(buffFrames) do
		core:BuildBuffFrame(plate, true)
	end
end

-- Create our buff frames on a plate.
function core:BuildBuffFrame(plate, reset, onlyOne)
	local visibleFrame = plate
	if not buffBars[plate] then
		BuildPlateBars(plate, visibleFrame)
	end

	if not buffBars[plate][P.numBars] then --user increased the size.
		BuildPlateBars(plate, visibleFrame)
	end

	buffFrames[plate] = buffFrames[plate] or {}

	if reset then
		for i = 1, table_getn(buffFrames[plate]) do
			buffFrames[plate][i]:Hide()
		end
	end

	local total = 1 --total number of spell frames
	if not buffFrames[plate][total] then
		buffFrames[plate][total] = CreateBuffFrame(buffBars[plate][1], plate)
	end
	buffFrames[plate][total]:SetParent(buffBars[plate][1])

	buffFrames[plate][total]:ClearAllPoints()

	if Testreversepos then
		buffFrames[plate][total]:SetPoint("TOP", buffBars[plate][1])
	else
		buffFrames[plate][total]:SetPoint("BOTTOMLEFT", buffBars[plate][1])
	end

	if onlyOne then return end

	local prevFrame = buffFrames[plate][total]
	for i = 2, P.iconsPerBar do
		total = total + 1
		if not buffFrames[plate][total] then
			buffFrames[plate][total] = CreateBuffFrame(buffBars[plate][1], plate)
		end
		buffFrames[plate][total]:SetParent(buffBars[plate][1])

		buffFrames[plate][total]:ClearAllPoints()

		buffFrames[plate][total]:SetPoint("BOTTOMLEFT", prevFrame, "BOTTOMRIGHT", -P.intervalY)

		prevFrame = buffFrames[plate][total]
	end

	if P.numBars > 1 then
		for r = 2, P.numBars do
			for i = 1, P.iconsPerBar do
				total = total + 1

				if not buffFrames[plate][total] then
					buffFrames[plate][total] = CreateBuffFrame(buffBars[plate][r], plate)
				end
				buffFrames[plate][total]:SetParent(buffBars[plate][r])

				buffFrames[plate][total]:ClearAllPoints()
				if i == 1 then
					buffFrames[plate][total]:SetPoint("BOTTOMLEFT", buffBars[plate][r])
				else
					buffFrames[plate][total]:SetPoint("BOTTOMLEFT", prevFrame, "BOTTOMRIGHT", -P.intervalY)
				end

				prevFrame = buffFrames[plate][total]
			end
		end
	end

	if not plate.PlateBuffsIsHooked then
		plate.PlateBuffsIsHooked = true
		plate:HookScript("OnSizeChanged", function(self, w, h) core:ResetPlateBarPoints(self) end)
	end
end

-- Reset a bar's anchor point.
function core:ResetBarPoint(barFrame, plate)
	barFrame:ClearAllPoints()
	barFrame:SetParent(plate)
	barFrame:SetPoint(P.barAnchorPoint, plate, P.plateAnchorPoint, P.barOffsetX, P.barOffsetY)
end

-- Reset all icon sizes. Called when user changes settings.
function core:ResetIconSizes()
	local iconSize = P.iconSize
	local iconSize2 = P.iconSize2
	local frame, increase, spellOpts
	for _, frames in pairs(buffFrames) do
		for i = 1, #frames do
			frame = frames[i]
			increase = P.increase
			if frame.debuffType == "Interrupt" then
				increase = P.interruptsScale
			else
				spellOpts = self:HaveSpellOpts(frame.spellName, frame.sID)
				if spellOpts then
					increase = spellOpts.increase or increase
				end
			end
			UpdateIconSize(frame, iconSize * increase, iconSize2 * increase)
		end
	end
end

-- Reset cooldown text sizes. Called when user changes settings.
function core:ResetDurationSizes()
	local frame, increase, spellOpts, timeLeft
	local currentTime = GetTime()
	for _, frames in pairs(buffFrames) do
		for i = 1, #frames do
			frame = frames[i]
			increase = P.increase
			if frame.debuffType == "Interrupt" then
				increase = P.interruptsScale
			else
				spellOpts = self:HaveSpellOpts(frame.spellName, frame.sID)
				if spellOpts then
					increase = spellOpts.increase or increase
				end
			end
			UpdateDurationFont(frame, increase)
			UpdateDuration2Font(frame, increase)
			timeLeft = frame.expirationTime - currentTime
			frame.overLimit = P.durationLimit > 0 and timeLeft > P.durationLimit
			frame.overLimit2 = P.durationLimit2 > 0 and timeLeft > P.durationLimit2
			UpdateDurationVisibility(frame)
		end
	end
end

-- Update stack text size.
function core:ResetStackSizes()
	local stackSize = P.stackSize
	local frame, increase, spellOpts
	for _, frames in pairs(buffFrames) do
		for i = 1, #frames do
			frame = frames[i]
			increase = P.increase
			if frame.debuffType == "Interrupt" then
				increase = P.interruptsScale
			else
				spellOpts = self:HaveSpellOpts(frame.spellName, frame.sID)
				if spellOpts then
					increase = spellOpts.increase or increase
				end
			end
			UpdateStackSize(frame, stackSize * increase)
		end
	end
end

-- Reset all bar anchors.
function core:ResetAllBarPoints()
	for plate in pairs(buffBars) do
		self:ResetPlateBarPoints(plate)
	end
end

-- Reset bar anchors for a particular plate.
function core:ResetPlateBarPoints(plate)
	local bars = buffBars[plate]
	if bars[1] then
		self:ResetBarPoint(bars[1], plate)
	end
	local barPoint, parentPoint = GetStackPoints()
	for r = 2, table_getn(bars) do
		bars[r]:ClearAllPoints()
		bars[r]:SetPoint(barPoint, bars[r - 1], parentPoint, 0, 0)
	end
end

-- When we change number of icons to show we hide all icons.
-- This will reshow the buffs again in their new locations.
function core:ShowAllKnownSpells()
	local GUID
	for plate in pairs(buffFrames) do
		GUID = GetPlateGUID(plate)
		if GUID then
			self:AddBuffsToPlate(plate, GUID)
		else
			local plateName = GetPlateName(plate)
			if plateName and nametoGUIDs[plateName] then
				self:AddBuffsToPlate(plate, nametoGUIDs[plateName])
			end
		end
	end
end