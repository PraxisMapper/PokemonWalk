extends Node
class_name Adapter

#Adapter is the class to handle referencing both online and offline map
#data to get the same results out of them for scanning. In WSC(P) this was just
#sorta brute-forced, and I'm gonna clean that up here.

#FUTURE TODO: this should probably try to automatically fill in from styles rather than
#being a hard-coded list if I make changes. That requires the styles to be marked as gameplay places.


#NOTE: in actual styles, names may have spaces.
static var gameplayAreas = {
	park = { full = 1000, offline = 1},
	university = { full = 20, offline = 2},
	natureReserve = { full = 1200, offline = 3},
	cemetery = { full = 1300, offline = 4},
	historical = { full = 500, offline = 5},
	theatre = { full = 40, offline = 6},
	concertHall = { full = 50, offline = 7},
	artsCenter = { full = 60, offline = 8},
	planetarium = { full = 70, offline = 9},
	artsCulture = { full = 80, offline = 10},
	library = { full = 90, offline = 11},
	publicBookcase = { full = 100, offline = 12},
	communityCentre = { full = 110, offline = 13},
	conferenceCentre = { full = 120, offline = 14},
	exhibitionCentre = { full = 130, offline = 15},
	eventsVenue = { full = 140, offline = 16},
	aquarium = { full = 150, offline = 17},
	artwork = { full = 160, offline = 18},
	attraction = { full = 170, offline = 19},
	gallery = { full = 180, offline = 20},
	museum = { full = 190, offline = 21},
	themePark = { full = 200, offline = 22},
	viewPoint = { full = 210, offline = 23},
	zoo = { full = 220, offline = 24},
	namedTrail = { full = 1500, offline = 25}
}

static var gameplayFullIds = {
	"1000" = "park",
	"20" = "university",
	"1200" = "natureReserve",
	"1300" = "cemetery",
	"500" = "historical",
	"40" = "theatre",
	"50" = "concertHall",
	"60" = "artsCenter",
	"70" = "planetarium",
	"80" = "artsCulture", #no longer in use, left here as a safety check.
	"90" = "library",
	"100" = "publicBookcase",
	"110" = "communityCentre",
	"120" = "conferenceCentre",
	"130" = "exhibitionCentre",
	"140" = "eventsVenue",
	"150" = "aquarium",
	"160" = "artwork",
	"170" = "attraction",
	"180" = "gallery",
	"190" = "museum",
	"200" = "themePark",
	"210" = "viewPoint",
	"220" = "zoo",
	"1500" = "namedTrail"
}
