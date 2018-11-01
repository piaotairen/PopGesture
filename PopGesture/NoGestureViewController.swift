//
//  NoGestureViewController.swift
//  PopGesture
//
//  Created by Cobb on 2018/11/1.
//  Copyright © 2018 Cobb. All rights reserved.
//

import UIKit

class NoGestureViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "NoGestureViewController"
        view.backgroundColor = .white
        
        interactivePopDisabled = true
    }
    
}
