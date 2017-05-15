//
//  BridgeLinkViewController.swift
//  Larry
//
//  Created by Inderpal Singh on 3/22/17.
//  Copyright © 2017 Layer. All rights reserved.
//

import UIKit
import SwiftyHue

protocol BridgeLinkDelegate {
    func connectLights()
}

class BridgeLinkViewController: UIViewController {
    
    var bridge: HueBridge!
    var bridgeAuthenticator: BridgeAuthenticator!
    var bridgeAccessConfig: BridgeAccessConfig!
    let bridgeAccessConfigUserDefaultsKey = "BridgeAccessConfig"
    var delegate: BridgeLinkDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        bridgeAuthenticator = BridgeAuthenticator(bridge: bridge, uniqueIdentifier: "swiftyhue#\(UIDevice.current.name)")
        bridgeAuthenticator.delegate = self;
        bridgeAuthenticator.start()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func openBridgeWindow(){
        
    }
    
    @IBAction func closeWindow(){
        self.dismiss(animated: true, completion: {})
    }
    
}

extension BridgeLinkViewController: BridgeAuthenticatorDelegate {
    public func bridgeAuthenticatorRequiresLinkButtonPress(_ authenticator: BridgeAuthenticator, secondsLeft: TimeInterval) {
        
    }
    
    func bridgeAuthenticator(_ authenticator: BridgeAuthenticator, didFinishAuthentication username: String) {
        self.bridgeAccessConfig = BridgeAccessConfig(bridgeId: "BridgeId", ipAddress: bridge.ip, username: username)
        writeBridgeAccessConfig(bridgeAccessConfig: self.bridgeAccessConfig)
        
        delegate?.connectLights()
        
        self.closeWindow()
    }
    
    func writeBridgeAccessConfig(bridgeAccessConfig: BridgeAccessConfig) {
        let userDefaults = UserDefaults.standard
        let bridgeAccessConfigJSON = bridgeAccessConfig.toJSON()
        userDefaults.set(bridgeAccessConfigJSON, forKey: self.bridgeAccessConfigUserDefaultsKey)
    }
    
    func bridgeAuthenticator(_ authenticator: BridgeAuthenticator, didFailWithError error: NSError) {
    }
    
    func bridgeAuthenticatorRequiresLinkButtonPress(authenticator: BridgeAuthenticator) {
    }
    
    func bridgeAuthenticatorDidTimeout(_ authenticator: BridgeAuthenticator) {
    }
}
