//
//  AlexaViewController.swift
//  Larry
//
//  Created by Inderpal Singh on 3/30/17.
//  Copyright © 2017 Layer. All rights reserved.
//

import UIKit

class AlexaViewController: UIViewController {
    @IBOutlet private weak var copyButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func copyCode(){
        let user = User.getUser()
        UIPasteboard.general.string = "\(user.userID)"
        copyButton.setTitle("Code Copied!", for: .normal)
    }
    
}
