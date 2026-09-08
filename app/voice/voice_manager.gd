extends Node

signal recording_started
signal recording_stopped
signal speech_text_received(text: String)
signal voice_error(message: String)

var is_recording := false

func start_recording() -> void:
    if is_recording:
        return
    is_recording = true
    recording_started.emit()
    print("Akari voice: recording started")

func stop_recording() -> void:
    if not is_recording:
        return
    is_recording = false
    recording_stopped.emit()
    print("Akari voice: recording stopped")

func submit_speech_text(text: String) -> void:
    text = text.strip_edges()
    if text.is_empty():
        return
    speech_text_received.emit(text)
