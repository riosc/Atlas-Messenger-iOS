//
//  LightSettingsTableViewController.swift
//  Larry
//
//  Created by Inderpal Singh on 3/22/17.
//  Copyright © 2017 Layer. All rights reserved.
//

import UIKit
import SwiftyHue
import Gloss

class LightSettingsTableViewController: UITableViewController, BridgeLinkDelegate {
    
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    var swiftyHue: SwiftyHue = SwiftyHue()
    var bridgeFinder = BridgeFinder()
    var bridges = [HueBridge]()
    var lights = [Light]()
    var resourceTypeToDisplay: HeartbeatBridgeResourceType = .lights
    
    override func viewDidLoad() {
        super.viewDidLoad()
        connectLights()
    }
    
    func connectLights(){
        resetTables()
        
        showLoading()
        bridgeFinder.delegate = self
        bridgeFinder.start()
        
        heartBeatLights()
    }
    
    func resetTables(){
        bridges = [HueBridge]()
        lights = [Light]()
        
        tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if(bridges.count > 0 && lights.count > 0){
            return 2
        }
        else if (bridges.count > 0) && (lights.count == 0){
            return 1
        }
        else if (bridges.count == 0) && (lights.count > 0){
            return 1
        }
        else{
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return bridges.count
        case 1:
            return lights.count
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "BridgeCell", for: indexPath as IndexPath)
            cell.textLabel?.text = self.bridges[indexPath.row].friendlyName
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "LightTableViewCell", for: indexPath as IndexPath) as! LightTableViewCell
            cell.light = self.lights[indexPath.row]
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "", for: indexPath as IndexPath)
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            let bridge = self.bridges[indexPath.row]
            loadBridgeWindow(bridge: bridge)
        case 1:
            let light = self.lights[indexPath.row]
            loadLightWindow(light: light)
        default:
            break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func showLoading(){
        activityIndicator.isHidden = false
    }
    
    func hideLoading(){
        activityIndicator.isHidden = true
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return (bridges.count > 0 ) ? "" : "Bridges"
        case 1:
            return (lights.count > 0 ) ? "" : "Lights"
        default:
            return ""
        }
    }
    
    func heartBeatLights(){
        if let bridgeAccessConfig = LightService().readBridgeAccessConfig(){
            swiftyHue.setBridgeAccessConfig(bridgeAccessConfig)
            swiftyHue.setLocalHeartbeatInterval(10, forResourceType: .lights)
            swiftyHue.startHeartbeat()
            swiftyHue.stopHeartbeat()
        }
    }
    
    func updateLights() {
        if let resourceCache = swiftyHue.resourceCache {
            switch resourceTypeToDisplay {
            case .lights:
                for light in resourceCache.lights.values {
                    lights.append(light)
                }
            default:
                break
            }
        }
        
        self.tableView.reloadData()
    }
    
    
    
    func loadBridgeWindow(bridge: HueBridge){
        if let _ = LightService().readBridgeAccessConfig() {
            openBridgeWindow(bridge: bridge)
            
        } else {
            openBridgeLinkWindow(bridge: bridge)
        }
    }
    
    func openBridgeWindow(bridge: HueBridge){
        let bridgeTableViewController = self.storyboard?.instantiateViewController(withIdentifier: "BridgeTableViewController") as? BridgeTableViewController
        bridgeTableViewController?.bridge = bridge
        self.navigationController?.pushViewController(bridgeTableViewController!, animated: true)
    }
    
    func openBridgeLinkWindow(bridge: HueBridge){
        let bridgeLinkViewController = self.storyboard?.instantiateViewController(withIdentifier: "BridgeLinkViewController") as? BridgeLinkViewController
        bridgeLinkViewController?.bridge = bridge
        bridgeLinkViewController?.delegate = self
        self.present(bridgeLinkViewController!, animated: true, completion: nil)
    }
    
    func loadLightWindow(light: Light){
        let lightTableViewController = self.storyboard?.instantiateViewController(withIdentifier: "LightTableViewController") as? LightTableViewController
        lightTableViewController?.light = light
        self.navigationController?.pushViewController(lightTableViewController!, animated: true)
    }
}

extension LightSettingsTableViewController: BridgeFinderDelegate {
    func bridgeFinder(_ finder: BridgeFinder, didFinishWithResult bridges: [HueBridge]) {
        self.bridges = bridges
        self.hideLoading()
        self.tableView.reloadData()
        
        
        updateLights()
    }
}
