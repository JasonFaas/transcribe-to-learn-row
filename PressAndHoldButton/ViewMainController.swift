//
//  ViewMainController.swift
//  PressAndHoldButton
//
//  Created by Jason A Faas on 1/27/20.
//  Copyright © 2020 Jason A Faas. All rights reserved.
//

import UIKit

class ViewMainController: UIViewController {
    
    var quickStartDbmHold: DatabaseManagement!
    
//    init() {
//        qu
//    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func goToMainMenu(_ sender: Any) {
        performSegue(withIdentifier: "sequeMainMenuToQuickStart",
        
                     sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        var viewQuickStartController = segue.destination as! ViewController
       
        viewQuickStartController.runUnitTests = false
        viewQuickStartController.quickStartDbmHold = self.quickStartDbmHold
    }

}
