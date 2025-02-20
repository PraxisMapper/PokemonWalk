extends Node
class_name SpawnLogic

const CommonWeight = 5.0
const UncommonWeight = 2.5
const RareWeight = 1

const starters = ["BULBASAUR", "CHARMANDER", "SQUIRTLE", "CHIKORITA", "CYNDAQUIL", "TOTODILE",
	"TREECKO", "TORCHIC", "MUDKIP", "TURTWIG", "CHIMCHAR", "PIPLUP", "SNIVY", "TEPIG", "OSHAWOTT",
	"CHESPIN", "FENNEKIN", "FROAKIE", "ROWLET", "LITTEN", "POPPLIO", "GROOKEY", "SCORBUNNY", "SOBBLE", 
	"SPRIGATITO", "FUECOCO", "QUAXLY"]


var sample = {
		name = "Mascot Week",
		description = "The mousey ones they want you to like.",
		spawns = {"PIKACHU" = 1, "AZURILL" = 1, "PLUSLE" = 1, "MINUN" = 1, "PACHIRISU" = 1, "EMOLGA" = 1,
		 "DEDENNE" = 1, "TOGEDEMARU" = 1, "MIMIKYU" = 1, "MORPEKO" = 1}
	}
	

#DONE:   21 different weeks. Could cycle them around for 3 months, won't be a lot of players on that long.
# Fire/Grass/Water starters, baby pokemon, Alola/Galarian/Hisuian forms, Mythicals, 2 Paradox weeks,
# Eeveelution week (twice), Vivillion pattern week, 2 fusion weeks (no trios, down to pidbat),
# rare types (ice, fairy, ghost, dragon, steel, electric), mascots
#NOTE: going by seconds into the year is not ISO standard, but I think i'd rather
#do this than juggle which week the first thursday is in and deal with 53 weeks sometimes.
static var eventEntries = [
	{ #0, Jan 1-7
		name = "New Year, New Pokemon",
		description = "Baby pokemon appear everywhere",
		spawns = {"PICHU" = 1, "CLEFFA" = 1, "IGGLYBUFF" = 1, "TOGEPI" = 1, "TYROGUE" = 1, "SMOOCHUM" = 1,
		"MAGBY" = 1, "ELEKID" = 1}
	},
	{ #1, Jan 8-14
		name = "Galar Week",
		description = "Galar forms ahoy!",
		spawns = {"PONYTA_1" = 1, "FARFETCHD_1" = 1, "MRMIME_1" = 1, "CORSOLA_1" = 1,
		"MEOWTH_2" = 1, "ZIGZAGZOON_1" = 1, "DARUMAKA_2" = 1, "YAMASK_1" = 1, "SLOWPOKE_1" = 1}
	},
	{ # 2, Jan 15-21
		name = "Fusion Week 1",
		description = "Mixing it up",
		spawns = {"PIKATRIO" = 1, "TWOMEW" = 1, "GOLDCHAMP" = 1, "CHAMPCHAMP" = 1, "CHAMPERPIE" = 1, 
		"SCYDRILL" = 1, "SCYGAR" = 1, "SCIKING" = 1 }
	},
	{ #3 Jan 22-28
		name = "Paradox Week 1",
		description = "The pokemon that used to be",
		spawns = {"GREATTUSK" = 1, "SCREAMTAIL" = 1, "BRUTEBONNET" = 1, "FLUTTERMANE" = 1, "SLITHERWING" =1,
		"SANDYSHOCKS" = 1, "ROARINGMOON" = 1, "WALKINGWAKE" = 1, "GOUGINGFIRE" = 1, "RAGINGBOLT" = 1, "KORAIDON" = 1}
	},
	{ #4, Jan 29- Feb 4
		name = "Eeveelution Week",
		description = "Too good for only one type",
		spawns = {"FLAREON" = 1, "JOLTEON" = 1, "VAPOREON" = 1, "GLACEON" = 1, "LEAFEON" =1,
		"UMBREON" = 1, "ESPEON" = 1, "SYLVEON" = 1}
	}, 
	{ #5, Feb 5-11
		name = "Grass Starter Week",
		description = "#1 in the Pokedex, #1 in our hearts",
		spawns = {"BULBASAUR" = 1, "CHIKORITA" = 1, "TREECKO" = 1, "TURTWIG" = 1,
		"SNIVY" = 1, "CHESPIN" = 1, "ROWLET" = 1, "GROOKEY" = 1, "SPRIGATITO" = 1}
	},
	{ #6, Feb 12-18
		name = "Vivillon Week",
		description = "Your chance to get all 20 variants",
		spawns = {"VIVILLON" = 1, "VIVILLON_1" = 1, "VIVILLON_2" = 1, "VIVILLON_3" = 1, "VIVILLON_4" = 1, 
		"VIVILLON_5" = 1, "VIVILLON_6" = 1, "VIVILLON_7" = 1, "VIVILLON_8" = 1, "VIVILLON_9" = 1, "VIVILLON_10" = 1, 
		"VIVILLON_11" = 1, "VIVILLON_12" = 1, "VIVILLON_13" = 1, "VIVILLON_14" = 1, "VIVILLON_15" = 1, "VIVILLON_16" = 1,
		"VIVILLON_17" = 1, "VIVILLON_18" = 1, "VIVILLON_19" = 1}
	},
	{ #7, Feb 19-25
		name = "Hisuian Week",
		description = "Back in the old days, pokemon looked like this",
		spawns = {"GROWLITHE_1" = 1, "VOLTORB_1" = 1, "ZORUA_1" = 1, "SLIGGOO_1" = 1, "QWILFISH_1" =1,
		"SNEASEL_1" = 1, "RUFFLET_1" = 1, "KLEAVOR" = 1}
	},
	{ #8, Feb 26 - Mar 4 (or Mar 3 on leap year)
		name = "Fire Starter Week",
		description = "We didn't start with fire, they were always burning-",
		spawns = {"CHARMANDER" = 1, "CYNDAQUIL" = 1, "TORCHIC" = 1,
		"CHIMCHAR" = 1, "TEPIG" = 1, "FENNEKIN" = 1, "LITTEN" = 1, "SCORBUNNY" = 1, "FUECOCO" = 1}
	}, 
	{ #9, Mar 5-11
		name = "Fusion Week 2",
		description = "Mixing it up",
		spawns = {"STEELGAR" = 1, "BEEZONE" = 1, "BEEVOIR" = 1, "PIDBAT" = 1,"GARDEQUEEN" = 1, 
		"GARDERADE" = 1, "GEFABLE" = 1}
	},
	{ #10, Mar 12-18
		name = "Alola Week",
		description = "Alolan forms ahoy!",
		spawns = {"RATTATA_1" = 1, "SANDSHREW_1" = 1, "VULPIX_1" = 1, "DIGLET_1" = 1,
		"MEOWTH_1" = 1, "GEODUDE_1" = 1, "GRIMER_1" = 1}
	},
	{ #11, Mar 19-25
		name = "Paradox Week 2",
		description = "The pokemon that have yet to be",
		spawns = {"IRONTREADS" = 1, "IRONBUNDLE" = 1, "IRONHANDS" = 1, "IRONJUGULIS" = 1, "IRONMOTH" = 1,
		"IRONTHORNS" = 1, "IRONVALIANT" = 1, "IRONLEAVES" = 1, "IRONBOULDER" = 1, "IRONCROWN" = 1, "MIRAIDON" =1}
	},
	{ #12, Mar26 - Apr1
		name = "Water Starter Week",
		description = "Water you waiting for? Get some water.",
		spawns = {"SQUIRTLE" = 1, "TOTODILE" = 1, "MUDKIP" = 1, "PIPLUP" = 1,
		"OSHAWOTT" = 1, "FROAKIE" = 1, "POPPLIO" = 1, "SOBBLE" = 1, "QUAXLY" = 1}
	},
	{ #13, Apr 2-8
		name = "Ice Week",
		description = "The rarest type, now available worldwide",
		spawns = {"VANILLITE" = 1, "CUBCHOO" = 1, "BERGMITE" = 1, "GLASTRIER" = 1, "CETODDLE" = 1, 
		"SNOM" = 1, "SNOVER" = 1, "FRIGIBAX" = 1 }
	},
	{ #14, Apr 9-15
		name = "Fairy Week",
		description = "The newest type, now available worldwide",
		spawns = {"CLEFAIRY" = 1, "FLABEBE" = 1, "COMFEY" = 1, "FIDOUGH" = 1, "TINKATINK" = 1, 
		"RALTS" = 1, "MIMIKYU" = 1, "IMPIDIMP" = 1 }
	},
	{ #15, Apr 16-22
		name = "Ghost Week",
		description = "The best type, now available worldwide",
		spawns = {"MISDREAVUS" = 1, "SINISTEA" = 1, "GREAVARD" = 1, "GASTLY" = 1, "SPIRITOMB" = 1, 
		"PUMPKABOO" = 1, "SANDYGHAST" = 1, "HONEDGE" = 1 }
	},
	{ #16, Apr 23-29
		name = "Dragon Week",
		description = "The coolest type, now available worldwide",
		spawns = {"DRATINI" = 1, "AXEW" = 1, "GOOMY" = 1, "GIBLE" = 1, "DREEPY" = 1, 
		"DEINO" = 1, "TYRUNT" = 1, "APPLIN" = 1 }
	},
	{ #17, Apr 30 - May 6
		name = "Steel Week",
		description = "The most refined type, now available worldwide",
		spawns = {"KLINK" = 1, "MELTAN" = 1, "SKARMORY" = 1, "ARON" = 1, "BELDUM" = 1, 
		"BRONZOR" = 1, "MAGNEMITE" = 1, "PAWNIARD" = 1 }
	},
	{ #18, May 7-13
		name = "Electric Week",
		description = "The most famous type, now available worldwide",
		spawns = {"VOLTORB" = 1, "ELECTABUZZ" = 1, "MAREEP" = 1, "SHINX" = 1, "YAMPER" = 1, 
		"TOXEL" = 1, "WATTREL" = 1, "CHARJABUG" = 1 }
	},
	{ #19, May 14-20
		name = "Mascot Week",
		description = "The mousey ones they want you to like.",
		spawns = {"PIKACHU" = 1, "AZURILL" = 1, "PLUSLE" = 1, "MINUN" = 1, "PACHIRISU" = 1, "EMOLGA" = 1,
		 "DEDENNE" = 1, "TOGEDEMARU" = 1, "MIMIKYU" = 1, "MORPEKO" = 1}
	}, #Start looping weeks from here, with exceptions for fun.
	{ #20, May 21-27
		name = "Galar Week",
		description = "Galar forms ahoy!",
		spawns = {"PONYTA_1" = 1, "FARFETCHD_1" = 1, "MRMIME_1" = 1, "CORSOLA_1" = 1,
		"MEOWTH_2" = 1, "ZIGZAGZOON_1" = 1, "DARUMAKA_2" = 1, "YAMASK_1" = 1, "SLOWPOKE_1" = 1}
	}, 
	{ #21, May28 - Jun3
		name = "Fusion Week 1",
		description = "Mixing it up",
		spawns = {"PIKATRIO" = 1, "TWOMEW" = 1, "GOLDCHAMP" = 1, "CHAMPCHAMP" = 1, "CHAMPERPIE" = 1, 
		"SCYDRILL" = 1, "SCYGAR" = 1, "SCIKING" = 1 }
	},
	{ #22, Jun 4-10
		name = "Paradox Week 1",
		description = "The pokemon that used to be",
		spawns = {"GREATTUSK" = 1, "SCREAMTAIL" = 1, "BRUTEBONNET" = 1, "FLUTTERMANE" = 1, "SLITHERWING" =1,
		"SANDYSHOCKS" = 1, "ROARINGMOON" = 1, "WALKINGWAKE" = 1, "GOUGINGFIRE" = 1, "RAGINGBOLT" = 1, "KORAIDON" = 1}
	},
	{ #23, Jun 11-17
		name = "Eeveelution Week",
		description = "Too good for only one type",
		spawns = {"FLAREON" = 1, "JOLTEON" = 1, "VAPOREON" = 1, "GLACEON" = 1, "LEAFEON" =1,
		"UMBREON" = 1, "ESPEON" = 1, "SYLVEON" = 1}
	}, 
	{ #24, Jun 18-24
		name = "Grass Starter Week",
		description = "#1 in the Pokedex, #1 in our hearts",
		spawns = {"BULBASAUR" = 1, "CHIKORITA" = 1, "TREECKO" = 1, "TURTWIG" = 1,
		"SNIVY" = 1, "CHESPIN" = 1, "ROWLET" = 1, "GROOKEY" = 1, "SPRIGATITO" = 1}
	},
	{ #25, Jun25 - Jul 1
		name = "Vivillon Week",
		description = "Your chance to get all 20 variants",
		spawns = {"VIVILLON" = 1, "VIVILLON_1" = 1, "VIVILLON_2" = 1, "VIVILLON_3" = 1, "VIVILLON_4" = 1, 
		"VIVILLON_5" = 1, "VIVILLON_6" = 1, "VIVILLON_7" = 1, "VIVILLON_8" = 1, "VIVILLON_9" = 1, "VIVILLON_10" = 1, 
		"VIVILLON_11" = 1, "VIVILLON_12" = 1, "VIVILLON_13" = 1, "VIVILLON_14" = 1, "VIVILLON_15" = 1, "VIVILLON_16" = 1,
		"VIVILLON_17" = 1, "VIVILLON_18" = 1, "VIVILLON_19" = 1}
	}, 
	{#26, Jul 2-8 (4th of july week)
		name = "Hisuian Week",
		description = "Back in the old days, pokemon looked like this",
		spawns = {"GROWLITHE_1" = 1, "VOLTORB_1" = 1, "ZORUA_1" = 1, "SLIGGOO_1" = 1, "QWILFISH_1" =1,
		"SNEASEL_1" = 1, "RUFFLET_1" = 1, "KLEAVOR" = 1}
	}, 
	{ #27, Jul 9-15
		name = "Fire Starter Week",
		description = "We didn't start with fire, they were always burning-",
		spawns = {"CHARMANDER" = 1, "CYNDAQUIL" = 1, "TORCHIC" = 1,
		"CHIMCHAR" = 1, "TEPIG" = 1, "FENNEKIN" = 1, "LITTEN" = 1, "SCORBUNNY" = 1, "FUECOCO" = 1}
	},
	{ #28, Jul 16-22
		name = "Fusion Week 2",
		description = "Mixing it up",
		spawns = {"STEELGAR" = 1, "BEEZONE" = 1, "BEEVOIR" = 1, "PIDBAT" = 1,"GARDEQUEEN" = 1, 
		"GARDERADE" = 1, "GEFABLE" = 1}
	},
	{ #29, Jul 23-29
		name = "Alola Week",
		description = "Alolan forms ahoy!",
		spawns = {"RATTATA_1" = 1, "SANDSHREW_1" = 1, "VULPIX_1" = 1, "DIGLET_1" = 1,
		"MEOWTH_1" = 1, "GEODUDE_1" = 1, "GRIMER_1" = 1}
	},
	{ #30, Jul30-Aug5
		name = "Paradox Week 2",
		description = "The pokemon that have yet to be",
		spawns = {"IRONTREADS" = 1, "IRONBUNDLE" = 1, "IRONHANDS" = 1, "IRONJUGULIS" = 1, "IRONMOTH" = 1,
		"IRONTHORNS" = 1, "IRONVALIANT" = 1, "IRONLEAVES" = 1, "IRONBOULDER" = 1, "IRONCROWN" = 1, "MIRAIDON" =1}
	},
	{ #31, Aug 6-12 August 12 is PraxisMapper's birthday
		name = "PraxisMapper's Birthday!",
		description = "August 12th is PraxisMapper's birthday, celebrate with some Mythicals.",
		spawns = { "MEW" = 2, "CELEBI" = 2, "JIRACHI" = 2, "JIRLEBEW" = 1, "MANAPHY" = 2, 
		"SHAYMIN" = 2, "VICTINI" = 2, "MELOETTA" = 2, "DIANCI" = 2, "MELTAN" = 2, "ZARUDE" = 2  }
	}, 
	{ #32, Aug 13-19
		name = "Water Starter Week",
		description = "Water you waiting for? Get some water.",
		spawns = {"SQUIRTLE" = 1, "TOTODILE" = 1, "MUDKIP" = 1, "PIPLUP" = 1,
		"OSHAWOTT" = 1, "FROAKIE" = 1, "POPPLIO" = 1, "SOBBLE" = 1, "QUAXLY" = 1}
	},
	{ #33, Aug 20-26
		name = "Ice Week",
		description = "The rarest type, now available worldwide",
		spawns = {"VANILLITE" = 1, "CUBCHOO" = 1, "BERGMITE" = 1, "GLASTRIER" = 1, "CETODDLE" = 1, 
		"SNOM" = 1, "SNOVER" = 1, "FRIGIBAX" = 1 }
	}, 
	{ #34, Aug 27- Sep 2
		name = "Fairy Week",
		description = "The newest type, now available worldwide",
		spawns = {"CLEFAIRY" = 1, "FLABEBE" = 1, "COMFEY" = 1, "FIDOUGH" = 1, "TINKATINK" = 1, 
		"RALTS" = 1, "MIMIKYU" = 1, "IMPIDIMP" = 1 }
	},
	{ #35, Sep 3-9
		name = "Eeveelution Week",
		description = "Too good for only one type",
		spawns = {"FLAREON" = 1, "JOLTEON" = 1, "VAPOREON" = 1, "GLACEON" = 1, "LEAFEON" =1,
		"UMBREON" = 1, "ESPEON" = 1, "SYLVEON" = 1}
	},
	{ #36, Sep 10-16
		name = "Dragon Week",
		description = "The coolest type, now available worldwide",
		spawns = {"DRATINI" = 1, "AXEW" = 1, "GOOMY" = 1, "GIBLE" = 1, "DREEPY" = 1, 
		"DEINO" = 1, "TYRUNT" = 1, "APPLIN" = 1 }
	},
	{ #37, Sep 17-23
		name = "Steel Week",
		description = "The most refined type, now available worldwide",
		spawns = {"KLINK" = 1, "MELTAN" = 1, "SKARMORY" = 1, "ARON" = 1, "BELDUM" = 1, 
		"BRONZOR" = 1, "MAGNEMITE" = 1, "PAWNIARD" = 1 }
	},
	{ #38, Sep 24-30
		name = "Electric Week",
		description = "The most famous type, now available worldwide",
		spawns = {"VOLTORB" = 1, "ELECTABUZZ" = 1, "MAREEP" = 1, "SHINX" = 1, "YAMPER" = 1, 
		"TOXEL" = 1, "WATTREL" = 1, "CHARJABUG" = 1 }
	},
	{ #39, Oct 1-7
		name = "Mascot Week",
		description = "The mousey ones they want you to like.",
		spawns = {"PIKACHU" = 1, "AZURILL" = 1, "PLUSLE" = 1, "MINUN" = 1, "PACHIRISU" = 1, "EMOLGA" = 1,
		 "DEDENNE" = 1, "TOGEDEMARU" = 1, "MIMIKYU" = 1, "MORPEKO" = 1}
	}, 
	{ #40, Oct 8-14
		name = "Galar Week",
		description = "Galar forms ahoy!",
		spawns = {"PONYTA_1" = 1, "FARFETCHD_1" = 1, "MRMIME_1" = 1, "CORSOLA_1" = 1,
		"MEOWTH_2" = 1, "ZIGZAGZOON_1" = 1, "DARUMAKA_2" = 1, "YAMASK_1" = 1, "SLOWPOKE_1" = 1}
	},
	{ #41 Oct 15-21
		name = "Fusion Week 1",
		description = "Mixing it up",
		spawns = {"PIKATRIO" = 1, "TWOMEW" = 1, "GOLDCHAMP" = 1, "CHAMPCHAMP" = 1, "CHAMPERPIE" = 1, 
		"SCYDRILL" = 1, "SCYGAR" = 1, "SCIKING" = 1 }
	},
	{ #42, Oct 22-28
		name = "Paradox Week 1",
		description = "The pokemon that used to be",
		spawns = {"GREATTUSK" = 1, "SCREAMTAIL" = 1, "BRUTEBONNET" = 1, "FLUTTERMANE" = 1, "SLITHERWING" =1,
		"SANDYSHOCKS" = 1, "ROARINGMOON" = 1, "WALKINGWAKE" = 1, "GOUGINGFIRE" = 1, "RAGINGBOLT" = 1, "KORAIDON" = 1}
	},
	{ #43, Oct 29 - Nov 4. Halloween.
		name = "Ghost Week",
		description = "The best type, now available worldwide",
		spawns = {"MISDREAVUS" = 1, "SINISTEA" = 1, "GREAVARD" = 1, "GASTLY" = 1, "SPIRITOMB" = 1, 
		"PUMPKABOO" = 1, "SANDYGHAST" = 1, "HONEDGE" = 1 }
	}, #44, Nov 5-11
	{
		name = "Grass Starter Week",
		description = "#1 in the Pokedex, #1 in our hearts",
		spawns = {"BULBASAUR" = 1, "CHIKORITA" = 1, "TREECKO" = 1, "TURTWIG" = 1,
		"SNIVY" = 1, "CHESPIN" = 1, "ROWLET" = 1, "GROOKEY" = 1, "SPRIGATITO" = 1}
	},
	{ #45, Nov 12-18
		name = "Vivillon Week",
		description = "Your chance to get all 20 variants",
		spawns = {"VIVILLON" = 1, "VIVILLON_1" = 1, "VIVILLON_2" = 1, "VIVILLON_3" = 1, "VIVILLON_4" = 1, 
		"VIVILLON_5" = 1, "VIVILLON_6" = 1, "VIVILLON_7" = 1, "VIVILLON_8" = 1, "VIVILLON_9" = 1, "VIVILLON_10" = 1, 
		"VIVILLON_11" = 1, "VIVILLON_12" = 1, "VIVILLON_13" = 1, "VIVILLON_14" = 1, "VIVILLON_15" = 1, "VIVILLON_16" = 1,
		"VIVILLON_17" = 1, "VIVILLON_18" = 1, "VIVILLON_19" = 1}
	},
	{ #46, Nov 19-25
		name = "Hisuian Week",
		description = "Back in the old days, pokemon looked like this",
		spawns = {"GROWLITHE_1" = 1, "VOLTORB_1" = 1, "ZORUA_1" = 1, "SLIGGOO_1" = 1, "QWILFISH_1" =1,
		"SNEASEL_1" = 1, "RUFFLET_1" = 1, "KLEAVOR" = 1}
	},
	{ #47, Nov 26 - Dec 2
		name = "Fire Starter Week",
		description = "We didn't start with fire, they were always burning-",
		spawns = {"CHARMANDER" = 1, "CYNDAQUIL" = 1, "TORCHIC" = 1,
		"CHIMCHAR" = 1, "TEPIG" = 1, "FENNEKIN" = 1, "LITTEN" = 1, "SCORBUNNY" = 1, "FUECOCO" = 1}
	},
	{ #48, Dec 3-9
		name = "Fusion Week 2",
		description = "Mixing it up",
		spawns = {"STEELGAR" = 1, "BEEZONE" = 1, "BEEVOIR" = 1, "PIDBAT" = 1,"GARDEQUEEN" = 1, 
		"GARDERADE" = 1, "GEFABLE" = 1}
	},
	{ #49, Dec 10-16
		name = "Alola Week",
		description = "Alolan forms ahoy!",
		spawns = {"RATTATA_1" = 1, "SANDSHREW_1" = 1, "VULPIX_1" = 1, "DIGLET_1" = 1,
		"MEOWTH_1" = 1, "GEODUDE_1" = 1, "GRIMER_1" = 1}
	},
	{ #50, Dec 17-23
		name = "Paradox Week 2",
		description = "The pokemon that have yet to be",
		spawns = {"IRONTREADS" = 1, "IRONBUNDLE" = 1, "IRONHANDS" = 1, "IRONJUGULIS" = 1, "IRONMOTH" = 1,
		"IRONTHORNS" = 1, "IRONVALIANT" = 1, "IRONLEAVES" = 1, "IRONBOULDER" = 1, "IRONCROWN" = 1, "MIRAIDON" =1}
	},
	{ #51 #Dec 24-30. Christmas! 
		name = "Christmas Week",
		description = "We got presents for you here, too.",
		spawns = {"DEERLING_3" = 1, "EISCUE" = 1, "SNOWVER" = 1, "IRONBUNDLE" = 1,
		"DELIBIRD" = 1, "STANTLER" = 1, "CRYOGONAL" = 1, "FROSLASS" = 1}
	},
	{ #52, Dec 31. Also includes Dec. 30 on leap years.
		name = "New Year, New Pokemon",
		description = "Baby pokemon appear everywhere",
		spawns = {"PICHU" = 1, "CLEFFA" = 1, "IGGLYBUFF" = 1, "TOGEPI" = 1, "TYROGUE" = 1, "SMOOCHUM" = 1,
		"MAGBY" = 1, "ELEKID" = 1}
	}
]

static func SpawnTable(cell8):
	var table = {
		total= 0
	}
	
	var commonRng = RandomNumberGenerator.new()
	commonRng.seed = cell8.hash()
	var count = GameGlobals.baseData.familiesByHabitat.size()
	#Last 2 habitats are "Rare" and "Legendary", we exclude those specifically.
	#Raids can use those, though.
	var habitat = commonRng.randi() % (count - 2)
	
	var possibleFamilies = GameGlobals.baseData.familiesByHabitat.values()[habitat]
	var options = possibleFamilies.size()
	
	for i in GameGlobals.commonPokemonPerArea:
		var family = possibleFamilies[commonRng.randi_range(0,options-1)]
		var base = GameGlobals.baseData.pokemon[family]
		
		#If this family has forms, check if we should pick one.
		if base.otherForms != null and base.otherForms.size() > 0:
			var checkForm = GameGlobals.baseData.pokemon[family + "_" + base.otherForms[0]]
			if checkForm.formType == "ALTERNATE":
				var form = commonRng.randi() % base.otherForms.size()
				if form != 0:
					family = family + "_" + base.otherForms[form] # str(form) #NOTE: this doesnt work for Minior
		
		if !table.has(family):
			table[family] = 10
		else:
			table[family] += 10
		table.total += 10

	#TODO functionalize this check
	var currentString = Time.get_datetime_dict_from_system(true)
	var yearAsSeconds= Time.get_unix_time_from_datetime_string(str(currentString.year) + "-01-01")
	var secondsIntoYear = Time.get_unix_time_from_system() - yearAsSeconds
	var weeksIntoYear = int(secondsIntoYear / (60 * 60 * 24 * 7))
	var weekEventPokemon = eventEntries[weeksIntoYear]
	
	if !weekEventPokemon.is_empty():
		for i in weekEventPokemon.spawns:
			if !table.has(i):
				table[i] = weekEventPokemon.spawns[i]
			else:
				table[i] += weekEventPokemon.spawns[i]
			table.total += weekEventPokemon.spawns[i]
	
	if GameGlobals.playerData.allowFusions == true:
		var fusionIdx = commonRng.randi_range(0, GameGlobals.baseData.allFamilies["FUSION"].size() - 1)
		var fusionHere = GameGlobals.baseData.allFamilies["FUSION"][fusionIdx]
		table[fusionHere] = 3
		table.total += 3

	return table
	
static func PickSpawn(table):
	#Table is a list of pokemon keys and the 'entries' on the table they have
	
	var pickItem = randf_range(0, table.total) #we CAN have decimal increments here.
	var keyCount = table.keys().size() - 1
	var runningCount = 0
	for k in table:
		if k == "total":
			continue
		if runningCount <= pickItem and table[k] + runningCount >= pickItem:
			return k
		runningCount += table[k]
	return "MISSINGNO"

static func RaidSpawnTable():
	#fills in all the pokemon that could show up as a raid boss.
	var options = []
	#The last 2 entries are RARE and LEGENDARY
	var keys = GameGlobals.baseData.familiesByHabitat.keys()
	options.append_array(GameGlobals.baseData.familiesByHabitat[keys[keys.size() - 1]])
	options.append_array(GameGlobals.baseData.familiesByHabitat[keys[keys.size() - 2]])
	
	#fusions don't have a habitat.
	if GameGlobals.playerData.allowFusions == true:
		options.append_array(GameGlobals.baseData.allFamilies["FUSION"])
	
	return options

#Test function for finding missing data
static func CheckSprites():
	for p in GameGlobals.baseData.pokemon:
		var spritePath = PokemonHelpers.GetPokemonFrontSprite(GameGlobals.baseData.pokemon[p].key, false, "M")
		if (!FileAccess.file_exists(spritePath)):
			print("Pokemon " + p + " is missing a sprite!")

#test function for viewing all pokemon in-game
#static func ResetInventorTest():
	#GameGlobals.pokemon.clear()
	#for p in GameGlobals.baseData.pokemon:
		#var pokemon = PokemonGenerator.MakeMobilePokemon(p)
		#GameGlobals.pokemon[pokemon.id] = pokemon
