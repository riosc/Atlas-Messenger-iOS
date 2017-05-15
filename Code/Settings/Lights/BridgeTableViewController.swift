//
//  BridgeTableViewController.swift
//  Larry
//
//  Created by Inderpal Singh on 3/22/17.
//  Copyright © 2017 Layer. All rights reserved.
//

import UIKit
import SwiftyHue

class BridgeTableViewController: UITableViewController {
    
    @IBOutlet private weak var ipLabel: UILabel!
    @IBOutlet private weak var deviceLabel: UILabel!
    @IBOutlet private weak var modelDescLabel: UILabel!
    @IBOutlet private weak var modelNameLabel: UILabel!
    @IBOutlet private weak var serialLabel: UILabel!
    @IBOutlet private weak var udnLabel: UILabel!
    
    var bridge: HueBridge?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setLabels()
    }
    
    func setLabels(){
        if let bridge = bridge {
            self.title = bridge.friendlyName
            self.ipLabel.text = bridge.ip
            self.deviceLabel.text = bridge.deviceType
            self.modelDescLabel.text = bridge.modelDescription
            self.modelNameLabel.text = bridge.modelName
            self.serialLabel.text = bridge.serialNumber
            self.udnLabel.text = bridge.UDN
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
