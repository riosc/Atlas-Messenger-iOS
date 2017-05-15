//
//  LightTableViewController.swift
//  Larry
//
//  Created by Inderpal Singh on 3/22/17.
//  Copyright © 2017 Layer. All rights reserved.
//

import UIKit
import SwiftyHue

class LightTableViewController: UITableViewController {
    @IBOutlet private weak var lightSwitch: UISwitch!
    
    @IBOutlet private weak var typeLabel: UILabel!
    @IBOutlet private weak var modelLabel: UILabel!
    @IBOutlet private weak var uniqueLabel: UILabel!
    @IBOutlet private weak var manufacturerLabel: UILabel!
    @IBOutlet private weak var versionLabel: UILabel!
    
    @IBOutlet private weak var brightnessLabel: UILabel!
    @IBOutlet private weak var hueLabel: UILabel!
    @IBOutlet private weak var saturationLabel: UILabel!
    @IBOutlet private weak var xyLabel: UILabel!
    @IBOutlet private weak var ctLabel: UILabel!
    @IBOutlet private weak var alertLabel: UILabel!
    @IBOutlet private weak var effectLabel: UILabel!
    @IBOutlet private weak var colorLabel: UILabel!
    @IBOutlet private weak var reachableLabel: UILabel!
    
    var swiftyHue: SwiftyHue = SwiftyHue()
    var light: Light?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setLabels()
    }
    
    func setLabels(){
        if let light = light {
            self.title = light.name
            
            typeLabel.text = light.type
            modelLabel.text = light.modelId
            uniqueLabel.text = light.uniqueId
            manufacturerLabel.text = light.manufacturerName
            versionLabel.text = light.swVersion
            
            lightSwitch.isOn = light.state.on!
            brightnessLabel.text = light.state.brightness?.description
            hueLabel.text = light.state.hue?.description
            saturationLabel.text = light.state.saturation?.description
            xyLabel.text = light.state.xy?.description
            ctLabel.text = light.state.ct?.description
            alertLabel.text = light.state.alert
            effectLabel.text = light.state.effect
            colorLabel.text = light.state.colormode
            reachableLabel.text = light.state.reachable?.description
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
