
local folder, core = ...
LibStub("AceAddon-3.0"):NewAddon(core, folder, "AceConsole-3.0", "AceEvent-3.0")

-- global lookup
local Debug = core.Debug

local LibNameplates = LibStub("LibNameplates-1.0", true)
if not LibNameplates then
	error(folder .. " requires LibNameplates-1.0.")
	return
end

local LSM = LibStub("LibSharedMedia-3.0")
if not LSM then
	error(folder .. " requires LibSharedMedia-3.0.")
	return
end

-- local
core.title = "PlateBuffs"
core.version = GetAddOnMetadata(folder, "X-Packaged-Version") or ""
core.titleFull = core.title .. " " .. core.version
core.addonDir = "Interface\\AddOns\\" .. folder .. "\\"

core.LibNameplates = LibNameplates
core.LSM = LSM

local LDS = LibStub("LibDualSpec-1.0", true)

local L = LibStub("AceLocale-3.0"):GetLocale(folder, true)
core.L = L

local defaultSpells1, defaultScale1, defaultDurationSize1, defaultStackSize1 = core.defaultSpells1, core.defaultScale1, core.defaultDurationSize1, core.defaultStackSize1
local defaultSpells2, defaultScale2, defaultDurationSize2, defaultStackSize2 = core.defaultSpells2, core.defaultScale2, core.defaultDurationSize2, core.defaultStackSize2
local defaultSpells3, defaultScale3, defaultDurationSize3, defaultStackSize3 = core.defaultSpells3, core.defaultScale3, core.defaultDurationSize3, core.defaultStackSize3
local defaultSpells4, defaultScale4, defaultDurationSize4, defaultStackSize4 = core.defaultSpells4, core.defaultScale4, core.defaultDurationSize4, core.defaultStackSize4
local CheckSpellID =  core.CheckSpellID
local totemList =core.totemList

local regEvents = {
	"PLAYER_TARGET_CHANGED",
	"UPDATE_MOUSEOVER_UNIT",
	"UNIT_AURA",
	"UNIT_TARGET"
}

core.db = {}
local db
local P  --db.profile

core.defaultSettings = {
	profile = {
		spellOpts = {},
		ignoreDefaultSpell = {} -- default spells that user has removed. Seems odd but this'll save space in the DB file allowing PB to load faster.
	}
}

core.buffFrames = {}
core.guidBuffs = {}
core.nametoGUIDs = {} -- w/o servername
core.buffBars = {}

local buffBars = core.buffBars
local guidBuffs = core.guidBuffs
local nametoGUIDs = core.nametoGUIDs
local buffFrames = core.buffFrames
local defaultSettings = core.defaultSettings

local _
local pairs = pairs
local UnitExists = UnitExists
local GetSpellInfo = GetSpellInfo

local nameToPlate = {}

core.iconTestMode = false

local table_getn = table.getn

SetCVar("ShowClassColorInNameplate", 1) -- "Class Colors in Nameplates" must be enabled to identify enemy players

--Add default spells to defaultSettings table.
for i = 1, table_getn(defaultSpells1) do
	local spellID = defaultSpells1[i]
	local spellName = GetSpellInfo(spellID)
	if spellName then
		core.defaultSettings.profile.spellOpts[spellName] = {
			spellID = spellID,
			increase = defaultScale1,
			cooldownSize = defaultDurationSize1,
			show = 1,
			stackSize = defaultStackSize1
		}
	end
end

for i = 1, table_getn(defaultSpells2) do
	local spellID = defaultSpells2[i]
	local spellName = GetSpellInfo(spellID)
	if spellName then
		core.defaultSettings.profile.spellOpts[spellName] = {
			spellID = spellID,
			increase = defaultScale2,
			cooldownSize = defaultDurationSize2,
			show = 1,
			stackSize = defaultStackSize2
		}
	end
end

for i = 1, table_getn(defaultSpells3) do
	local spellID = defaultSpells3[i]
	local spellName = GetSpellInfo(defaultSpells3[i])
	if spellName then
		core.defaultSettings.profile.spellOpts[spellName] = {
			spellID = spellID,
			increase = defaultScale3,
			cooldownSize = defaultDurationSize3,
			show = 1,
			stackSize = defaultStackSize3
		}
	end
end

for i = 1, table_getn(defaultSpells4) do
	local spellID = defaultSpells4[i]
	local spellName = GetSpellInfo(spellID)
	if spellName then
		core.defaultSettings.profile.spellOpts[spellName] = {
			spellID = spellID,
			increase = defaultScale4,
			cooldownSize = defaultDurationSize4,
			show = 2,
			stackSize = defaultStackSize4
		}
	end
end

for i = 1, table_getn(CheckSpellID) do
	local spellID = CheckSpellID[i]
	local spellName = GetSpellInfo(spellID)
	if core.defaultSettings.profile.spellOpts[spellName] then
		core.defaultSettings.profile.spellOpts[spellName].grabid = true
	end
end

local totems = {}
do
	local name, texture, _
	for i = 1, table_getn(totemList) do
		name, _, texture = GetSpellInfo(totemList[i])
		totems[name] = texture
	end
end

core.Dummy = function() end

function core:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("PB_DB", core.defaultSettings, true)
	self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
	self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
	self.db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")
	self.db.RegisterCallback(self, "OnProfileDeleted", "OnProfileChanged")
	self:RegisterChatCommand("pb", "MySlashProcessorFunc")

	if LDS then LDS:EnhanceDatabase(self.db, self.title) end
	
	self:BuildAboutMenu()

	local config = LibStub("AceConfig-3.0")
	local dialog = LibStub("AceConfigDialog-3.0")
	config:RegisterOptionsTable(self.title, self.CoreOptionsTable)
	dialog:AddToBlizOptions(self.title, self.title)

	config:RegisterOptionsTable(self.title .. "Display", self.DisplayOptionsTable)
	dialog:AddToBlizOptions(self.title .. "Display", L["Display conditions"], self.title)

	config:RegisterOptionsTable(self.title .. "Style", self.DefaultSpellOptionsTable)
	dialog:AddToBlizOptions(self.title .. "Style", L["Style settings"], self.title)

	config:RegisterOptionsTable(self.title .. "Position", self.BarOptionsTable)
	dialog:AddToBlizOptions(self.title .. "Position", L["Position settings"], self.title)

	config:RegisterOptionsTable(self.title .. "Spells", self.SpellOptionsTable)
	dialog:AddToBlizOptions(self.title .. "Spells", L["Specific Spells"], self.title)

	config:RegisterOptionsTable(self.title .. "About", self.AboutOptionsTable)
	dialog:AddToBlizOptions(self.title .. "About", L.about, self.title)

	--last UI
	local optionsTable = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	config:RegisterOptionsTable(self.title .. "Profile", optionsTable)
	dialog:AddToBlizOptions(self.title .. "Profile", L["Profiles"], self.title)

	if LDS then LDS:EnhanceOptions(optionsTable, self.db) end
end

local function GetPlateName(plate)
	return LibNameplates:GetName(plate)
end
core.GetPlateName = GetPlateName

local function GetPlateType(plate)
	return LibNameplates:GetType(plate)
end
core.GetPlateType = GetPlateType

local function IsPlateInCombat(plate)
	return LibNameplates:IsInCombat(plate)
end
core.IsPlateInCombat = IsPlateInCombat

local function GetPlateThreat(plate)
	return LibNameplates:GetThreatSituation(plate)
end
core.GetPlateThreat = GetPlateThreat

local function GetPlateReaction(plate)
	return LibNameplates:GetReaction(plate)
end
core.GetPlateReaction = GetPlateReaction

local function GetPlateGUID(plate)
	return LibNameplates:GetGUID(plate)
end
core.GetPlateGUID = GetPlateGUID

local function PlateIsBoss(plate)
	return LibNameplates:IsBoss(plate)
end
core.PlateIsBoss = PlateIsBoss

local function PlateIsElite(plate)
	return LibNameplates:IsElite(plate)
end
core.PlateIsElite = PlateIsElite

local function GetPlateByGUID(guid)
	return LibNameplates:GetNameplateByGUID(guid)
end
core.GetPlateByGUID = GetPlateByGUID

local function GetPlateByName(name, maxhp)
	return LibNameplates:GetNameplateByName(name, maxhp)
end
core.GetPlateByName = GetPlateByName

local function GetTargetPlate()
	return LibNameplates:GetTargetNameplate()
end
core.GetTargetPlate = GetTargetPlate

do
	local OnEnable = core.OnEnable
	function core:OnEnable(...)
		if OnEnable then
			OnEnable(self, ...)
		end

		db = self.db
		P = db.profile

		for i, event in pairs(regEvents) do
			self:RegisterEvent(event)
		end

		LibNameplates.RegisterCallback(self, "LibNameplates_NewNameplate")
		LibNameplates.RegisterCallback(self, "LibNameplates_FoundGUID")
		LibNameplates.RegisterCallback(self, "LibNameplates_RecycleNameplate")

		if P.playerCombatWithOnly == true or P.npcCombatWithOnly == true then
			LibNameplates.RegisterCallback(self, "LibNameplates_CombatChange")
			LibNameplates.RegisterCallback(self, "LibNameplates_ThreatChange")
		end

		-- Update old options.
		if P.cooldownSize < 6 then
			P.cooldownSize = core.defaultSettings.profile.cooldownSize
		end
		if P.stackSize < 6 then
			P.stackSize = core.defaultSettings.profile.stackSize
		end

		for plate in pairs(core.buffBars) do
			for i = 1, table_getn(core.buffBars[plate]) do
				core.buffBars[plate][i]:Show() --reshow incase user disabled addon.
			end
		end
	end
end

do
	local prev_OnDisable = core.OnDisable
	function core:OnDisable(...)
		if prev_OnDisable then
			prev_OnDisable(self, ...)
		end

		LibNameplates.UnregisterAllCallbacks(self)

		for plate in pairs(core.buffBars) do
			for i = 1, table_getn(core.buffBars[plate]) do
				core.buffBars[plate][i]:Hide() --makesure all frames stop OnUpdating.
			end
		end
	end
end

-- User has reset proflie, so we reset our spell exists options.
function core:OnProfileChanged(...)
	self:Disable()
	self:Enable()
end

-- /da function brings up the UI options
function core:MySlashProcessorFunc(input)
	InterfaceOptionsFrame_OpenToCategory(self.titleFull)
	InterfaceOptionsFrame_OpenToCategory(self.titleFull)
end

-- note to self, not buffBars
function core:HidePlateSpells(plate)
	if buffFrames[plate] then
		for i = 1, table_getn(buffFrames[plate]) do
			buffFrames[plate][i]:Hide()
		end
	end
end

local function isTotem(name)
	return totems[name]
end

function core:ShouldAddBuffs(plate)
	local plateName = GetPlateName(plate) or "UNKNOWN"

	if P.showTotems == false and isTotem(plateName) then
		return false
	end

	local plateType = GetPlateType(plate)
	if (P.abovePlayers == true and plateType == "PLAYER") or (P.aboveNPC == true and plateType == "NPC") then
		if plateType == "PLAYER" and P.playerCombatWithOnly == true and (not IsPlateInCombat(plate)) then
			return false
		end

		if plateType == "NPC" and P.npcCombatWithOnly == true and (not IsPlateInCombat(plate) and GetPlateThreat(plate) == "LOW") then
			return false
		end

		local plateReaction = GetPlateReaction(plate)
		if P.aboveFriendly == true and plateReaction == "FRIENDLY" then
			return true
		elseif P.aboveNeutral == true and plateReaction == "NEUTRAL" then
			return true
		elseif P.aboveHostile == true and plateReaction == "HOSTILE" then
			return true
		end
	end

	return false
end

function core:AddOurStuffToPlate(plate)
	local GUID = GetPlateGUID(plate)
	if GUID then
		self:RemoveOldSpells(GUID)
		self:AddBuffsToPlate(plate, GUID)
		return
	end

	local plateName = GetPlateName(plate) or "UNKNOWN"
	if P.saveNameToGUID == true and nametoGUIDs[plateName] and (GetPlateType(plate) == "PLAYER" or PlateIsBoss(plate)) then
		self:RemoveOldSpells(nametoGUIDs[plateName])
		self:AddBuffsToPlate(plate, nametoGUIDs[plateName])
	elseif P.unknownSpellDataIcon == true then
		self:AddUnknownIcon(plate)
	end
end

function core:LibNameplates_RecycleNameplate(event, plate)
	self:HidePlateSpells(plate)
end

function core:LibNameplates_NewNameplate(event, plate)
	if self:ShouldAddBuffs(plate) == true then
		core:AddOurStuffToPlate(plate)
	end
end

function core:LibNameplates_FoundGUID(event, plate, GUID, unitID)
	if self:ShouldAddBuffs(plate) == true then
		if not guidBuffs[GUID] then
			self:CollectUnitInfo(unitID)
		end

		self:RemoveOldSpells(GUID)
		self:AddBuffsToPlate(plate, GUID)
	end
end

function core:HaveSpellOpts(spellName, spellID)
	if not P.ignoreDefaultSpell[spellName] and P.spellOpts[spellName] then
		if P.spellOpts[spellName].grabid then
			if P.spellOpts[spellName].spellID == spellID then
				return P.spellOpts[spellName]
			else
				return false
			end
		else
			return P.spellOpts[spellName]
		end
	end
	return false
end

do
	local UnitGUID = UnitGUID
	local UnitName = UnitName
	local UnitIsPlayer = UnitIsPlayer
	local UnitClassification = UnitClassification
	local table_remove = table.remove
	local table_insert = table.insert
	local UnitBuff = UnitBuff
	local UnitDebuff = UnitDebuff

	function core:CollectUnitInfo(unitID)
		
		if not unitID or UnitIsUnit(unitID, "player") then return end

		local GUID = UnitGUID(unitID)
		if not GUID then return end
		
		local unitName = UnitName(unitID)
		if unitName and P.saveNameToGUID == true and UnitIsPlayer(unitID) or UnitClassification(unitID) == "worldboss" then
			nametoGUIDs[unitName] = GUID
		end

		if P.watchUnitIDAuras == true then
			guidBuffs[GUID] = guidBuffs[GUID] or {}

			--Remove all the entries.
			for i = table_getn(guidBuffs[GUID]), 1, -1 do
				table_remove(guidBuffs[GUID], i)
			end

			local i = 1
			local name, icon, count, duration, expirationTime, unitCaster, spellId, debuffType

			while UnitBuff(unitID, i) do
				name, _, icon, count, _, duration, expirationTime, unitCaster, _, _, spellId = UnitBuff(unitID, i)
				icon = icon:upper():gsub("(.+)\\(.+)\\", "")
				local spellOpts = self:HaveSpellOpts(name, spellId)
				if spellOpts and spellOpts.show and P.defaultBuffShow ~= 4 then
					if
						spellOpts.show == 1 or
						(spellOpts.show == 2 and unitCaster == "player") or
						(spellOpts.show == 4 and not UnitCanAttack("player", unitID)) or
						(spellOpts.show == 5 and UnitCanAttack("player", unitID))
					then
						table_insert(guidBuffs[GUID], {
							name = name,
							icon = icon,
							expirationTime = expirationTime,
							startTime = expirationTime - duration,
							duration = duration,
							playerCast = (unitCaster == "player") and 1,
							stackCount = count,
							sID = spellId,
							caster = unitCaster and core:GetFullName(unitCaster),
							scale = spellOpts and (spellOpts.increase or 1) or 1
						})
					end
				elseif duration > 0 then
					if
						P.defaultBuffShow == 1 or
						(P.defaultBuffShow == 2 and unitCaster == "player") or
						(P.defaultBuffShow == 4 and unitCaster == "player")
					then
						table_insert(guidBuffs[GUID], {
							name = name,
							icon = icon,
							expirationTime = expirationTime,
							startTime = expirationTime - duration,
							duration = duration,
							playerCast = (unitCaster == "player") and 1,
							stackCount = count,
							sID = spellId,
							caster = unitCaster and core:GetFullName(unitCaster),
							scale = spellOpts and (spellOpts.increase or 1) or 1
						})
					end
				end

				i = i + 1
			end

			i = 1
			while UnitDebuff(unitID, i) do
				name, _, icon, count, debuffType, duration, expirationTime, unitCaster, _, _, spellId = UnitDebuff(unitID, i)
				icon = icon:upper():gsub("INTERFACE\\ICONS\\", "")
				local spellOpts = self:HaveSpellOpts(name, spellId)
				if spellOpts and spellOpts.show and P.defaultDebuffShow ~= 4 then
					if
						spellOpts.show == 1 or
						(spellOpts.show == 2 and unitCaster == "player") or
						(spellOpts.show == 4 and not UnitCanAttack("player", unitID)) or
						(spellOpts.show == 5 and UnitCanAttack("player", unitID))
					then
						table_insert(guidBuffs[GUID], {
							name = name,
							icon = icon,
							expirationTime = expirationTime,
							startTime = expirationTime - duration,
							duration = duration,
							playerCast = (unitCaster == "player") and 1,
							stackCount = count,
							debuffType = debuffType,
							isDebuff = true,
							sID = spellId,
							caster = unitCaster and core:GetFullName(unitCaster),
							scale = spellOpts and (spellOpts.increase or 1) or 1
						})
					end
				elseif duration > 0 then
					if
						P.defaultDebuffShow == 1 or
						(P.defaultDebuffShow == 2 and unitCaster == "player") or
						(P.defaultDebuffShow == 4 and unitCaster == "player")
					then
						table_insert(guidBuffs[GUID], {
							name = name,
							icon = icon,
							expirationTime = expirationTime,
							startTime = expirationTime - duration,
							duration = duration,
							playerCast = (unitCaster == "player") and 1,
							stackCount = count,
							debuffType = debuffType,
							isDebuff = true,
							sID = spellId,
							caster = unitCaster and core:GetFullName(unitCaster),
							scale = spellOpts and (spellOpts.increase or 1) or 1
						})
					end
				end
				i = i + 1
			end

			if core.iconTestMode == true then
				for j = table_getn(guidBuffs[GUID]), 1, -1 do
					for t = 1, P.iconsPerBar - 1 do
						table_insert(guidBuffs[GUID], j, guidBuffs[GUID][j]) --reinsert the entry abunch of times.
					end
				end
			end
		end
		
		if unitName and not self:UpdatePlateByGUID(GUID) and (UnitIsPlayer(unitID) or UnitClassification(unitID) == "worldboss") then
			-- LibNameplates can't find a nameplate that matches that GUID. Since the unitID's a player/worldboss which have unique names, add buffs to the frame that matches that name.
			-- Note, this /can/ add buffs to the wrong frame if a hunter pet has the same name as a player. This is so rare that I'll risk it.
			self:UpdatePlateByName(unitName, UnitHealthMax(unitID))
		end
	end
end

function core:PLAYER_TARGET_CHANGED(event, ...)
	if UnitExists("target") then
		self:CollectUnitInfo("target")
	end
end

function core:UNIT_TARGET(event, unitID)
	if not UnitIsUnit(unitID, "player") and UnitExists(unitID .. "target") then
		self:CollectUnitInfo(unitID .. "target")
	end
end

function core:LibNameplates_CombatChange(event, plate, inCombat)
	if core:ShouldAddBuffs(plate) == true then
		core:AddOurStuffToPlate(plate)
	else
		core:HidePlateSpells(plate)
	end
end

function core:LibNameplates_ThreatChange(event, plate, threatSit)
	if core:ShouldAddBuffs(plate) == true then
		core:AddOurStuffToPlate(plate)
	else
		core:HidePlateSpells(plate)
	end
end

function core:UPDATE_MOUSEOVER_UNIT(event, ...)
	if UnitExists("mouseover") then
		self:CollectUnitInfo("mouseover")
	end
end

function core:UNIT_AURA(event, unitID)
	if UnitExists(unitID) then
		self:CollectUnitInfo(unitID)
	end
end

function core:AddNewSpell(spellName, spellID)
	Debug("AddNewSpell", spellName, spellID)
	P.ignoreDefaultSpell[spellName] = nil
	P.spellOpts[spellName] = {show = 1, spellID = spellID}
	self:BuildSpellUI()
end

function core:RemoveSpell(spellName)
	if self.defaultSettings.profile.spellOpts[spellName] then
		P.ignoreDefaultSpell[spellName] = true
	end
	P.spellOpts[spellName] = nil
	core:BuildSpellUI()
end

function core:UpdatePlateByGUID(GUID)
	local plate = GetPlateByGUID(GUID)
	if plate and self:ShouldAddBuffs(plate) == true then
		self:AddBuffsToPlate(plate, GUID)
		return true
	end
	return false
end

-- This will add buff frames to a frame matching a given name.
-- This should only be used for player names because mobs/npcs can share the same name.
function core:UpdatePlateByName(name, maxhp)
	local GUID = nametoGUIDs[name]
	if GUID then
		local plate = GetPlateByName(name, maxhp)
		if plate and self:ShouldAddBuffs(plate) == true then
			core:AddBuffsToPlate(plate, GUID)
			return true
		end
	end
	return false
end

-- This should speed up the look up and the display when it comes
-- to targeted units and their nameplates, hopefully.
function core:UpdateTargetPlate(GUID)
	if UnitExists("target") and UnitGUID("target") == GUID then
		local plate = GetTargetPlate()
		if plate and self:ShouldAddBuffs(plate) == true then
			self:AddBuffsToPlate(plate, GUID)
			return true
		end
	end
	return false
end

function core:GetAllSpellIDs()
	local spells, name = {}, nil

	for i, spellID in pairs(defaultSpells1) do
		name = GetSpellInfo(spellID)
		spells[name] = spellID
	end
	for i, spellID in pairs(defaultSpells2) do
		name = GetSpellInfo(spellID)
		spells[name] = spellID
	end
	for i, spellID in pairs(defaultSpells3) do
		name = GetSpellInfo(spellID)
		spells[name] = spellID
	end
	for i, spellID in pairs(defaultSpells4) do
		name = GetSpellInfo(spellID)
		spells[name] = spellID
	end

	for i = 76567, 1, -1 do --76567
		name = GetSpellInfo(i)
		if name and not spells[name] then
			spells[name] = i
		end
	end
	return spells
end

function core:SkinCallback(skin, glossAlpha, gloss, _, _, colors)
	self.db.profile.skin_SkinID = skin
	self.db.profile.skin_Gloss = glossAlpha
	self.db.profile.skin_Backdrop = gloss
	self.db.profile.skin_Colors = colors
end

function core:SetCDAnchor(frame)
	local anchor = P.cdAnchor
	frame.cd:ClearAllPoints()
	if anchor == "TOP" then
		frame.cd:SetPoint("BOTTOM", frame.icon, "TOP", P.cdOffsetX, P.cdOffsetY + 3)
	elseif anchor == "CENTER" then
		frame.cd:SetPoint("CENTER", frame.icon, "CENTER", P.cdOffsetX, P.cdOffsetY)
	elseif anchor == "BOTTOM" then
		frame.cd:SetPoint("TOP", frame.icon, "BOTTOM", P.cdOffsetX, P.cdOffsetY -3)
	end
end