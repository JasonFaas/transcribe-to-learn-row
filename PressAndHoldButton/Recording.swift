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
    var primaryLabel: UILabel
    
    init(primaryLabel: UILabel) {
        self.primaryLabel = primaryLabel
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
    
    func playback() {
        do {
            try preparePlayer()
            
            audioPlayer.play()
        } catch {
            
        }
    }
    
    func startRecording() throws {
        let audioFilename = _getDocumentsDirectory().appendingPathComponent("recording.m4a")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
        audioRecorder.delegate = self as? AVAudioRecorderDelegate
        audioRecorder.record()
    }
    
    func finishRecording() {
        audioRecorder.stop()
        audioRecorder = nil
    }
    
    func _getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func getFileURL() -> URL {
        let path = _getDocumentsDirectory().appendingPathComponent("recording.m4a")
        return path as URL
    }
    
    func setupRecordingSession() {
        do {
            recordingSession = AVAudioSession.sharedInstance()
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        print("Recording setup complete")
                    } else {
                        // failed to record
                        print("Failed to Record Level 1")
                        exit(0)
                    }}}
        } catch { // failed to record
            print("Failed to Record Level 2")
            exit(0)
        }
    }
}
