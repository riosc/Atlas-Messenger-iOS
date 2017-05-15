//
//  LightTableViewCell.swift
//  Larry
//
//  Created by Inderpal Singh on 3/22/17.
//  Copyright © 2017 Layer. All rights reserved.
//

import UIKit
import SwiftyHue

class LightTableViewCell: UITableViewCell {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var lightSwitch: UISwitch!
    
    var swiftyHue: SwiftyHue = SwiftyHue()
    
    var light: Light? {
        didSet {
            if let light = light {
                titleLabel.text = light.name
                lightSwitch.isOn = light.state.on!
            }
        }
    }
    
    @IBAction func changeSwitch(lightSwitch: UISwitch){
        var lightState = LightState()
        lightState.on = lightSwitch.isOn
        
        if let bridgeAccessConfig = LightService().readBridgeAccessConfig() {
            swiftyHue.setBridgeAccessConfig(bridgeAccessConfig)
            let sendAPI = swiftyHue.bridgeSendAPI
            
            sendAPI.updateLightStateForId(light!.identifier, withLightState: lightState, completionHandler: { (error) in
                print("CHANGE")
                print(error)
            })
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}

