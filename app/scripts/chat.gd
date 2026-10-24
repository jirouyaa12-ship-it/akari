extends Node

const CHAT_ENDPOINT := "https://akari-backend-liard.vercel.app/api/chat"
const CONFIG_PATH := "user://akari_config.cfg"

var voice_manager
var http_request: HTTPRequest
var access_token := ""
var waiting_for_reply := false
var settings_dialog: AcceptDialog
var token_input: LineEdit

@onready var message_list: VBoxContainer = $UI/MainPanel/Content/ChatArea/Messages/MessageList
@onready var message_input: LineEdit = $UI/MainPanel/Content/ChatArea/InputRow/MessageInput
@onready var send_button: Button = $UI/MainPanel/Content/ChatArea/InputRow/SendButton
@onready var mic_button: Button = $UI/MainPanel/Content/ChatArea/InputRow/MicButton
@onready var settings_button: Button = $UI/MainPanel/Content/Header/HeaderRow/SettingsButton

func _ready() -> void:
    _load_config()
    _create_settings_dialog()

    http_request = HTTPRequest.new()
    http_request.timeout = 35.0
    add_child(http_request)
    http_request.request_completed.connect(_on_chat_request_completed)

    voice_manager = preload("res://app/voice/voice_manager.gd").new()
    add_child(voice_manager)
    voice_manager.recording_started.connect(_on_recording_started)
    voice_manager.recording_stopped.connect(_on_recording_stopped)
    voice_manager.speech_text_received.connect(_on_speech_text_received)
    voice_manager.voice_error.connect(_on_voice_error)

    print("Akari chat system ready")
    send_button.pressed.connect(_on_send_pressed)
    mic_button.pressed.connect(_on_mic_pressed)
    settings_button.pressed.connect(_on_settings_pressed)
    message_input.text_submitted.connect(_on_message_submitted)

func _load_config() -> void:
    var config := ConfigFile.new()
    if config.load(CONFIG_PATH) == OK:
        access_token = str(config.get_value("backend", "access_token", ""))

func _create_settings_dialog() -> void:
    settings_dialog = AcceptDialog.new()
    settings_dialog.title = "Akari Connection Settings"
    settings_dialog.dialog_text = "Enter your Akari access token. Keep it private."
    settings_dialog.ok_button_text = "Save Token"
    add_child(settings_dialog)

    token_input = LineEdit.new()
    token_input.placeholder_text = "Akari access token"
    token_input.secret = true
    token_input.clear_button_enabled = true
    settings_dialog.add_child(token_input)
    settings_dialog.confirmed.connect(_on_save_token_pressed)

func _on_settings_pressed() -> void:
    token_input.text = access_token
    settings_dialog.popup_centered(Vector2i(520, 220))

func _on_save_token_pressed() -> void:
    access_token = token_input.text.strip_edges()
    var config := ConfigFile.new()
    config.set_value("backend", "access_token", access_token)
    if config.save(CONFIG_PATH) == OK:
        add_message("Akari: Access token saved on this device.")
    else:
        add_message("Akari: I couldn't save the token.")

func _on_mic_pressed() -> void:
    if voice_manager.is_recording:
        voice_manager.stop_recording()
    else:
        voice_manager.start_recording()

func _on_recording_started() -> void:
    mic_button.text = "Stop"

func _on_recording_stopped() -> void:
    mic_button.text = "Mic"

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
    if waiting_for_reply:
        add_message("Akari: Please wait for my current reply.")
        return
    if access_token.is_empty():
        add_message("Akari: Open Settings and save your access token first.")
        _on_settings_pressed()
        return

    add_message("You: " + message)
    message_input.clear()

    var headers := PackedStringArray([
        "Content-Type: application/json",
        "Authorization: Bearer " + access_token
    ])
    var payload := JSON.stringify({"message": message, "model": "gpt-6-luna"})

    waiting_for_reply = true
    send_button.disabled = true
    var error := http_request.request(
        CHAT_ENDPOINT,
        headers,
        HTTPClient.METHOD_POST,
        payload
    )
    if error != OK:
        waiting_for_reply = false
        send_button.disabled = false
        add_message("Akari: Couldn't start the network request.")

func _on_chat_request_completed(
    result: int,
    response_code: int,
    _headers: PackedStringArray,
    body: PackedByteArray
) -> void:
    waiting_for_reply = false
    send_button.disabled = false

    if result != HTTPRequest.RESULT_SUCCESS:
        add_message("Akari: Couldn't reach the server. Check your internet.")
        return

    var parsed = JSON.parse_string(body.get_string_from_utf8())

    if response_code == 401:
        add_message("Akari: Access token rejected. Check Settings.")
        return

    if response_code < 200 or response_code >= 300:
        var error_message := "AI service error (HTTP " + str(response_code) + ")."
        if parsed is Dictionary and parsed.has("error"):
            error_message = str(parsed["error"])
        add_message("Akari: " + error_message)
        return

    if not parsed is Dictionary or not parsed.has("reply"):
        add_message("Akari: The server returned an unexpected response.")
        return

    var response := str(parsed["reply"]).strip_edges()
    if response.is_empty():
        add_message("Akari: I received an empty reply.")
        return

    add_message("Akari: " + response)
    voice_manager.speak_response(response)

func add_message(text: String) -> void:
    var label := Label.new()
    label.text = text
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    message_list.add_child(label)