extends CanvasLayer

#login elements
@onready var login_email = $enter/box/email
@onready var login_password = $enter/box/password
@onready var login_btn_send = $enter/box/send
@onready var login_btn_register = $enter/box/register

#register elements
@onready var register_poppup = $enter/register_popup
@onready var register_name = $enter/register_popup/box/name
@onready var register_email = $enter/register_popup/box/email
@onready var register_password = $enter/register_popup/box/password
@onready var register_btn_send = $enter/register_popup/box/send
@onready var register_btn_register = $enter/register_popup/box/register

#info elemetns
@onready var info_poppup = $enter/info_popup
@onready var label_info = $enter/info_popup/info

func _ready():
	login_btn_register.connect("button_down", open_register_poppup)
	register_btn_send.connect("button_down", send_register)
	login_btn_send.connect("button_down", login)

func open_register_poppup():
	register_poppup.popup()

func send_register():
	register_poppup.hide()
	var response = await Network.register_user(register_email.text, register_password.text, register_name.text)
	if response:
		label_info.text = response
		info_poppup.popup()
		return
	label_info.text = "REGISTERED!"
	info_poppup.popup()
	login_email.text = register_email.text
	login_password.text = register_password.text

func login():
	var response = await Network.login_user(login_email.text, login_password.text)
	if response:
		label_info.text = response
		info_poppup.popup()
	else:
		get_tree().change_scene_to_file("res://scenes/lobby.tscn")
