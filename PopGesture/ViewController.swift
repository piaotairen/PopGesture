//
//  ViewController.swift
//  PopGesture
//
//  Created by Cobb on 2018/11/1.
//  Copyright © 2018 Cobb. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "RootViewController"
    }

    @IBAction func pushGestureController(_ sender: Any) {
        navigationController?.pushViewController(GestureViewController(), animated: true)
    }
    
    @IBAction func pushNoGestureController(_ sender: Any) {
        navigationController?.pushViewController(NoGestureViewController(), animated: true)
    }
    
}

