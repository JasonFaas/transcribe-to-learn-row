//
//  ViewController.swift
//  PressAndHoldButton
//
//  Created by Jason A Faas on 8/10/19.
//  Copyright © 2019 Jason A Faas. All rights reserved.
//

import UIKit
import Speech

import PressAndHoldButton

class ViewController: UIViewController {

    @IBOutlet weak var toPronounce: UILabel!
    @IBOutlet weak var primaryLabel: UILabel!
    @IBOutlet weak var buttonTextUpdate: UIButton!
    @IBOutlet weak var skipThis: UIButton!
    @IBOutlet weak var buttonPinyinToggle: UIButton!
    
    let fullTranslations:Array<TranslationInfo> = TranslationInfo().getAllTranslations()
    var translationValue = 0
    var paragraphValue = 0
    var toPronounceCharacters = ""
    var pronouncedSoFar = ""
    var pinyinOn = true
    var pinyinToggleText: [Bool: String] = [true: "Turn On Pinyin",
                                            false: "True Off Pinyin", ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !unitTests() {
            exit(0)
        }
        // Do any additional setup after loading the view.
        
        //setup Recorder
        self.setupView()
        
        self.translationValue = Int.random(in: 0 ..< fullTranslations.count)
//        self.translationValue = 7
        self.toPronounce.text = getToPronounce()
    }
    
    func getToPronounce() -> String {
        
        let nextParagraph = self.fullTranslations[self.translationValue % self.fullTranslations.count].simplifiedChar
        
        let pinyinStr = self.fullTranslations[self.translationValue % self.fullTranslations.count].pinyinChar
        if !nextParagraph.contains("。") {
            self.toPronounceCharacters = nextParagraph
            return String("\(nextParagraph)\n\(pinyinStr)")
        } else {
            var sentences:[Substring] = nextParagraph.split(separator: "。")
            var pinyinSentences:[Substring] = pinyinStr.split(separator: ".")
            let sentence = removeExtraFromString(String(sentences[self.paragraphValue]))
            let pinyin = removeExtraFromString(String(pinyinSentences[self.paragraphValue]))
            
            self.toPronounceCharacters = sentence
            return String("\(sentence)\n\(pinyin)")
        }
    }
    
    @IBAction func pinyinToggle(_ sender: Any) {
        self.pinyinOn = !self.pinyinOn
        self.buttonPinyinToggle.setTitle(self.pinyinToggleText[self.pinyinOn], for: .normal)
    }
    
    func removeExtraNewlineForComparrison(_ str: String) -> String {
        let retStr = str.replacingOccurrences(of: "\n", with: "")
        return retStr
    }
        func removeExtraFromString(_ str: String) -> String {
            var retStr = str.replacingOccurrences(of: ".", with: "\n")
        retStr = retStr.replacingOccurrences(of: "。", with: "\n")
        retStr = retStr.replacingOccurrences(of: ",", with: "\n")
        retStr = retStr.replacingOccurrences(of: "，", with: "\n")
        
        return retStr
    }
    
    func unitTests() -> Bool {
        
        print(fullTranslations.count)
        assert(fullTranslations[7].simplifiedChar.contains("。"))
        print(fullTranslations[7].simplifiedChar.split(separator: "。")[3])
        assert(fullTranslations[7].simplifiedChar.split(separator: "。").count == 4)
        
        
        return true
    }
    
    @IBAction func skipThisPress(_ sender: Any) {
        self.skipThis.isEnabled = false
        
        self.primaryLabel.text = "I know you'll get it next time"
        
        self.advanceToNextPhrase()
    }
    
    
    @IBAction func releaseOutside(_ sender: Any) {
        released()
    }
    
    @IBAction func pressAndHoldBbutton(_ sender: UIButton) {
        released()
    }
    
    func released() {
        self.buttonTextUpdate.isEnabled = false
        
        primaryLabel.text = "\(String(primaryLabel.text ?? "hello"))\nProcessing..."
        
        finishRecording(success: true)
        
        do {
            try preparePlayer()
            audioPlayer.play()
            transcribeFile(url: getFileURL() as URL)
        } catch {
            
        }
        self.buttonTextUpdate.isEnabled = true
    }
    
    func preparePlayer() throws {
        var error: NSError?
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: getFileURL() as URL)
        } catch let error1 as NSError {
            error = error1
            audioPlayer = nil
        }
        if let err = error {
            primaryLabel.text = "\(String(primaryLabel.text ?? "hello")) Error loading audio to playback."
            print("AVAudioPlayer error: \(err.localizedDescription)")
        } else {
            audioPlayer.delegate = self as? AVAudioPlayerDelegate
            audioPlayer.prepareToPlay()
            audioPlayer.volume = 10.0
            
            let maxTime:Int = 20
            if Int(audioPlayer.duration) > maxTime {
                primaryLabel.text = "\(String(primaryLabel.text ?? "hello"))\nDuration longer than \(maxTime) seconds cannot be transcribed (\(Int(audioPlayer.duration)))..."
                throw TranscribtionError.durationTooLong(duration: Int(audioPlayer.duration))
            }
            
        }
    }

    
    @IBAction func release(_ sender: Any) {
        primaryLabel.text = "Listening..."
        
        startRecording()
    }
    
    
    
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var audioPlayer:AVAudioPlayer!
    
    
    func setupView() {
        recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        self.primaryLabel.text = "recording setup complete"
                    } else {
                        // failed to record
                        self.primaryLabel.text = "Failed to Record Level 1"
                    }}}
        } catch { // failed to record
            primaryLabel.text = "Failed to Record Level 2"
        }
    }
    
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func getFileURL() -> URL {
        let path = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        return path as URL
    }
    
    func startRecording() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder.delegate = self as? AVAudioRecorderDelegate
            audioRecorder.record()
            
//            recordButton.setTitle("Tap to Stop", for: .normal)
        } catch {
            finishRecording(success: false)
        }
    }
    
    func finishRecording(success: Bool) {
        audioRecorder.stop()
        audioRecorder = nil
        if !success {
            primaryLabel.text = "\(String(primaryLabel.text ?? "hello")) Did not record."
        }
    }
    
    func advanceToNextPhrase() {
        
        let currentParagraph = self.fullTranslations[self.translationValue % self.fullTranslations.count].simplifiedChar
        
        if !currentParagraph.contains("。") {
            self.translationValue += 1
        } else {
            let sentences:[Substring] = currentParagraph.split(separator: "。")
            self.paragraphValue += 1
            if sentences.count == self.paragraphValue {
                self.translationValue += 1
                self.paragraphValue = 0
            }
        }
        
        self.toPronounce.text = self.getToPronounce()
        
        self.pronouncedSoFar = ""
    }
    
    fileprivate func transcribeFile(url: URL) {
        // 1
        //en-US or zh_Hans_CN - https://gist.github.com/jacobbubu/1836273
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh_Hans_CN")) else {
            print("Speech recognition not available for specified locale")
            return
        }
        
        if !recognizer.isAvailable {
            print("Speech recognition not currently available")
            return
        }
        
        // 2
//        updateUIForTranscriptionInProgress()
        let request = SFSpeechURLRecognitionRequest(url: url)
        
        // 3
        recognizer.recognitionTask(with: request) {
            [unowned self] (result, error) in
            guard let result = result else {
                print("There was an error transcribing that file")
                return
            }
            
            // 4
            if result.isFinal {
                var transcribed:String = result.bestTranscription.formattedString
                
                transcribed = transcribed.replacingOccurrences(of: "。", with: "")
                transcribed = transcribed.replacingOccurrences(of: "！", with: "")
                transcribed = "\(self.pronouncedSoFar)\(transcribed)"
                
                let compareString = self.removeExtraNewlineForComparrison(self.toPronounceCharacters)
                if transcribed == compareString {
                    self.primaryLabel.text = "Great Pronunciation:\n\(transcribed)"
                    
                    self.advanceToNextPhrase()
                } else if compareString.contains(transcribed) {
                    self.pronouncedSoFar = "\(self.pronouncedSoFar)\(transcribed)"
                        self.primaryLabel.text = "\(String(self.primaryLabel.text ?? "hello")) \nKeep Going: \(self.pronouncedSoFar)"
                } else {
                    self.primaryLabel.text = "Try again:\n\(transcribed)"
                    self.pronouncedSoFar = ""
                    self.skipThis.isEnabled = true
                }
                
            }
        }
//
        
    }


}

