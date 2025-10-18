local _, core = ...

local table_insert, table_getn, GetSpellInfo = table.insert, table.getn, GetSpellInfo

------------------ Default Buff/Debuff Lists ------------------
-- First Category
local iconScale1 = 1.6
local showCondition1 = 1 -- "Show Always"
local spellList1 = {
	-- Immunities
	48707,	-- Anti-Magic Shell
	18647,	-- Banish
	33786,	-- Cyclone
	19753,	-- Divine Intervention
	642,	-- Divine Shield
	45438,	-- Ice Block
	10278,	-- Hand of Protection
	-- BG Important Buffs
	46393,	-- Brutal Assault
	46392,	-- Focused Assault
	34976,	-- Netherstorm Flag (EotS flag)
	23335,	-- Silverwing Flag (Alliance WSG flag)
	23333,	-- Warsong Flag (Horde WSG flag)
}
-- Second Category
local iconScale2 = 1.4
local showCondition2 = 1 -- "Show Always"
local spellList2 = {
	-- Breakable CCs
	30217,	-- Adamantite Grenade
	2094,	-- Blind
	67769,	-- Cobalt Frag Bomb
	42950,	-- Dragon's Breath
	30216,	-- Fel Iron Bomb
	60210,	-- Freezing Arrow Effect
	14309,	-- Freezing Trap Effect
	1776,	-- Gouge
	49203,	-- Hungering Cold
	20511,	-- Intimidating Shout
	12826,	-- Polymorph
	20066,	-- Repentance
	51724,	-- Sap
	19503,	-- Scatter Shot
	6358,	-- Seduction - Succubus
	10955,	-- Shackle Undead
	49012,	-- Wyvern Sting
	-- Semi-breakable CCs
	6215,	-- Fear
	51514,	-- Hex
	17928,	-- Howl of Terror
	10890,	-- Psychic Scream
	14327,	-- Scare Beast
	10326,	-- Turn Evil
	-- Unbreakable CCs
	6789,	-- Death Coil (CheckSpellID)
	605,	-- Mind Control
	64058,	-- Psychic Horror
	-- Stuns
	5211,	-- Bash
	1833,	-- Cheap Shot
	12809,	-- Concussion Blow
	44572,	-- Deep Freeze
	47481,	-- Gnaw - Ghoul
	853,	-- Hammer of Justice
	24394,	-- Intimidation
	408,	-- Kidney Shot
	22570,	-- Maim
	2812,	-- Holy Wrath
	12355,	-- Impact (CheckSpellID)
	9005,	-- Pounce
	50518,	-- Ravage - Ravager
	30283,	-- Shadowfury
	46968,	-- Shockwave
	50519,	-- Sonic Blast (Bat)
	-- Silences
	1330,	-- Garrote - Silence
	15487,	-- Silence
	18498,	-- Silenced - Gag Order
	55021,	-- Silenced - Improved Counterspell
	18425,	-- Silenced - Improved Kick
	63529,	-- Silenced - Shield of the Templar
	24259,	-- Spell Lock - Felhunter
	47476,	-- Strangulate
	43523,	-- Unstable Affliction (CheckSpellID)
	-- Disarms
	53359,	-- Chimera Shot - Scorpid
	676,	-- Disarm
	51722,	-- Dismantle
	64346,	-- Fiery Payback
	50541,	-- Snatch - Bird of Prey
	-- Big Defensives
	45182,	-- Cheating Death
	31224,	-- Cloak of Shadows
	19263,	-- Deterrence
	47585,	-- Dispersion
	498,	-- Divine Protection
	26669,	-- Evasion (CheckSpellID)
	48792,	-- Icebound Fortitude
	33206,	-- Pain Suppression
	871,	-- Shield Wall
	-- Healing Reduction
	49050,	-- Aimed Shot
	47486,	-- Mortal Strike
	64850,	-- Unrelenting Assault
	57975,	-- Wound Poison VII
}
-- Third Category
local iconScale3 = 1.2
local showCondition3 = 1 -- "Show Always"
local spellList3 = {
	-- DK
	49016,	-- Hysteria
	-- Druid
	22812,	-- Barkskin
	50334,	-- Berserk (CheckSpellID)
	18658,	-- Hibernate
	48451,	-- Lifebloom
	16689,	-- Nature's Grasp
	69369,	-- Predator's Swiftness
	48441,	-- Rejuvenation
	61336,	-- Survival Instincts
	-- Hunter
	37587,	-- Bestial Wrath
	53271,	-- Master's Call
	53480,	-- Roar of Sacrifice
	34692,	-- The Beast Within
	-- Mage
	12472,	-- Icy Veins
	-- Paladin
	31821,	-- Aura Mastery
	31884,	-- Avenging Wrath
	53563,	-- Beacon of Light
	54428,	-- Divine Plea
	64205,	-- Divine Sacrifice
	1044,	-- Hand of Freedom
	6940,	-- Hand of Sacrifice
	53601,	-- Sacred Shield
	-- Priest
	10060,	-- Power Infusion
	48066,	-- Power Word: Shield
	41635,	-- Prayer of Mending
	-- Rogue
	13750,	-- Adrenaline Rush
	51713,	-- Shadow Dance
	-- Shaman
	2825,	-- Bloodlust
	49284,	-- Earth Shield
	8178,	-- Grounding Totem Effect
	32182,	-- Heroism
	61301,	-- Riptide
	-- Warrior
	46924,	-- Bladestorm
	12292,	-- Death Wish
	1719,	-- Recklessness
	20230,	-- Retaliation (CheckSpellID)
	2565,	-- Shield Block
	23920,	-- Spell Reflection
	12328,	-- Sweeping Strikes
	-- Others
	52418,	-- Carrying Seaforium
	6615,	-- Free Action
	53908,	-- Speed (CheckSpellID)
}
-- Fourth Category
local iconScale4 = 1
local showCondition4 = 2 -- "Show Mine Only"
local spellList4 = {
	-- Set according to spellsByClass
}
-- Spells with "Check SpellID" enabled (must also exist in a spellLists)
local CheckSpellID = {
	50334,	-- Berserk
	6789,	-- Death Coil
	26669,	-- Evasion
	12355,	-- Impact
	20230,	-- Retaliation
	53908,	-- Speed
	43523,	-- Unstable Affliction
}

---------- Class-specific Additional Buff/Debuff ----------
local spellsByClass = {
    DEATHKNIGHT = {
        spellList4 = {
            55078, -- Blood Plague
            45524, -- Chains of Ice
            51735, -- Ebon Plague
            55095, -- Frost Fever
            58617, -- Glyph of Heart Strike
            50436, -- Icy Clutch
            50536, -- Unholy Blight
        },
    },
    DRUID = {
        spellList3 = {
            16882, -- Detect Greater Invisibility
            132,   -- Detect Invisibility
            6512,  -- Detect Lesser Invisibility
        },
        spellList4 = {
            60433, -- Earth and Moon
            53308, -- Entangling Roots
            770,   -- Faerie Fire
            16857, -- Faerie Fire (Feral)
            45334, -- Feral Charge Effect
            48468, -- Insect Swarm
            48463, -- Moonfire
        },
    },
    HUNTER = {
        spellList4 = {
            5116,  -- Concussive Shot
            49050, -- Aimed Shot
            64804, -- Entrapment
            13810, -- Frost Trap Aura
            53338, -- Hunter's Mark
            3043,  -- Scorpid Sting
            49001, -- Serpent Sting
            3034,  -- Viper Sting
            2974,  -- Wing Clip
        },
    },
    MAGE = {
        spellList4 = {
            42945, -- Blast Wave
            7321,  -- Chilled
            42931, -- Cone of Cold
            12494, -- Frostbite
            42842, -- Frostbolt
            47610, -- Frostfire Bolt
            42917, -- Frost Nova
            55360, -- Living Bomb
            55080, -- Shattered Barrier
            31589, -- Slow
        },
    },
    PALADIN = {
        spellList3 = {
            49039, -- Lichborne
        },
        spellList4 = {
            48827, -- Avenger's Shield
			20217, -- Blessing of Kings
			48932, -- Blessing of Might
			20911, -- Blessing of Sanctuary
			48936, -- Blessing of Wisdom
			25898, -- Greater Blessing of Kings
			48934, -- Greater Blessing of Might
			25899, -- Greater Blessing of Sanctuary
			48938, -- Greater Blessing of Wisdom
            20184, -- Judgement of Justice
            20185, -- Judgement of Light
            20186, -- Judgement of Wisdom
        },
    },
    PRIEST = {
        spellList3 = {
            6346,  -- Fear Ward
            49039, -- Lichborne
        },
        spellList4 = {
            48300, -- Devouring Plague
            48125, -- Shadow Word: Pain
            48160, -- Vampiric Touch
        },
    },
    ROGUE = {
        spellList3 = {
            16882, -- Detect Greater Invisibility
            132,   -- Detect Invisibility
            6512,  -- Detect Lesser Invisibility
        },
        spellList4 = {
            31125, -- Blade Twisting
            3409,  -- Crippling Poison
            57970, -- Deadly Poison IX
            48674, -- Deadly Throw
            8647,  -- Expose Armor
            48672, -- Rupture
            51693, -- Waylay
        },
    },
    SHAMAN = {
        spellList4 = {
            49231, -- Earth Shock
            3600,  -- Earthbind
            64695, -- Earthgrab
            49233, -- Flame Shock
            49236, -- Frost Shock
            58799, -- Frostbrand Attack
            32175, -- Stormstrike
        },
    },
    WARLOCK = {
        spellList3 = {
            6346,  -- Fear Ward
            49039, -- Lichborne
        },
        spellList4 = {
            18118, -- Aftermath
            47813, -- Corruption
            47864, -- Curse of Agony
            18223, -- Curse of Exhaustion
            47865, -- Curse of the Elements
            11719, -- Curse of Tongues
            50511, -- Curse of Weakness
            63311, -- Glyph of Shadowflame
            59164, -- Haunt
            47811, -- Immolate
            47836, -- Seed of Corruption
            61291, -- Shadowflame
        },
    },
    WARRIOR = {
        spellList4 = {
            7922,  -- Charge Stun
            1715,  -- Hamstring
            23694, -- Improved Hamstring
            20253, -- Intercept
            47486, -- Mortal Strike
            12323, -- Piercing Howl
            47465, -- Rend
            7386,  -- Sunder Armor
        },
    },
}
local myClass = select(2, UnitClass("player"))
local classSpells = myClass and spellsByClass[myClass]
if classSpells and classSpells.spellList3 then
	for _, id in ipairs(classSpells.spellList3) do
    	table_insert(spellList3, id)
	end
end
if classSpells and classSpells.spellList4 then
	for _, id in ipairs(classSpells.spellList4) do
    	table_insert(spellList4, id)
	end
end

---- Interrupts list, assuming 30% duration reduction (worst-case scenario) ----
core.InterruptsDuration = {
	[6552]  = 4 * 0.7,	-- Warrior: Pummel
	[72]    = 6 * 0.7,	-- Warrior: Shield Bash
	[1766]  = 5 * 0.7,	-- Rogue: Kick
	[47528] = 4 * 0.7,	-- DK: Mind Freeze
	[57994] = 2 * 0.7,	-- Shaman: Wind Shear
	[19647] = 6 * 0.7,	-- Warlock: Spell Lock (Felhunter)
	[2139]  = 8 * 0.7,	-- Mage: Counterspell
	[16979] = 4 * 0.7	-- Druid: Feral Charge (Bear)
}

------ Core default spell configurations by category ------
core.defaultSettings = {
	profile = {
		spellOpts = {},
		ignoreDefaultSpell = {}
	}
}
local spellOpts = core.defaultSettings.profile.spellOpts
for i = 1, table_getn(spellList1) do
	local spellID = spellList1[i]
	local spellName = GetSpellInfo(spellID)
	if spellName then
		spellOpts[spellName] = {
			spellID = spellID,
			iconScale = iconScale1,
			show = showCondition1,
		}
	end
end
for i = 1, table_getn(spellList2) do
	local spellID = spellList2[i]
	local spellName = GetSpellInfo(spellID)
	if spellName then
		spellOpts[spellName] = {
			spellID = spellID,
			iconScale = iconScale2,
			show = showCondition2,
		}
	end
end
for i = 1, table_getn(spellList3) do
	local spellID = spellList3[i]
	local spellName = GetSpellInfo(spellID)
	if spellName then
		spellOpts[spellName] = {
			spellID = spellID,
			iconScale = iconScale3,
			show = showCondition3,
		}
	end
end
for i = 1, table_getn(spellList4) do
	local spellID = spellList4[i]
	local spellName = GetSpellInfo(spellID)
	if spellName then
		spellOpts[spellName] = {
			spellID = spellID,
			iconScale = iconScale4,
			show = showCondition4,
		}
	end
end
for i = 1, table_getn(CheckSpellID) do
	local spellID = CheckSpellID[i]
	local spellName = GetSpellInfo(spellID)
	if spellOpts[spellName] then
		spellOpts[spellName].grabid = true
	end
end