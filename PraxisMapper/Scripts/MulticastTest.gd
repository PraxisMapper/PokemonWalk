extends Node
class_name MulticastTest

# TODO: I should make a Server scene that handles info for a distributed multiplayer game
# This is nice and might be worth including, but I'll probably need to actually have the
# ability to run a server on any client to make this truly work. It should be a separate scene
# that shows a count of other hosts, data it can share, etc.

var sender
var listener

func Setup():
	sender = PacketPeerUDP.new()
	sender.set_broadcast_enabled(true)
	
	var interfaces = IP.get_local_interfaces()
	#My understanding is that this IP can be anything as long as it's unique
	for i in interfaces:
		sender.join_multicast_group("24.48.96.192:13579", i.name)
	
	print("multicast set?")
	
	listener = PacketPeerUDP.new()
	listener.bind(13579)
	
	#TODO: print when packet received
	
	var timer = Timer.new()
	timer.one_shot = false
	timer.timeout.connect(Send)
	timer.start()

func Send():
	pass
	
func Receive():
	pass

func GetBroadcastAddress(ip):
	pass
	#How? Probably start here, looking for local IPs:
	#IP.get_local_addresses() 
