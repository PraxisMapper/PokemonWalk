extends RefCounted
class_name UserCerts

# This is the start of a support class that could eventually let users pass data between each other
# without a server. In theory, if a user has a list of public keys, they can sign and verify objects
# against each other to ensure that only the intended recipient can interact with it. The hard part
# here is getting a public key from someone without a server, and managing them in a client.

#Right now, with a 2048 bit rsa key, signatures are 512 bytes as a string, and an encrypted
#password is a similar size. So roughly add 1kb to any packed stuff to send.

var crypto = Crypto.new()
var json = JSON.new()

func MakeUserCert():
	var key = crypto.generate_rsa(2048)
	key.save("user://generated.key") #both keys unless we add ', true' to this call.
	key.save("user://generated.pub", true)
	return key

func Sign(userPrivKey, thingToSign, signObject = false):
	if (thingToSign.has("signature")):
		thingToSign.erase("signature")
	
	var rawsig = crypto.sign(HashingContext.HASH_SHA256, 
		json.stringify(thingToSign).sha256_buffer(), 
		userPrivKey)
	var sig = Marshalls.raw_to_base64(rawsig)

	if signObject == true:
		thingToSign.signature = sig
	return sig

func VerifyObject(object):
	return Verify(object.publicKey, object)

func Verify(publicKey, thingToVerify, signature = ''):
	var restoreSig = false
	if (thingToVerify.has('signature')):
		restoreSig = true
		signature = thingToVerify.signature
		thingToVerify.erase('signature')
		
	var verified = crypto.verify(HashingContext.HASH_SHA256, 
		json.stringify(thingToVerify).sha256_buffer(), 
		Marshalls.base64_to_raw(signature),
		publicKey)

	if (restoreSig):
		thingToVerify.signature = signature
	return verified

func Encrypt(publicKey:CryptoKey, thingToEncrypt):
	var pbaData = thingToEncrypt.to_utf8_buffer()
	var results = crypto.encrypt(publicKey, pbaData)
	return Marshalls.raw_to_base64(results)

func Decrypt(privateKey, stringToDecrypt:String):
	var pbaResults = crypto.decrypt(privateKey, Marshalls.base64_to_raw(stringToDecrypt))
	var textData = pbaResults.get_string_from_utf8()
	return textData
	
#Pack up an object and send it to another user based on their public key. Cant be read or edited
func Package(TargetPublicKey, ThingToPack, SendersPrivateKey = null):
	#take a dictionary, encrypt it, sign it, return the results
	var results = {}
	var tempPass = MakeTempPass()
	results.password = Encrypt(TargetPublicKey, tempPass)
	
	#Now to encrypt the payload!
	var encoder = AESContext.new()
	var pwdBuffer = tempPass.to_utf8_buffer()
	var errCode = encoder.start(AESContext.MODE_ECB_ENCRYPT, pwdBuffer)
	
	var payloadStr = json.stringify(ThingToPack)
	var buffer = payloadStr.to_utf8_buffer()
	var expand = buffer.size() % 16
	if (expand > 0):
		buffer.resize(buffer.size() + 16 - expand)
	var payload = encoder.update(buffer)
	encoder.finish()
	results.payload = Marshalls.raw_to_base64(payload)
	
	if SendersPrivateKey == null:
		SendersPrivateKey = CryptoKey.new()
		SendersPrivateKey.load("user://generated.key")
	Sign(SendersPrivateKey, results, true)
	
	return results

#This is unpacking something sent to the user.
func UnPack(SenderPublicKey, ThingToUnpack, MyPrivateKey = null):
	var verified = Verify(SenderPublicKey, ThingToUnpack)
	if (verified == false):
		return null
	
	#Step 2 is to get the password for the payload.
	if MyPrivateKey == null:
		MyPrivateKey = CryptoKey.new()
		MyPrivateKey.load("user://generated.key")
	var temppass = Decrypt(MyPrivateKey, ThingToUnpack.password)
	
	#Now to decrypt the payload!
	var decoder = AESContext.new()
	decoder.start(AESContext.MODE_ECB_DECRYPT, temppass.to_ascii_buffer())
	var payload = decoder.update(Marshalls.base64_to_raw(ThingToUnpack.payload))
	decoder.finish()
	
	var string_data = payload.get_string_from_utf8()
	json.parse(string_data)
	var final_data = json.data
	
	return final_data

func MakeTempPass():
	var size = 16
	var passBytes = PackedByteArray()
	passBytes.resize(size)
	for i in size:
		passBytes[i-1] = randi_range(33,127)
		
	return passBytes.get_string_from_ascii()

#NOTE: This is just to run all of the above functions and make sure they behave
#Removing this in the future.
func TestThisAllOut():
	print('Starting encryption test')
	var Alice = MakeUserCert()
	var alice_pub_key_string = Alice.save_to_string(true)
	print('fake-remote user data generated')
	
	var Bob = MakeUserCert()
	var bob_pub_key_string = Bob.save_to_string(true)
	print('fake-local user data generated')
	
	#NOTE: this was important. CryptoKey doesn't automatically notice
	#a key is only the public key, you MUST set the 2nd parameter to TRUE for that.
	#Much of my earlier issue was that these were not working without that.
	var alice_pub_key = CryptoKey.new()
	alice_pub_key.load_from_string(alice_pub_key_string, true)
	var bob_pub_key = CryptoKey.new()
	bob_pub_key.load_from_string(bob_pub_key_string, true)
	var test_data = {dummy1 = "asdf", dummy2 = 4534, third = "3"}
	
	var packed_data = Package(alice_pub_key, test_data, Bob)
	print(packed_data)
	var unpacked_data = UnPack(bob_pub_key, packed_data, Alice)
	print(unpacked_data)
