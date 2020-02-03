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
    
    
    @IBAction func goToMainMenu(_ sender: Any) {
    }
}
