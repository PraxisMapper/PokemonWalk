extends Node

#This is where any server-reliant connections will occur.
# Values used for login/auth and server comms
static var username = ''
static var password = ''
static var authKey = '' #for normal security with a login
static var headerKey = '' #for header-only security
static var serverURL = '' #dedicated games want this to be a fixed value and not entered on the login screen.
#NOTE: serverURL should NOT end with a /. Changed from Solar2D's pattern.

static var reauthCode = 419 #AuthTimeout HTTP response
static var isReauthing = false #most calls should abort or wait if we're reauthing.

static func reauthListener(result, response_code, headers, body):
	if response_code == 200:
		var json = JSON.new()
		json.parse(body.get_string_from_utf8())
		var data = json.get_data()
		PraxisServer.authKey = data.authToken
		isReauthing = false
	else:
		OS.delay_msec(1000)
		PraxisServer.Reauth()

static func Reauth():
	if (isReauthing == true):
		return #TODO better handling/retry logic.
		
	isReauthing = true
	var request = HTTPRequest.new()
	var call = request.request(PraxisServer.serverURL + "/Server/Login/" + PraxisServer.username + "/" + PraxisServer.password)
