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
    
    @IBOutlet weak var mainMenuBtn: UIButton!
    
    var dbmHold: DatabaseManagement!
    var nextLangDispHold: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        do {
            // TODO: Print count of hsk 1 words
            for i in 1 ... 6 {
                hskCount = try self.dbmHold.getRowsInTranslationTableWithDifficulty(DbTranslation.hskTable, i)

                print("HSK_\(i): \(hskCount)")
            }
            let hsk1Count
            // TODO: Print count of hsk 2 words
            let hsk2Count = try self.dbmHold.getRowsInTranslationTableWithDifficulty(DbTranslation.hskTable, 2)
            print("HSK_2 \(hsk2Count)")
            
            // TODO: Print count of logWords of hsk 1
            let hsk2Count = try self.dbmHold.getLogRowsCountWithDifficulty(2)
            print("HSK_2 \(hsk2Count)")
            // TODO: Print count of logWords of hsk 2
        } catch {
            print("Error :(")
        }
    }
    
    
    @IBAction func goToMainMenuFromProgress(_ sender: Any) {
        performSegue(withIdentifier: "sequeProgressToMainMenu",
                     sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if sender is UIButton {
            let senderButton: UIButton = sender as! UIButton
            
            if senderButton == mainMenuBtn {
                print("Hit MainMenu Button in Progress")
                 let viewMainController = segue.destination as! ViewMainController
                
                 viewMainController.dbmHold = self.dbmHold
                 viewMainController.nextLangDispHold = self.nextLangDispHold
            } else {
                print("Valid Button Not Hit?!!")
            }
        } else {
            print("Not a button?!?!")
        }
    }
}
