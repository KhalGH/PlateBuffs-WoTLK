local folder, core = ...

if not core.LibNameplates then return end

local MSQ = core.MSQ or LibStub("LibButtonFacade", true) or LibStub("Masque", true)
core.MSQ = MSQ

local LSM = core.LSM or LibStub("LibSharedMedia-3.0", true)
core.LSM = LSM

--Globals
local _G = _G
local pairs = pairs
local table_insert = table.insert
local table_sort = table.sort
local table_getn = table.getn
local Debug = core.Debug
local tonumber = tonumber
local GetSpellInfo = GetSpellInfo
local select = select
local string_format = string.format
local GetAddOnMetadata = GetAddOnMetadata

core.tooltip = core.tooltip or CreateFrame("GameTooltip", folder .. "Tooltip", UIParent, "GameTooltipTemplate")
local tooltip = core.tooltip
tooltip:Show()
tooltip:SetOwner(UIParent, "ANCHOR_NONE")

-- local
local spellIDs = {}

local L = core.L or LibStub("AceLocale-3.0"):GetLocale(folder, true)

local P = {}
local prev_OnEnable = core.OnEnable
function core:OnEnable()
	prev_OnEnable(self)
	P = self.db.profile

	if P.addSpellDescriptions == true then
		spellIDs = self:GetAllSpellIDs()
	end

	self:BuildSpellUI()
end

local defaultSettings = core.defaultSettings.profile

defaultSettings.defaultBuffShow = 3
defaultSettings.defaultDebuffShow = 3
defaultSettings.unknownSpellDataIcon = false
defaultSettings.saveNameToGUID = true
defaultSettings.watchCombatlog = true
defaultSettings.addSpellDescriptions = false
defaultSettings.watchUnitIDAuras = true
defaultSettings.abovePlayers = true
defaultSettings.aboveNPC = true
defaultSettings.aboveFriendly = true
defaultSettings.aboveNeutral = true
defaultSettings.aboveHostile = true
defaultSettings.textureSize = 0
defaultSettings.barAnchorPoint = "BOTTOM"
defaultSettings.plateAnchorPoint = "TOP"
defaultSettings.barOffsetX = 0
defaultSettings.barOffsetY = -1
defaultSettings.iconsPerBar = 4
defaultSettings.barGrowth = 1
defaultSettings.numBars = 3
defaultSettings.iconWidth = 26
defaultSettings.iconHeight = 26
defaultSettings.iconScale = 1
defaultSettings.showInterrupts = true
defaultSettings.interruptsScale = 1.4
defaultSettings.biggerSelfSpells = false
defaultSettings.shrinkBar = true
defaultSettings.showBarBackground = false
defaultSettings.durationSize = 11
defaultSettings.stackSize = 8
defaultSettings.intervalX = 4
defaultSettings.intervalY = 4
defaultSettings.decimalThreshold = 0
defaultSettings.digitsnumber = 1
defaultSettings.durationAnchor = "CENTER"
defaultSettings.durationOffsetX = 0
defaultSettings.durationOffsetY = 0
defaultSettings.borderTexture = "Interface\\Addons\\PlateBuffs\\media\\DefaultBorder.blp"
defaultSettings.colorByType = true
defaultSettings.color1 = {0.80, 0, 0}
defaultSettings.color2 = {0.20, 0.60, 1.00}
defaultSettings.color3 = {0.60, 0.00, 1.00}
defaultSettings.color4 = {0.60, 0.40, 0}
defaultSettings.color5 = {0.00, 0.60, 0}
defaultSettings.color6 = {0.83, 0.83, 0.83}
defaultSettings.color7 = {0.20, 0.80, 0.60}
defaultSettings.blacklistTotems = true
defaultSettings.npcCombatWithOnly = false
defaultSettings.playerCombatWithOnly = false
defaultSettings.enableBlinkFade = true
defaultSettings.blinkThreshold = 3
defaultSettings.fadeThreshold = 3
defaultSettings.blinkFadeMinDuration = 6
defaultSettings.blinkTargetOnly = true
defaultSettings.fadeTargetOnly = false
defaultSettings.durationFont = "Friz Quadrata TT"
defaultSettings.showDuration = true
defaultSettings.showClockOverlay = false
defaultSettings.legacyCooldownClock = false
defaultSettings.enableAdjustFreq = false
defaultSettings.UpdateRate = 0.1

core.CoreOptionsTable = {
	name = core.title,
	type = "group",
	childGroups = "tab",
	get = function(info)
		local key = info[#info]
		return P[key]
	end,
	set = function(info, v)
		local key = info[#info]
		P[key] = v
	end,
	args = {
		text1 = {
			type = "description",
			name = string_format(L["ShowDescription"], GetAddOnMetadata(folder, "Version")),
			order = 1,
		},
		enable = {
			type = "toggle",
			name = L["Enable"],
			desc = L["Enables / Disables the addon"],
			order = 2,
			width = "full",
			get = function(info)
				return core:IsEnabled()
			end,
			set = function(info, val)
				if val == true then
					core:Enable()
				else
					core:Disable()
				end
			end
		}
	}
}

core.DisplayOptionsTable = {
	type = "group",
	name = core.titleFull,
	childGroups = "tab",
	get = function(info)
		local key = info[#info]
		return P[key]
	end,
	set = function(info, v)
		local key = info[#info]
		P[key] = v
	end,
	args = {
		displayHeader = {
			type = "header",
			name = L["Aura type"],
			order = 1
		},
		defaultBuffShow = {
			type = "select",
			name = L["Show Buffs"],
			desc = L["Show buffs above nameplate."],
			order = 2,
			values = {ALL, L["Mine + SpellList"], L["Only SpellList"], L["Mine Only"]}
		},
		defaultDebuffShow = {
			type = "select",
			name = L["Show Debuffs"],
			desc = L["Show debuffs above nameplate."],
			order = 3,
			values = {ALL, L["Mine + SpellList"], L["Only SpellList"], L["Mine Only"]}
		},
		showInterrupts = {
			type = "toggle",
			name = L["Show Interrupts"],
			desc = L["Show Interrupts as simulated debuffs above player nameplates."],
			order = 4
		},
		addSpellDescriptions = {
			type = "toggle",
			name = L["Add Spell Description"],
			desc = L["Add spell descriptions to the specific spell's list.\nDisabling this will lower memory usage and login time."],
			order = 5,
			get = function()
				return P.addSpellDescriptions
			end,
			set = function(info, val)
				P.addSpellDescriptions = not P.addSpellDescriptions
				if P.addSpellDescriptions then
					spellIDs = core:GetAllSpellIDs()
					core:BuildSpellUI()
				end
			end
		},
		typeHeader = {
			type = "header",
			name = L["Unit type"],
			order = 6
		},
		abovePlayers = {
			type = "toggle",
			name = L["Players"],
			desc = L["Add buffs above players. 'Class Color in Nameplates' must be enabled."],
			order = 7
		},
		aboveNPC = {
			type = "toggle",
			name = L["NPC"],
			desc = L["Add buffs above NPCs"],
			order = 8
		},
		reactionHeader = {
			name = L["Unit reaction"],
			type = "header",
			order = 9
		},
		aboveFriendly = {
			type = "toggle",
			name = L["Friendly"],
			desc = L["Add buffs above friendly plates"],
			order = 10
		},
		aboveNeutral = {
			type = "toggle",
			name = L["Neutral"],
			desc = L["Add buffs above neutral plates"],
			order = 11
		},
		aboveHostile = {
			type = "toggle",
			name = L["Hostile"],
			desc = L["Add buffs above hostile plates"],
			order = 12
		},
		otherHeader = {
			name = L["Misc"],
			type = "header",
			order = 13
		},
		spacer1 = {
			type = "description",
			name = "",
			order = 14
		},
		watchCombatlog = {
			type = "toggle",
			name = L["Watch Combatlog"],
			desc = L["Watch combatlog for people gaining/losing spells.\nDisable this if you're having performance issues."],
			order = 15,
			get = function()
				return P.watchCombatlog
			end,
			set = function(info, val)
				P.watchCombatlog = not P.watchCombatlog
				core:RegisterLibAuraInfo()
			end
		},
		saveNameToGUID = {
			type = "toggle",
			name = L["Save player GUID"],
			desc = L["Remember player GUID's so target/mouseover isn't needed every time nameplate appears.\nKeep this enabled"],
			order = 16,
			get = function(info)
				return P.saveNameToGUID
			end,
			set = function(info, val)
				P.saveNameToGUID = val
			end
		},
		unknownSpellDataIcon = {
			type = "toggle",
			name = L["Show question mark"],
			desc = L["Displays a question mark above unidentified nameplates. Identify them by target or mouseover."],
			order = 17
		},
		blacklistTotems = {
			type = "toggle",
			name = L["Blacklist Totems"],
			desc = L["Ignore PlateBuffs on totem nameplates"],
			order = 18
		},
		playerCombatWithOnly = {
			type = "toggle",
			name = L["Player combat only"],
			desc = L["Only show spells above nameplates that are in combat."],
			order = 19,
			set = function(info, val)
				P.playerCombatWithOnly = val
				core:Disable()
				core:Enable()
			end
		},
		npcCombatWithOnly = {
			type = "toggle",
			name = L["NPC combat only"],
			desc = L["Only show spells above nameplates that are in combat."],
			order = 20,
			set = function(info, val)
				P.npcCombatWithOnly = val
				core:Disable()
				core:Enable()
			end
		}
	}
}

core.BarOptionsTable = {
	type = "group",
	name = core.titleFull,
	childGroups = "tab",
	get = function(info)
		local key = info[#info]
		return P[key]
	end,
	set = function(info, v)
		local key = info[#info]
		P[key] = v
	end,
	args = {
		positionHeader = {
			type = "header",
			name = L["Position settings"],
			order = 1
		},
		separator0 = {
			type = "description",
			name = " ",
			order = 1.5
		},
		barAnchorPoint = {
			type = "select",
			name = L["Buff frame's Anchor Point"],
			order = 2,
			desc = L["Point of the buff frame that gets anchored to the nameplate.\ndefault = Bottom"],
			values = {
				TOP = L["Top"],
				BOTTOM = L["Bottom"],
				TOPLEFT = L["Top Left"],
				BOTTOMLEFT = L["Bottom Left"],
				TOPRIGHT = L["Top Right"],
				BOTTOMRIGHT = L["Bottom Right"]
			},
			set = function(info, val)
				P.barAnchorPoint = val
				core:ResetAllBarPoints()
			end
		},
		plateAnchorPoint = {
			type = "select",
			name = L["Nameplate's Anchor Point"],
			order = 3,
			desc = L["Point of the nameplate our buff frame gets anchored to.\ndefault = Top"],
			values = {
				TOP = L["Top"],
				BOTTOM = L["Bottom"],
				TOPLEFT = L["Top Left"],
				BOTTOMLEFT = L["Bottom Left"],
				TOPRIGHT = L["Top Right"],
				BOTTOMRIGHT = L["Bottom Right"]
			},
			set = function(info, val)
				P.plateAnchorPoint = val
				core:ResetAllBarPoints()
			end
		},
		separator1 = {
			type = "description",
			name = " ",
			order = 3.5
		},
		barOffsetX = {
			type = "range",
			name = L["Offset X"],
			desc = L["Left to right offset."],
			order = 4,
			min = -256,
			max = 256,
			step = 1,
			bigStep = 10,
			set = function(info, val)
				P.barOffsetX = val
				core:ResetAllBarPoints()
			end
		},
		barOffsetY = {
			type = "range",
			name = L["Offset Y"],
			desc = L["Up to down offset."],
			order = 5,
			min = -256,
			max = 256,
			step = 1,
			bigStep = 10,
			set = function(info, val)
				P.barOffsetY = val
				core:ResetAllBarPoints()
			end
		},
		separator2 = {
			type = "description",
			name = " ",
			order = 5.5
		},
		iconsPerBar = {
			type = "range",
			name = L["Icons per row"],
			desc = L["Number of icons to display per row."],
			order = 6,
			min = 1,
			max = 16,
			step = 1,
			set = function(info, val)
				P.iconsPerBar = val
				core:ResetAllPlateIcons()
				core:ShowAllKnownSpells()
			end
		},
		numBars = {
			type = "range",
			name = L["Max rows"],
			desc = L["Max number of rows to show."],
			order = 7,
			min = 1,
			max = 4,
			step = 1,
			set = function(info, val)
				P.numBars = val
				core:ResetAllPlateIcons()
				core:UpdateBarsBackground()
				core:ShowAllKnownSpells()
			end
		},
		separator3 = {
			type = "description",
			name = " ",
			order = 7.5
		},
		intervalX = {
			type = "range",
			name = L["Interval X"],
			desc = L["Change interval between icons."],
			order = 8,
			min = 0,
			max = 80,
			step = 1,
			set = function(info, val)
				P.intervalX = val
				core:ResetIconSizes()
			end
		},
		intervalY = {
			type = "range",
			name = L["Interval Y"],
			desc = L["Change interval between icons."],
			order = 9,
			min = 0,
			max = 80,
			step = 1,
			set = function(info, val)
				P.intervalY = val
				core:ResetIconSizes()
			end
		},
		separator4 = {
			type = "description",
			name = " ",
			order = 9.5
		},
		barGrowth = {
			type = "select",
			name = L["Row Growth"],
			desc = L["Which way do the bars grow, up or down."],
			order = 10,
			values = {L["Up"], L["Down"]},
			set = function(info, val)
				P.barGrowth = val
				core:ResetAllBarPoints()
			end
		},
		shrinkBar = {
			type = "toggle",
			name = L["Center Horizontally"],
			desc = L["Horizontally center the bar if not full."],
			order = 11,
			set = function(info, val)
				P.shrinkBar = val
				core:UpdateAllPlateBarSizes()
			end
		},
		separator5 = {
			type = "description",
			name = "\n",
			order = 11.5
		},
		iconTestMode = {
			type = "toggle",
			name = L["Test Mode"],
			desc = L["For each spell on someone, multiply it by the number of icons per bar.\nThis option won't be saved at logout."],
			order = 12,
			get = function()
				return core.iconTestMode
			end,
			set = function()
				core.iconTestMode = not core.iconTestMode
			end
		},
		showBarBackground = {
			type = "toggle",
			name = L["Show bar background"],
			desc = L["Show the area where spell icons will be. This is to help you configure the bars."],
			order = 13,
			set = function(info, val)
				P.showBarBackground = val
				core:UpdateBarsBackground()
			end
		}
	}
}

local tmpNewName = ""
local tmpNewID = ""

core.SpellOptionsTable = {
	type = "group",
	name = core.titleFull,
	args = {
		inputName = {
			type = "input",
			name = L["Spell name"],
			desc = L["Input a spell name. (case sensitive)\nOr spellID"],
			order = 1,
			get = function(info)
				return tmpNewName, tmpNewID
			end,
			set = function(info, val)
				local spellLink = GetSpellLink(tonumber(val) or val)
				if spellLink then
					local spellID = spellLink:match("spell:(%d+)")
					if spellID then
						local spellName = GetSpellInfo(spellID)
						if spellName then
							tmpNewName = spellName
							tmpNewID = tonumber(spellID)
							return
						end
					end
				end
				tmpNewName = val
				tmpNewID = "No spellID"
			end
		},
		addName = {
			type = "execute",
			name = L["Add spell"],
			desc = L["Add spell to list."],
			order = 2,
			func = function(info)
				if tmpNewName ~= "" then
					if tmpNewID ~= "" then
						core:AddNewSpell(tmpNewName, tmpNewID)
					else
						core:AddNewSpell(tmpNewName)
					end
					tmpNewName = ""
				end
			end
		},
		spellList = {
			type = "group",
			order = 3,
			name = L["Specific Spells"],
			args = {} --done late
		}
	}
}

core.DefaultSpellOptionsTable = {
	type = "group",
	name = core.titleFull,
	get = function(info)
		local key = info[#info]
		return P[key]
	end,
	set = function(info, v)
		local key = info[#info]
		P[key] = v
	end,
	args = {
		iconHeader = {
			type = "header",
			name = L["Icon settings"],
			order = 1
		},
		blank1 = {
			type = "description",
			name = " ",
			order = 1.5,
		},
		iconWidth = {
			type = "range",
			name = L["Icon width"],
			desc = L["Size of the icons."],
			order = 2,
			min = 8,
			max = 80,
			step = 1,
			set = function(info, val)
				P.iconWidth = val
				core:ResetIconSizes()
			end
		},
		iconHeight = {
			type = "range",
			name = L["Icon height"],
			desc = L["Size of the icons."],
			order = 3,
			min = 8,
			max = 80,
			step = 1,
			set = function(info, val)
				P.iconHeight = val
				core:ResetIconSizes()
			end
		},
		textureSize = {
			name = L["Texture zoom"],
			desc = L["increase texture zoom.\nDefault=0.0"],
			type = "range",
			order = 4,
			min = 0,
			max = 0.3,
			step = 0.01,
			bigStep = 0.1,
			set = function(info, val)
				P.textureSize = val
				core:ResetAllPlateIcons()
			end
		},
		biggerSelfSpells = {
			type = "toggle",
			name = L["Larger self spells"],
			desc = L["Make your spells 20% bigger then other's."],
			order = 5
		},
		borderHeader = {
			type = "header",
			name = L["Border settings"],
			order = 6
		},
		borderTexture = {
			name = L["Border Texture"],
			desc = L["Set border texture."],
			type = "select",
			order = 7,
			values = {
				[""] = NONE,
				["Interface\\Addons\\PlateBuffs\\media\\DefaultBorder.blp"] = L["Default"],
				["Interface\\Addons\\PlateBuffs\\media\\ThinBorder.tga"] = L["Thin"],
				["Interface\\Addons\\PlateBuffs\\media\\SquareBorder.tga"] = L["Square"],
				["Interface\\Addons\\PlateBuffs\\media\\ThinSquareBorder.tga"] = L["Thin Square"],
				["Masque"] = (MSQ and "Masque" or nil)
			},
			set = function(info, val)
				P.borderTexture = val
				core:ResetAllPlateIcons()
			end
		},
		colorbyType = {
			type = "toggle",
			name = L["Color debuff by type"],
			desc = L["If not set Physical color used for all debuffs"],
			order = 8,
			width = "double",
			get = function(info)
				return P.colorByType
			end,
			set = function(info, val)
				P.colorByType = val
			end
		},
		color1 = {
			type = "color",
			name = L["Physical"],
			order = 9,
			get = function(info)
				return P.color1[1], P.color1[2], P.color1[3], 1
			end,
			set = function(info, r, g, b)
				P.color1 = {r, g, b}
			end
		},
		color2 = {
			name = L["Magic"],
			type = "color",
			order = 10,
			get = function(info)
				return P.color2[1], P.color2[2], P.color2[3], 1
			end,
			set = function(info, r, g, b)
				P.color2 = {r, g, b}
			end
		},
		color3 = {
			name = L["Curse"],
			type = "color",
			order = 11,
			get = function(info)
				return P.color3[1], P.color3[2], P.color3[3], 1
			end,
			set = function(info, r, g, b)
				P.color3 = {r, g, b}
			end
		},
		color4 = {
			name = L["Disease"],
			type = "color",
			order = 12,
			get = function(info)
				return P.color4[1], P.color4[2], P.color4[3], 1
			end,
			set = function(info, r, g, b)
				P.color4 = {r, g, b}
			end
		},
		color5 = {
			name = L["Poison"],
			type = "color",
			order = 13,
			get = function(info)
				return P.color5[1], P.color5[2], P.color5[3], 1
			end,
			set = function(info, r, g, b)
				P.color5 = {r, g, b}
			end
		},
		color6 = {
			name = L["Buff"],
			type = "color",
			order = 14,
			get = function(info)
				return P.color6[1], P.color6[2], P.color6[3], 1
			end,
			set = function(info, r, g, b)
				P.color6 = {r, g, b}
			end
		},
		blank2 = {
			type = "description",
			name = " ",
			order = 14.5,
		},
		textHeader = {
			type = "header",
			name = L["Text settings"],
			order = 15
		},
		blank3 = {
			type = "description",
			name = " ",
			order = 15.5,
		},
		durationSize = {
			type = "range",
			name = L["Duration Text Size"],
			desc = L["Text size"],
			order = 16,
			min = 6,
			max = 20,
			step = 1,
			set = function(info, val)
				P.durationSize = val
				core:ResetDurationSizes()
			end
		},
		stackSize = {
			type = "range",
			name = L["Stack Text Size"],
			desc = L["Text size"],
			order = 17,
			min = 6,
			max = 20,
			step = 1,
			set = function(info, val)
				P.stackSize = val
				core:ResetStackSizes()
			end
		},
		blank4 = {
			type = "description",
			name = " ",
			order = 17.5,
		},
		showDuration = {
			type = "toggle",
			name = L["Show Duration"],
			desc = L["Show duration text on the spell icon."],
			width = "full",
			order = 18,
			set = function(info, val)
				P.showDuration = val
				core:ResetDurationSizes()
			end
		},
		durationAnchor = {
			type = "select", 
			order = 19,
			name = L["Duration Text Anchor"],
			desc = L["Anchor point for the duration text relative to the icon."],
			values = {
				BOTTOM = L["Under Icon"],
				CENTER = L["On Icon"],
				TOP = L["Above Icon"]
			},
			set = function(info, val)
				P.durationAnchor = val
				P.durationOffsetX = defaultSettings.durationOffsetX
				P.durationOffsetY = defaultSettings.durationOffsetY
				core:UpdateAllDurationAnchors()
			end,
			disabled = function() return not P.showDuration end
		},
		durationOffsetX = {
			type = "range",
			name = L["Offset X"],
			desc = L["Left to right offset."],
			order = 20,
			min = -30,
			max = 30,
			step = 0.5,
			set = function(info, val)
				P.durationOffsetX = val
				core:UpdateAllDurationAnchors()
			end,
			disabled = function() return not P.showDuration end
		},
		durationOffsetY = {
			type = "range",
			name = L["Offset Y"],
			desc = L["Up to down offset."],
			order = 21,
			min = -30,
			max = 30,
			step = 0.5,
			set = function(info, val)
				P.durationOffsetY = val
				core:UpdateAllDurationAnchors()
			end,
			disabled = function() return not P.showDuration end
		},
		durationFont = {
			type = "select",
			name = L["Duration Text Font"],
			order = 22,
			values = LSM:HashTable("font"),
			dialogControl = "LSM30_Font",
			get = function()
				return P.durationFont or defaultSettings.durationFont
			end,
			set = function(_, val)
				P.durationFont = val
				core:ResetDurationSizes()
			end,
			disabled = function() return not P.showDuration end
		},
		decimalThreshold = {
			type = "range",
			name = L["Decimal Threshold"],
			desc = L["Show decimal digits for durations below this value (in seconds)."],
			order = 23,
			min = 0,
			max = 10,
			step = 1,
			disabled = function() return not P.showDuration end
		},
		digitsnumber = {
			type = "range",
			name = L["Decimal precision"],
			desc = L["Number of decimal places for duration values below 'Decimal Threshold'"],
			order = 24,
			min = 0,
			max = 2,
			step = 1,
			disabled = function() return not P.showDuration end
		},
		blank5 = {
			type = "description",
			name = " ",
			order = 24.5
		},
		interruptsHeader = {
			type = "header",
			name = L["Interrupts settings"],
			order = 25
		},
		blank6 = {
			type = "description",
			name = " ",
			order = 25.5
		},
		color7 = {
			name = L["Border Color"],
			type = "color",
			order = 26,
			get = function(info)
				return P.color7[1], P.color7[2], P.color7[3], 1
			end,
			set = function(info, r, g, b)
				P.color7 = {r, g, b}
			end
		},
		interruptsScale = {
			type = "range",
			name = L["Icon Scale"],
			order = 27,
			min = 1,
			max = 3,
			step = 0.1,
			set = function(info, val)
				P.interruptsScale = val
				core:ResetDurationSizes()
				core:ResetStackSizes()
				core:ResetIconSizes()
			end
		},
		blank7 = {
			type = "description",
			name = " ",
			order = 27.5
		},
		animationHeader = {
			type = "header",
			name = L["Animation settings"],
			order = 28
		},
		enableBlinkFade = {
			type = "toggle",
			name = L["Enable Blink/Fade"],
			desc = L["Enable Blink/Fade animation when duration is expiring"],
			order = 29,
			width = "full"
		},
		blank8 = {
			type = "description",
			name = " ",
			order = 29.5,
		},
		blinkThreshold = {
			type = "range",
			name = L["Blink threshold time"],
			desc = L["Blink icon below x seconds"],
			order = 30,
			min = 0,
			max = 10,
			step = 1,
			disabled = function() return not P.enableBlinkFade end
		},
		fadeThreshold = {
			type = "range",
			name = L["Fade threshold time"],
			desc = L["Progressive fade out icon below x seconds"],
			order = 31,
			min	= 0,
			max	= 10,
			step = 1,
			disabled = function() return not P.enableBlinkFade end
		},
		blinkFadeMinDuration = {
			type = "range",
			name = L["Min duration for Blink/Fade"],
			desc = L["Blink and fade effects will only apply to auras with a duration longer than this value."],
			order = 32,
			min = 3,
			max = 10,
			step = 1,
			disabled = function() return not P.enableBlinkFade end
		},
		blinkTargetOnly = {
			type = "toggle",
			name = L["Only blink on target"],
			desc = L["Restrict blinking effect to auras on the target's nameplate only"],
			order = 33,
			disabled = function() return not P.enableBlinkFade end
		},
		fadeTargetOnly = {
			type = "toggle",
			name = L["Only fade on target"],
			desc = L["Restrict fade effect to auras on the target's nameplate only"],
			width = "double",
			order = 34,
			disabled = function() return not P.enableBlinkFade end
		},
		blank9 = {
			type = "description",
			name = " ",
			order = 34.5,
		},
		showClockOverlay = {
			type = "toggle",
			name = L["Show 'clock' overlay"],
			desc = L["Show a vertical 'clock' overlay over spell textures showing the time remaining."] ,
			order = 35
		},
		legacyCooldownClock = {
			type = "toggle",
			name = L["Legacy 'clock' overlay"],
			desc = L["Use the old radial clock overlay which tends to disappear when the frame's moving.\nRequires UI Reload."],
			disabled = function() return (UnitAffectingCombat("player") or InCombatLockdown() or not P.showClockOverlay) end,
			order = 36
		},
		blank10 = {
			type = "description",
			name = " ",
			order = 36.5,
		},
		enableAdjustFreq = {
			type = "toggle",
			name = L["Adjust Update Interval"],
			desc = L["Allows changing the time interval (in seconds) between updates for each icon."],
			order = 37,
			set = function(_, val)
				P.enableAdjustFreq = val
				if not val then
					P.UpdateRate = defaultSettings.UpdateRate
				end
			end
		},
		UpdateRate = {
			type = "range",
			name = L["Update Interval"],
			desc = L["Lower values make animations smoother but can significantly increase CPU usage."],
			order = 38,
			min = 0,
			max = 0.2,
			step = 0.01,
			disabled = function() return not P.enableAdjustFreq end
		}
	}
}

do
	local _spelliconcache = {}
	local function SpellString(spellID, size)
		size = size or 12
		if not _spelliconcache[spellID .. size] then
			if spellID and tonumber(spellID) then
				local icon = select(3, GetSpellInfo(spellID))
				_spelliconcache[spellID .. size] = "\124T" .. icon .. ":" .. size .. "\124t"
				return _spelliconcache[spellID .. size]
			else
				return "\124TInterface\\Icons\\" .. core.unknownIcon .. ":" .. size .. "\124t"
			end
		else
			return _spelliconcache[spellID .. size]
		end
	end

	function core:BuildSpellUI()
		local SpellOptionsTable = core.SpellOptionsTable
		SpellOptionsTable.args.spellList.args = {}

		local list = {}
		for name, data in pairs(P.spellOpts) do
			if not P.ignoreDefaultSpell[name] then
				table_insert(list, name)
			end
		end

		table_sort(list, function(a, b) return (a and b) and a < b end)

		local testDone = false
		local spellName, data, spellID
		local spellDesc, spellTexture
		local iconSize
		local nameColour
		local iconTexture

		for i = 1, table_getn(list) do
			spellName = list[i]
			data = P.spellOpts[spellName]
			spellID = P.spellOpts[spellName].spellID or "No spellID"
			iconSize = data.iconScale or P.iconScale
			iconTexture = SpellString(spellID)

			if data.show == 1 then
				nameColour = "|cff00ff00%s|r" --green
			elseif data.show == 3 then
				nameColour = "|cffff0000%s|r" --red
			elseif data.show == 5 then
				nameColour = "|cffcd00cd%s|r" --purple
			elseif data.show == 4 then
				nameColour = "|cffb9ffff%s|r" --birizoviy
			else
				nameColour = "|cffffff00%s|r" --yellow
			end

			spellDesc = "??"
			spellTexture = "Interface\\Icons\\" .. core.unknownIcon

			if spellIDs[spellName] or (spellID and type(spellID) == "number") then
				spellIDs[spellName] = spellIDs[spellName] or spellID
				tooltip:SetHyperlink("spell:" .. spellIDs[spellName])

				spellTexture = select(3, GetSpellInfo(spellIDs[spellName]))

				local lines = tooltip:NumLines()
				if lines > 0 then
					spellDesc = _G[folder .. "TooltipTextLeft" .. lines] and _G[folder .. "TooltipTextLeft" .. lines]:GetText() or "??"
				end
			end

			--add spell to table.
			SpellOptionsTable.args.spellList.args[spellName] = {
				type = "group",
				name = iconTexture .. " " .. nameColour:format(spellName .. " (" .. iconSize .. ") #" .. spellID),
				desc = spellDesc, --L["Spell name"],
				order = i,
				args = {}
			}
			if P.addSpellDescriptions == true then
				SpellOptionsTable.args.spellList.args[spellName].args.spellDesc = {
					type = "description",
					name = spellDesc,
					image = spellTexture,
					imageWidth = 32,
					imageHeight = 32,
					order = 1
				}
			end
			SpellOptionsTable.args.spellList.args[spellName].args.showOpt = {
				type = "select",
				name = L["Show"],
				desc = L["Always show spell, only show your spell, never show spell"],
				values = {
					L["Always"],
					L["Mine only"],
					L["Never"],
					L["Only Friend"],
					L["Only Enemy"]
				},
				order = 2,
				get = function(info)
					return P.spellOpts[info[2]].show or 1
				end,
				set = function(info, val)
					P.spellOpts[info[2]].show = val
					core:BuildSpellUI()
				end
			}
			SpellOptionsTable.args.spellList.args[spellName].args.iconSize = {
				type = "range",
				name = L["Icon Scale"],
				order = 3,
				min = 1,
				max = 3,
				step = 0.1,
				get = function(info)
					return P.spellOpts[info[2]].iconScale or P.iconScale
				end,
				set = function(info, val)
					P.spellOpts[info[2]].iconScale = val
					core:ResetDurationSizes()
					core:ResetStackSizes()
					core:ResetIconSizes()
					core:BuildSpellUI()
				end
			}
			SpellOptionsTable.args.spellList.args[spellName].args.spellID = {
				type = "input",
				name = L["Spell ID"],
				order = 4,
				get = function(info)
					return tostring(P.spellOpts[info[2]].spellID or "Spell ID not set")
				end,
				set = function(info, val)
					local num = tonumber(val)
					if num then
						P.spellOpts[info[2]].spellID = num
					else
						P.spellOpts[info[2]].spellID = "No SpellID"
					end
				end
			}

			if data.when then
				SpellOptionsTable.args.spellList.args[spellName].args.addedWhen = {
					type = "description",
					name = L["Added: "] .. data.when,
					order = 5
				}
			end

			SpellOptionsTable.args.spellList.args[spellName].args.grabID = {
				type = "toggle",
				name = L["Check Spell ID"],
				desc = L["Check exact Spell ID for this aura. Useful when different spells share a name"],
				order = 6,
				get = function(info)
					return P.spellOpts[info[2]].grabid
				end,
				set = function(info, val)
					P.spellOpts[info[2]].grabid = not P.spellOpts[info[2]].grabid
				end
			}

			SpellOptionsTable.args.spellList.args[spellName].args.removeSpell = {
				type = "execute",
				order = 100,
				name = L["Remove Spell"],
				desc = L["Remove spell from list"],
				func = function(info)
					core:RemoveSpell(info[2])
				end
			}
		end
	end
end

do
	core.AboutOptionsTable = {
		name = core.titleFull,
		type = "group",
		childGroups = "tab",
		get = function(info)
			local key = info[#info]
			return P[key]
		end,
		set = function(info, v)
			local key = info[#info]
			P[key] = v
		end,
		args = {}
	}

	local tostring = tostring

	local fields = {
		"Title",
		"Notes",
		"Author",
		"X-Backporter",
		"X-Modder",
		"Version",
		"X-Date",
		"X-Website",
	}
	local haseditbox = {
		["X-Website"] = true,
	}
	local fNames = {
		["X-Backporter"] = "Backporter",
		["X-Modder"] = "Modder",
		["X-Date"] = "Date",
		["X-Website"] = "Website",
	}
	local yellow = "|cffffd100%s|r"

	local val
	function core:BuildAboutMenu()
		self.AboutOptionsTable.args.about = {
			type = "group",
			name = L.about,
			order = 99,
			args = {}
		}

		for i, field in pairs(fields) do
			val = GetAddOnMetadata(folder, field)
			if val then
				if haseditbox[field] then
					self.AboutOptionsTable.args.about.args[field] = {
						type = "input",
						name = fNames[field] or field,
						desc = L.clickCopy,
						order = i + 10,
						width = "double",
						get = function(info)
							local key = info[#info]
							return GetAddOnMetadata(folder, key)
						end
					}
				else
					self.AboutOptionsTable.args.about.args[field] = {
						type = "description",
						name = yellow:format((fNames[field] or field) .. ": ") .. val,
						width = "double",
						order = i + 10
					}
				end
			end
		end

		LibStub("AceConfig-3.0"):RegisterOptionsTable(self.title, self.AboutOptionsTable) --
		LibStub("AceConfigDialog-3.0"):SetDefaultSize(self.title, 600, 500) --680
	end
end
