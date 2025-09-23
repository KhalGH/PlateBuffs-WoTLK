local core = select(2, ...)

-- Nameplates with these names are totems. By default we ignore totem nameplates.
local totemList = {
	2484, --Earthbind Totem
	8143, --Tremor Totem
	8177, --Grounding Totem
	8512, --Windfury Totem
	6495, --Sentry Totem
	8170, --Cleansing Totem
	3738, --Wrath of Air Totem
	2062, --Earth Elemental Totem
	2894, --Fire Elemental Totem
	58734, --Magma Totem
	58582, --Stoneclaw Totem
	58753, --Stoneskin Totem
	58739, --Fire Resistance Totem
	58656, --Flametongue Totem
	58745, --Frost Resistance Totem
	58757, --Healing Stream Totem
	58774, --Mana Spring Totem
	58749, --Nature Resistance Totem
	58704, --Searing Totem
	58643, --Strength of Earth Totem
	57722 --Totem of Wrath
}

core.totemList = totemList