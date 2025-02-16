extends Node
class_name PlusCodes

var SEPARATOR_ = '+'
static var CODE_ALPHABET_ = '23456789CFGHJMPQRVWX'

static func EncodeLatLon(lat, lon):
	return EncodeLatLonSize(lat, lon, 10)
	
static func EncodeLatLonSize(lat, lon, size):
	var code = ''
	var digit11 = ''
	var nextLatChar = 0
	var nextLonChar = 0
	
	var xMul = 8000
	var yMul = 8000
	if size == 11:
		xMul *= 4
		yMul *= 5
		
	var currentLat = int(floor((lat + 90) * yMul))
	var currentLon = int(floor((lon + 180) * xMul))
		
	if size == 11:
		var nextLonIndex = (currentLon % 4) 
		var nextLatIndex = (currentLat % 5)
		var indexDigit = (nextLatIndex * 4 + nextLonIndex)
		digit11 = CODE_ALPHABET_[indexDigit]
		currentLat = floor(currentLat / 5)
		currentLon = floor(currentLon / 4)
	
	for i in 5:
		nextLonChar = (currentLon % 20)
		nextLatChar = (currentLat % 20)
		
		code = CODE_ALPHABET_[nextLatChar] + CODE_ALPHABET_[nextLonChar] + code
		currentLat = floor(currentLat / 20)
		currentLon = floor(currentLon / 20)

	code = code + digit11
	
	return code.substr(0, 8) + "+" + code.substr(8, -1)
	
static func RemovePlus(code):
	if code == null:
		return null
	return code.replace("+", "")
	
static func ShiftCode(code, xChange, yChange):
	if code == "":
		return ""
		
	if (abs(xChange) > 20 or abs(yChange) > 20):
		#recursive call
		code = ShiftCode(code.substr(0, code.length() - 2), xChange / 20, yChange / 20) + code.substr(code.length() - 2, 2)
		xChange = xChange % 20
		yChange = yChange % 20	
	code = RemovePlus(code)
	var xVals = []
	var yVals = []
	
	for i in code.length() / 2:
		var yLet = code.substr(i * 2, 1)
		var xLet = code.substr((i * 2) + 1, 1)
		yVals.push_back(CODE_ALPHABET_.find(yLet))
		xVals.push_back(CODE_ALPHABET_.find(xLet))
		
	if xChange != 0:
		xVals[xVals.size() -1] += xChange
		for i in range(xVals.size() -1, 0, -1):
			if (xVals[i] > 19):
				xVals[i -1] = xVals[i - 1] + (1)
				xVals[i] = xVals[i] - 20
			elif (xVals[i] < 0):
				xVals[i -1] = xVals[i - 1] - (1)
				
				xVals[i] = xVals[i] + 20
	if yChange != 0:
		yVals[yVals.size() -1] += yChange
		for i in range(yVals.size() -1, 0, -1):
			if (yVals[i] > 19):
				yVals[i -1] = yVals[i - 1] + (1)
				yVals[i] = yVals[i] - 20
			elif (yVals[i] < 0):
				yVals[i -1] = yVals[i - 1] - (1)
				yVals[i] = yVals[i] + 20
	var newCode = ''
	for i in code.length() / 2:
		newCode = newCode + CODE_ALPHABET_[yVals[i]] + CODE_ALPHABET_[xVals[i]]
	
	return newCode
	
static func Decode(plusCode):
	var lat = -90.0
	var lon = -180.0
	plusCode = plusCode.replace("+", "")
	var totalChars = plusCode.length()
	var charsProcessed = 0
	var precision = 20
	var xVal = 0
	var yVal = 0
	while (charsProcessed < totalChars):
		if (charsProcessed < 10):
			xVal = PlusCodes.GetLetterIndex(plusCode[charsProcessed + 1])
			yVal = PlusCodes.GetLetterIndex(plusCode[charsProcessed])
			
			lat += precision * yVal
			lon += precision * xVal
			precision /= 20.0
			charsProcessed += 2
		else:			
			#lat/row is /, column/lon is %
			xVal = PlusCodes.GetLetterIndex(plusCode[charsProcessed]) % 4
			yVal = PlusCodes.GetLetterIndex(plusCode[charsProcessed]) / 4
			
			lon += (xVal * (precision / (4.0 ** (charsProcessed - 9))))
			lat += (yVal * (precision / (5.0 ** (charsProcessed - 9))))
			
			charsProcessed += 1
	return Vector2(lon, lat) #x, y!

static func GetDistanceDegrees(plusCode1, plusCode2):
	var vec1 = PlusCodes.Decode(plusCode1)
	var vec2 = PlusCodes.Decode(plusCode2)
	return vec1.distance_to(vec2)

#This picks out distances on both axes in Cell10 spaces
#so the results can be adjusted to pixels fairly easily by multiplying the results
#by Vector2(4,5) for cell11s or Vector2(16,25) for cell12s
static func GetDistanceCell10s(plusCode1, plusCode2):
	if plusCode1 == null or plusCode2 == null:
		return 0
	plusCode1 = PlusCodes.RemovePlus(plusCode1)
	plusCode2 = PlusCodes.RemovePlus(plusCode2)
	var diffY = 0
	var diffX = 0
	var diff = 0
	var multipliers = [160000, 8000, 400, 20, 1] #how many Cell10s to multiply
	var ycoords = [0, 2, 4, 6, 8]
	var xcoords = [1, 3, 5, 7, 9]
	for y in ycoords:
		diff = PlusCodes.GetLetterIndex(plusCode1[y]) - PlusCodes.GetLetterIndex(plusCode2[y])
		diff *= multipliers[ycoords.find(y)]
		diffY += diff
	for x in xcoords:
		#TODO: reverse this. These coords are backwards if we're using 1 as the base for the results.
		#and update places that call this function.
		diff = PlusCodes.GetLetterIndex(plusCode1[x]) - PlusCodes.GetLetterIndex(plusCode2[x])
		diff *= multipliers[xcoords.find(x)]
		diffX += diff

	return Vector2(diffX, diffY)
	
static func GetDistanceCell8s(code1, code2):
	return GetDistanceCell10s(code1.substr(0,8) + "22", code2.substr(0,8) + "22") / 20

#NOTE: 0 is NORTH on this function, whereas in most Godot values its EAST
static func GetDirection(plusCode1, plusCode2):
	#adjust the values to have north == 0 instead of east.
	var vec1 = PlusCodes.Decode(plusCode1).rotated(-PI / 2)
	var vec2 = PlusCodes.Decode(plusCode2).rotated(-PI / 2)
	var vecDir = vec1.direction_to(vec2)
	return rad_to_deg(vecDir.angle())

static func GetLetterIndex(letter):
	return CODE_ALPHABET_.find(letter)
	
static func GetNearbyCells(code, distance): #TODO: use this instead of manual loops in places
	var cells = []
	for y in range(-distance, distance + 1):
		for x in range(-distance, distance + 1):
			cells.push_back(PlusCodes.ShiftCode(code, x, y))
	return cells
