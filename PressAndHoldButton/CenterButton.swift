//
//  CenterButton.swift
//  Say Again Mandarin
//
//  Created by Jason A Faas on 2/16/20.
//  Copyright © 2020 Jason A Faas. All rights reserved.
//

import Foundation

import UIKit

class CenterButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupButton()
    }
    
    private func setupButton() {
//        backgroundColor = Colors.tropicBlue
//        titleLabel?.font = UIFont(name: FontNameCode.courierNew, size: 22)
        layer.cornerRadius = frame.size.height/2
//        setTitleColor(.white, for: .normal)
    }
}
