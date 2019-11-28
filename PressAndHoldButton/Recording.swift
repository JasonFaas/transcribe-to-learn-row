//
//  Recording.swift
//  PressAndHoldButton
//
//  Created by Jason A Faas on 11/27/19.
//  Copyright © 2019 Jason A Faas. All rights reserved.
//

import Foundation

import Speech

class Recording {
    
    /// The speech recogniser used by the controller to record the user's speech.
    private let speechRecogniser = SFSpeechRecognizer(locale: Locale(identifier: "zh_Hans_CN"))!

    /// The current speech recognition request. Created when the user wants to begin speech recognition.
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?

    /// The current speech recognition task. Created when the user wants to begin speech recognition.
    private var recognitionTask: SFSpeechRecognitionTask?

    /// The audio engine used to record input from the microphone.
    private let audioEngine = AVAudioEngine()
    
    var translation: Transcription
    
    init(translation: Transcription) {
        self.translation = translation
    }
    
    
    
    // TODO: Add better stack trace info
    func _startRecording() throws {
        guard speechRecogniser.isAvailable else {
            throw "Speech recognition is unavailable, so do not attempt to start."
        }
        
        if let recognitionTask = recognitionTask {
            // We have a recognition task still running, so cancel it before starting a new one.
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            SFSpeechRecognizer.requestAuthorization({ _ in })
            throw "SFSpeechRecognizer not authorized"
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(AVAudioSession.Category.record)
        try audioSession.setMode(AVAudioSession.Mode.measurement)
        try audioSession.setActive(true, options: AVAudioSession.SetActiveOptions.notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        guard let recognitionRequest = recognitionRequest else {
            throw "Could not create request instance"
        }
        
        recognitionTask = speechRecogniser.recognitionTask(with: recognitionRequest) { [unowned self] result, error in
            if let result = result {
                let transcribed = result.bestTranscription.formattedString
                print(transcribed)
                self.translation.mostRecentTranscription(transcribed)
                
               

            }
            
            if result?.isFinal ?? (error != nil) {
                if let result = result {
                    print("IS FINAL!!!")
                    print(result.bestTranscription.formattedString)
                }
                inputNode.removeTap(onBus: 0)
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
    }
    

        
    func _finishRecording() {
        self.audioEngine.stop()
        self.recognitionRequest?.endAudio()
        
        if let recognitionTask = recognitionTask {
            // We have a recognition task still running, so cancel it before starting a new one.
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
//        if let recognitionTask = recognitionTask {
//            // We have a recognition task still running, so cancel it before starting a new one.
//            recognitionTask.cancel()
//        }
    }
}
