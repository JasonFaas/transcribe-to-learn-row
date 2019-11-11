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
    
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var audioPlayer:AVAudioPlayer!
    
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
    
    func preparePlayer() throws {
        var error: NSError?
        do {
            self.audioPlayer = try AVAudioPlayer(contentsOf: getFileURL() as URL)
            
        } catch let error1 as NSError {
            error = error1
            self.audioPlayer = nil
        }
        if let err = error {
            feedbackLabel.text = "\(String(feedbackLabel.text ?? "hello")) Error loading audio to playback."
            print("AVAudioPlayer error: \(err.localizedDescription)")
        } else {
            self.audioPlayer.delegate = self as? AVAudioPlayerDelegate
            self.audioPlayer.prepareToPlay()
            
            self.audioPlayer.volume = 10.0
            
            let maxTime:Int = 20
            if Int(self.audioPlayer.duration) > maxTime {
                feedbackLabel.text = "\(String(feedbackLabel.text ?? "hello"))\nDuration longer than \(maxTime) seconds cannot be transcribed (\(Int(self.audioPlayer.duration)))..."
                throw TranscribtionError.durationTooLong(duration: Int(self.audioPlayer.duration))
            }
            
        }
    }
    
    func fullStartRecording() {
        self.feedbackLabel.text = "Listening..."
        
        do {
            try self._startRecording()
        } catch {
            self.finishRecording()
            self.feedbackLabel.text = "\(String(self.feedbackLabel.text ?? "hello")) Did not record."
        }
    }
    
    
    func _startRecording() throws {
        let audioFilename = _getDocumentsDirectory().appendingPathComponent("recording.m4a")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        self.audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
        self.audioRecorder.delegate = self as? AVAudioRecorderDelegate
        self.audioRecorder.record()
    }
    
    func fullFinishRecording() {
        self.buttonTextUpdate.isEnabled = false
        
        self.feedbackLabel.text = "\(String(self.feedbackLabel.text ?? "hello"))\nProcessing..."
        
        self.finishRecording()
        
        do {
            try preparePlayer()
            
            self.audioPlayer.play()
            
            self.transcribeFile(url: self.getFileURL() as URL)
        } catch {
            print("Function: \(#file):\(#line), Error: \(error)")
        }
        
        self.buttonTextUpdate.isEnabled = true
    }
    
    func finishRecording() {
        self.audioRecorder.stop()
        self.audioRecorder = nil
    }
    
    func _getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func getFileURL() -> URL {
        let path = _getDocumentsDirectory().appendingPathComponent("recording.m4a")
        return path as URL
    }
    
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
    
    func setupRecordingSession() {
        do {
            self.recordingSession = AVAudioSession.sharedInstance()
            try self.recordingSession.setCategory(.playAndRecord, mode: .default)
            try self.recordingSession.setActive(true)
            self.recordingSession.requestRecordPermission() {
                [unowned self] allowed in DispatchQueue.main.async {
                    if allowed {
                        print("Recording setup complete")
                    } else {
                        print("Function: \(#file):\(#line), Error: Failed to Record Level 1")
                        exit(0)
                    }
                }
            }
        } catch {
            print("Function: \(#file):\(#line), Error: Failed to Record Level 2")
            exit(0)
        }
    }
    
    func runUnitTests() throws {
        try self.dbm.runUnitTests()
    }
}
