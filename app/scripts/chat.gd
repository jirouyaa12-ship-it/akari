extends Node
var voice_manager

@onready var message_list: VBoxContainer = $UI/MainPanel/Content/ChatArea/Messages/MessageList
@onready var message_input: LineEdit = $UI/MainPanel/Content/ChatArea/InputRow/MessageInput
@onready var send_button: Button = $UI/MainPanel/Content/ChatArea/InputRow/SendButton
@onready var mic_button: Button = $UI/MainPanel/Content/ChatArea/InputRow/MicButton

func _ready() -> void:
	voice_manager = preload("res://app/voice/voice_manager.gd").new()
	add_child(voice_manager)
	voice_manager.recording_started.connect(_on_recording_started)
	voice_manager.recording_stopped.connect(_on_recording_stopped)
	voice_manager.speech_text_received.connect(_on_speech_text_received)
	voice_manager.voice_error.connect(_on_voice_error)

	print("Akari chat system ready")
	send_button.pressed.connect(_on_send_pressed)
	mic_button.pressed.connect(_on_mic_pressed)
	message_input.text_submitted.connect(_on_message_submitted)

func _on_mic_pressed() -> void:
	if voice_manager.is_recording:
		voice_manager.stop_recording()
	else:
		voice_manager.start_recording()


func _on_recording_started() -> void:
	mic_button.text = "Stop"
	print("Akari voice: recording started")


func _on_recording_stopped() -> void:
	mic_button.text = "Mic"
	print("Akari voice: recording stopped")


func _on_speech_text_received(text: String) -> void:
	send_message(text)


func _on_voice_error(message: String) -> void:
	print("Akari voice error: ", message)


func _on_send_pressed() -> void:
	send_message(message_input.text)

func _on_message_submitted(_text: String) -> void:
	send_message(message_input.text)

func send_message(message: String) -> void:
	message = message.strip_edges()

	if message.is_empty():
		return

	add_message("You: " + message)

	var response := get_response(message)
	add_message("Akari: " + response)
	voice_manager.speak_response(response)

	message_input.clear()
	message_input.grab_focus()

func add_message(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_list.add_child(label)

func get_response(message: String) -> String:
	var lower_message := message.to_lower()

	if lower_message in ["hi", "hello", "hey", "hii", "hiii"]:
		return "Hii! 🌸 It's nice to hear from you!"

	if "how are you" in lower_message:
		return "I'm doing great! I'm happy we're finally chatting properly. ✨"

	if "akari" in lower_message:
		return "Yep! Akari is here! 💕"

	return "Hehe, I'm listening! Tell me more. 🌸"
