//
//  ViewController.swift
//  PressAndHoldButton
//
//  Created by Jason A Faas on 8/10/19.
//  Copyright © 2019 Jason A Faas. All rights reserved.
//

import UIKit
import Speech

class ViewController: UIViewController {

    @IBOutlet weak var toPronounce: UILabel!
    @IBOutlet weak var primaryLabel: UILabel!
    @IBOutlet weak var buttonTextUpdate: UIButton!
    
    
    class TranslationInfo {
        let simplifiedChar:String
        let pinyinChar:String
        let englishChar:String
        let englishTranslation:String
        
        init(simplifiedChar: String,
            pinyinChar: String,
            englishChar: String,
            englishTranslation: String) {
            self.simplifiedChar = simplifiedChar
            self.pinyinChar = pinyinChar
            self.englishChar = englishChar
            self.englishTranslation = englishTranslation
        }
    }
    
    let fullTranslations = [TranslationInfo(simplifiedChar: "你好",
                                            pinyinChar: "nǐ hǎo",
                                            englishChar: "ni hao",
                                            englishTranslation: "Hello"),
                            TranslationInfo(simplifiedChar: "美国人",
                                            pinyinChar: "měiguó rén",
                                            englishChar: "meiguo ren",
                                            englishTranslation: "American Person"),
                            TranslationInfo(simplifiedChar: "没问题",
                                            pinyinChar: "méi wèn tí",
                                            englishChar: "mei wen ti",
                                            englishTranslation: "No problem"),
                            TranslationInfo(simplifiedChar: "很高兴认识你",
                                            pinyinChar: "",
                                            englishChar: "hengaoxingrenshini",
                                            englishTranslation: "Nice to meet you"),
                            TranslationInfo(simplifiedChar: "生日快乐",
                                            pinyinChar: "",
                                            englishChar: "shengrikuaile",
                                            englishTranslation: "Happy Birthday"),
                            TranslationInfo(simplifiedChar: "我对海鲜过敏",
                                            pinyinChar: "",
                                            englishChar: "Wǒ duì hǎixiān guòmǐn",
                                            englishTranslation: "I am allergic to seafood"),
                            ]
    var translationValue = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //setup Recorder
        self.setupView()
        
        self.translationValue = Int.random(in: 0 ..< fullTranslations.count)
        self.toPronounce.text = fullTranslations[translationValue].simplifiedChar
    }
    @IBAction func releaseOutside(_ sender: Any) {
        primaryLabel.text = "\(String(primaryLabel.text ?? "hello")) Out"
        
        released()
    }
    
    @IBAction func pressAndHoldBbutton(_ sender: UIButton) {
        primaryLabel.text = "\(String(primaryLabel.text ?? "hello")) In"
        
        released()
    }
    
    func released() {
        
        self.buttonTextUpdate.isEnabled = false
        
        primaryLabel.text = "\(String(primaryLabel.text ?? "hello")) Stop."
        
        finishRecording(success: true)
        
        
        
        preparePlayer()
        audioPlayer.play()
        transcribeFile(url: getFileURL() as URL)
        
    }
    
    func preparePlayer() {
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
            
            primaryLabel.text = "\(String(primaryLabel.text ?? "hello")) duration: \(Int(audioPlayer.duration)) seconds."
            
        }
    }

    
    @IBAction func release(_ sender: Any) {
        primaryLabel.text = "Start."
        
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
        if success {
            primaryLabel.text = "\(String(primaryLabel.text ?? "hello")) Actually recorded."
        } else {
            primaryLabel.text = "\(String(primaryLabel.text ?? "hello")) Did not record."
        }
    }
    
    fileprivate func transcribeFile(url: URL) {
        
        
        // 1
        //en-US or zh_Hans_CN - https://gist.github.com/jacobbubu/1836273
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh_Hans_CN")) else {
            print("Speech recognition not available for specified locale")
            self.buttonTextUpdate.isEnabled = true
            return
        }
        
        if !recognizer.isAvailable {
            print("Speech recognition not currently available")
            self.buttonTextUpdate.isEnabled = true
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
                self.buttonTextUpdate.isEnabled = true
                return
            }
            
            // 4
            if result.isFinal {
                var transcribed = result.bestTranscription.formattedString
                self.primaryLabel.text = "\(String(self.primaryLabel.text ?? "hello")) \(transcribed)."
                
                transcribed = transcribed.replacingOccurrences(of: "。", with: "")
                transcribed = transcribed.replacingOccurrences(of: "！", with: "")
                
                if transcribed == self.toPronounce.text {
                    self.primaryLabel.text = "\(String(self.primaryLabel.text ?? "hello")) Great Pronunciation."
                    
                    self.translationValue += 1
                    self.toPronounce.text = self.fullTranslations[self.translationValue % self.fullTranslations.count].simplifiedChar
                    
                }
            }
            
            
            self.buttonTextUpdate.isEnabled = true
        }
//
        
    }


}

