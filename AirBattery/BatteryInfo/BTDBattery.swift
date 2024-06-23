//
//  BTDBattery.swift
//  AirBattery
//
//  Created by apple on 2024/6/23.
//

import SwiftUI
import Foundation

class BTDBattery {
    var scanTimer: Timer?
    static var allDevices = [String]()
    @AppStorage("readBTHID") var readBTHID = true
    
    func startScan() {
        let interval = TimeInterval(58.0 * updateInterval * 2)
        scanTimer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(scanDevices), userInfo: nil, repeats: true)
        print("ℹ️ Start scanning Bluetooth HID devices...")
        scanDevices(longScan: true)
    }
    
    @objc func scanDevices(longScan: Bool = false) {
        Thread.detachNewThread {
            if self.readBTHID {
                if longScan {
                    BTDBattery.getOtherDevice(last: "2h")
                } else {
                    BTDBattery.getOtherDevice(last: "\(Int(updateInterval * 2))m")
                }
                let connects = BTDBattery.getConnected()
                let names = BTDBattery.allDevices.filter({ connects.contains($0) })
                for name in names {
                    if var device = AirBatteryModel.getByName(name) {
                        device.lastUpdate = Date().timeIntervalSince1970
                        AirBatteryModel.updateDevice(device)
                    }
                }
            }
        }
    }
    
    static func getConnected(mac: Bool = false) -> [String]{
        var connected:[String] = []
        if let json = try? JSONSerialization.jsonObject(with: Data(SPBluetoothDataModel.data.utf8), options: []) as? [String: Any],
        let SPBluetoothDataTypeRaw = json["SPBluetoothDataType"] as? [Any],
        let SPBluetoothDataType = SPBluetoothDataTypeRaw[0] as? [String: Any]{
            if let device_connected = SPBluetoothDataType["device_connected"] as? [Any]{
                for device in device_connected{
                    let d = device as! [String: Any]
                    if let key = d.keys.first, let info = d[key] as? [String: Any]  {
                        if !mac {
                            connected.append(key)
                        } else {
                            if let id = info["device_address"] as? String { connected.append(id) }
                        }
                    }
                }
            }
        }
        return connected
    }
    
    static func getOtherDevice(last: String = "10m") {
        let parent = UserDefaults.standard.string(forKey: "deviceName") ?? "Mac"
        guard let result = process(path: "/bin/bash", arguments: ["\(Bundle.main.resourcePath!)/logReader.sh", last]) else { return }
        let connected = getConnected(mac: true)
        var list = [[String : Any]]()
        let devices = result.components(separatedBy: "\n")
        for device in devices {
            if let json = try? JSONSerialization.jsonObject(with: Data(device.utf8), options: []) as? [String: Any] {
                if let index = list.firstIndex(where: { dict in
                    let name = dict["name"] as! String
                    let mac = dict["mac"] as! String
                    let type = dict["type"] as! String
                    let nameNow = json["name"] as! String
                    let macNow = json["mac"] as! String
                    let typeNow = json["type"] as! String
                    return ( name == nameNow && mac == macNow && type == typeNow)
                }) {
                    list[index] = json
                } else {
                    list.append(json)
                }
            }
        }
        for d in list {
            let mac = d["mac"] as! String
            let name = d["name"] as! String
            let type = d["type"] as! String
            let time = d["time"] as! String
            let level = d["level"] as! Int
            let status = (d["status"] as! String) == "+" ? 1 : 0
            if connected.contains(mac) {
                if let index = allDevices.firstIndex(of: name) { allDevices[index] = name } else { allDevices.append(name) }
                AirBatteryModel.updateDevice(Device(deviceID: mac, deviceType: type, deviceName: name, batteryLevel: min(100, max(0, level)), isCharging: status, parentName: parent, lastUpdate: Date().timeIntervalSince1970, realUpdate: isoFormatter.date(from: time)?.timeIntervalSince1970 ?? 0.0))
            }/* else {
                if let index = allDevices.firstIndex(of: name) { allDevices.remove(at: index) }
                AirBatteryModel.updateDevice(Device(deviceID: mac, deviceType: type, deviceName: name, batteryLevel: min(100, max(0, level)), isCharging: status, parentName: parent, lastUpdate: Date(timeIntervalSince1970: 0).timeIntervalSince1970))
            }*/
        }
        
        /*guard let result = process(path: "\(Bundle.main.resourcePath!)/hidpp/bin/hidpp-list-devices", arguments: []) else { return }
        let devices = result.components(separatedBy: "\n")
        for device in devices {
            if let json = try? JSONSerialization.jsonObject(with: Data(device.utf8), options: []) as? [String: Any] {
                if var name = json["name"] as? String, let pid = json["pid"] as? String,
                   let status = json["status"] as? Int, let level = json["level"] as? Int {
                    if name == "" { name = getDeviceName("0x\(pid.uppercased())", "Logitech Device") }
                    let type = getDeviceTypeWithPID("0x\(pid.uppercased())", "hid")
                    if !(status == 1 && level == 0) {
                        AirBatteryModel.updateDevice(Device(deviceID: pid, deviceType: type, deviceName: name, batteryLevel: min(100, max(0, level)), isCharging: status, parentName: deviceName, lastUpdate: Date().timeIntervalSince1970))
                    }
                }
            }
        }*/
    }
}
