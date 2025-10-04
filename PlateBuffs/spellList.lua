local core = select(2, ...)

------------------ Default Buff/Debuff Lists ------------------
-- 1.75x Scaled Icons & "Show Always" enabled
local defaultSpells1 = {
	34976,	-- Netherstorm Flag (EotS flag)
	23335,	-- Silverwing Flag (Alliance WSG flag)
	23333,	-- Warsong Flag (Horde WSG flag)
}
-- 1.50x Scaled Icons & "Show Always" enabled
local defaultSpells2 = {
	46393,	-- Brutal Assault
	33786,	-- Cyclone
	19263,	-- Deterrence
	47585,	-- Dispersion
	642,	-- Divine Shield
	45438,	-- Ice Block
	5384,	-- Feign Death
	46392,	-- Focused Assault
	6615,	-- Free Action
}
-- 1.25x Scaled Icons & "Show Always" enabled
local defaultSpells3 = {
	30217,	-- Adamantite Grenade
	13750,	-- Adrenaline Rush
	49050,	-- Aimed Shot
	48707,	-- Anti-Magic Shell
	31821,	-- Aura Mastery
	12042,	-- Arcane Power
	31884,	-- Avenging Wrath
	18647,	-- Banish
	22812,	-- Barkskin
	5211,	-- Bash
	53563,	-- Beacon of Light
	50334,	-- Berserk (CheckSpellID)
	37587,	-- Bestial Wrath
	46924,	-- Bladestorm
	2094,	-- Blind
	2825,	-- Bloodlust
	52418,	-- Carrying Seaforium
	1833,	-- Cheap Shot
	45182,	-- Cheating Death
	53359,	-- Chimera Shot - Scorpid
	31224,	-- Cloak of Shadows
	67769,	-- Cobalt Frag Bomb
	12809,	-- Concussion Blow
	6789,	-- Death Coil (CheckSpellID)
	12292,	-- Death Wish
	44572,	-- Deep Freeze
	676,	-- Disarm
	51722,	-- Dismantle
	54428,	-- Divine Plea
	498,	-- Divine Protection
	64205,	-- Divine Sacrifice	
	42950,	-- Dragon's Breath
	49284,	-- Earth Shield
	26669,	-- Evasion (CheckSpellID)
	6215,	-- Fear
	30216,	-- Fel Iron Bomb
	64346,	-- Fiery Payback
	60210,	-- Freezing Arrow Effect
	14309,	-- Freezing Trap Effect
	1330,	-- Garrote - Silence
	47481,	-- Gnaw - Ghoul
	1776,	-- Gouge
	8178,	-- Grounding Totem Effect
	853,	-- Hammer of Justice
	1044,	-- Hand of Freedom
	10278,	-- Hand of Protection
	6940,	-- Hand of Sacrifice
	32182,	-- Heroism
	51514,	-- Hex
	18658,	-- Hibernate
	2812,	-- Holy Wrath
	17928,	-- Howl of Terror
	49203,	-- Hungering Cold
	48792,	-- Icebound Fortitude
	12472,	-- Icy Veins
	12355,	-- Impact (CheckSpellID)
	20511,	-- Intimidating Shout
	24394,	-- Intimidation
	408,	-- Kidney Shot
	48451,	-- Lifebloom
	22570,	-- Maim
	53271,	-- Master's Call
	605,	-- Mind Control
	47486,	-- Mortal Strike
	16689,	-- Nature's Grasp
	33206,	-- Pain Suppression
	12826,	-- Polymorph
	9005,	-- Pounce
	10060,	-- Power Infusion
	48066,	-- Power Word: Shield
	41635,	-- Prayer of Mending
	69369,	-- Predator's Swiftness
	9913,	-- Prowl
	64058,	-- Psychic Horror
	10890,	-- Psychic Scream
	50518,	-- Ravage - Ravager
	1719,	-- Recklessness
	48441,	-- Rejuvenation
	20066,	-- Repentance
	20230,	-- Retaliation (CheckSpellID)
	61301,	-- Riptide
	53480,	-- Roar of Sacrifice
	53601,	-- Sacred Shield
	51724,	-- Sap
	14327,	-- Scare Beast
	19503,	-- Scatter Shot
	6358,	-- Seduction - Succubus
	10955,	-- Shackle Undead
	51713,	-- Shadow Dance
	30283,	-- Shadowfury
	2565,	-- Shield Block
	871,	-- Shield Wall
	46968,	-- Shockwave
	15487,	-- Silence
	18498,	-- Silenced - Gag Order
	55021,	-- Silenced - Improved Counterspell
	18425,	-- Silenced - Improved Kick
	63529,	-- Silenced - Shield of the Templar
	50541,	-- Snatch - Bird of Prey
	50519,	-- Sonic Blast (Bat)
	53908,	-- Speed (CheckSpellID)
	24259,	-- Spell Lock - Felhunter
	23920,	-- Spell Reflection
	1784,	-- Stealth
	47476,	-- Strangulate
	61336,	-- Survival Instincts
	12328,	-- Sweeping Strikes
	34692,	-- The Beast Within
	10326,	-- Turn Evil
	64850,	-- Unrelenting Assault
	43523,	-- Unstable Affliction (CheckSpellID)
	57975,	-- Wound Poison VII
	49012,	-- Wyvern Sting
}
-- 1.00x Scaled Icons & "Show Mine Only" enabled
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
if classSpells and classSpells.defaultSpells3 then
	for _, id in ipairs(classSpells.defaultSpells3) do
    	table.insert(defaultSpells3, id)
	end
end
if classSpells and classSpells.defaultSpells4 then
	for _, id in ipairs(classSpells.defaultSpells4) do
    	table.insert(defaultSpells4, id)
	end
end

----------- Reference for core.lua -----------
core.defaultSpells1 = defaultSpells1
core.defaultSpells2 = defaultSpells2
core.defaultSpells3 = defaultSpells3
core.defaultSpells4 = defaultSpells4
core.CheckSpellID  = CheckSpellID