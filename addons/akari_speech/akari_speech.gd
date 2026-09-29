@tool
extends EditorPlugin

var export_plugin: AndroidExportPlugin

func _enter_tree() -> void:
	export_plugin = AndroidExportPlugin.new()
	add_export_plugin(export_plugin)

func _exit_tree() -> void:
	remove_export_plugin(export_plugin)
	export_plugin = null


class AndroidExportPlugin extends EditorExportPlugin:
	var _plugin_name := "AkariSpeech"

	func _supports_platform(platform) -> bool:
		return platform is EditorExportPlatformAndroid

	func _get_android_libraries(platform, debug) -> PackedStringArray:
        return PackedStringArray([
            "akari_speech/bin/release/AkariSpeech-release.aar"
        ])
			return PackedStringArray([
			"akari_speech/bin/release/AkariSpeech-release.aar"
		])

	func _get_android_dependencies(platform, debug) -> PackedStringArray:
		return PackedStringArray([])

	func _get_name() -> String:
		return _plugin_name
