//
//  ViewSettingsController.swift
//  Say Again Mandarin
//
//  Created by Jason A Faas on 2/18/20.
//  Copyright © 2020 Jason A Faas. All rights reserved.
//

import UIKit

class ViewSettingsController: UIViewController {
    
    var dbmHold: DatabaseManagement!
    var nextLangDispHold: String!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func goToMainMenuFromSettings(_ sender: Any) {
        performSegue(withIdentifier: "sequeSettingsToMainMenu",
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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
