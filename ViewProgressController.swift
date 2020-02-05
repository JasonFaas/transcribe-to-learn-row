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
    
    var dbmHold: DatabaseManagement!
    var nextLangDispHold: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var allButtons: [Int:UIButton] = [
            1: level1Btn,
            2: level2Btn,
            3: level3Btn,
            4: level4Btn,
            5: level5Btn,
            6: level6Btn,
            7: level7Btn,
        ]

        // Do any additional setup after loading the view.
        
        do {
            for i in 1 ... 6 {
                let hskCount = self.dbmHold.getRowsInTranslationTableWithDifficulty(DbTranslation.hskTable,
                                                                                    i)
                let hskAnswered = self.dbmHold.getLogRowsCountWithDifficulty(i)
                let hskPercentage = Int(100 * hskAnswered / hskCount)
                allButtons[i]?.setTitle("Level \(i): \(hskPercentage)%", for: .normal)
            }
            
            for i in 7 ... 8 {
                let hskCount = self.dbmHold.getRowsInTranslationTableWithDifficulty(DbTranslation.hskTable,
                                                                                    i)
                let hskAnswered = self.dbmHold.getLogRowsCountWithDifficulty(i)
                
                print("HSK_\(i) Count: \(hskCount)")
                print("HSK_\(i) Answered: \(hskAnswered)")
            }
            dbmHold.printAllLogWordsTable()
        } catch {
            print("Error :(")
        }
    }
    
    
    @IBAction func goToMainMenuFromProgress(_ sender: Any) {
        performSegue(withIdentifier: "sequeProgressToMainMenu",
                     sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        

        if segue.destination is ViewMainController {
            print("Hit MainMenu Button in Progress")
             let viewMainController = segue.destination as! ViewMainController
            
             viewMainController.dbmHold = self.dbmHold
             viewMainController.nextLangDispHold = self.nextLangDispHold
        } else {
            print("Valid Button Not Hit?!!")
        }

    }
}
