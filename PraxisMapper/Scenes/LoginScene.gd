extends Node2D

@onready var txtUsername: LineEdit = $txtUsername
@onready var txtPassword: LineEdit = $txtPassword
@onready var txtServer: LineEdit = $txtServer
@onready var lblError: Label = $lblError
@onready var request: HTTPRequest = $HTTPRequest
@onready var timer: Timer = $Timer
@onready var api2: PraxisEndpoints = $PraxisEndpoints
var passkey = "UniquePasskeyGoesHere"

# Called when the node enters the scene tree for the first time.
func _ready():
	var lastData = FileAccess.open_encrypted_with_pass("user://savedData.access", FileAccess.READ, passkey)
	if (lastData != null):
		var data = lastData.get_as_text().split("|")
		if (data[2].ends_with('/')):
			data[2] = data[2].substr(0, data[2].length() - 2)
		lastData.close()
		txtUsername.text = data[0]
		txtPassword.text = data[1]
		txtServer.text = data[2]
		
		_on_btn_login_pressed()

func _on_btn_login_pressed():
	print("login pressed")
	lblError.text = "Logging in...."
	
	PraxisServer.serverURL = txtServer.text
	api2.response_data.connect(login_completed)
	api2.Login('', txtUsername.text, txtPassword.text)

func login_completed(result):
	request.request_completed.disconnect(login_completed)
	if (typeof(result) == TYPE_STRING and result == "ERROR"):
		lblError.text = "Error logging in"
		return
		
	var json = JSON.new()
	json.parse(result.get_string_from_utf8())
	var data = json.get_data()
	#if successful, save name/pwd/server to file to load as auto-login next time.
	var authData = FileAccess.open_encrypted_with_pass("user://savedData.access", FileAccess.WRITE, "passkeyGoesHere")
	authData.store_string(txtUsername.text + "|" + txtPassword.text + "|" +txtServer.text)
	authData.close()
	
	PraxisServer.username = txtUsername.text
	PraxisServer.password = txtPassword.text
	PraxisServer.serverURL = txtServer.text
	PraxisServer.authKey = data.authToken
	
	get_tree().change_scene_to_file("res://Scenes/OverheadView.tscn")

func _on_btn_create_acct_pressed():
	print("create pressed")
	lblError.text = "Creating account...."
	PraxisServer.serverURL = txtServer.text
	api2.response_data.connect(createCompleted)
	api2.CreateAccount(txtUsername.text, txtPassword.text)

func createCompleted(result):
	request.request_completed.disconnect(createCompleted)
	if (typeof(result) == TYPE_STRING and result == "ERROR"):
		lblError.text = "Account creation failed."
		return
		
	var json = JSON.new()
	json.parse(result.get_string_from_utf8())
	var data = json.get_data()
	if (data == true): 
		_on_btn_login_pressed()
	else:
		lblError.text = "Account creation failed."
