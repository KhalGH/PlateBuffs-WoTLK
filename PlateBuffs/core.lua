
local folder, core = ...

LibStub("AceAddon-3.0"):NewAddon(core, folder, "AceConsole-3.0", "AceEvent-3.0")

core.title = "PlateBuffs"
core.version = GetAddOnMetadata(folder, "X-Packaged-Version") or ""
core.titleFull = core.title .. " " .. core.version
core.addonDir = "Interface\\AddOns\\" .. folder .. "\\"

local LibNameplates = LibStub("LibNameplates-1.0", true)
if not LibNameplates then
	error(folder .. " requires LibNameplates-1.0.")
	return
end
core.LibNameplates = LibNameplates

local LSM = LibStub("LibSharedMedia-3.0")
if not LSM then
	error(folder .. " requires LibSharedMedia-3.0.")
	return
end
core.LSM = LSM

local LDS = LibStub("LibDualSpec-1.0", true)

local L = LibStub("AceLocale-3.0"):GetLocale(folder, true)
core.L = L

core.db = {}
local db
local P  --db.profile

local pairs = pairs
local UnitExists = UnitExists
local UnitIsUnit = UnitIsUnit
local table_getn = table.getn

core.buffFrames = {}
core.guidBuffs = {}
core.nametoGUIDs = {} -- w/o servername
core.buffBars = {}
core.iconTestMode = false

local buffBars = core.buffBars
local guidBuffs = core.guidBuffs
local nametoGUIDs = core.nametoGUIDs
local buffFrames = core.buffFrames
local totems = core.totems

local function GetPlateName(plate) return LibNameplates:GetName(plate) end
local function GetPlateType(plate) return LibNameplates:GetType(plate) end
local function IsPlateInCombat(plate) return LibNameplates:IsInCombat(plate) end
local function GetPlateThreat(plate) return LibNameplates:GetThreatSituation(plate) end
local function GetPlateReaction(plate) return LibNameplates:GetReaction(plate) end
local function GetPlateGUID(plate) return LibNameplates:GetGUID(plate) end
local function PlateIsBoss(plate) return LibNameplates:IsBoss(plate) end
local function PlateIsElite(plate) return LibNameplates:IsElite(plate) end
local function GetPlateByGUID(guid)	return LibNameplates:GetNameplateByGUID(guid) end
local function GetPlateByName(name, maxhp, filter) return LibNameplates:GetNameplateByName(name, maxhp, filter) end
local function GetTargetPlate()	return LibNameplates:GetTargetNameplate() end
core.GetPlateName = GetPlateName
core.GetPlateType = GetPlateType
core.IsPlateInCombat = IsPlateInCombat
core.GetPlateThreat = GetPlateThreat
core.GetPlateReaction = GetPlateReaction
core.GetPlateGUID = GetPlateGUID
core.PlateIsBoss = PlateIsBoss
core.PlateIsElite = PlateIsElite
core.GetPlateByGUID = GetPlateByGUID
core.GetPlateByName = GetPlateByName
core.GetTargetPlate = GetTargetPlate

function core:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("PB_DB", core.defaultSettings, true)
	self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
	self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
	self.db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")
	self.db.RegisterCallback(self, "OnProfileDeleted", "OnProfileChanged")
	self:RegisterChatCommand("pb", "MySlashProcessorFunc")

	SetCVar("ShowClassColorInNameplate", 1) -- "Class Colors in Nameplates" must be enabled to identify enemy players

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
	dialog:AddToBlizOptions(self.title .. "About", L["About"], self.title)

	--last UI
	local optionsTable = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	config:RegisterOptionsTable(self.title .. "Profile", optionsTable)
	dialog:AddToBlizOptions(self.title .. "Profile", L["Profiles"], self.title)

	if LDS then LDS:EnhanceOptions(optionsTable, self.db) end
end

do
	local regEvents = {
		"PLAYER_TARGET_CHANGED",
		"UPDATE_MOUSEOVER_UNIT",
		"UNIT_AURA",
		"UNIT_TARGET"
	}

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

		for plate, bars in pairs(buffBars) do
			for i = 1, table_getn(bars) do
				bars[i]:Show() --reshow incase user disabled addon.
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

		for plate, bars in pairs(buffBars) do
			for i = 1, table_getn(bars) do
				bars[i]:Hide() --makesure all frames stop OnUpdating.
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
	InterfaceOptionsFrame_OpenToCategory(self.title)
	InterfaceOptionsFrame_OpenToCategory(self.title)
end

-- note to self, not buffBars
function core:HidePlateSpells(plate)
	if buffFrames[plate] then
		for i = 1, table_getn(buffFrames[plate]) do
			buffFrames[plate][i]:Hide()
		end
	end
end

function core:ShouldAddBuffs(plate)
	local plateName = GetPlateName(plate) or "UNKNOWN"

	if P.blacklistTotems and totems[plateName] then
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
		self:AddOurStuffToPlate(plate)
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
	if self:ShouldAddBuffs(plate) == true then
		self:AddOurStuffToPlate(plate)
	else
		self:HidePlateSpells(plate)
	end
end

function core:LibNameplates_ThreatChange(event, plate, threatSit)
	if self:ShouldAddBuffs(plate) == true then
		self:AddOurStuffToPlate(plate)
	else
		self:HidePlateSpells(plate)
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

-- Pets can carry a player's name; only player/boss plates may claim a name-mapped GUID.
local function IsPlayerOrBossPlate(plate)
	return GetPlateType(plate) == "PLAYER" or PlateIsBoss(plate)
end

-- This will add buff frames to a frame matching a given name.
-- This should only be used for player names because mobs/npcs can share the same name.
function core:UpdatePlateByName(name, maxhp)
	local GUID = nametoGUIDs[name]
	if GUID then
		local plate = GetPlateByName(name, maxhp, IsPlayerOrBossPlate)
		if plate and self:ShouldAddBuffs(plate) == true then
			self:AddBuffsToPlate(plate, GUID)
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

function core:SkinCallback(skin, glossAlpha, gloss, _, _, colors)
	self.db.profile.skin_SkinID = skin
	self.db.profile.skin_Gloss = glossAlpha
	self.db.profile.skin_Backdrop = gloss
	self.db.profile.skin_Colors = colors
end