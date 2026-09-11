package com.akari.speech

import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin

class AkariSpeechPlugin(godot: Godot) : GodotPlugin(godot) {

    override fun getPluginName(): String {
        return "AkariSpeech"
    }
}
