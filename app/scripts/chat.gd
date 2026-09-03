extends Node

@onready var message_list: VBoxContainer = $UI/MainPanel/Content/ChatArea/Messages/MessageList
@onready var message_input: LineEdit = $UI/MainPanel/Content/ChatArea/InputRow/MessageInput
@onready var send_button: Button = $UI/MainPanel/Content/ChatArea/InputRow/SendButton

func _ready() -> void:
    print("Akari chat system ready")
    send_button.pressed.connect(_on_send_pressed)
    message_input.text_submitted.connect(_on_message_submitted)

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
