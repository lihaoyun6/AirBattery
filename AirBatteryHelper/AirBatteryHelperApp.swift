//
//  AirBatteryHelperApp.swift
//  AirBatteryHelper
//
//  Created by apple on 2024/2/21.
//

import Cocoa

class HelperAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let runningApps = NSWorkspace.shared.runningApplications
        let isRunning = runningApps.contains {
            $0.bundleIdentifier == "com.lihaoyun6.AirBattery"
        }
        
        if !isRunning {
            var path = Bundle.main.bundleURL
            for _ in 1...4 {
                path = path.deletingLastPathComponent()
            }
            NSWorkspace.shared.openApplication(at: path, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
        }
    }
}
