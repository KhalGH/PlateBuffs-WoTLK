local core = select(2, ...)

-- 1.75x Scaled Icons
local defaultSpells1 = {
	34976,	-- Netherstorm Flag (EotS flag)
	23335,	-- Silverwing Flag (Alliance WSG flag)
	23333,	-- Warsong Flag (Horde WSG flag)
}

-- 1.50x Scaled Icons
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

-- 1.25x Scaled Icons
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
	50334,	-- Berserk (CheckIDSpells)
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
	6789,	-- Death Coil (CheckIDSpells)
	12292,	-- Death Wish
	44572,	-- Deep Freeze
	676,	-- Disarm
	51722,	-- Dismantle
	54428,	-- Divine Plea
	498,	-- Divine Protection
	64205,	-- Divine Sacrifice	
	42950,	-- Dragon's Breath
	49284,	-- Earth Shield
	26669,	-- Evasion (CheckIDSpells)
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
	12355,	-- Impact
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
	20230,	-- Retaliation (CheckIDSpells)
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
	53908,	-- Speed (CheckIDSpells)
	24259,	-- Spell Lock - Felhunter
	23920,	-- Spell Reflection
	1784,	-- Stealth
	47476,	-- Strangulate
	61336,	-- Survival Instincts
	12328,	-- Sweeping Strikes
	34692,	-- The Beast Within
	10326,	-- Turn Evil
	64850,	-- Unrelenting Assault
	43523,	-- Unstable Affliction (CheckIDSpells)
	57975,	-- Wound Poison VII
	49012,	-- Wyvern Sting
}

-- 1.00x Scaled Icons (Own Spells)
local defaultSpells4 = {
}

local myClass = select(2, UnitClass("player"))
local table_insert = table.insert

if myClass == "DEATHKNIGHT" then
	table_insert(defaultSpells4, #defaultSpells4+1, 55078)	-- Blood Plague
	table_insert(defaultSpells4, #defaultSpells4+1, 45524)	-- Chains of Ice
	table_insert(defaultSpells4, #defaultSpells4+1, 68766)	-- Desecration
	table_insert(defaultSpells4, #defaultSpells4+1, 51735)	-- Ebon Plague
	table_insert(defaultSpells4, #defaultSpells4+1, 55095)	-- Frost Fever
	table_insert(defaultSpells4, #defaultSpells4+1, 58617)	-- Glyph of Heart Strike
	table_insert(defaultSpells4, #defaultSpells4+1, 50436)	-- Icy Clutch
	table_insert(defaultSpells4, #defaultSpells4+1, 50536)	-- Unholy Blight
elseif myClass == "DRUID" then
	table_insert(defaultSpells3, #defaultSpells3+1, 16882)	-- Detect Greater Invisibility (Not Own)
	table_insert(defaultSpells3, #defaultSpells3+1, 132)	-- Detect Invisibility (Not Own)
	table_insert(defaultSpells3, #defaultSpells3+1, 6512)	-- Detect Lesser Invisibility (Not Own)
	table_insert(defaultSpells4, #defaultSpells4+1, 60433)	-- Earth and Moon
	table_insert(defaultSpells4, #defaultSpells4+1, 53308)	-- Entangling Roots
	table_insert(defaultSpells4, #defaultSpells4+1, 770)	-- Faerie Fire
	table_insert(defaultSpells4, #defaultSpells4+1, 16857)	-- Faerie Fire (Feral)
	table_insert(defaultSpells4, #defaultSpells4+1, 45334)	-- Feral Charge Effect
	table_insert(defaultSpells4, #defaultSpells4+1, 48468)	-- Insect Swarm
	table_insert(defaultSpells4, #defaultSpells4+1, 48463)	-- Moonfire
elseif myClass == "HUNTER" then
	table_insert(defaultSpells4, #defaultSpells4+1, 5116)	-- Concussive Shot
	table_insert(defaultSpells4, #defaultSpells4+1, 49050)	-- Aimed Shot
	table_insert(defaultSpells4, #defaultSpells4+1, 64804)	-- Entrapment
	table_insert(defaultSpells4, #defaultSpells4+1, 13810)	-- Frost Trap Aura
	table_insert(defaultSpells4, #defaultSpells4+1, 53338)	-- Hunter's Mark
	table_insert(defaultSpells4, #defaultSpells4+1, 3043)	-- Scorpid Sting
	table_insert(defaultSpells4, #defaultSpells4+1, 49001)	-- Serpent Sting
	table_insert(defaultSpells4, #defaultSpells4+1, 3034)	-- Viper Sting
	table_insert(defaultSpells4, #defaultSpells4+1, 2974)	-- Wing Clip
elseif myClass == "MAGE" then
	table_insert(defaultSpells4, #defaultSpells4+1, 42945)	-- Blast Wave
	table_insert(defaultSpells4, #defaultSpells4+1, 7321)	-- Chilled
	table_insert(defaultSpells4, #defaultSpells4+1, 42931)	-- Cone of Cold
	table_insert(defaultSpells4, #defaultSpells4+1, 12494)	-- Frostbite
	table_insert(defaultSpells4, #defaultSpells4+1, 42842)	-- Frostbolt
	table_insert(defaultSpells4, #defaultSpells4+1, 47610)	-- Frostfire Bolt
	table_insert(defaultSpells4, #defaultSpells4+1, 42917)	-- Frost Nova
	table_insert(defaultSpells4, #defaultSpells4+1, 55360)	-- Living Bomb
	table_insert(defaultSpells4, #defaultSpells4+1, 55080)	-- Shattered Barrier
	table_insert(defaultSpells4, #defaultSpells4+1, 31589)	-- Slow
elseif myClass == "PALADIN" then
	table_insert(defaultSpells3, #defaultSpells3+1, 49039)	-- Lichborne (Not Own)
	table_insert(defaultSpells4, #defaultSpells4+1, 48827)	-- Avenger's Shield
	table_insert(defaultSpells4, #defaultSpells4+1, 20184)	-- Judgement of Justice
	table_insert(defaultSpells4, #defaultSpells4+1, 20185)	-- Judgement of Light
	table_insert(defaultSpells4, #defaultSpells4+1, 20186)	-- Judgement of Wisdom
elseif myClass == "PRIEST" then
	table_insert(defaultSpells3, #defaultSpells3+1, 6346)	-- Fear Ward (Not Own)
	table_insert(defaultSpells3, #defaultSpells3+1, 49039)	-- Lichborne (Not Own)
	table_insert(defaultSpells4, #defaultSpells4+1, 48300)	-- Devouring Plague
	table_insert(defaultSpells4, #defaultSpells4+1, 48125)	-- Shadow Word: Pain
	table_insert(defaultSpells4, #defaultSpells4+1, 48160)	-- Vampiric Touch
elseif myClass == "ROGUE" then
	table_insert(defaultSpells3, #defaultSpells3+1, 16882)	-- Detect Greater Invisibility (Not Own)
	table_insert(defaultSpells3, #defaultSpells3+1, 132)	-- Detect Invisibility (Not Own)
	table_insert(defaultSpells3, #defaultSpells3+1, 6512)	-- Detect Lesser Invisibility (Not Own)
	table_insert(defaultSpells4, #defaultSpells4+1, 31125)	-- Blade Twisting
	table_insert(defaultSpells4, #defaultSpells4+1, 3409)	-- Crippling Poison
	table_insert(defaultSpells4, #defaultSpells4+1, 57970)	-- Deadly Poison IX
	table_insert(defaultSpells4, #defaultSpells4+1, 48674)	-- Deadly Throw
	table_insert(defaultSpells4, #defaultSpells4+1, 8647)	-- Expose Armor
	table_insert(defaultSpells4, #defaultSpells4+1, 48672)	-- Rupture
	table_insert(defaultSpells4, #defaultSpells4+1, 51693)	-- Waylay
elseif myClass == "SHAMAN" then
	table_insert(defaultSpells4, #defaultSpells4+1, 49231)	-- Earth Shock
	table_insert(defaultSpells4, #defaultSpells4+1, 3600)	-- Earthbind
	table_insert(defaultSpells4, #defaultSpells4+1, 64695)	-- Earthgrab
	table_insert(defaultSpells4, #defaultSpells4+1, 49233)	-- Flame Shock
	table_insert(defaultSpells4, #defaultSpells4+1, 49236)	-- Frost Shock
	table_insert(defaultSpells4, #defaultSpells4+1, 58799)	-- Frostbrand Attack
	table_insert(defaultSpells4, #defaultSpells4+1, 32175)	-- Stormstrike
elseif myClass == "WARLOCK" then
	table_insert(defaultSpells3, #defaultSpells3+1, 6346)	-- Fear Ward (Not Own)
	table_insert(defaultSpells3, #defaultSpells3+1, 49039)	-- Lichborne (Not Own)
	table_insert(defaultSpells4, #defaultSpells4+1, 18118)	-- Aftermath
	table_insert(defaultSpells4, #defaultSpells4+1, 47813)	-- Corruption
	table_insert(defaultSpells4, #defaultSpells4+1, 47864)	-- Curse of Agony
	table_insert(defaultSpells4, #defaultSpells4+1, 18223)	-- Curse of Exhaustion
	table_insert(defaultSpells4, #defaultSpells4+1, 47865)	-- Curse of the Elements
	table_insert(defaultSpells4, #defaultSpells4+1, 11719)	-- Curse of Tongues
	table_insert(defaultSpells4, #defaultSpells4+1, 50511)	-- Curse of Weakness
	table_insert(defaultSpells4, #defaultSpells4+1, 63311)	-- Glyph of Shadowflame
	table_insert(defaultSpells4, #defaultSpells4+1, 59164)	-- Haunt
	table_insert(defaultSpells4, #defaultSpells4+1, 47811)	-- Immolate
	table_insert(defaultSpells4, #defaultSpells4+1, 47836)	-- Seed of Corruption
	table_insert(defaultSpells4, #defaultSpells4+1, 61291)	-- Shadowflame
elseif myClass == "WARRIOR" then
	table_insert(defaultSpells4, #defaultSpells4+1, 7922)	-- Charge Stun
	table_insert(defaultSpells4, #defaultSpells4+1, 1715)	-- Hamstring
	table_insert(defaultSpells4, #defaultSpells4+1, 23694)	-- Improved Hamstring
	table_insert(defaultSpells4, #defaultSpells4+1, 20253)	-- Intercept
	table_insert(defaultSpells4, #defaultSpells4+1, 47486)	-- Mortal Strike
	table_insert(defaultSpells4, #defaultSpells4+1, 12323)	-- Piercing Howl
	table_insert(defaultSpells4, #defaultSpells4+1, 47465)	-- Rend
	table_insert(defaultSpells4, #defaultSpells4+1, 7386)	-- Sunder Armor
end

-- Spells that share name
local CheckIDSpells = {
	50334,	-- Berserk
	6789,	-- Death Coil
	26669,	-- Evasion
	20230,	-- Retaliation
	53908,	-- Speed
	43523,	-- Unstable Affliction
}

core.defaultSpells1 = defaultSpells1
core.defaultSpells2 = defaultSpells2
core.defaultSpells3 = defaultSpells3
core.defaultSpells4 = defaultSpells4
core.CheckIDSpells  = CheckIDSpells