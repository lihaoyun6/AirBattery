//
//  AppleScript.swift
//  AirBattery
//
//  Created by apple on 2024/7/3.
//

import Foundation
import WidgetKit

class listAll: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        return AirBatteryModel.getAll(noFilter: true).map({ $0.deviceName })
    }
}

class reloadAll: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        Thread.detachNewThread {
            print("Reloading all widgets...")
            AirBatteryModel.writeData()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}

class getUsage: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        let device = self.evaluatedArguments!["name"] as! String
        if let ret = AirBatteryModel.getByName(device)?.batteryLevel {
            return ret
        }
        return -1
    }
}

class getStatus: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        let device = self.evaluatedArguments!["name"] as! String
        if let ret = AirBatteryModel.getByName(device)?.isCharging {
            return ret
        }
        return -1
    }
}
