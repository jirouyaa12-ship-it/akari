package com.godot.game;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.speech.RecognitionListener;
import android.speech.RecognizerIntent;
import android.speech.SpeechRecognizer;

import java.util.ArrayList;
import java.util.Locale;

public final class AkariSpeechBridge {

    private static Activity activity;
    private static SpeechRecognizer recognizer;

    private static String result = "";
    private static String error = "";
    private static boolean listening = false;

    private AkariSpeechBridge() {
    }

    public static void initialize(Activity hostActivity) {
        activity = hostActivity;
    }

    public static boolean isAvailable() {
        return activity != null
                && SpeechRecognizer.isRecognitionAvailable(activity);
    }

    public static void start() {
        if (activity == null || !isAvailable()) {
            error = "Speech recognition is unavailable.";
            return;
        }

        activity.runOnUiThread(() -> {
            try {
                if (recognizer != null) {
                    recognizer.destroy();
                    recognizer = null;
                }

                result = "";
                error = "";

                recognizer = SpeechRecognizer.createSpeechRecognizer(activity);
                recognizer.setRecognitionListener(new RecognitionListener() {
                    @Override
                    public void onReadyForSpeech(Bundle params) {
                        listening = true;
                    }

                    @Override
                    public void onBeginningOfSpeech() {
                    }

                    @Override
                    public void onRmsChanged(float rmsdB) {
                    }

                    @Override
                    public void onBufferReceived(byte[] buffer) {
                    }

                    @Override
                    public void onEndOfSpeech() {
                    }

                    @Override
                    public void onError(int errorCode) {
                        listening = false;
                        error = "Speech recognition error: " + errorCode;
                    }

                    @Override
                    public void onResults(Bundle results) {
                        listening = false;

                        ArrayList<String> matches =
                                results.getStringArrayList(
                                        SpeechRecognizer.RESULTS_RECOGNITION);

                        if (matches != null && !matches.isEmpty()) {
                            result = matches.get(0);
                        }
                    }

                    @Override
                    public void onPartialResults(Bundle partialResults) {
                    }

                    @Override
                    public void onEvent(int eventType, Bundle params) {
                    }
                });

                Intent intent = new Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH);
                intent.putExtra(
                        RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                        RecognizerIntent.LANGUAGE_MODEL_FREE_FORM);
                intent.putExtra(
                        RecognizerIntent.EXTRA_LANGUAGE,
                        Locale.getDefault().toLanguageTag());
                intent.putExtra(
                        RecognizerIntent.EXTRA_PARTIAL_RESULTS,
                        false);

                recognizer.startListening(intent);

            } catch (Exception e) {
                listening = false;
                error = e.getClass().getSimpleName() + ": " + e.getMessage();
            }
        });
    }

    public static String getResult() {
        String value = result;
        result = "";
        return value;
    }

    public static String getError() {
        String value = error;
        error = "";
        return value;
    }

    public static boolean isListening() {
        return listening;
    }

    public static void stop() {
        if (activity == null) {
            return;
        }

        activity.runOnUiThread(() -> {
            if (recognizer != null) {
                recognizer.stopListening();
                recognizer.destroy();
                recognizer = null;
            }

            listening = false;
        });
    }
}
