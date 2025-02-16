extends Node2D
class_name DailyChallenge

var placeTracker: PlaceTracker

func CheckForCompletedChallenge(current):
	pass
	#Let this node decide if its complete or not
	if !GameGlobals.playerData.has("dailyChallenge"):
		return
	if GameGlobals.playerData.dailyChallenge.challengeType == 0:
		#have we entered the requested place? if yes, set end timer and then check if we're there long enough
		pass
	elif GameGlobals.playerData.dailyChallenge.challengeType == 1:
		#checking RecentTracker for this day's activity. NOTE: This requires it to reset at midnight, not roll!
		pass


func GetDailyChallenges():
	#This needs to only fire off once after loading, 
	var today = Time.get_date_string_from_system()
	var dailyRng = RandomNumberGenerator.new()
	if (GameGlobals.playerData.has("dailyChallenge") 
	and GameGlobals.playerData.dailyChallenge.has("today")
	and GameGlobals.playerData.dailyChallenge.today == today):
		#I should have already generated and saved this data.
		$lblChallenge1.text = GameGlobals.playerData.dailyChallenge.desc
		#return #TODO uncomment once i check on generation
	else:
		dailyRng.seed = today.hash() #we probably already made this data too

	while PraxisCore.currentPlusCode == "":
		await get_tree().create_timer(0.5).timeout
	
	var cell6 = PraxisCore.currentPlusCode.substr(0,6)
	#Hmm. to make this work the best, we will need to pick a base pluscode. May also need a home
	#base here? Or pick the first code we opened up with for the day.
	
	#TODO: could loop this twice for 2 results.
	var task = {
		name = "",
		challengeType = 0,
		day = today,
		desc = "",
		startingCell6 = cell6, #Used to re-gen the data if we need to for the day.
		placeName = "", #display name of target place
		placeArea = "", # Cell6 for the specific place
		placeType = 0,
		trackTime = false,
		timeStarting = 0, #This gets set to the current time when the player first enteres this place
		timeEnding = 0, #This is timeStarting + 15 minutes,may not need saved after all.
		rewardPokemonKey = "", #Which pokemon you're gonna get if you do this.
	}
	
	#with RNG set, roll up where to go and find it.
	#pick any entry in the style set that isn't background/unmatched/serverGenerated
	#var placeType = GameGlobals.styleData[str(dailyRng.randi() % (GameGlobals.styleData.keys().size() - 4))]
	var placeType = GameGlobals.styleData.keys()[dailyRng.randi() % (GameGlobals.styleData.keys().size() - 4)]
	task.placeType = placeType
	#WAIT NO, instead of this I should scan for all possible places in range, then pick one?
	#pick a cell to go to
	

	#TODO: need to determine if this is going empty because of the picked terrainId, or if it's a math issue
	#with how it picks places.
	#I may just be better off with a list of viable places instead of starting with a specific terrainID in mind
	#though perhaps both are viable tasks once I get a baseline functioning
	
	#Will also need to check PlaceTracker to propose new places most of the time.
	#but repeats can be allowed.
	#does this need PlaceTracker to be a child node of GameGlobals? It'll have to wait until after
	#the pluscode is processed to fire off from main, though. Yay signals!
	var unvisitedPlaces = []
	
	var placesHere = GameGlobals.ScanForPlaces(cell6, placeType)
	for place in placesHere:
		if !placeTracker.HasVisited(place.name, place.area):
			unvisitedPlaces.push_back(place)

	var attemptCounter = 0
	while unvisitedPlaces.size() <= 5 and attemptCounter <20:
		var xShift = dailyRng.randi_range(-2, 3) #2nd number is exclusive
		var yShift = dailyRng.randi_range(-2, 3) #2nd number is exclusive
		var targetArea = PlusCodes.ShiftCode(cell6, xShift, yShift)
		var possiblePlaces = GameGlobals.ScanForPlaces(targetArea, placeType)
		for place in possiblePlaces:
			if !placeTracker.HasVisited(place.name, place.area):
				unvisitedPlaces.push_back(place)
		attemptCounter += 1

	var legendId = dailyRng.randi() % GameGlobals.baseData.familiesByHabitat["Legendary"].size()
	task.rewardPokemonKey = legendId
	
	if (unvisitedPlaces.size() != 0):
		var place = unvisitedPlaces[dailyRng.randi() % unvisitedPlaces.size()]
		task.placeName = place.name
		task.placeArea = place.area	

		task.desc = "Go to " + task.placeName + " in Sector " + task.placeArea 
		if (place.geoType == 3): #only apply time limit to areas you could walk in. Lines and points dont have a timer.
			task.desc += " for 15 minutes"
			task.trackTime = true
		task.desc += "to catch " + GameGlobals.baseData.familiesByHabitat["Legendary"][task.rewardPokemonKey]
		$lblChallenge1.text = task.desc
	else:
		task.desc = "Walk though 250 spaces to catch " + GameGlobals.baseData.familiesByHabitat["Legendary"][task.rewardPokemonKey]
		$lblChallenge1.text = task.desc
		task.challengeType = 1
		#this is where we fall back to "walk X spaces today" with a recentTracker or something.
	
	GameGlobals.playerData.dailyChallenge = task
	GameGlobals.Save()
	
