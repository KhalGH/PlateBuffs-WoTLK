local core = select(2, ...)

------------------ Default Buff/Debuff Lists ------------------
-- 1.6x Scaled Icons & "Show Always" enabled
local defaultScale1 = 1.6
local defaultDurationSize1 = 16
local defaultStackSize1 = 12
local defaultSpells1 = {
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
	6615,	-- Free Action
	34976,	-- Netherstorm Flag (EotS flag)
	23335,	-- Silverwing Flag (Alliance WSG flag)
	23333,	-- Warsong Flag (Horde WSG flag)
}
-- 1.4x Scaled Icons & "Show Always" enabled
local defaultScale2 = 1.4
local defaultDurationSize2 = 14
local defaultStackSize2 = 11
local defaultSpells2 = {
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
-- 1.2x Scaled Icons & "Show Always" enabled
local defaultScale3 = 1.2
local defaultDurationSize3 = 12
local defaultStackSize3 = 10
local defaultSpells3 = {
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
	53908,	-- Speed (CheckSpellID)
}
-- 1.00x Scaled Icons & "Show Mine Only" enabled
local defaultScale4 = 1
local defaultDurationSize4 = 11
local defaultStackSize4 = 8
local defaultSpells4 = {
	-- Set according to spellsByClass
}
-- Spells with "Check SpellID" enabled (must also exist in a defaultSpells list)
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
        defaultSpells4 = {
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
        defaultSpells3 = {
            16882, -- Detect Greater Invisibility
            132,   -- Detect Invisibility
            6512,  -- Detect Lesser Invisibility
        },
        defaultSpells4 = {
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
        defaultSpells4 = {
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
        defaultSpells4 = {
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
        defaultSpells3 = {
            49039, -- Lichborne
        },
        defaultSpells4 = {
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
        defaultSpells3 = {
            6346,  -- Fear Ward
            49039, -- Lichborne
        },
        defaultSpells4 = {
            48300, -- Devouring Plague
            48125, -- Shadow Word: Pain
            48160, -- Vampiric Touch
        },
    },
    ROGUE = {
        defaultSpells3 = {
            16882, -- Detect Greater Invisibility
            132,   -- Detect Invisibility
            6512,  -- Detect Lesser Invisibility
        },
        defaultSpells4 = {
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
        defaultSpells4 = {
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
        defaultSpells3 = {
            6346,  -- Fear Ward
            49039, -- Lichborne
        },
        defaultSpells4 = {
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
        defaultSpells4 = {
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
local table_insert = table.insert
if classSpells and classSpells.defaultSpells3 then
	for _, id in ipairs(classSpells.defaultSpells3) do
    	table_insert(defaultSpells3, id)
	end
end
if classSpells and classSpells.defaultSpells4 then
	for _, id in ipairs(classSpells.defaultSpells4) do
    	table_insert(defaultSpells4, id)
	end
end

----------- Reference for core.lua -----------
core.defaultSpells1, core.defaultScale1, core.defaultDurationSize1, core.defaultStackSize1 = defaultSpells1, defaultScale1, defaultDurationSize1, defaultStackSize1
core.defaultSpells2, core.defaultScale2, core.defaultDurationSize2, core.defaultStackSize2 = defaultSpells2, defaultScale2, defaultDurationSize2, defaultStackSize2
core.defaultSpells3, core.defaultScale3, core.defaultDurationSize3, core.defaultStackSize3 = defaultSpells3, defaultScale3, defaultDurationSize3, defaultStackSize3
core.defaultSpells4, core.defaultScale4, core.defaultDurationSize4, core.defaultStackSize4 = defaultSpells4, defaultScale4, defaultDurationSize4, defaultStackSize4
core.CheckSpellID = CheckSpellID
