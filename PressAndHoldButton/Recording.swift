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

class RecordingForTranslation {
    
    /// The speech recogniser used by the controller to record the user's speech.
    private let speechRecogniser = SFSpeechRecognizer(locale: Locale(identifier: "zh_Hans_CN"))!

    /// The current speech recognition request. Created when the user wants to begin speech recognition.
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?

    /// The current speech recognition task. Created when the user wants to begin speech recognition.
    private var recognitionTask: SFSpeechRecognitionTask?

    /// The audio engine used to record input from the microphone.
    private let audioEngine = AVAudioEngine()
    
    var feedbackLabel: UILabel
    var toPronounceHanzi: UILabel
    var toPronouncePinyin: UILabel
    var buttonTextUpdate: UIButton
    var skipThis: UIButton
    var pinyinToggleButton: UIButton
    
    var dbm: DatabaseManagement
    var currentTranslation: DbTranslation
    
    var pinyinOn = false
    var pinyinToggleText: [Bool: String] = [true: "Turn On Pinyin",
                                            false: "True Off Pinyin", ]
    
    init(feedbackLabel: UILabel,
         toPronounceHanzi: UILabel,
         toPronouncePinyin: UILabel,
         buttonTextUpdate: UIButton,
         skipThis: UIButton,
         pinyinToggleButton: UIButton) {
        self.feedbackLabel = feedbackLabel
        self.buttonTextUpdate = buttonTextUpdate
        self.skipThis = skipThis
        self.toPronounceHanzi = toPronounceHanzi
        self.toPronouncePinyin = toPronouncePinyin
        self.pinyinToggleButton = pinyinToggleButton
        
        self.dbm = DatabaseManagement()
        self.currentTranslation = self.dbm.getRandomRowFromTranslations()
        self.updateUiWithTranslation(currentTranslation)
    }
    
    func pinyinToggle() {
        self.pinyinOn = !self.pinyinOn
        self.pinyinToggleButton.setTitle(self.pinyinToggleText[!self.pinyinOn], for: .normal)
        self.toPronouncePinyin.isHidden = !self.pinyinOn
    }
    
    func skipThisPress() {
        self.advanceToNextPhrase(letterGrade: "F")
        self.feedbackLabel.text = "I know you'll get it next time"
        
        self.skipThis.isEnabled = false
        
        self.dbm.printAllResultsTable()
    }
    
    func perfectResult() {
        self.feedbackLabel.text = "Great Pronunciation:\n\(self.currentTranslation.getHanzi())"
        
        self.advanceToNextPhrase(letterGrade: "A")
        
        self.skipThis.isEnabled = false
        self.dbm.printAllResultsTable()
    }
    
    func updateUiWithTranslation(_ dbTranslation: DbTranslation) {
        self._setHanziField(self.currentTranslation.getHanzi())
        self._setPinyinField(self.currentTranslation.getPinyin())
    }
    
    func _setHanziField(_ hanzi: String) {
        self.toPronounceHanzi.text = hanzi
    }
    
    func _setPinyinField(_ pinyin: String) {
        self.toPronouncePinyin.text = pinyin
    }
    
    func fullStartRecording() {
        self.feedbackLabel.text = "Listening..."
        
        do {
            try self._startRecording()
        } catch {
            self.finishRecording()
            self.feedbackLabel.text = "\(String(self.feedbackLabel.text ?? "hello")) Did not record."

            print("Function: \(#file):\(#line), Error: \(error)")
        }
    }
    
   
    func _startRecording() throws {
        print("Hello 1")
        guard speechRecogniser.isAvailable else {
            throw "Speech recognition is unavailable, so do not attempt to start."
        }
        
        if let recognitionTask = recognitionTask {
            // We have a recognition task still running, so cancel it before starting a new one.
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        print("Hello 2")
        
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
                print(result.bestTranscription.formattedString)
//                self.delegate.speechController(self, didRecogniseText: result.bestTranscription.formattedString)
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
        self.buttonTextUpdate.isEnabled = false
        
        self.feedbackLabel.text = "\(String(self.feedbackLabel.text ?? "hello"))\nProcessing..."
        
        self.finishRecording()
        
//        do {
//        } catch {
//            print("Function: \(#file):\(#line), Error: \(error)")
//        }
        
        self.buttonTextUpdate.isEnabled = true
    }
    
    func finishRecording() {
//        self.audioEngine.inputNode.removeTap(onBus: 0)
        
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
    
    // TODO: Move this somewhere?
    fileprivate func transcribeFile(url: URL) {
        
        //en-US or zh_Hans_CN - https://gist.github.com/jacobbubu/1836273
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh_Hans_CN")) else {
            print("Speech recognition not available for specified locale")
            return
        }
        
        if !recognizer.isAvailable {
            print("Speech recognition not currently available")
            return
        }
        
        // updateUIForTranscriptionInProgress()
        let request = SFSpeechURLRecognitionRequest(url: url)
        
        recognizer.recognitionTask(with: request) {
            [unowned self] (result, error) in
            guard let result = result else {
                print("Function: \(#file):\(#line), Error: There was an error transcribing that file")
                return
            }
            
            if result.isFinal {
                let transcribed:String = result.bestTranscription.formattedString
                print("iOS Transcription:\(transcribed):")
                
                let transribedForCompare = self.cleanUpTranscribed(transcribed)
                
                self.feedbackLabel.text = transribedForCompare
                
//

//                transcribed = "\(self.pronouncedSoFar)\(transcribed)"
//
//                let compareString = self.removeExtraNewlineForComparrison(self.toPronounceCharacters)
                if transribedForCompare == self.cleanUpTranscribed(self.currentTranslation.getHanzi()) {
                    self.perfectResult()
//                } else if compareString.contains(transcribed) {
//                    self.pronouncedSoFar = "\(self.pronouncedSoFar)\(transcribed)"
//                        self.primaryLabel.text = "\(String(self.primaryLabel.text ?? "hello")) \nKeep Going: \(self.pronouncedSoFar)"
//                } else {
//                    self.primaryLabel.text = "Try again:\n\(transcribed)"
//                    self.pronouncedSoFar = ""
                    
//                }
//
                } else {
                    self.skipThis.isEnabled = true
                }
            }
        }
        
    }
    
    func cleanUpTranscribed(_ transcribed: String) -> String {
        var returnMe = transcribed
        let charsToRemove = ["。", "！", "？", " ", "，"]
        
        for charToRemove in charsToRemove {
            returnMe = returnMe.replacingOccurrences(of: charToRemove, with: "")
        }
        
        return returnMe
    }
    
    
    func updateQuizScreenWithQuizInfo(quizInfo: DbTranslation) {
        self.toPronounceHanzi.text = quizInfo.getHanzi()
        self.toPronouncePinyin.text = quizInfo.getPinyin()
    }

    func advanceToNextPhrase(letterGrade: String) {
        // log info
        self.dbm.logResult(letterGrade: letterGrade,
                           quizInfo: self.currentTranslation,
                           pinyinOn: self.pinyinOn)
        
        self.currentTranslation = self.dbm.getRandomRowFromTranslations()
        
        self.updateQuizScreenWithQuizInfo(quizInfo: self.currentTranslation)
        
        

//        let currentParagraph = self.fullTranslations[self.translationValue % self.fullTranslations.count].simplifiedChar
//        let pinyinOn = self.pinyinOn
//        let currentHanzi = self.fullTranslations[self.translationValue % self.fullTranslations.count].simplifiedChar
//        if !currentParagraph.contains("。") {
//
//            self.dbm.logResult(letterGrade: letterGrade,
//                               hanzi: currentHanzi,
//                               pinyinOn: pinyinOn)
//
//            self.translationValue += 1
//        } else {
//            let sentences:[Substring] = currentParagraph.split(separator: "。")
//            self.paragraphValue += 1
//            if sentences.count == self.paragraphValue {
//                self.dbm.logResult(letterGrade: letterGrade,
//                                   hanzi: currentHanzi,
//                                   pinyinOn: pinyinOn)
//
//                self.translationValue += 1
//                self.paragraphValue = 0
//            }
//        }
//
//        let (characters, pinyin) = self.getToPronounce()
//        self.toPronounce.text = characters
//        self.toPronouncePinyin.text = pinyin
//
//        self.pronouncedSoFar = ""
    }
    
    func runUnitTests() throws {
        try self.dbm.runUnitTests()
    }
}
