//
//  ViewMainController.swift
//  PressAndHoldButton
//
//  Created by Jason A Faas on 1/27/20.
//  Copyright © 2020 Jason A Faas. All rights reserved.
//

import UIKit

class ViewMainController: UIViewController {
    
    @IBOutlet weak var progressBtn: UIButton!
    @IBOutlet weak var qsButton: UIButton!
    
    var quickStartDbmHold: DatabaseManagement!
    var quickStartNextLangDispHold: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func goToMainMenu(_ sender: Any) {
        performSegue(withIdentifier: "sequeMainMenuToQuickStart",
                     sender: self)
    }
    
    @IBAction func goToProgress(_ sender: Any) {
        performSegue(withIdentifier: "segueMainMenuToProgress",
                     sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if sender is UIButton {
            let senderButton: UIButton = sender as! UIButton
            
            if senderButton == qsButton {
                 var viewQuickStartController = segue.destination as! ViewQuickStartController
                
                 viewQuickStartController.runUnitTests = false
                 viewQuickStartController.quickStartDbmHold = self.quickStartDbmHold
                 viewQuickStartController.quickStartNextLangDispHold = self.quickStartNextLangDispHold
            } else if senderButton == progressBtn {
                var viewProgressController = segue.destination as! ViewProgressController
                
                viewProgressController.dbmHold = self.quickStartDbmHold
                viewProgressController.nextLangDispHold = self.quickStartNextLangDispHold
            } else {
                print("Valid Button Not Hit?!!")
            }
        } else {
            print("Not a button?!?!")
        }
    }

}
