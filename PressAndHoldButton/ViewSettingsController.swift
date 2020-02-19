//
//  ViewSettingsController.swift
//  Say Again Mandarin
//
//  Created by Jason A Faas on 2/18/20.
//  Copyright © 2020 Jason A Faas. All rights reserved.
//

import UIKit

class ViewSettingsController: UIViewController {
    
    @IBOutlet weak var pinyinSwitch: UISwitch!
    @IBOutlet weak var simpleSwitch: UISwitch!
    @IBOutlet weak var englishSwitch: UISwitch!
    var dbmHold: DatabaseManagement!
    var nextLangDispHold: String!
    
    var mapSwitchSetting: [UISwitch:String] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
            
//        mapSwitchSetting[DbSettings.settingEnglish] = englishSwitch
//        mapSwitchSetting[DbSettings.settingMandarinSimplified] = simpleSwitch
//        mapSwitchSetting[DbSettings.settingPinyinDefaultOn] = pinyinSwitch
            
        mapSwitchSetting[englishSwitch] = DbSettings.settingEnglish
        mapSwitchSetting[simpleSwitch] = DbSettings.settingMandarinSimplified
        mapSwitchSetting[pinyinSwitch] = DbSettings.settingPinyinDefaultOn

        for (settingSwitch, settingString) in mapSwitchSetting {
            let stufffff = self.dbmHold.getSetting(settingString)
            settingSwitch.setOn(stufffff, animated: false)
        }
    }
    @IBAction func settingsValueChange(_ sender: Any, forEvent event: UIEvent) {
        let switchStuff = sender as! UISwitch
        for (settingSwitch, settingString) in mapSwitchSetting {
            if settingSwitch == switchStuff {
                print("\(settingString) updated")
            }
//            let stufffff = self.dbmHold.getSetting(settingString)
//            settingSwitch.setOn(stufffff, animated: false)
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    @IBAction func goToMainMenuFromSettings(_ sender: Any) {
        performSegue(withIdentifier: "segueSettingsToMainMenu",
                     sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is ViewMainController {
            print("Hit MainMenu Button in Settings")
            let nextController = segue.destination as! ViewMainController
            nextController.dbmHold = self.dbmHold
            nextController.nextLangDispHold = self.nextLangDispHold
        } else {
            print("Valid Button Not Hit?!!")
        }
    }
}
