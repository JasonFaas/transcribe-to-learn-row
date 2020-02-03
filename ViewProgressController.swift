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
