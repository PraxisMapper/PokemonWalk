extends Node2D
class_name PraxisHost
# PraxisHost is a take on allowing a client device to act as a server/host for multiplayer
# games via a distributed network. A device in host mode won't play the normal game, but will
# manage and track clients in service to them. 

# Clients can communicate with each other similarly to hosts, but only on the same router.
# Hosts should be servers that can cross that boundary. Hosts will have slightly higher
# ability to validate save data, in that they'll handle more data and relay it around, but 
# clients should be able to do the same actions small-scale if they can interact with each other.

#The primary difference between Host and Client is that Host is expected to be stationary,
#and be at the same IP in the near future. Clients are expected to move and play the game, possibly 
#changing IPs multiple times even while playing. They will both have the same code available.

#The generic packet format for this will be something like this:
#{
# dataType: "string",
# #other data entries as necessary for the dataType.
# sender: id,
# signature: sig.
#}

#TODO: simplify stuff so other games can use this without editing too much code
#That probably means a few functions that wrap some of this core behavior, that do the 
#important parts in that chain automatically.
#That makes the core look like, what?
#SendData(remote, baseObject) and ReceiveData(remote, rawData)?
#And that chain checks trust, validates/makes signatures, and converts to/from JSON
#So the actual game needs to have, somewhere, a feature list to inject, and 
#a list of functions to handle via requests. Are those in GameGlobals, or do I make those static?


#TODO: May need some kind of 'pending' operations array so we can save stuff that 
#we want to do and remove it once we've gotten a response from the remote.
#TODO: set up support functions for a chain-signed ledger, since that may become a thing?
#our ledger plan will become eventually correct, mostly by ignoring people that don't agree 
#or aren't trusted, possibly with a mechanism for them to take our copy and agree with us.
#TODO: allow UI to manually add host IP
#TODO: may need to allow Windows PC users to run a host and set their location/range manually.

#TODO: I need to check if another device' external IP is the same as this one. If so, they
#need to communicate via local IP or broadcast only, not via external, because they're on
#the same router.

#TODO: Document expected usage. Possibly change name.
#Probably something like "in your loading screen, call PraxisHost.DeclareFeature(name)
#to let other clients know what you can and cannot handle on this version of the app, and 
#PraxisHost.AddNetworkFunction(name, callable) to tell the program which function to call
#for what dataType of packet received. EX: PraxisHost.AddNetworkFunction("runbattle1", RunBattle)
#would send a packet with a dataType of "runbattle1" to the RunBattle function passed in. It
#might be a good idea to have your features and your network function names line up. If your 
#function returns data, that will be sent back to the original sender, so ensure it follow the
#PraxisHost packet format, which includes at least a dataType entry to send to a network function
#on the remote device. Don't have your network function send to the remote, return the data to send."

var HostIdentifierPacket = "PraxisHost".to_ascii_buffer()
var ClientIdentifierPacket = "PraxisClient".to_ascii_buffer()
var status = "Initializing..."

var autoAcquireHosts = true #if false, don't accept info on other hosts from clients, only admins.
var desc = "PraxisHost"
var externalIP = ""
var sendport = 13579 # For direct comms
var listenPort = 13580 # For direct comms
var broadcastListenPort = 35791 # for broadcast discovery of clients.
var location = ""
var publicKey = {}
var privateKey = {}
var certHelper = UserCerts.new()
var json = JSON.new()
static var featuresAvailable = [] # This gets filled in by the app. Use instead of version-checking.
static var usableFunctions = {} # the Callable() entries we can use to process data.
#NOTE: usableFunctions will be passed (remote, data). Data may be null, both parameters must be declared
var myIPs = []
var myID = ""

var selfData = {} # This device's data.
var hostList = {} # should change rarely, but we expect these to be available most of the time at the same IP
var clientList = {} # Expected to change frequently and IPs will vary.
var lastUpdated = 0 #Time since we got a change to ANYTHING.
var threadIds = []

var serverListener = UDPServer.new()
var serverSender = {}

var broadcaster = {}
var broadcastListener = {}

var availableData = {}
var areaSizeToTrack = "4+" #4 means "Cell4 base area", 6 means "Cell6 base area", + means "and neighbors"
# 4 is 1 degree square, 4+ is 3 degrees square, 6 is .05 degree square, 6+ is .15 degree square
#      (~111km)              (~333km)              (~6km)                       (~18km)

#Signals and UI updates need to use call_deferred in threads.
signal log(msg)

func location_changed(cur, old):
	var loc = cur.substr(0,int(areaSizeToTrack.left(1)))
	if location != loc and selfData != {}:
		location = loc
		selfData.area = DetermineArea(PraxisCore.currentPlusCode, selfData.size)
		#TODO: should this cause re-processing if the servers moved? This is probably a
		#case of "server started first, got usable location later"

func _ready() -> void:
	await get_tree().process_frame #Let the UI show up before we moe on.
	status = "Getting external IP"
	await get_tree().process_frame
	location = PraxisCore.currentPlusCode
	log.connect(Log)
	var ipThread = Thread.new()
	ipThread.start(GetExternalIP)
	ipThread.wait_to_finish() #allow it to close. We need this value before server setup.
	
	var cleanup = Thread.new()
	cleanup.start(ThreadCleanup)
	
	#do rest of setup. May move this to a thread as well so the UI updates.
	var setupThread = Thread.new()
	setupThread.start(SetupServer)
	setupThread.wait_to_finish()

func ClearData():
	externalIP = ""

func SetupServer():
	myIPs = IP.get_local_addresses()
	print(myIPs)
	myID = OS.get_unique_id()
	
	#load previous data from disk
	status = "Loading data..."
	await get_tree().process_frame
	hostList = PraxisCore.LoadData("user://HostList.json")
	if (hostList == null):
		hostList = {}
	#clientList probably shouldn't be persisted.
	availableData = PraxisCore.LoadData("user://GameData.json")
	if (availableData == null):
		availableData = {}
	
	status = "Loading keypair..."
	privateKey = CryptoKey.new()
	privateKey.load("user://generated.key")
	publicKey = CryptoKey.new()
	publicKey.load("user://generated.pub", true)
	
	#generate and save keys if we somehow didn't have them before.
	if (privateKey == null):
		var crypto = Crypto.new()
		privateKey = crypto.generate_rsa(2048)
		privateKey.save("user://generated.key")
		privateKey.save("user://generated.pub", true)
		publicKey.load("user://generated.pub", true)
		
	#hook up some baseline functions here for network purposes.
	#Probably includes finding hosts, confirming id/keys from hosts/clients others?
	#the broadcast listener is JUST to find other clients/hosts on the same LAN.
	usableFunctions["publicKey"] = ValidatePublicKey
	usableFunctions["sendPublicKey"] = SendPublicKey
	usableFunctions["hostList"] = MergeHostList
	
	status = "Initializing network..."
	var area = DetermineArea(PraxisCore.currentPlusCode, areaSizeToTrack)
	
	#Initialize network objects
	serverListener = UDPServer.new()
	var errorL = serverListener.listen(listenPort)
	print("Listener state: " + str(errorL))
	
	serverSender = PacketPeerUDP.new()
	var errorS = serverSender.bind(sendport)
	print("sender state: " + str(errorS))
	
	broadcaster = PacketPeerUDP.new()
	broadcaster.set_broadcast_enabled(true)
	broadcaster.set_dest_address("255.255.255.255", broadcastListenPort)
	
	broadcastListener = PacketPeerUDP.new()
	broadcastListener.set_broadcast_enabled(true) # may be required on some phones.
	broadcastListener.bind(broadcastListenPort)
	print("Broadcaster Listener on:" + str(broadcastListener.is_bound()))
	
	var blThread = Thread.new()
	blThread.start(ListenForBroadcasts)

	#Create data on this host to share with others.
	selfData = {
		dataType = "host",
		#This will be stored for each host and be signed by that host to confirm it.
		hostInfo = { 
			ip = externalIP,
			id = myID, #ISSUE: this changes every run on Windows? May need to save and load it?
			publicKey = publicKey.save_to_string(true),
			area = area, #Actual Rect2 bounding box in GPS coords. Use to interset with other hosts areas.
			features = featuresAvailable, #may as well do this here instead of adding more requests for this.
		},
		trustData = {}, #This will be filled in for other servers. OBVIOUSLY we trust ourselves.
		#trustData = {
		# id = other servers unique id
		# ip = external ip
		# mark = implicit/trust/suspect/deny are expected
		# date = date this value was assigned.
		# sign = signed by ID's public key to share their opinion on this entry.
		
		# mark values: (Other apps may add more, this is my initial planned default)
		
		# implicitCode: as Implicit, but also may allow running code passed from this host
		# executing arbitrary code from a remote device is dangerous, but in the event that
		# some game wants/needs it, I'll allow it in a case where you already applied max
		# trust to that server. The only benefit I can currently think of is that this would
		# allow the server to run a different version of the app from the clients or other hosts.
		
		# implicit: Always trust this ID's data as long as it verifies, ignore consensus.
		# Intended for a network of hosts, so they can't be manipulated into untrusting each other.
		
		# trust: Default. We haven't seen this ID fail to verify tons, cheat, or send bad data.
		# downgrade to 'suspect' after some number (3 in a day?) of bad data packets are passed, or if 
		# some number (majority? minimum? percentage?) of received trust values are 'suspect' or worse.
		
		# suspect: This ID has failed a lot of verification checks, or passed bad data at least once.
		# Upon getting some number of suspect entries (3? Percentage based? more complex?), downgrade to 'deny'
		
		# deny: drop messages from this ID entirely, we refush to deal with them until an admin changes this.
		# Can be set by admins directly, inherited from other servers with implicit trust, or if a 
		# suspect remote user continually sends bad data.
		
		#}
		desc = desc,
		size = areaSizeToTrack, # 4+, 6, or 6+. Possibly others?
		hostCount = hostList.size(),
		availableCount = availableData.size(),
	}
	certHelper.Sign(privateKey, selfData.hostInfo, true)
	print(selfData)
	$txtLocation.text = location
	$txtRange.text = areaSizeToTrack
	$lblId.text = "My ID: " + selfData.hostInfo.id
	status = "Startup complete"

func _process(delta: float) -> void:
	$lblStatus.text = "Server Status: " + status
	ParsePackets()

static func DeclareFeature(feat):
	featuresAvailable.append(feat)

static func AddNetworkFunction(name, callable):
	usableFunctions[name] = callable

var saveHostMutex = Mutex.new()
func SaveHostData():
	saveHostMutex.lock()
	PraxisCore.SaveData("user://HostList.json", hostList)
	PraxisCore.SaveData("user://GameData.json", availableData)
	saveHostMutex.unlock()
	
func SendPublicKey(remote, ignored):
	#need to package and send the public key, so others can verify our data
	var data = {
		dataType = "publicKey",
		publicKey = selfData.hostInfo.publicKey,
	}
	print("sending public key: "+ str(data))
	return data

func ValidatePublicKey(remote, data):
	print("validating public key: " + str(data))
	#Validation steps:
	#Is this a packet this function can handle
	if data.dataType != "publicKey":
		print("not a public key data packet")
		return #no type, this isn't a reply to the sender.
	
	#Is this packet signed correctly?
	if !certHelper.Verify(data.publicKey, data):
		print("public key packet failed to verify")
		return
	
	#do we have an entry for this remote already, and is it the same?
	var remoteid = data.id
	if (hostList.has(remoteid)):
		if hostList[remoteid].id == remoteid:
			return #good, we already had this.
		else:
			#ok, we need to trust-strike whoever we got the original from. 
			#TODO: determine that logic.
			pass
	else:
		data.erase("dataType")
		hostList[remoteid] == data
		SaveHostData()

func ListenForBroadcasts():
	while broadcastListener.wait() == OK:
		var data = broadcastListener.get_var() #I want to try and do this where possible.
		var remote = broadcastListener.get_packet_ip()
		if myIPs.has(remote):
			continue #ignore packets we sent ourself
		print(remote)
		
		if data == HostIdentifierPacket:
			pass
			#This is another Praxis game host, handle accordingly
		
		if data == ClientIdentifierPacket:
			pass
			#This is a Praxis game client, handle accordingly
		
		print("Broadcast received: " + str(data))
		call_deferred("Log", remote + " sent " + str(data))
		if data == null:
			continue #dunno why this didn't pull it out correctly but quit

func ValidateData(data):
	if !data.has("dataType"): #not a packet we can use here.
		return false
	
	if data.has("signature"):
		var pubKeyStr
		if hostList.has(data.id):
			pubKeyStr = hostList[data.id].publicKey
		elif data.has("publicKey"):
			pubKeyStr = data.publicKey
		else:
			print("cant validate, skipping packet")
			#NOTE: can't validate this if we're being asked to send out public key from an unknown host
			return true #TODO: should this be true, instead of false? config?
		
		var pubKey = CryptoKey.new()
		pubKey.load_from_string(pubKeyStr)
			
		var isValid = certHelper.Verify(pubKey, data)
		if (!isValid):
			print("Packet failed to validate")
		return isValid
	return true #This probably wants a schema check if possible in the future

var peers = [] #Temp TODO determine if this is better or not.
func ParsePackets():
	serverListener.poll()
	if serverListener.is_connection_available():
		var peer: PacketPeerUDP = serverListener.take_connection()
		#var packet = peer.get_packet()
		#ALT: just use objects here, but only allow full if they're implicitCode trusted
		var obj = peer.get_var()
		var ip = peer.get_packet_ip()
		if myIPs.has(ip):
			print("received self-broadcast, disregard: " + obj.dataType)
			return #ignore packets we sent ourself
		print("new peer sent object:" + str(obj)) 
		ProcessPacket(peer, obj)
		# Keep a reference so we can keep contacting the remote peer.
		#This may be too early?
		peer.close()

		
func PackAndSendData(receiver, data):
	#Helper for sending data.
	#Data needs to have a dataType variable. The rest of the requirements are handled here
	data.id = myID
	certHelper.Sign(privateKey, data, true)
	#receiver.put_var(data) #TODO: may need to confirm if this should be deferred.
	var p = PacketPeerUDP.new()
	p.connect_to_host(receiver.get_packet_ip(), listenPort)
	p.put_var(data)
	p.close()

func ProcessPacket(sender, data): #data is an object.
	print("Received " + data.dataType + " packet")
	call_deferred("Log", sender.get_packet_ip() + ": Received " + data.dataType + " packet")
	
	#Step 1: verify this packet from the sender
	if ValidateData(data) == false:
		#TODO: consider a strike against the sender for a packet failing to validate?
		return

	#Step 2 check what kind of message this is and respond appropriately.
	if usableFunctions.has(data.dataType):
		#TODO: this should be put into a thread perhaps. Test both separately.
		#Unthreaded option:
		#var results = usableFunctions[data.dataType].call(sender, data)
		#if results != null:
			##Pass the results back, since they were apparently expected.
			#print("sending " + str(results))
			#sender.put_var(results)
		#threaded option:
		#NOTE: this needs another function to handle sending.
		var callable = ThreadWrapper.bind(usableFunctions[data.dataType], sender, data)
		#not this: #var callable = usableFunctions[data.dataType].bind(sender, data)
		threadIds.append(WorkerThreadPool.add_task(callable))
		
	#If I don't have a function assigned for this, I must disregard this
	#But thats probably not a trust strike, thats most likely a version difference
	
func ThreadWrapper(callable, remote, data):
	#this is now inside a WorkerThreadPool thread.
	var results = callable.call(remote, data)
	if results != null:
		#Pass the results back, since they were apparently expected.
		print("sending " + str(results))
		call_deferred("Log", "Sending " + results.dataType + " packet to " + remote.get_packet_ip())
		PackAndSendData(remote, results)
	remote.close()

func SpreadLoop():
	pass
	#This is the function that sits in a thread and sends data to other known hosts
	#or clients, and pushes data out to them.
	for h in hostList:
		#Skip hosts we have blocked.
		if h.trustData[selfData.hostInfo.id] == "deny":
			continue
		
		#Check if we've updated anything for them
		if h.lastUpdated >= lastUpdated:
			continue
		
		#Update their entry
		h.lastUpdated = Time.get_unix_time_from_system()
		
	for c in clientList:
		#Check if we've updated anything for them.
		if c.lastUpdated >= lastUpdated:
			continue
			
		c.lastUpdated = Time.get_unix_time_from_system()

func CheckHost(hostData):
	#get a list of hosts and their data. We don't plan on talking to hosts out of
	#range but clients may need that info if they travel far away.
	
	#NOTE: we should be able to hit a host directly for its data, and if it doesnt match
	#what we expected strike the person we got the initial wrong data from.
	pass
	
func SendSelfData(remote):
	print("sending signed self data: " + str(selfData))
	remote.put_var(selfData)
	call_deferred("Log", "Sent Self-Data")

func GetHostData(packet):
	#This is data about a host sent to us, from a client or a host itself.
	if !ValidateData(packet.hostInfo):
		return
	if hostList.has(packet.hostInfo.id):
		#check and update this entry
		#make sure the hostInfo block matches, since that shouldn't change
		#then check and process the trustData block.
		#NOTE: if this host data is for the host we got this from, trust it over data
		#we got from other hosts secondhand.
		pass
	else:
		hostList[packet.hostInfo.id] = packet
		#NOTE: I will need to remove this date value when sending this or it fails to validate
		hostList[packet.hostInfo.id].dateLastUpdated = Time.get_unix_time_from_system()
	
func SendAllHostData(remote):
	#take our host info, strip it to whats needed, and send it.
	var finalData = {}
	finalData.dataType = "knownHosts"
	for hd in hostList:
		var host = {
			hostInfo = hd.hostInfo,
			trustData = hd.trustData
		}
		finalData[host.hostInfo.id] = host
	finalData[selfData.id] = selfData
	
	print("sending hosts: " + str(finalData))
	remote.put_var(finalData)

func GetExternalIP():
	var upnp = UPNP.new()
	var err = upnp.discover(2000) #NOTE: This blocks, and should be on a thread.
	if (err != OK):
		print("Error discovering external IP.")
		return
	externalIP =  upnp.query_external_address()

func Log(msg):
	print("logging " + msg)
	$lblLog.text += msg + "\n"

func UpdateUI():
	$lblRecentClients.text = "Recent clients: " + str(clientList.size())
	$lblIP.text = "IP: " + externalIP

func DetermineArea(plusCode, size):
	var basePoint = PlusCodes.Decode(plusCode)
	var minPoint = basePoint
	var codeSize = int(size.left(1))
	var codeDist = PraxisCore["resolutionCell" +size.left(1)]
	var pointShift = Vector2(codeDist, codeDist)
	var maxPoint = basePoint + pointShift
	if (size.right(1)) == "+":
		minPoint -= pointShift
		maxPoint += pointShift

	#TODO: confirm this rectangle works with client geolocation points. I dont want to have
	#my Y-axis messed up on this since PlusCodes are upside-down from Godot coordinates.
	return Rect2(minPoint.x, maxPoint.y, maxPoint.x - minPoint.x, maxPoint.y - minPoint.y)

#This should probably be limited down to only handle host/client info,
#and actual game data handled elsewhere.
func FullSync(host):
	pass
	# TODO: send a FullSync request to a host, receive all data from it
	# and merge those in smoothly to my current data set.

func ProcessClientSave(remote, data):
	pass
	#TODO: The Client is sending us their save data, we should unpack, validate,
	#and process it into our data here. This may be a game-specific call that doesnt belong here.

func MergeHostList(remote, data):
	pass

#TODO: is this necessary?
func MergeClientList(incoming):
	#Take incoming, update our local clientList with new data.
	#The Client List is only ID/IP/Signed/DateChanged/LastReceived I think
	#A game-specific client save file might be tracked in a separate dictionary.
	for c in incoming.clients:
		pass
		if clientList.has(c.id):
			pass
			#Compare existing data, ensure its legit. 
		else:
			#validate, then add data
			if certHelper.Verify(c.publicKey, c):
				clientList[c.id] = c
			else:
				pass
				#Stuff didn't verify, thats a strike against the sender.
	
func AddHost():
	pass
	#add a host the user typed in and ask them for their data.
	
func StopHosting():
	#Stop processing incoming requests, allow currently running requests to finish,
	#save all resources to disk.
	pass
	
func TestDirectSend():
	var data = {
		dataType = "sendPublicKey",
		id = myID
	}
	certHelper.Sign(privateKey, data, true)
	
	#TEST forcing this.
	hostList.a = "192.168.50.128"
	hostList.b = "192.168.50.74"
	
	#For all other discovered entries, send them the publicKey request.
	for h in hostList:
		var p = PacketPeerUDP.new()
		p.connect_to_host(hostList[h], listenPort)
		p.put_var(data)
		p.close()

func StartBroadcastSearch():
	var timer = Timer.new()
	add_child(timer)
	timer.one_shot = false
	timer.wait_time = 2
	timer.start()
	while true:
		await timer.timeout
		#print("Sending broadcast ID:" + str(HostIdentifierPacket))
		#broadcaster.put_packet(HostIdentifierPacket) #NOTE: objects can be allowed through these.
		#broadcaster.put_var(HostIdentifierPacket)
		print("sending self data")
		SendSelfData(broadcaster)
	#Send a sample packet to everybody, either via broadcast or through the host list.


func ThreadCleanup():
	while threadIds.size() > 0:
		var t = threadIds.pop_front()
		WorkerThreadPool.wait_for_task_completion(t)
	await get_tree().create_timer(500).timeout
	
#This should be elsewhere, but probably a core, common one.
#func MapData():
	#pass
	#maybe hosts/clients can share map data instead of going to a fileserver?
	#This may not work if packet size is limited and these files are big.
	#8MB is the default cap for sending data. That should cover MOST areas as a Cell6.
