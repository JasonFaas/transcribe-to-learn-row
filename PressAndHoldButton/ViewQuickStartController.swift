//
//  ViewController.swift
//  PressAndHoldButton
//
//  Created by Jason A Faas on 8/10/19.
//  Copyright © 2019 Jason A Faas. All rights reserved.
//

import UIKit
import Speech

import MessageUI

class ViewQuickStartController: UIViewController, MFMailComposeViewControllerDelegate {

    @IBOutlet weak var sayAgainHTRButton: UIButton!
    @IBOutlet weak var phrasesDue: UILabel!
    @IBOutlet weak var devQuickSkip: UIButton!
    @IBOutlet weak var toPronounce: UILabel!
    @IBOutlet weak var generalCommentLabel: UILabel!
    @IBOutlet weak var sayInZwHTRButton: UIButton!
    @IBOutlet weak var skipThis: UIButton!
    @IBOutlet weak var buttonPinyinToggle: UIButton!
    @IBOutlet weak var toPronouncePinyin: UILabel!
    @IBOutlet weak var mainMenuButton: UIButton!
    
    //TODO review all these variables to see if they are actually needed
    var translationValue = 0
    var paragraphValue = 0
    var toPronounceCharacters = ""
    var pronouncedSoFar = ""
    
    var mainManagement: MainManagement!
    
    var runUnitTests: Bool = true // Will be set to false by ViewMainMenuController
    var quickStartDbmHold: DatabaseManagement!
    var quickStartNextLangDispHold: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        AVCaptureDevice.requestAccess(for: .audio) { [unowned self] authStatus in
               DispatchQueue.main.async {
                   if authStatus == true {
                       print("Good to go! - Microphone ")
                   } else {
                       print("Recording NOT Authorized")
                   }
               }
           }
           
       SFSpeechRecognizer.requestAuthorization { [unowned self] authStatus in
              DispatchQueue.main.async {
                  if authStatus == .authorized {
                      print("Good to go! - Transcription")
                  } else {
                      print("Transcription permission was declined.")
                  }
              }
          }
        
        if !SFSpeechRecognizer(locale: Locale(identifier: "zh_Hans_CN"))!.isAvailable {
            print("Go to Settings->General->Keyboard and \"Enable Dictation\". Then select \"Dictation Languages\" and select \"Mandarin\"")
        }
        
        self.mainManagement = MainManagement(
            feedbackLabel: self.generalCommentLabel,
            toPronounceHanzi: self.toPronounce,
            toPronouncePinyin: self.toPronouncePinyin,
            sayInZwHTRButton: self.sayInZwHTRButton,
            skipThis: self.skipThis,
            pinyinToggleButton: self.buttonPinyinToggle,
            dueProgress: self.phrasesDue,
            quickStartDbmHold: quickStartDbmHold,
            quickStartNextLangDispHold: quickStartNextLangDispHold,
            sayAgainHTRButton: sayAgainHTRButton
        )
        
        do {
            if runUnitTests {
                try mainManagement.runUnitTests()
            } else {
                print("Skipped MainManagement Unit Tests")
            }
        } catch {
            print("Function: \(#file):\(#line), Error: \(error)")
            exit(1)
        }
    }
    
    @IBAction func pinyinToggle(_ sender: Any) {
        self.mainManagement.pinyinToggle()
    }
    
    @IBAction func devQuickSkip(_ sender: Any) {
        self.mainManagement.skipThisPress(grade: SpeakingGrade.B)
    }
    
    @IBAction func skipThisPress(_ sender: Any) {
        self.mainManagement.skipThisPress(grade: SpeakingGrade.F)
    }
    
    // Starting Press and Release Record
    
    @IBAction func releaseOutsideHoldToRecord(_ sender: Any) {
        released(sender)
    }
    
    @IBAction func pressAndHoldHoldToRecord(_ sender: UIButton) {
        released(sender)
    }
    
    func released(_ sender: Any) {
        let sayAgainButton: UIButton = sender as! UIButton
        if sayAgainButton == sayInZwHTRButton {
            
        } else if sayAgainButton == sayAgainHTRButton {
            
        } else {
            print("Function: \(#function):\(#line) - Big Error")
        }
        // TODO: If sayAgainButton, do not logResult
        self.mainManagement.fullFinishRecording(sayAgainButton)
    }
    
    @IBAction func pressHoldToRecord(_ sender: Any) {
        let sayAgainButton: UIButton = sender as! UIButton
        if sayAgainButton == sayInZwHTRButton {
            
        } else if sayAgainButton == sayAgainHTRButton {
            
        } else {
            print("Function: \(#function):\(#line) - Big Error")
        }
        
        // TODO: If sayAgainButton, update to say to previous result
        self.mainManagement.fullStartRecording(sayAgainButton)
    }
    
    // Ending Press and Release Record
    
    
    @IBAction func reportError(_ sender: Any) {
        self.sendErrorReport()
    }
    
    func sendErrorReport() {
        print("Try to send error report")
        
        if MFMailComposeViewController.canSendMail() {
            let composeVC = MFMailComposeViewController()
            composeVC.mailComposeDelegate = self as! MFMailComposeViewControllerDelegate
             
            // Configure the fields of the interface.
            composeVC.setToRecipients(["jasonf752@gmail.com"])
            composeVC.setSubject("Thanks for sending an Error Report!")
            
            let currentTranslation: DbTranslation = self.mainManagement.getCurrentTranslation()
            let currentTranscription: String = self.mainManagement.getCurrentTranscription()
            
            var messageBody: String = "Report of current info:\n"
            messageBody += "\(currentTranslation.getHanzi())"
            messageBody += "\n"
            messageBody += "\(currentTranslation.getEnglish())"
            messageBody += "\n"
            messageBody += "\(currentTranslation.getPinyin())"
            messageBody += "\n\n"
            messageBody += "\(currentTranscription)"
            
            composeVC.setMessageBody(messageBody, isHTML: false)
            

            self.present(composeVC, animated: true, completion: nil)
            print("Sent error report")
        } else {
            print("UNABLE TO SEND Error Report")
            // show failure alert
        }
        
        
    }
    
    @IBAction func goToMainMenuFromQuickStart(_ sender: Any) {
        performSegue(withIdentifier: "sequeQuickStartToMainMenuV2",
        
                     sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        var viewMainMenuController = segue.destination as! ViewMainController
        viewMainMenuController.dbmHold = self.mainManagement.transcription.dbm
        viewMainMenuController.nextLangDispHold = self.mainManagement.transcription.currentTranslation.getLanguageToDisplay()
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
    
}
