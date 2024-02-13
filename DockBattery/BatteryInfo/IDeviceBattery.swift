//
//  AirBatteryModel.swift
//  DockBattery
//
//  Created by apple on 2024/2/6.
//

import Foundation

class IDeviceBattery {
    var scanTimer: Timer?
    var deviceIDs: [String: String] = [:]
    
    func startScanning() {
        scanTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(scanDevices), userInfo: nil, repeats: true)
        Thread.detachNewThread { self.getIDeviceBattery() }
    }
    
    @objc func scanDevices() { Thread.detachNewThread { self.getIDeviceBattery() } }
    
    func getIDeviceBattery() {
        var netDevices: [String] = []
        var usbDevices: [String] = []
        if let result = process(path: "\(Bundle.main.resourcePath!)/libimobiledevice/bin/idevice_id", arguments: ["-n"]) {
            netDevices = result.components(separatedBy: .newlines)
            for id in netDevices { deviceIDs[id] = "n" }
        }
        if let result = process(path: "\(Bundle.main.resourcePath!)/libimobiledevice/bin/idevice_id", arguments: ["-l"]) {
            usbDevices = result.components(separatedBy: .newlines)
            for id in usbDevices { deviceIDs[id] = "" }
        }
        for id in usbDevices {
            if let d = AirBatteryModel.getByID(id) {
                if (Double(Date().timeIntervalSince1970) - d.lastUpdate) > 60 { writeBatteryInfo(id, "") }
            } else {
                writeBatteryInfo(id, "")
            }
        }
        for id in netDevices {
            //print("[\(id)] \(Date().timeIntervalSince1970)")
            if let d = AirBatteryModel.getByID(id) {
                if (Double(Date().timeIntervalSince1970) - d.lastUpdate) > 60 { writeBatteryInfo(id, "-n") }
            } else {
                //print("√[\(id)] \(Date().timeIntervalSince1970)")
                writeBatteryInfo(id, "-n")
            }
        }
    }
    
    func writeBatteryInfo(_ id: String, _ connectType: String) {
        let lastUpdate = Date().timeIntervalSince1970
        if connectType == "" { _ = process(path: "\(Bundle.main.resourcePath!)/libimobiledevice/bin/wificonnection", arguments: ["-u", id, "true"]) }
        if let deviceInfo = process(path: "\(Bundle.main.resourcePath!)/libimobiledevice/bin/ideviceinfo", arguments: [connectType, "-u", id]){
            let i = deviceInfo.components(separatedBy: .newlines)
            if let deviceName = i.filter({ $0.contains("DeviceName") }).first?.components(separatedBy: ": ").last,
               let model = i.filter({ $0.contains("ProductType") }).first?.components(separatedBy: ": ").last,
               let type = i.filter({ $0.contains("DeviceClass") }).first?.components(separatedBy: ": ").last {
                if let batteryInfo = process(path: "\(Bundle.main.resourcePath!)/libimobiledevice/bin/ideviceinfo", arguments: [connectType, "-u", id, "-q", "com.apple.mobile.battery"]) {
                    let b = batteryInfo.components(separatedBy: .newlines)
                    if let level = b.filter({ $0.contains("BatteryCurrentCapacity") }).first?.components(separatedBy: ": ").last,
                       let charging = b.filter({ $0.contains("BatteryIsCharging") }).first!.components(separatedBy: ": ").last {
                        var idevice = Device(deviceID: id, deviceType: type, deviceName: deviceName, deviceModel: model, batteryLevel: Int(level)!, isCharging: Bool(charging)! ? 1 : 0, lastUpdate: lastUpdate)
                        var iwatchs: [Device] = []
                        if let watchInfo = process(path: "\(Bundle.main.resourcePath!)/libimobiledevice/bin/comptest", arguments: [id]) {
                            let w = watchInfo.components(separatedBy: .newlines)
                            if let watchID = w.filter({ $0.contains("Checking watch") }).first?.components(separatedBy: " ").last,
                               let watchName = w.filter({ $0.contains("DeviceName") }).first?.components(separatedBy: ": ").last,
                               let watchModel = w.filter({ $0.contains("ProductType") }).first?.components(separatedBy: ": ").last,
                               let watchLevel = w.filter({ $0.contains("BatteryCurrentCapacity") }).first?.components(separatedBy: ": ").last,
                               let watchCharging = w.filter({ $0.contains("BatteryIsCharging") }).first?.components(separatedBy: ": ").last {
                                iwatchs.append(Device(deviceID: watchID, deviceType: "iWatch", deviceName: watchName, deviceModel: watchModel, batteryLevel: Int(watchLevel)!, isCharging: Bool(watchCharging)! ? 1 : 0, lastUpdate: lastUpdate))
                            }
                        }
                        if !iwatchs.isEmpty { idevice.subDevices = iwatchs }
                        AirBatteryModel.updateIdevices(idevice)
                    }
                }
            }
        }
    }
}
