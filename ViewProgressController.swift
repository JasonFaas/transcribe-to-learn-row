//
//  ViewProgressController.swift
//  PressAndHoldButton
//
//  Created by Jason A Faas on 2/2/20.
//  Copyright © 2020 Jason A Faas. All rights reserved.
//

import Foundation

import UIKit

class ViewProgressController: UIViewController {
    
    @IBOutlet weak var level1Btn: UIButton!
    @IBOutlet weak var level2Btn: UIButton!
    @IBOutlet weak var level3Btn: UIButton!
    @IBOutlet weak var level4Btn: UIButton!
    @IBOutlet weak var level5Btn: UIButton!
    @IBOutlet weak var level6Btn: UIButton!
    @IBOutlet weak var level7Btn: UIButton!
    @IBOutlet weak var mainMenuBtn: UIButton!
    
    var displayLevel: Int = 0
    
    var dbmHold: DatabaseManagement!
    var nextLangDispHold: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let allButtons: [Int:UIButton] = [
            1: level1Btn,
            2: level2Btn,
            3: level3Btn,
            4: level4Btn,
            5: level5Btn,
            6: level6Btn,
            7: level7Btn,
        ]

        // Do any additional setup after loading the view.
        
        for i in 1 ... 6 {
            let hskCount = self.dbmHold.getRowsInTranslationTableWithDifficulty(DbTranslation.hskTable,
                                                                                i)
            let hskAnswered = self.dbmHold.getLogRowsCountWithDifficulty(i)
            let hskPercentage = Int(100 * hskAnswered / hskCount)
            allButtons[i]?.setTitle("Level \(i): \(hskPercentage)%", for: .normal)
        }
        
        let hsk7 = self.dbmHold.getLogRowsCountWithDifficulty(7)
        let hsk8 = self.dbmHold.getLogRowsCountWithDifficulty(8)
        
        allButtons[7]?.setTitle("Level \(7): \(hsk7 + hsk8) Total", for: .normal)
    }
    
    @IBAction func goToLevel1(_ sender: Any) {
        displayLevel = 1
        goToLevelDetail(sender)
    }
    
    @IBAction func goToLevel2(_ sender: Any) {
        displayLevel = 2
        goToLevelDetail(sender)
    }
    
    @IBAction func goToLevel3(_ sender: Any) {
        displayLevel = 3
        goToLevelDetail(sender)
    }
    
    @IBAction func goToLevel4(_ sender: Any) {
        displayLevel = 4
        goToLevelDetail(sender)
    }
    
    @IBAction func goToLevel5(_ sender: Any) {
        displayLevel = 5
        goToLevelDetail(sender)
    }
    
    @IBAction func goToLevel6(_ sender: Any) {
        displayLevel = 6
        goToLevelDetail(sender)
    }
    
    @IBAction func goToLevel7(_ sender: Any) {
        displayLevel = 7
        goToLevelDetail(sender)
    }
    
    func goToLevelDetail(_ sender: Any) {
        performSegue(withIdentifier: "segueProgressToLevelDetail",
        sender: self)
    }
    
    
    @IBAction func goToMainMenuFromProgress(_ sender: Any) {
        performSegue(withIdentifier: "sequeProgressToMainMenu",
                     sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is ViewMainController {
            print("Hit MainMenu Button in Progress")
             let nextController = segue.destination as! ViewMainController
            
             nextController.dbmHold = self.dbmHold
             nextController.nextLangDispHold = self.nextLangDispHold
        } else if segue.destination is ViewLevelDetailController {
             let nextController = segue.destination as! ViewLevelDetailController
            
             nextController.dbmHold = self.dbmHold
             nextController.nextLangDispHold = self.nextLangDispHold
            nextController.levelToDisplay = self.displayLevel
        } else {
            print("Valid Button Not Hit?!!")
        }
    }
}
