local folder, core = ...

local pairs, select, tonumber, string_match, string_sub, math_floor, table_insert, table_remove, table_getn, bit_band, wipe, GetTime =
      pairs, select, tonumber, string.match, string.sub, math.floor, table.insert, table.remove, table.getn, bit.band, wipe, GetTime

local UnitGUID, UnitName, UnitExists, UnitIsPlayer, UnitIsUnit, UnitPlayerControlled, UnitClassification, UnitCanAttack, UnitAura, UnitHealthMax, GetSpellInfo = 
      UnitGUID, UnitName, UnitExists, UnitIsPlayer, UnitIsUnit, UnitPlayerControlled, UnitClassification, UnitCanAttack, UnitAura, UnitHealthMax, GetSpellInfo

local COMBATLOG_OBJECT_TYPE_PLAYER 			= COMBATLOG_OBJECT_TYPE_PLAYER or 0x00000400
local COMBATLOG_OBJECT_REACTION_FRIENDLY 	= COMBATLOG_OBJECT_REACTION_FRIENDLY or 0x00000010
local COMBATLOG_OBJECT_REACTION_HOSTILE 	= COMBATLOG_OBJECT_REACTION_HOSTILE or 0x00000040
local COMBATLOG_OBJECT_CONTROL_PLAYER 		= COMBATLOG_OBJECT_CONTROL_PLAYER or 0x00000100

local spellDuration 		= core.spellDuration
local spellDebuffType 		= core.spellDebuffType
local auraInfoPvP 			= core.auraInfoPvP
local drSpells 				= core.drSpells
local guidBuffs 			= core.guidBuffs
local nametoGUIDs 			= core.nametoGUIDs
local InterruptsDuration	= core.InterruptsDuration

local GUIDDurations = {}
local GUIDDrEffects = {}
local spellTexture = {}

--Save debuffType as a number, then return as a string when requested.
local debuffTypes = {
	Magic = 1,
	Disease = 2,
	Poison = 3,
	Curse = 4,
	[1] = "Magic",
	[2] = "Disease",
	[3] = "Poison",
	[4] = "Curse",	
}

local pveDR = {
	["controlled_stun"] = true,
	["random_stun"] = true,
	["opener_stun"] = true,
	["cyclone"] = true,
	["charge"] = true,
	["taunt"] = true,
}

local resetDRTime = 15
local playerGUID = UnitGUID("player")
local eventFrame = CreateFrame("Frame")

local P
do
	local prev_OnEnable = core.OnEnable
	function core:OnEnable()
		prev_OnEnable(self)
		P = self.db.profile
		playerGUID = UnitGUID("player")
		core:RegisterCLEU()
		core:StartSweeper()
	end
end

do
	local CombatLogClearEntries = CombatLogClearEntries
	function core:RegisterCLEU()
		if P.watchCombatlog == true then
			eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
			CombatLogClearEntries()
		else
			eventFrame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		end
	end
end

do
	local prev_OnDisable = core.OnDisable
	function core:OnDisable(...)
		if prev_OnDisable then
			prev_OnDisable(self, ...)
		end
		eventFrame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		core:StopSweeper()
	end
end

local function FlagIsPlayer(flags)
	return flags and (bit_band(flags, COMBATLOG_OBJECT_TYPE_PLAYER) ~= 0)
end

local function FlagIsFriendly(flags)
	return flags and (bit_band(flags, COMBATLOG_OBJECT_REACTION_FRIENDLY) ~= 0)
end

local function FlagIsHostle(flags)
	return flags and (bit_band(flags, COMBATLOG_OBJECT_REACTION_HOSTILE) ~= 0)
end

local function FlagIsPlayerControlled(flags)
	return flags and bit_band(flags, COMBATLOG_OBJECT_CONTROL_PLAYER) ~= 0
end

local function ForceNameplateUpdate(dstGUID, dstName, dstFlags)
	if not core:UpdateTargetPlate(dstGUID) and not core:UpdatePlateByGUID(dstGUID) then
		-- No nameplate matches that GUID. Fall back to the plate whose name maps to it.
		if dstName and FlagIsPlayer(dstFlags) then
			local shortName = string_match(dstName, "(.+)-") or dstName -- Nameplates don't have server names.
			nametoGUIDs[shortName] = dstGUID
			core:UpdatePlateByName(shortName)
		end
	end
end

local function GUIDBuffIndex(dstGUID, spellID, srcGUID)
	local t = guidBuffs[dstGUID]
	if not t then return end
	local wildcard
	for i = 1, #t do
		local rec = t[i]
		if rec.sID == spellID and rec.debuffType ~= "Interrupt" then
			if rec.srcGUID == srcGUID then
				return i
			elseif rec.srcGUID == nil and wildcard == nil then
				wildcard = i
			end
		end
	end
	if wildcard then
		local rec = t[wildcard]
		rec.srcGUID = srcGUID
		rec.playerCast = srcGUID == playerGUID and 1
	end
	return wildcard
end

local function AddSpellToGUID(dstGUID, spellID, spellName, texture, duration, srcGUID, isDebuff, debuffType, expirationTime, amount, scale)
	guidBuffs[dstGUID] = guidBuffs[dstGUID] or {}
	local t = guidBuffs[dstGUID]
	if #t > 0 then
		core:RemoveOldSpells(dstGUID)
	end
	local i = GUIDBuffIndex(dstGUID, spellID, srcGUID)
	if i then
		t[i].duration = duration or 0
		t[i].expirationTime = expirationTime or 0
		return true
	end
	local rec = {
		name = spellName,
		icon = texture,
		duration = (duration or 0),
		playerCast = srcGUID == playerGUID and 1,
		stackCount = amount or 0,
		expirationTime = expirationTime or 0,
		sID = spellID,
		srcGUID = srcGUID,
		scale = scale or 1
	}
	if isDebuff then
		rec.isDebuff = true
		rec.debuffType = debuffType or "none"
	end
	t[#t + 1] = rec
	return true
end

local function GetDRDuration(dstGUID, spellID, duration)
	local drType = drSpells[spellID]
	if drType then
		local effects = GUIDDrEffects[dstGUID]
		local dr = effects and effects[drType]
		if dr and GetTime() < dr.reset then
			if dr.diminished == 0 then
				dr.diminished = 1
				return duration
			end
			return duration * dr.diminished
		end
	end
	return duration
end

--Return the duration of a spell. Both flags come from the combat log
local function GetDuration(spellID, srcGUID, dstGUID, srcIsPlayerControlled, dstIsPlayerControlled)
	local duration
	if srcIsPlayerControlled and dstIsPlayerControlled and auraInfoPvP[spellID] then
		--The server caps a CC only when caster and target are both player controlled
		duration = auraInfoPvP[spellID]
	elseif spellDuration[spellID] then
		local casters = GUIDDurations[spellID]
		duration = (srcGUID and casters and casters[srcGUID]) or spellDuration[spellID]
	else
		return
	end
	return GetDRDuration(dstGUID, spellID, duration)
end

local function LearnAura(spellID, texture, duration, debuffKey, srcGUID)
	spellTexture[spellID] = texture
	--UnitAura sometimes reports 0 duration for auras that do have one.
	if duration <= 0 then return end
	local baseDuration = spellDuration[spellID]
	if not baseDuration then
		spellDuration[spellID] = duration
		spellDebuffType[spellID] = debuffKey
	elseif srcGUID then
		--Per caster override for specs and glyphs.
		local casters = GUIDDurations[spellID]
		if duration == baseDuration then
			--Back at the base duration: assume the caster dropped w/e extended it.
			if casters then
				casters[srcGUID] = nil
			end
		elseif duration > ((casters and casters[srcGUID]) or baseDuration) then
			--New high-water mark; never overwritten downward, only reset at the base.
			if not casters then
				casters = {}
				GUIDDurations[spellID] = casters
			end
			casters[srcGUID] = duration
		end
	end
end

--A live DR aura proves one application already landed, so the next one is capped at half
local function GUIDSeenDRAura(dstGUID, drType, expirationTime, dstIsPlayerControlled)
	if not (dstIsPlayerControlled or pveDR[drType]) then return end
	local effects = GUIDDrEffects[dstGUID]
	if not effects then
		effects = {}
		GUIDDrEffects[dstGUID] = effects
	end
	local dr = effects[drType]
	if not dr then
		dr = { reset = 0, diminished = 1 }
		effects[drType] = dr
	end
	if GetTime() >= dr.reset then
		dr.diminished = 0.5
	end
	local window = expirationTime + resetDRTime
	if window > dr.reset then
		dr.reset = window
	end
end

local function CollectAuras(unitID, GUID, filter)
	local name, icon, count, duration, expirationTime, unitCaster, spellId, debuffType, debuffKey, srcGUID, drType, shouldAdd, scale, spellOpts, _
	local isDebuff = filter == "HARMFUL" or nil
	local defaultShow = isDebuff and P.defaultDebuffShow or P.defaultBuffShow
	if defaultShow == 5 then return end
	local isPlayerControlled = UnitPlayerControlled(unitID)
	local i = 1
	while true do
		name, _, icon, count, debuffType, duration, expirationTime, unitCaster, _, _, spellId = UnitAura(unitID, i, filter)
		if not name then break end
		duration = math_floor(duration + .5)
		debuffKey = debuffTypes[debuffType]
		srcGUID = unitCaster and UnitGUID(unitCaster)
		LearnAura(spellId, icon, duration, debuffKey, srcGUID)
		if isDebuff then
			drType = drSpells[spellId]
			if drType and expirationTime > 0 then
				GUIDSeenDRAura(GUID, drType, expirationTime, isPlayerControlled)
			end
		end
		shouldAdd = false
		scale = 1
		spellOpts = core:HaveSpellOpts(name, spellId)
		if spellOpts and spellOpts.show and defaultShow ~= 4 then
			shouldAdd = spellOpts.show == 1 
						or (spellOpts.show == 2 and unitCaster == "player")
						or (spellOpts.show == 4 and not UnitCanAttack("player", unitID))
						or (spellOpts.show == 5 and UnitCanAttack("player", unitID))
			scale = spellOpts.increase or 1
		elseif duration > 0 then -- REVISAR
			shouldAdd = defaultShow == 1
						or (defaultShow == 2 and unitCaster == "player")
						or (defaultShow == 4 and unitCaster == "player")
		end
		if shouldAdd then
			table_insert(guidBuffs[GUID], {
				name = name,
				icon = icon,
				expirationTime = expirationTime,
				duration = duration,
				playerCast = (unitCaster == "player") and 1,
				stackCount = count,
				debuffType = isDebuff and debuffType,
				isDebuff = isDebuff,
				sID = spellId,
				srcGUID = srcGUID,
				scale = scale
			})
		end
		i = i + 1
	end
end

function core:CollectUnitInfo(unitID)
	if not unitID or UnitIsUnit(unitID, "player") then return end
	local GUID = UnitGUID(unitID)
	if not GUID then return end
	local unitName = UnitName(unitID)
	if unitName and P.saveNameToGUID == true and (UnitIsPlayer(unitID) or UnitClassification(unitID) == "worldboss") then
		nametoGUIDs[unitName] = GUID
	end
	guidBuffs[GUID] = guidBuffs[GUID] or {}
	for i = table_getn(guidBuffs[GUID]), 1, -1 do
		if guidBuffs[GUID][i].debuffType ~= "Interrupt" then
			table_remove(guidBuffs[GUID], i)
		end
	end
	CollectAuras(unitID, GUID, "HELPFUL")
	CollectAuras(unitID, GUID, "HARMFUL")
	if core.iconTestMode == true then
		for j = table_getn(guidBuffs[GUID]), 1, -1 do
			for t = 1, P.iconsPerBar - 1 do
				table_insert(guidBuffs[GUID], j, guidBuffs[GUID][j]) --reinsert the entry abunch of times.
			end
		end
	end
	if unitName and not self:UpdatePlateByGUID(GUID) and (UnitIsPlayer(unitID) or UnitClassification(unitID) == "worldboss") then
		self:UpdatePlateByName(unitName, UnitHealthMax(unitID))
	end
end

local function NextDR(diminished)
	if diminished == 1 then
		return 0.50
	elseif diminished == 0.50 then
		return 0.25
	end
	return 0
end

local function GUIDAppliedDRAura(dstGUID, drType, duration, dstIsPlayerControlled)
	if not (dstIsPlayerControlled or pveDR[drType]) then return end
	local now = GetTime()
	local effects = GUIDDrEffects[dstGUID]
	if not effects then
		effects = {}
		GUIDDrEffects[dstGUID] = effects
	end
	local dr = effects[drType]
	if not dr then
		dr = { reset = 0, diminished = 1 }
		effects[drType] = dr
	end
	local live = now < dr.reset
	local diminished = (live and dr.diminished) or 1
	if diminished == 0 then
		diminished = 1
	end
	dr.diminished = NextDR(diminished)
	local window = now + (duration or 0) + resetDRTime
	if not live or window > dr.reset then
		dr.reset = window
	end
end

local function GUIDRemovedDRAura(dstGUID, drType)
	local effects = GUIDDrEffects[dstGUID]
	local dr = effects and effects[drType]
	if not dr then return end
	local now = GetTime()
	if now < dr.reset then
		dr.reset = now + resetDRTime
	end
end

-- Global purge of GUID state that nothing will read again.
local sweepInterval = 60
local sweepElapsed = 0
local livePlateGUIDs = {}
local function SweepGUIDTables()
	local empty
	local now = GetTime()
	for guid, effects in pairs(GUIDDrEffects) do
		empty = true
		for drType, dr in pairs(effects) do
			if now >= dr.reset then
				effects[drType] = nil
			else
				empty = false
			end
		end
		if empty then
			GUIDDrEffects[guid] = nil
		end
	end
	wipe(livePlateGUIDs)
	local plateGUID
	for _, plate in core.IteratePlates() do
		plateGUID = core.GetPlateGUID(plate)
		if plateGUID then
			livePlateGUIDs[plateGUID] = true
		end
	end
	for guid, t in pairs(guidBuffs) do
		if #t > 0 then
			core:RemoveOldSpells(guid)
		end
		if #t == 0 and not livePlateGUIDs[guid] then
			guidBuffs[guid] = nil
		end
	end
end

local function SweeperOnUpdate(self, elapsed)
	sweepElapsed = sweepElapsed + elapsed
	if sweepElapsed < sweepInterval then return end
	sweepElapsed = 0
	SweepGUIDTables()
end

function core:StartSweeper()
	sweepElapsed = 0
	eventFrame:SetScript("OnUpdate", SweeperOnUpdate)
end

function core:StopSweeper()
	eventFrame:SetScript("OnUpdate", nil)
end

function core:PLAYER_ENTERING_WORLD()
	wipe(guidBuffs)
	wipe(nametoGUIDs)
	wipe(GUIDDurations)
	wipe(GUIDDrEffects)
end

local function GetDebuffType(spellID)
	if not spellDuration[spellID] then return "none" end
	local debuffType = spellDebuffType[spellID]
	return debuffType and debuffTypes[debuffType] or "none"
end

local function GetSpellIcon(spellID)
	local texture = spellTexture[spellID]
	if not texture then
		texture = select(3, GetSpellInfo(spellID))
		spellTexture[spellID] = texture
	end
	return texture
end

local function CheckFilter(tip, spelllist)
	if tip == "BUFF" then
		return not (spelllist and P.defaultBuffShow == 4)
	elseif tip == "DEBUFF" then
		return not (spelllist and P.defaultDebuffShow == 4)
	end
	return nil
end

local function HandleAuraApply(srcGUID, srcFlags, dstGUID, dstName, dstFlags, spellID, spellName, auraType, amount)
	if auraType == "BUFF" and P.defaultBuffShow == 5 then return end
	if auraType == "DEBUFF" and P.defaultDebuffShow == 5 then return end
	local duration = GetDuration(spellID, srcGUID, dstGUID, FlagIsPlayerControlled(srcFlags), FlagIsPlayerControlled(dstFlags))
	local expirationTime = duration ~= 0 and GetTime() + duration or 0
	local texture = GetSpellIcon(spellID)
	local isDebuff = auraType == "DEBUFF"
	local debuffType = GetDebuffType(spellID)
	local updateBars = false
	local spellOpts = core:HaveSpellOpts(spellName, spellID)
	if spellOpts and spellOpts.show and CheckFilter(auraType, true) then
		if
			spellOpts.show == 1 or
			(spellOpts.show == 2 and srcGUID == playerGUID) or
			(spellOpts.show == 4 and FlagIsFriendly(dstFlags)) or
			(spellOpts.show == 5 and FlagIsHostle(dstFlags))
		then
			updateBars = AddSpellToGUID(dstGUID, spellID, spellName, texture, duration, srcGUID, isDebuff, debuffType, expirationTime, amount, spellOpts.increase)
		end
	else
		if
			(auraType == "BUFF" and (P.defaultBuffShow == 1 or ((P.defaultBuffShow == 2 or P.defaultBuffShow == 4) and srcGUID == playerGUID))) or
			(auraType == "DEBUFF" and (P.defaultDebuffShow == 1 or ((P.defaultDebuffShow == 2 or P.defaultDebuffShow == 4) and srcGUID == playerGUID)))
		then
			updateBars = AddSpellToGUID(dstGUID, spellID, spellName, texture, duration, srcGUID, isDebuff, debuffType, expirationTime, amount, 1)
		end
	end
	if updateBars then
		ForceNameplateUpdate(dstGUID, dstName, dstFlags)
	end
	return duration
end

function eventFrame:SPELL_AURA_APPLIED(srcGUID, srcFlags, dstGUID, dstName, dstFlags, spellID, spellName, auraType, amount)
	local duration
	if spellDuration[spellID] then
		duration = HandleAuraApply(srcGUID, srcFlags, dstGUID, dstName, dstFlags, spellID, spellName, auraType, amount)
	end
	local drType = drSpells[spellID]
	if drType then
		GUIDAppliedDRAura(dstGUID, drType, duration, FlagIsPlayerControlled(dstFlags))
	end
end

function eventFrame:SPELL_AURA_REMOVED(srcGUID, srcFlags, dstGUID, dstName, dstFlags, spellID, spellName, auraType, amount)
	local drType = drSpells[spellID]
	if drType then
		GUIDRemovedDRAura(dstGUID, drType)
	end
	local i = GUIDBuffIndex(dstGUID, spellID, srcGUID)
	if i then
		table_remove(guidBuffs[dstGUID], i)
		ForceNameplateUpdate(dstGUID, dstName, dstFlags)
	end
end

function eventFrame:SPELL_AURA_REFRESH(srcGUID, srcFlags, dstGUID, dstName, dstFlags, spellID, spellName, auraType, amount)
	local dstIsPlayerControlled = FlagIsPlayerControlled(dstFlags)
	local drType = drSpells[spellID]
	local duration
	local i = GUIDBuffIndex(dstGUID, spellID, srcGUID)
	if i then
		local rec = guidBuffs[dstGUID][i]
		if drType then
			duration = GetDuration(spellID, srcGUID, dstGUID, FlagIsPlayerControlled(srcFlags), dstIsPlayerControlled)
			rec.duration = duration or rec.duration
		end
		rec.expirationTime = rec.duration ~= 0 and GetTime() + rec.duration or 0
		ForceNameplateUpdate(dstGUID, dstName, dstFlags)
	elseif spellDuration[spellID] then
		duration = HandleAuraApply(srcGUID, srcFlags, dstGUID, dstName, dstFlags, spellID, spellName, auraType, amount)
	end
	if drType then
		GUIDAppliedDRAura(dstGUID, drType, duration, dstIsPlayerControlled)
	end
end

function eventFrame:SPELL_AURA_APPLIED_DOSE(srcGUID, srcFlags, dstGUID, dstName, dstFlags, spellID, spellName, auraType, amount)
	local i = GUIDBuffIndex(dstGUID, spellID, srcGUID)
	if i then
		local rec = guidBuffs[dstGUID][i]
		rec.stackCount = amount
		rec.expirationTime = rec.duration ~= 0 and GetTime() + rec.duration or 0
		ForceNameplateUpdate(dstGUID, dstName, dstFlags)
		return
	end
	--We're not tracking this aura yet: add it with the stack count the log reports.
	if spellDuration[spellID] then
		HandleAuraApply(srcGUID, srcFlags, dstGUID, dstName, dstFlags, spellID, spellName, auraType, amount)
	end
end

function eventFrame:SPELL_AURA_REMOVED_DOSE(srcGUID, srcFlags, dstGUID, dstName, dstFlags, spellID, spellName, auraType, amount)
	local i = GUIDBuffIndex(dstGUID, spellID, srcGUID)
	if i then
		local rec = guidBuffs[dstGUID][i]
		rec.stackCount = amount
		ForceNameplateUpdate(dstGUID, dstName, dstFlags)
	end
end

function eventFrame:SPELL_INTERRUPT(srcGUID, srcFlags, dstGUID, dstName, dstFlags, spellID, spellName)
	if not P.showInterrupts then return end
	local duration = InterruptsDuration[spellID]
	if not duration then return end
	duration = duration * (1 - P.interruptsReduction)
	if not FlagIsPlayer(dstFlags) then return end
	guidBuffs[dstGUID] = guidBuffs[dstGUID] or {}
	if #guidBuffs[dstGUID] > 0 then
		core:RemoveOldSpells(dstGUID)
	end
	table_insert(guidBuffs[dstGUID], #guidBuffs[dstGUID] + 1, {
		name = spellName,
		icon = GetSpellIcon(spellID),
		duration = duration,
		playerCast = srcGUID == playerGUID and 1,
		stackCount = 0,
		isDebuff = true,
		debuffType = "Interrupt",
		expirationTime = GetTime() + duration,
		sID = spellID,
		srcGUID = srcGUID,
		scale = P.interruptsScale
	})
	ForceNameplateUpdate(dstGUID, dstName, dstFlags)
end

function eventFrame:UNIT_DIED(srcGUID, srcFlags, dstGUID, dstName, dstFlags)
	GUIDDrEffects[dstGUID] = nil
	local t = guidBuffs[dstGUID]
	if t and #t > 0 then
		-- Remove all known buffs for that unit.
		for i = #t, 1, -1 do
			t[i] = nil
		end
		ForceNameplateUpdate(dstGUID, dstName, dstFlags)
	end
end

eventFrame.SPELL_AURA_BROKEN		= eventFrame.SPELL_AURA_REMOVED
eventFrame.SPELL_AURA_BROKEN_SPELL	= eventFrame.SPELL_AURA_REMOVED
eventFrame.UNIT_DESTROYED	= eventFrame.UNIT_DIED
eventFrame.UNIT_DISSIPATES	= eventFrame.UNIT_DIED
eventFrame.PARTY_KILL		= eventFrame.UNIT_DIED

eventFrame:SetScript("OnEvent", function(self, event, timestamp, eventType, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellID, spellName, spellSchool, auraType, amount)
    if dstGUID ~= playerGUID and self[eventType] then
        self[eventType](self, srcGUID, srcFlags, dstGUID, dstName, dstFlags, spellID, spellName, auraType, amount)
    end
end)
