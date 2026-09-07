local folder, core = ...

local pairs, select, tonumber, string_match, string_sub, math_floor, table_insert, table_remove, table_getn, bit_band, GetTime =
      pairs, select, tonumber, string.match, string.sub, math.floor, table.insert, table.remove, table.getn, bit.band, GetTime

local UnitGUID, UnitName, UnitExists, UnitIsPlayer, UnitIsUnit, UnitClassification, UnitCanAttack, UnitBuff, UnitDebuff, UnitHealthMax, GetSpellInfo = 
      UnitGUID, UnitName, UnitExists, UnitIsPlayer, UnitIsUnit, UnitClassification, UnitCanAttack, UnitBuff, UnitDebuff, UnitHealthMax, GetSpellInfo

local COMBATLOG_OBJECT_TYPE_PLAYER 			= COMBATLOG_OBJECT_TYPE_PLAYER or 0x00000400
local COMBATLOG_OBJECT_REACTION_FRIENDLY 	= COMBATLOG_OBJECT_REACTION_FRIENDLY or 0x00000010
local COMBATLOG_OBJECT_REACTION_HOSTILE 	= COMBATLOG_OBJECT_REACTION_HOSTILE or 0x00000040

local spellDuration 		= core.spellDuration
local spellDebuffType 		= core.spellDebuffType
local auraInfoPvP 			= core.auraInfoPvP
local drSpells 				= core.drSpells
local guidBuffs 			= core.guidBuffs
local nametoGUIDs 			= core.nametoGUIDs
local InterruptsDuration	= core.InterruptsDuration

local GUIDDurations = {}
local GUIDAuras = {}
local GUIDDrEffects_reset = {}
local GUIDDrEffects_diminished = {}
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
	["ctrlstun"] = true,
	["rndstun"] = true,
	["taunt"] = true,
	["cyclone"] = true,
}

local resetDRTime = 18 --Time it tacks for DR to reset.

local eventFrame = CreateFrame("Frame")
eventFrame:SetScript("OnEvent", function(self, event, timestamp, eventType, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellID, spellName, spellSchool, auraType, amount)
    if self[eventType] then
        self[eventType](self, srcGUID, srcName, dstGUID, dstName, dstFlags, spellID, spellName, auraType, amount)
    end
end)

local P
local playerGUID
do
	local prev_OnEnable = core.OnEnable
	function core:OnEnable()
		prev_OnEnable(self)
		P = self.db.profile
		playerGUID = UnitGUID("player")
		core:RegisterCLEU()
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
	end
end

local function FlagIsPlayer(flags)
	return (bit_band(flags, COMBATLOG_OBJECT_TYPE_PLAYER) ~= 0)
end

local function FlagIsFriendly(flags)
	return (bit_band(flags, COMBATLOG_OBJECT_REACTION_FRIENDLY) ~= 0)
end

local function FlagIsHostle(flags)
	return (bit_band(flags, COMBATLOG_OBJECT_REACTION_HOSTILE) ~= 0)
end

-- Remove all auras on a GUID.
local function RemoveAllAurasFromGUID(dstGUID)
	if GUIDAuras[dstGUID] then
		for i=#GUIDAuras[dstGUID], 1, -1 do 
			table_remove(GUIDAuras[dstGUID], i)
		end
	end
end

local function ForceNameplateUpdate(dstGUID, dstName, dstFlags)
	if not core:UpdateTargetPlate(dstGUID) and not core:UpdatePlateByGUID(dstGUID) then
		-- We can't find a nameplate that matches that GUID.
		-- Lets check if the GUID is a player, if so find a
		-- nameplate that matches the player's name.
		if dstFlags and FlagIsPlayer(dstFlags) then
			local shortName = string_match(dstName, "(.+)-") or dstName -- Nameplates don't have server names.
			nametoGUIDs[shortName] = dstGUID
			core:UpdatePlateByName(shortName)
		end
	end
end

function core:AddSpellToGUID(dstGUID, spellID, srcName, spellName, spellTexture, duration, srcGUID, isDebuff, debuffType, expires, stackCount, scale)
	guidBuffs[dstGUID] = guidBuffs[dstGUID] or {}
	if #guidBuffs[dstGUID] > 0 then
		self:RemoveOldSpells(dstGUID)
	end

	local getTime = GetTime()
	local count = #guidBuffs[dstGUID]
	if count == 0 then
		i = 0
		table_insert(guidBuffs[dstGUID], i + 1, {
			name = spellName,
			icon = spellTexture,
			duration = (duration or 0),
			playerCast = srcGUID == playerGUID and 1,
			stackCount = stackCount or 0,
			startTime = getTime,
			expirationTime = expires or 0 - 0.1,
			sID = spellID,
			caster = srcName,
			scale = scale or 1
		})

		if isDebuff then
			guidBuffs[dstGUID][i + 1].isDebuff = true
			guidBuffs[dstGUID][i + 1].debuffType = debuffType or "none"
		end

		return true
	else
		for i = 1, count do
			if
				guidBuffs[dstGUID][i].sID == spellID and
					(not guidBuffs[dstGUID][i].caster or guidBuffs[dstGUID][i].caster == srcName)
			 then
				guidBuffs[dstGUID][i].expirationTime = expires or 0 - 0.1
				guidBuffs[dstGUID][i].startTime = getTime
				return true
			elseif i == count then
				table_insert(guidBuffs[dstGUID], i + 1, {
					name = spellName,
					icon = spellTexture,
					duration = (duration or 0),
					playerCast = srcGUID == playerGUID and 1,
					stackCount = stackCount or 0,
					startTime = getTime,
					expirationTime = expires or 0 - 0.1,
					sID = spellID,
					caster = srcName,
					scale = scale or 1
				})

				if isDebuff then
					guidBuffs[dstGUID][i + 1].isDebuff = true
					guidBuffs[dstGUID][i + 1].debuffType = debuffType or "none"
				end
				return true
			end
		end
	end
	return false
end

local GetDRDuration
do
	local drType, key, reset
	function GetDRDuration(dstGUID, spellID, duration)
		duration = duration or GetDuration(spellID, nil, dstGUID)
		drType = drSpells[spellID]
		if drType then
			key = dstGUID..drType
			reset = GUIDDrEffects_reset[key]
			if reset and GetTime() < reset then
				return duration * (GUIDDrEffects_diminished[key] or 1)
			end
		end
		return duration
	end
end


local GetDuration
do
	local B, maskedB
	local function GUIDIsPlayer(guid)
		B = tonumber(string_sub(guid, 5, 5), 16);
		maskedB = B % 8; -- x % 8 has the same effect as x & 0x7 on numbers <= 0xf
	--	local knownTypes = {[0]="player", [3]="NPC", [4]="pet", [5]="vehicle"};
	--	print("Your target is a " .. (knownTypes[maskedB] or " unknown entity!"));
		return maskedB == 0
	end

	local duration, dur
	--Return the duration of a spell.
	function GetDuration(spellID, srcGUID, dstGUID, dstIsPlayer)
		dstIsPlayer = dstIsPlayer or dstGUID and GUIDIsPlayer(dstGUID) or false
		if dstIsPlayer and auraInfoPvP[spellID] then
			--Receiver is a player and the spell has a PvP duration. Return the pvp duration.
			duration = auraInfoPvP[spellID]
			if dstGUID and duration then
				--Check if there's dimminshing returns on the spell.
				duration = GetDRDuration(dstGUID, spellID, duration)
			end
			return tonumber(duration or 0)
		elseif spellDuration[spellID] then
			--Check caster GUID was given.
			if srcGUID then
				--Check if we've seen that caster cast a spell with a duration that doesn't match our own (spec/glphed into something?)
				if GUIDDurations[srcGUID.."-"..spellID] then
					dur = GUIDDurations[srcGUID.."-"..spellID]
					--Check if receiver GUID was given.
					if dstGUID then
						--Check if there's dimminshing returns on the spell.
						dur = GetDRDuration(dstGUID, spellID, dur)
					end
					return dur
				end
			end
			return spellDuration[spellID]
		end
	end
end


local LearnAura
do
	local baseDuration
	function LearnAura(spellID, texture, duration, debuffKey, srcGUID)
		spellTexture[spellID] = texture
		if not spellDuration[spellID] then
			spellDuration[spellID] = duration
			spellDebuffType[spellID] = debuffKey
		elseif not auraInfoPvP[spellID] and srcGUID then
			baseDuration = GetDuration(spellID)
			if baseDuration and baseDuration ~= duration and duration > 0 then
				-- Sometimes UnitAura says a spell has 0 duration when it realy has more.
				--caster's duration doesn't match our DB, they're probably speced into something. lets remember that.
				GUIDDurations[srcGUID.."-"..spellID] = duration
			end
		end
	end
end



local function AddAuraFromUnitID(dstGUID, name, texture, stackCount, debuffType, duration, expirationTime, srcGUID, spellID, isDebuff)
	GUIDAuras[dstGUID] = GUIDAuras[dstGUID] or {}
	table_insert(GUIDAuras[dstGUID], #GUIDAuras[dstGUID]+1, {
		name = name,
		texture = texture,
		debuffType = debuffType,
		duration = duration,
		expirationTime = expirationTime,
		spellID = spellID,
		srcGUID = srcGUID,
		isDebuff = isDebuff,
		stackCount = stackCount,
	})
end

do
	-- Returns a unit's name with server if server isn't our own.
	-- This name matches the one shown in combatlog.
	local name, realm, fullname
	local function GetFullName(unitID)
		name, realm = UnitName(unitID)
		fullname = name
		if realm and realm ~= "" then
			fullname = fullname.."-"..realm
		end
		return fullname
	end

	function core:CollectUnitInfo(unitID)
		if not unitID or UnitIsUnit(unitID, "player") then return end
		local GUID = UnitGUID(unitID)
		if not GUID then return end
		local unitName = UnitName(unitID)

		RemoveAllAurasFromGUID(GUID)

		if unitName and P.saveNameToGUID == true and UnitIsPlayer(unitID) or UnitClassification(unitID) == "worldboss" then
			nametoGUIDs[unitName] = GUID
		end
		guidBuffs[GUID] = guidBuffs[GUID] or {}
		--Remove all the entries.
		for i = table_getn(guidBuffs[GUID]), 1, -1 do
			if guidBuffs[GUID][i].debuffType ~= "Interrupt" then
				table_remove(guidBuffs[GUID], i)
			end
		end
		local i = 1
		local name, icon, count, duration, expirationTime, unitCaster, spellId, debuffType, debuffKey, srcGUID, _
		while P.defaultBuffShow ~= 5 do
			name, _, icon, count, debuffType, duration, expirationTime, unitCaster, _, _, spellId = UnitBuff(unitID, i)
			if not name then break end

			duration = math_floor(duration + .5)
			debuffKey = debuffTypes[debuffType]
			srcGUID = nil
			if UnitExists(unitCaster) then
				srcGUID = UnitGUID(unitCaster)
			end
			LearnAura(spellId, icon, duration, debuffKey, srcGUID)
			AddAuraFromUnitID(
				GUID,
				name,
				icon,
				count and count > 1 and count or nil,
				debuffKey and debuffType or "none",
				duration,
				expirationTime,
				srcGUID,
				spellId,
				false
			)
			
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
						caster = unitCaster and GetFullName(unitCaster),
						scale = spellOpts.increase or 1
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
						caster = unitCaster and GetFullName(unitCaster),
						scale = 1
					})
				end
			end
			i = i + 1
		end

		i = 1
		while P.defaultDebuffShow ~= 5 do
			name, _, icon, count, debuffType, duration, expirationTime, unitCaster, _, _, spellId = UnitDebuff(unitID, i)
			if not name then break end

			duration = math_floor(duration + .5)
			debuffKey = debuffTypes[debuffType]
			srcGUID = nil
			if UnitExists(unitCaster) then
				srcGUID = UnitGUID(unitCaster)
			end
			LearnAura(spellId, icon, duration, debuffKey, srcGUID)
			AddAuraFromUnitID(
				GUID,
				name,
				icon,
				count and count > 1 and count or nil,
				debuffKey and debuffType or "none",
				duration,
				expirationTime,
				srcGUID,
				spellId,
				true
			)

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
						caster = unitCaster and GetFullName(unitCaster),
						scale = spellOpts.increase or 1
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
						caster = unitCaster and GetFullName(unitCaster),
						scale = 1
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
		
		if unitName and not self:UpdatePlateByGUID(GUID) and (UnitIsPlayer(unitID) or UnitClassification(unitID) == "worldboss") then
			-- LibNameplates can't find a nameplate that matches that GUID. Since the unitID's a player/worldboss which have unique names, add buffs to the frame that matches that name.
			-- Note, this /can/ add buffs to the wrong frame if a hunter pet has the same name as a player. This is so rare that I'll risk it.
			self:UpdatePlateByName(unitName, UnitHealthMax(unitID))
		end
	end
end

local GUIDGainedDRAura
do
	local drType, key, reset
	function GUIDGainedDRAura(dstGUID, spellID, dstIsPlayer)
		drType = drSpells[spellID]
		if dstIsPlayer or pveDR[drType] then
			key = dstGUID..drType
			reset = GUIDDrEffects_reset[key]
			if reset and reset <= GetTime() then
				GUIDDrEffects_diminished[key] = 1
			end
		end
	end
end

local GUIDRemovedDRAura
do
	local drType, key
	local function NextDR(diminished)
		if diminished == 1 then
			return 0.50
		elseif diminished == 0.50 then
			return 0.25
		end
		return 0
	end
	function GUIDRemovedDRAura(dstGUID, spellID, dstIsPlayer)
		drType = drSpells[spellID]
		if dstIsPlayer or pveDR[drType] then
			key = dstGUID..drType
			GUIDDrEffects_reset[key] = GetTime() + resetDRTime
			GUIDDrEffects_diminished[key] = NextDR( GUIDDrEffects_diminished[key] or 1.0 )
		end
	end
end

local RemoveExpiredAuras
do
	local data, currentTime
	-- Remove expired auras from a GUID
	function RemoveExpiredAuras(dstGUID)
		if GUIDAuras[dstGUID] then
			currentTime = GetTime()
			for i = #GUIDAuras[dstGUID], 1, -1 do
				data = GUIDAuras[dstGUID][i]
				if data.expirationTime > 0 and currentTime > data.expirationTime then
					table_remove(GUIDAuras[dstGUID], i)
				end
			end
		end
	end
end

local GetDebuffType
do
	local debuffType
	--Return the debuff type of a spell.
	function GetDebuffType(spellID)
		if not spellDuration[spellID] then return "none" end
		debuffType = spellDebuffType[spellID]
		return debuffType and debuffTypes[debuffType] or "none"
	end
end

local AddAuraToGUID
do
	local texture
	local function GetSpellIcon(spellID)
		texture = spellTexture[spellID]
		if not texture then
			texture = select(3, GetSpellInfo(spellID))
			spellTexture[spellID] = texture
		end
		return texture
	end
	local duration, texture
	-- Add a auraID to our GUID list.
	function AddAuraToGUID(dstGUID, name, spellID, srcGUID, isDebuff, amount)
		duration = GetDuration(spellID, srcGUID, dstGUID)
		GUIDAuras[dstGUID] = GUIDAuras[dstGUID] or {}
		table_insert(GUIDAuras[dstGUID], #GUIDAuras[dstGUID]+1, {
			name = name,
			texture = GetSpellIcon(spellID),
			debuffType = GetDebuffType(spellID),
			duration = duration,
			expirationTime = duration ~= 0 and GetTime() + duration or 0,
			spellID = spellID,
			srcGUID = srcGUID,
			isDebuff = isDebuff,
			stackCount = amount,
		})
	end
end

local AddAuraDose
do
	local data
	-- Increase stack count of an aura.
	function AddAuraDose(dstGUID, spellID, srcGUID, amount)
		if GUIDAuras[dstGUID] then
			if srcGUID then
				for i=1, #GUIDAuras[dstGUID] do 
					data = GUIDAuras[dstGUID][i]
					if data.spellID == spellID and data.srcGUID == srcGUID then
						data.stackCount = amount
						data.expirationTime = data.duration ~= 0 and data.duration + GetTime() or 0
						return true, data.stackCount, data.expirationTime
					end
				end
			end
			for i=1, #GUIDAuras[dstGUID] do 
				data = GUIDAuras[dstGUID][i]
				if data.spellID == spellID then
					data.stackCount = amount
					data.expirationTime = data.duration ~= 0 and data.duration + GetTime() or 0
					return true, data.stackCount, data.expirationTime
				end
			end

		end
		return false
	end
end

local RemoveAuraDose
do
	local data
	-- Remove stacks from a aura.
	function RemoveAuraDose(dstGUID, spellID, srcGUID, amount)
		if GUIDAuras[dstGUID] then
			if srcGUID then
				for i=1, #GUIDAuras[dstGUID] do 
					data = GUIDAuras[dstGUID][i]
					if data.spellID == spellID and data.srcGUID == srcGUID then
						data.stackCount = amount
						return true, data.stackCount, data.expirationTime
					end
				end
			end
			for i=1, #GUIDAuras[dstGUID] do 
				data = GUIDAuras[dstGUID][i]
				if data.spellID == spellID then
					data.stackCount = amount
					return true, data.stackCount, data.expirationTime
				end
			end

		end
		return false
	end
end

local RefreshAura
do
	local data
	-- Refresh the start and expiration time of a aura.
	function RefreshAura(dstGUID, spellID, srcGUID)
		if GUIDAuras[dstGUID] then
			if srcGUID then
				for i=1, #GUIDAuras[dstGUID] do 
					data = GUIDAuras[dstGUID][i]
					if data.spellID == spellID and data.srcGUID == srcGUID then
						data.expirationTime = data.duration ~= 0 and data.duration + GetTime() or 0
						return true, data.expirationTime
					end
				end
			end
			for i=1, #GUIDAuras[dstGUID] do 
				data = GUIDAuras[dstGUID][i]
				if data.spellID == spellID then
					data.expirationTime = data.duration ~= 0 and data.duration + GetTime() or 0
					return true, data.expirationTime
				end
			end
		end
		return false
	end
end

local RemoveAuraFromGUID
do
	local data
	-- Remove a aura from a GUID.
	function RemoveAuraFromGUID(dstGUID, spellID, srcGUID)
		if GUIDAuras[dstGUID] then
			if srcGUID then
				for i= #GUIDAuras[dstGUID],1, -1 do 
					data = GUIDAuras[dstGUID][i]
					if data.spellID == spellID and srcGUID == data.srcGUID then
						table_remove(GUIDAuras[dstGUID], i)
						return
					end
				end
			end
			for i= #GUIDAuras[dstGUID],1, -1 do 
				data = GUIDAuras[dstGUID][i]
				if data.spellID == spellID  then
					table_remove(GUIDAuras[dstGUID], i)
					return
				end
			end
		end
	end
end


local GUIDAuraID
do
	local data
	function GUIDAuraID(dstGUID, spellID, srcGUID)
		if GUIDAuras[dstGUID] then
			if srcGUID then
				for i=1, #GUIDAuras[dstGUID] do 
					data = GUIDAuras[dstGUID][i]
					if data.spellID == spellID and data.srcGUID == srcGUID then
						return true, data.name, data.texture, data.stackCount or 0, data.debuffType, data.duration, data.expirationTime, data.isDebuff, data.srcGUID, data.spellID
					end
				end
			end
			for i=1, #GUIDAuras[dstGUID] do 
				data = GUIDAuras[dstGUID][i]
				if data.spellID == spellID then
					return true, data.name, data.texture, data.stackCount or 0, data.debuffType, data.duration, data.expirationTime, data.isDebuff, data.srcGUID, data.spellID
				end
			end
		end
		return false
	end
end

local function CheckFilter(tip, spelllist)
	if tip == "BUFF" then
		return not (spelllist and P.defaultBuffShow == 4)
	elseif tip == "DEBUFF" then
		return not (spelllist and P.defaultDebuffShow == 4)
	end
	return nil
end

local function HandleAuraApply(srcGUID, srcName, dstGUID, dstName, dstFlags, spellID, auraType)
	if dstGUID == playerGUID then return end
	if auraType == "BUFF" and P.defaultBuffShow == 5 then return end
	if auraType == "DEBUFF" and P.defaultDebuffShow == 5 then return end
	local found, spellName, spellTexture, stackCount, debuffType, duration, expires, isDebuff, casterGUID = GUIDAuraID(dstGUID, spellID, srcGUID)
	if found then
		spellTexture = spellTexture:upper():gsub("INTERFACE\\ICONS\\", "")
		local updateBars = false
		local spellOpts = core:HaveSpellOpts(spellName, spellID)
		if spellOpts and spellOpts.show and CheckFilter(auraType, true) then
			if
				P.spellOpts[spellName].show == 1 or
				(P.spellOpts[spellName].show == 2 and srcGUID == playerGUID) or
				(P.spellOpts[spellName].show == 4 and FlagIsFriendly(dstFlags)) or
				(P.spellOpts[spellName].show == 5 and FlagIsHostle(dstFlags))
			then
				updateBars = core:AddSpellToGUID(dstGUID, spellID, srcName, spellName, spellTexture, duration, srcGUID, isDebuff, debuffType, expires, stackCount, spellOpts.increase)
			end
		else
			if
				(auraType == "BUFF" and P.defaultBuffShow == 1) or
				((P.defaultBuffShow == 2 and srcGUID == playerGUID) or (P.defaultBuffShow == 4 and srcGUID == playerGUID)) or
				(auraType == "DEBUFF" and P.defaultDebuffShow == 1) or
				((P.defaultDebuffShow == 2 and srcGUID == playerGUID) or (P.defaultDebuffShow == 4 and srcGUID == playerGUID))
			then
				updateBars = core:AddSpellToGUID(dstGUID, spellID, srcName, spellName, spellTexture, duration, srcGUID, isDebuff, debuffType, expires, stackCount)
			end
		end
		if updateBars then
			ForceNameplateUpdate(dstGUID, dstName, dstFlags)
		end
	end
end

function eventFrame:SPELL_AURA_APPLIED(srcGUID, srcName, dstGUID, dstName, dstFlags, spellID, spellName, auraType, amount)
	if drSpells[spellID] then
		GUIDGainedDRAura(dstGUID, spellID, FlagIsPlayer(dstFlags))
	end
	if spellDuration[spellID] then
		RemoveExpiredAuras(dstGUID)
		AddAuraToGUID(dstGUID, spellName, spellID, srcGUID, auraType == "DEBUFF", amount)
		HandleAuraApply(srcGUID, srcName, dstGUID, dstName, dstFlags, spellID, auraType)
	end
end

function eventFrame:SPELL_AURA_REMOVED(srcGUID, srcName, dstGUID, dstName, dstFlags, spellID, spellName, auraType, amount)
	RemoveAuraFromGUID(dstGUID, spellID, srcGUID)
	if drSpells[spellID] then
		GUIDRemovedDRAura(dstGUID, spellID, FlagIsPlayer(dstFlags))
	end

	if dstGUID == playerGUID then return end

	if guidBuffs[dstGUID] then
		for i = #guidBuffs[dstGUID], 1, -1 do
			if guidBuffs[dstGUID][i].sID == spellID and (not guidBuffs[dstGUID][i].caster or guidBuffs[dstGUID][i].caster == srcName) then
				table_remove(guidBuffs[dstGUID], i)
				ForceNameplateUpdate(dstGUID, dstName, dstFlags)
				return
			end
		end
	end
end

do
	local refreshed, expirationTime
	function eventFrame:SPELL_AURA_REFRESH(srcGUID, srcName, dstGUID, dstName, dstFlags, spellID, spellName, auraType, amount)
		if drSpells[spellID] then
			GUIDRemovedDRAura(dstGUID, spellID, FlagIsPlayer(dstFlags))
			GUIDGainedDRAura(dstGUID, spellID, FlagIsPlayer(dstFlags))
		end
		refreshed, expirationTime = RefreshAura(dstGUID, spellID, srcGUID)
		if refreshed then
			if dstGUID == playerGUID then return end
			if guidBuffs[dstGUID] then
				for i = #guidBuffs[dstGUID], 1, -1 do
					if guidBuffs[dstGUID][i].sID == spellID and (not guidBuffs[dstGUID][i].caster or guidBuffs[dstGUID][i].caster == srcName) then
						guidBuffs[dstGUID][i].startTime = GetTime()
						guidBuffs[dstGUID][i].expirationTime = expirationTime
						ForceNameplateUpdate(dstGUID, dstName, dstFlags)
						return
					end
				end
			end
			HandleAuraApply(srcGUID, srcName, dstGUID, dstName, dstFlags, spellID, auraType)
			return
		end
		self:SPELL_AURA_APPLIED(srcGUID, srcName, dstGUID, dstName, dstFlags, spellID, spellName, auraType, amount)
	end
end

do
	local dosed, stackCount, expirationTime
	--DOSE = spell stacking
	function eventFrame:SPELL_AURA_APPLIED_DOSE(srcGUID, srcName, dstGUID, dstName, dstFlags, spellID, spellName, auraType, amount)
		dosed, stackCount, expirationTime = AddAuraDose(dstGUID, spellID, srcGUID, amount)
		if dosed then
			HandleAuraApply(srcGUID, srcName, dstGUID, dstName, dstFlags, spellID, auraType)
			return
		end
		--Spell isn't in our list, let's add it.
		self:SPELL_AURA_APPLIED(srcGUID, srcName, dstGUID, dstName, dstFlags, spellID, spellName, auraType, amount)
	end
end

do
	local dosed, stackCount, expirationTime
	function eventFrame:SPELL_AURA_REMOVED_DOSE(srcGUID, srcName, dstGUID, dstName, dstFlags, spellID, spellName, auraType, amount)
		dosed, stackCount, expirationTime = RemoveAuraDose(dstGUID, spellID, srcGUID, amount)
		if dosed then
			if dstGUID == playerGUID then return end
			if guidBuffs[dstGUID] then
				for i = #guidBuffs[dstGUID], 1, -1 do
					if guidBuffs[dstGUID][i].sID == spellID and (not guidBuffs[dstGUID][i].caster or guidBuffs[dstGUID][i].caster == srcName) then
						guidBuffs[dstGUID][i].stackCount = stackCount
						guidBuffs[dstGUID][i].startTime = GetTime()
						guidBuffs[dstGUID][i].expirationTime = expirationTime
						ForceNameplateUpdate(dstGUID, dstName, dstFlags)
						return
					end
				end
			end
			HandleAuraApply(srcGUID, srcName, dstGUID, dstName, dstFlags, spellID, auraType)			
			return
		end
	end
end

local function AddInterruptToGUID(dstGUID, spellID, srcName, duration, srcGUID)
	guidBuffs[dstGUID] = guidBuffs[dstGUID] or {}
	if #guidBuffs[dstGUID] > 0 then
		core:RemoveOldSpells(dstGUID)
	end
	local getTime = GetTime()
	local spellName, _, spellTexture = GetSpellInfo(spellID)
	spellTexture = spellTexture:upper():gsub("INTERFACE\\ICONS\\", "")
	table_insert(guidBuffs[dstGUID], #guidBuffs[dstGUID] + 1, {
		name = spellName,
		icon = spellTexture,
		duration = duration,
		playerCast = srcGUID == playerGUID and 1,
		stackCount = 0,
		isDebuff = true,
		debuffType = "Interrupt",
		startTime = getTime,
		expirationTime = getTime + duration,
		sID = spellID,
		caster = srcName,
		scale = P.interruptsScale
	})
end

function eventFrame:SPELL_INTERRUPT(srcGUID, srcName, dstGUID, dstName, dstFlags, spellID, spellName, auraType, amount)
	if not P.showInterrupts then return end
	if dstGUID == playerGUID then return end
	local duration = InterruptsDuration[spellID]
	if not duration then return end
	duration = duration * (1 - P.interruptsReduction)
	if not FlagIsPlayer(dstFlags) then return end
	AddInterruptToGUID(dstGUID, spellID, srcName, duration, srcGUID)
	ForceNameplateUpdate(dstGUID, dstName, dstFlags)
end

function eventFrame:UNIT_DIED(srcGUID, srcName, dstGUID, dstName, dstFlags, spellID, spellName, auraType, amount)
	if GUIDAuras[dstGUID] then
		RemoveAllAurasFromGUID(dstGUID)
		if dstGUID == playerGUID then return end
		if guidBuffs[dstGUID] then
			-- Remove all known buffs for that person.
			-- Maybe we're in a BG and don't need their old buffs on our plates.
			for i = table_getn(guidBuffs[dstGUID]), 1, -1 do
				table_remove(guidBuffs[dstGUID], i)
			end
			ForceNameplateUpdate(dstGUID, dstName, dstFlags)
		end
	end
end

eventFrame.SPELL_AURA_BROKEN		= eventFrame.SPELL_AURA_REMOVED
eventFrame.SPELL_AURA_BROKEN_SPELL	= eventFrame.SPELL_AURA_REMOVED
eventFrame.UNIT_DESTROYED	= eventFrame.UNIT_DIED
eventFrame.UNIT_DISSIPATES	= eventFrame.UNIT_DIED
eventFrame.PARTY_KILL		= eventFrame.UNIT_DIED