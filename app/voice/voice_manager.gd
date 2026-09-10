extends Node

signal recording_started
signal recording_stopped
signal recording_ready(recording: AudioStreamWAV)
signal speech_text_received(text: String)
signal voice_error(message: String)

const RECORD_BUS := "AkariRecord"

var is_recording := false
var microphone_player: AudioStreamPlayer
var record_effect: AudioEffectRecord
var record_bus_index := -1


func _ready() -> void:
    setup_recording()


func setup_recording() -> void:
    record_bus_index = AudioServer.get_bus_index(RECORD_BUS)

    if record_bus_index == -1:
        AudioServer.add_bus()
        record_bus_index = AudioServer.bus_count - 1
        AudioServer.set_bus_name(record_bus_index, RECORD_BUS)

    record_effect = AudioEffectRecord.new()
    record_effect.format = AudioStreamWAV.FORMAT_16_BITS
    AudioServer.add_bus_effect(record_bus_index, record_effect, 0)

    microphone_player = AudioStreamPlayer.new()
    microphone_player.stream = AudioStreamMicrophone.new()
    microphone_player.bus = RECORD_BUS
    add_child(microphone_player)

    print("Akari voice: microphone recording ready")


func start_recording() -> void:
    if is_recording:
        return

    if microphone_player == null or record_effect == null:
        voice_error.emit("Microphone recording is not ready.")
        print("Akari voice error: recording system not ready")
        return

    is_recording = true
    record_effect.set_recording_active(true)
    microphone_player.play()

    recording_started.emit()
    print("Akari voice: recording started")


func stop_recording() -> void:
    if not is_recording:
        return

    is_recording = false

    var recording := record_effect.get_recording()

    record_effect.set_recording_active(false)
    microphone_player.stop()

    recording_stopped.emit()
    print("Akari voice: recording stopped")

    if recording == null:
        voice_error.emit("No audio recording was captured.")
        print("Akari voice error: no recording captured")
        return

    var wav_path := "user://akari_test_recording.wav"
    var save_result := recording.save_to_wav(wav_path)

    if save_result == OK:
        print("Akari voice: WAV saved to ", wav_path)
        print("Akari voice: WAV length = ", recording.get_length(), " seconds")
        print("Akari voice: WAV data bytes = ", recording.data.size())
    else:
        print("Akari voice error: could not save WAV. Error = ", save_result)

    recording_ready.emit(recording)


func submit_speech_text(text: String) -> void:
    text = text.strip_edges()

    if text.is_empty():
        return

    speech_text_received.emit(text)
