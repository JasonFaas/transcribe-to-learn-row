//
//  ViewMainController.swift
//  PressAndHoldButton
//
//  Created by Jason A Faas on 1/27/20.
//  Copyright © 2020 Jason A Faas. All rights reserved.
//

import UIKit

class ViewMainController: UIViewController {
    
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var progressBtn: UIButton!
    @IBOutlet weak var qsButton: UIButton!
    
    var dbmHold: DatabaseManagement!
    var nextLangDispHold: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func goToQuickStartFromMainMenu(_ sender: Any) {
        performSegue(withIdentifier: "sequeMainMenuToQuickStart",
                     sender: self)
    }
    
    @IBAction func goToProgressFromMainMenu(_ sender: Any) {
        performSegue(withIdentifier: "segueMainMenuToProgress",
                     sender: self)
    }
    
    @IBAction func goToSettingsFromMainMenu(_ sender: Any) {
        performSegue(withIdentifier: "segueMainMenuToSettings",
                     sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if segue.destination is ViewQuickStartController {
            print("Hit QS Button in MainMenu")
            let viewQuickStartController = segue.destination as! ViewQuickStartController
            viewQuickStartController.runUnitTests = false
            viewQuickStartController.quickStartDbmHold = self.dbmHold
            viewQuickStartController.quickStartNextLangDispHold = self.nextLangDispHold
        } else if segue.destination is ViewProgressController {
            print("Hit Progress Button in MainMenu")
            let viewProgressController = segue.destination as! ViewProgressController
            viewProgressController.dbmHold = self.dbmHold
            viewProgressController.nextLangDispHold = self.nextLangDispHold
        } else if segue.destination is ViewSettingsController {
            print("Hit Settings Button in MainMenu")
            let viewSettingsController = segue.destination as! ViewSettingsController
            viewSettingsController.dbmHold = self.dbmHold
            viewSettingsController.nextLangDispHold = self.nextLangDispHold
        } else {
            print("Valid Button Not Hit?!!")
        }
    }

}
