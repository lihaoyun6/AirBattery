//
//  CommandLineTool.swift
//  AirBattery
//
//  Created by apple on 2025/05/19.
//

import Foundation

class CommandLineTool {
    static func runAsRoot(_ command: String, completion: (() -> Void)? = nil) {
        let script = "do shell script \"\(command)\" with administrator privileges"
        var error: NSDictionary?
        
        if let scriptObject = NSAppleScript(source: script) {
            let _ = scriptObject.executeAndReturnError(&error)
            
            if error == nil {
                completion?()
            } else {
                print("Error executing command: \(String(describing: error))")
            }
        }
    }
    
    static func isInstalled() -> Bool {
        let attributes = try? fd.attributesOfItem(atPath: "/usr/local/bin/airbattery")
        return attributes?[.type] as? FileAttributeType == .typeSymbolicLink
    }
    
    static func install(action: (() -> Void)? = nil) {
        if let resourceURL = Bundle.main.resourceURL {
            let binPath = resourceURL.appendingPathComponent("abt").path
            if !fd.fileExists(atPath: "/usr/local/bin") {
                runAsRoot("/bin/mkdir -p /usr/local/bin;/bin/ln -s '\(binPath)' /usr/local/bin/airbattery") {
                    action?()
                }
            } else {
                runAsRoot("/bin/ln -s '\(binPath)' /usr/local/bin/airbattery") {
                    action?()
                }
            }
        }
    }
    
    static func uninstall(action: (() -> Void)? = nil) {
        runAsRoot("/bin/rm /usr/local/bin/airbattery") { action?() }
    }
}
