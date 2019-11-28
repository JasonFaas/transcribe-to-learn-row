//
//  Recording.swift
//  PressAndHoldButton
//
//  Created by Jason A Faas on 9/7/19.
//  Copyright © 2019 Jason A Faas. All rights reserved.
//

import Foundation

import UIKit
import Speech

class MainManagement {
    
    /// The speech recogniser used by the controller to record the user's speech.
    private let speechRecogniser = SFSpeechRecognizer(locale: Locale(identifier: "zh_Hans_CN"))!

    /// The current speech recognition request. Created when the user wants to begin speech recognition.
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?

    /// The current speech recognition task. Created when the user wants to begin speech recognition.
    private var recognitionTask: SFSpeechRecognitionTask?

    /// The audio engine used to record input from the microphone.
    private let audioEngine = AVAudioEngine()
    
    
    var dbm: DatabaseManagement
    var currentTranslation: DbTranslation
    
    var updateUi: UiUpdate
    
    var lastTranslation:String = ""
    
    init(feedbackLabel: UILabel,
         toPronounceHanzi: UILabel,
         toPronouncePinyin: UILabel,
         buttonTextUpdate: UIButton,
         skipThis: UIButton,
         pinyinToggleButton: UIButton) {
        
        self.dbm = DatabaseManagement()
        self.currentTranslation = self.dbm.getEasiestUnansweredRowFromTranslations(-1)
        
        self.updateUi = UiUpdate(feedbackLabel: feedbackLabel,
                                 toPronounceHanzi: toPronounceHanzi,
                                 toPronouncePinyin: toPronouncePinyin,
                                 buttonTextUpdate: buttonTextUpdate,
                                 skipThis: skipThis,
                                 pinyinToggleButton: pinyinToggleButton)
        
        self.updateUi.updateUiWithTranslation(currentTranslation)
    }
    
    func skipThisPress() {
        self.advanceToNextPhrase(letterGrade: "F")
        self.updateUi.updateFeedbackText("I know you'll get it next time")
        
        self.updateUi.disableSkip()
        
        self.dbm.printAllResultsTable()
    }
    
    func pinyinToggle() {
        self.updateUi.pinyinToggle()
    }
    
    func perfectResult() {
        self.updateUi.updateFeedbackText("Great Pronunciation:\n\(self.currentTranslation.getHanzi())")
        
        self.advanceToNextPhrase(letterGrade: "A")
        
        self.updateUi.disableSkip()
        self.dbm.printAllResultsTable()
    }
    
    func fullStartRecording() {
        self.updateUi.disableRecording()
        self.updateUi.updateFeedbackText("Listening...")
        
        do {
            try self._startRecording()
        } catch {
            self.finishRecording()
            self.updateUi.addToFeedbackText(" Did not record.")

            print("Function: \(#file):\(#line), Error: \(error)")
        }
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
        
        
        print("Hello 3")
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        guard let recognitionRequest = recognitionRequest else {
            throw "Could not create request instance"
        }
        
        recognitionTask = speechRecogniser.recognitionTask(with: recognitionRequest) { [unowned self] result, error in
            if let result = result {
                let transcribed = result.bestTranscription.formattedString
                print(transcribed)
                self.lastTranslation = self.cleanUpTranscribed(transcribed)
                
                self.updateUi.updateFeedbackText("Listening... \n\(self.lastTranslation)")

            }
            
            if result?.isFinal ?? (error != nil) {
                if let result = result {
                    print("IS FINAL!!!")
                    print(result.bestTranscription.formattedString)
                }
                inputNode.removeTap(onBus: 0)
            }
        }
        
        print("Hello 4")
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        
        
        print("Hello 5")
        audioEngine.prepare()
        try audioEngine.start()
    }
    
    func fullFinishRecording() {
        self.updateUi.addToFeedbackText("\nComplete")
        
        self.finishRecording()

        if self.lastTranslation == self.cleanUpTranscribed(self.currentTranslation.getHanzi()) {
            self.perfectResult()
        } else {
            self.updateUi.enableSkip()
        }
        
        self.updateUi.enableRecording()
    }
    
    func finishRecording() {
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
    
    func cleanUpTranscribed(_ transcribed: String) -> String {
        var returnMe = transcribed
        let charsToRemove = ["。", "！", "？", " ", "，"]
        
        for charToRemove in charsToRemove {
            returnMe = returnMe.replacingOccurrences(of: charToRemove, with: "")
        }
        
        return returnMe
    }
    

    func advanceToNextPhrase(letterGrade: String) {
        // log info
        self.dbm.logResult(letterGrade: letterGrade,
                           quizInfo: self.currentTranslation,
                           pinyinOn: self.updateUi.pinyinOn)
        
        self.currentTranslation = self.dbm.getEasiestUnansweredRowFromTranslations(self.currentTranslation.getId())
        
        self.updateUi.updateQuizScreenWithQuizInfo(quizInfo: self.currentTranslation)
    }
    
    func runUnitTests() throws {
        try self.dbm.runUnitTests()
    }
}
