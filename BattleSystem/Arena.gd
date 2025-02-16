extends RefCounted
class_name Arena

#Area holds the stuff that applies to everyone, or one side of a fight.

enum arena_tags {NONE,MUD_SPORT,WATER_SPORT, SPIKES, TOXIC_SPIKES, MIST, FUTURE_SIGHT,DOOM_DESIRE, WISH, STEALTH_ROCK, STICKY_WEB, TRICK_ROOM, GRAVITY, REFLECT, LIGHT_SCREEN, AURORA_VEIL, TAILWIND}

var biome = ""
var weather = ""
var terrain = ""
var tags= []
var ignoreAbilities = false
