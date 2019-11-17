//
//  ViewController.swift
//  PressAndHoldButton
//
//  Created by Jason A Faas on 8/10/19.
//  Copyright © 2019 Jason A Faas. All rights reserved.
//

import UIKit
import Foundation
import Speech

import PressAndHoldButton

class ViewController: UIViewController {

    @IBOutlet weak var toPronounce: UILabel!
    @IBOutlet weak var generalCommentLabel: UILabel!
    @IBOutlet weak var buttonTextUpdate: UIButton!
    @IBOutlet weak var skipThis: UIButton!
    @IBOutlet weak var buttonPinyinToggle: UIButton!
    @IBOutlet weak var toPronouncePinyin: UILabel!
    
    //TODO review all these variables to see if they are actually needed
    var translationValue = 0
    var paragraphValue = 0
    var toPronounceCharacters = ""
    var pronouncedSoFar = ""
    var pinyinOn = true
    var pinyinToggleText: [Bool: String] = [true: "Turn On Pinyin",
                                            false: "True Off Pinyin", ]
    
    
    
/// The speech recogniser used by the controller to record the user's speech.
private let speechRecogniser = SFSpeechRecognizer(locale: Locale(identifier: "zh_Hans_CN"))!

/// The current speech recognition request. Created when the user wants to begin speech recognition.
private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?

/// The current speech recognition task. Created when the user wants to begin speech recognition.
private var recognitionTask: SFSpeechRecognitionTask?

/// The audio engine used to record input from the microphone.
private let audioEngine = AVAudioEngine()
    
//    var delegate: SpeechControllerDelegate?
//
    
    

    var currentTranslation: DbTranslation!
    
    var translation: RecordingForTranslation!
    
    var dbm: DatabaseManagement!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //TODO: Really, no unit tests?
//        if !unitTests() {
//            exit(0)
//        }
        
        // Setup
        
        
        SFSpeechRecognizer.requestAuthorization { [unowned self] authStatus in
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    print("Good to go!")
                } else {
                    print("Transcription permission was declined.")
                }
            }
        }

        
    }
    
//    func getToPronounce() -> (String, String) {
//
//        let nextParagraph = self.fullTranslations[self.translationValue % self.fullTranslations.count].simplifiedChar
//
//        let pinyinStr = self.fullTranslations[self.translationValue % self.fullTranslations.count].pinyinChar
//        if !nextParagraph.contains("。") {
//            self.toPronounceCharacters = nextParagraph
//            return (nextParagraph, pinyinStr)
//        } else {
//            var sentences:[Substring] = nextParagraph.split(separator: "。")
//            var pinyinSentences:[Substring] = pinyinStr.split(separator: ".")
//            let sentence = removeExtraFromString(String(sentences[self.paragraphValue]))
//            let pinyin = removeExtraFromString(String(pinyinSentences[self.paragraphValue]))
//
//            self.toPronounceCharacters = sentence
//            return (sentence, pinyin)
//        }
//    }
    
    @IBAction func pinyinToggle(_ sender: Any) {
        self.pinyinOn = !self.pinyinOn
        self.buttonPinyinToggle.setTitle(self.pinyinToggleText[!self.pinyinOn], for: .normal)
        self.toPronouncePinyin.isHidden = !self.pinyinOn
    }
    
//    func removeExtraNewlineForComparrison(_ str: String) -> String {
//        let retStr = str.replacingOccurrences(of: "\n", with: "")
//        return retStr
//    }
//        func removeExtraFromString(_ str: String) -> String {
//            var retStr = str.replacingOccurrences(of: ".", with: "\n")
//        retStr = retStr.replacingOccurrences(of: "。", with: "\n")
//        retStr = retStr.replacingOccurrences(of: ",", with: "\n")
//        retStr = retStr.replacingOccurrences(of: "，", with: "\n")
//
//        return retStr
//    }
    
    @IBAction func skipThisPress(_ sender: Any) {
        self.skipThis.isEnabled = false
        
//        self.advanceToNextPhrase(letterGrade: "F")
        self.generalCommentLabel.text = "I know you'll get it next time"
    }
    
    
    @IBAction func releaseOutside(_ sender: Any) {
        released()
    }
    
    @IBAction func pressAndHoldBbutton(_ sender: UIButton) {
        released()
    }
    
    // Releasing buttom to translate
    func released() {
        self.buttonTextUpdate.isEnabled = false
        
        generalCommentLabel.text = "\(String(generalCommentLabel.text ?? "hello"))\nProcessing..."
        
        self.stopRecording()
        
//        self.translation.finishRecording()
//
//        self.translation.playback()
//        self.transcribeFile(url: self.translation.getFileURL() as URL)
        
        //TODO: Move isEnabled down to finish translating
        self.buttonTextUpdate.isEnabled = true
    }

    // Holding down to start listening
    @IBAction func holdDownAndListen(_ sender: Any) {
        
        
        generalCommentLabel.text = "Listening..."
        
        do {
            try startRecording()
        } catch {
            //TODO: SWift stacktrace
            print(error)
            print("Could not begin recording")
        }
        
//        do {
//            try self.translation.startRecording()
//        } catch {
//            self.translation.finishRecording()
//            generalCommentLabel.text = "\(String(generalCommentLabel.text ?? "hello")) Did not record."
//        }
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            stopRecording()
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
//    func getFileURL() -> URL {
//    let path = getDocumentsDirectory().appendingPathComponent("recording.m4a")
//    return path as URL
//    }
    
    func startRecording() throws {
        guard speechRecogniser.isAvailable else {
            // Speech recognition is unavailable, so do not attempt to start.
            return
        }
        if let recognitionTask = recognitionTask {
            // We have a recognition task still running, so cancel it before starting a new one.
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            SFSpeechRecognizer.requestAuthorization({ _ in })
            return
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(AVAudioSession.Category.record)
        try audioSession.setMode(AVAudioSession.Mode.measurement)
        try audioSession.setActive(true, options: AVAudioSession.SetActiveOptions.notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Could not create request instance")
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
        
        //TODO: don't think I want to record
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
    }
    
    fileprivate func convertFromAVAudioSessionCategory(_ input: AVAudioSession.Category) -> String {
            return input.rawValue
    }
    
    
    /// Ends the current speech recording session.
    func stopRecording() {
        
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
    
//    func nextTranslation() {
//
//        guard let recognizer = SFSpeechRecognizer() else {
//          return
//        }
//
//        if !recognizer.isAvailable {
//          print("Speech recognition not available")
//          return
//        }
//
//        let request = SFSpeechURLRecognitionRequest(url: getFileURL())
//        request.shouldReportPartialResults = true
//        recognizer.recognitionTask(with: request) {
//          (result, error) in
//          guard error == nil else { print("Error: \(error)"); return }
//          guard let result = result else { print("No result!"); return }
//
//          print(result.bestTranscription.formattedString)
//        }
//
//    }
    
//    fileprivate func transcribeFile() {
//      var url = getFileURL()
//
//      // 1
////      guard let recognizer = SFSpeechRecognizer() else {
////        print("Speech recognition not available for specified locale")
////        return
////      }
//
////      if !recognizer.isAvailable {
////        print("Speech recognition not currently available")
////        return
////      }
//
//      // 2
//      let srRequest = SFSpeechURLRecognitionRequest(url: url)
//
//
//        speechRecognizer.recognitionTask(with: srRequest) { (result, error) in
//            if let error = error {
//            print(error.localizedDescription)
//                print("Url Translation Error")
//            } else {
//                if let result = result {
//                    print(4)
//                    print(result.bestTranscription.formattedString)
//                    if result.isFinal {
//                        print(5)
//                        print(result.bestTranscription.formattedString)
//                        // Store the transcript into the database.
//                    }
//                }
//            }
//        }
//
//
////      // 3
////      recognizer.recognitionTask(with: request) {
////        [unowned self] (result, error) in
////        guard let result = result else {
////
////          print("There was an error transcribing that file")
////            print(error)
////          return
////        }
////
////        // 4
////        if result.isFinal {
////          print(result.bestTranscription.formattedString)
////        }
////      }
//    }
    
//    func preparePlayer() {
//    var error: NSError?
//    do {
//    audioPlayer = try AVAudioPlayer(contentsOf: getFileURL() as URL)
//    } catch let error1 as NSError {
//    error = error1
//    audioPlayer = nil
//    }
//    if let err = error {
//    print("AVAudioPlayer error: \(err.localizedDescription)")
//    } else {
//        audioPlayer.delegate = self as? AVAudioPlayerDelegate
//    audioPlayer.prepareToPlay()
//    audioPlayer.volume = 10.0
//    }
//    }
    
    func updateQuizScreenWithQuizInfo(quizInfo: DbTranslation) {
        self.toPronounce.text = quizInfo.getHanzi()
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
    
//    fileprivate func transcribeFile(url: URL) {
//        // 1
//        //en-US or zh_Hans_CN - https://gist.github.com/jacobbubu/1836273
//        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh_Hans_CN")) else {
//            print("Speech recognition not available for specified locale")
//            return
//        }
//
//        if !recognizer.isAvailable {
//            print("Speech recognition not currently available")
//            return
//        }
//
//        // 2
////        updateUIForTranscriptionInProgress()
//        let request = SFSpeechURLRecognitionRequest(url: url)
//
//        // 3
//        recognizer.recognitionTask(with: request) {
//            [unowned self] (result, error) in
//            guard let result = result else {
//                print("There was an error transcribing that file")
//                return
//            }
//
//            // 4
//            if result.isFinal {
//                var transcribed:String = result.bestTranscription.formattedString
//                print(transcribed)
////
////                transcribed = transcribed.replacingOccurrences(of: "。", with: "")
////                transcribed = transcribed.replacingOccurrences(of: "！", with: "")
////                transcribed = "\(self.pronouncedSoFar)\(transcribed)"
////
////                let compareString = self.removeExtraNewlineForComparrison(self.toPronounceCharacters)
////                if transcribed == compareString {
////                    self.primaryLabel.text = "Great Pronunciation:\n\(transcribed)"
////                    self.skipThis.isEnabled = false
////
////                    self.advanceToNextPhrase(letterGrade: "A")
////                } else if compareString.contains(transcribed) {
////                    self.pronouncedSoFar = "\(self.pronouncedSoFar)\(transcribed)"
////                        self.primaryLabel.text = "\(String(self.primaryLabel.text ?? "hello")) \nKeep Going: \(self.pronouncedSoFar)"
////                } else {
////                    self.primaryLabel.text = "Try again:\n\(transcribed)"
////                    self.pronouncedSoFar = ""
//                    self.skipThis.isEnabled = true
////                }
////
//            }
//        }
//
//        self.dbm.printAllResultsTable()
//    }

}
