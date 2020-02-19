//
//  ViewDetailViewController.swift
//  PressAndHoldButton
//
//  Created by Jason A Faas on 2/4/20.
//  Copyright © 2020 Jason A Faas. All rights reserved.
//

import UIKit

class ViewLevelDetailController: UIViewController {
    
    @IBOutlet weak var primaryLabel: UILabel!
    @IBOutlet weak var otherLabel: UILabel!
    
    var dbmHold: DatabaseManagement!
    var nextLangDispHold: String!
    var levelToDisplay: Int!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        print("Display Level Detail for \(levelToDisplay)")
        
        do {
            let notAnswered = try self.dbmHold.getLogWordsAnswered(hskLevel: levelToDisplay * 10, answered: false)
            let notAns: String = notAnswered.joined(separator: "\n")
            self.primaryLabel.text = "Never Answered\n\n\(notAns)"

            
            let yesAnswered = try self.dbmHold.getLogWordsAnswered(hskLevel: levelToDisplay * 10, answered: true)
            let yesAns = yesAnswered.joined(separator: "\n")
            self.otherLabel.text = "Answered\n\n\(yesAns)"
        } catch {
            self.primaryLabel.text = "\(error)"
        }
    }
    
    @IBAction func goToMainMenu(_ sender: Any) {
        performSegue(withIdentifier: "segueLevelDetailToProgress",
        sender: self)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is ViewProgressController {
             let nextController = segue.destination as! ViewProgressController
            
             nextController.dbmHold = self.dbmHold
             nextController.nextLangDispHold = self.nextLangDispHold
        } else {
            print("Valid Button Not Hit in Level Detail?!!")
        }
    }

}
