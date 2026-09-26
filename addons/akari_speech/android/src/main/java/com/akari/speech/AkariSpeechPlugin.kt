package com.akari.speech

import android.content.Intent
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.UsedByGodot
import java.util.Locale

class AkariSpeechPlugin(godot: Godot) : GodotPlugin(godot) {

    private var recognizer: SpeechRecognizer? = null
    private var result: String = ""
    private var error: String = ""
    private var listening: Boolean = false

    override fun getPluginName(): String {
        return "AkariSpeech"
    }

    @UsedByGodot
    fun isAvailable(): Boolean {
        val activity = getActivity() ?: return false
        return SpeechRecognizer.isRecognitionAvailable(activity)
    }

    @UsedByGodot
    fun startListening() {
        val activity = getActivity()

        if (activity == null) {
            error = "Android activity is unavailable."
            return
        }

        if (!SpeechRecognizer.isRecognitionAvailable(activity)) {
            error = "Speech recognition is unavailable."
            return
        }

        activity.runOnUiThread {
            try {
                recognizer?.destroy()
                recognizer = null

                result = ""
                error = ""
                listening = false

                recognizer = SpeechRecognizer.createSpeechRecognizer(activity)

                recognizer?.setRecognitionListener(object : RecognitionListener {
                    override fun onReadyForSpeech(params: Bundle?) {
                        listening = true
                    }

                    override fun onBeginningOfSpeech() {
                    }

                    override fun onRmsChanged(rmsdB: Float) {
                    }

                    override fun onBufferReceived(buffer: ByteArray?) {
                    }

                    override fun onEndOfSpeech() {
                        listening = false
                    }

                    override fun onError(errorCode: Int) {
                        listening = false
                        error = "Speech recognition error: $errorCode"
                    }

                    override fun onResults(results: Bundle?) {
                        listening = false

                        val matches = results?.getStringArrayList(
                            SpeechRecognizer.RESULTS_RECOGNITION
                        )

                        if (!matches.isNullOrEmpty()) {
                            result = matches[0]
                        }
                    }

                    override fun onPartialResults(partialResults: Bundle?) {
                    }

                    override fun onEvent(eventType: Int, params: Bundle?) {
                    }
                })

                val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                    putExtra(
                        RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                        RecognizerIntent.LANGUAGE_MODEL_FREE_FORM
                    )
                    putExtra(
                        RecognizerIntent.EXTRA_LANGUAGE,
                        Locale.getDefault().toLanguageTag()
                    )
                    putExtra(
                        RecognizerIntent.EXTRA_PARTIAL_RESULTS,
                        false
                    )
                }

                recognizer?.startListening(intent)

            } catch (exception: Exception) {
                listening = false
                error = "${exception.javaClass.simpleName}: ${exception.message}"
            }
        }
    }

    @UsedByGodot
    fun getResult(): String {
        val value = result
        result = ""
        return value
    }

    @UsedByGodot
    fun getError(): String {
        val value = error
        error = ""
        return value
    }

    @UsedByGodot
    fun isListening(): Boolean {
        return listening
    }

    @UsedByGodot
    fun stopListening() {
        val activity = getActivity() ?: return

        activity.runOnUiThread {
            try {
                recognizer?.stopListening()
                recognizer?.destroy()
            } catch (_: Exception) {
            }

            recognizer = null
            listening = false
        }
    }
}
