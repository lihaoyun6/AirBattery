//
//  AirBatteryModel.swift
//  DockBattery
//
//  Created by apple on 2024/2/9.
//

import Foundation

struct Device {
    var hasBattery: Bool = true
    var deviceID: String
    var deviceType: String
    var deviceName: String
    var deviceModel: String?
    var batteryLevel: Int
    var isCharging: Int
    var lastUpdate: Double
    var subDevices: [Device]?
}

class AirBatteryModel {
    static var iDevices: [Device] = []
    static var btDevices: [Device] = []
    static var bleDevices: [Device] = []
    
    static func updateIdevices(byName: Bool = false, _ device: Device) {
        if byName {
            if let index = self.iDevices.firstIndex(where: { $0.deviceName == device.deviceName }) { self.iDevices[index] = device } else { self.iDevices.append(device) }
        } else {
            if let index = self.iDevices.firstIndex(where: { $0.deviceID == device.deviceID }) { self.iDevices[index] = device } else { self.iDevices.append(device) }
        }
    }
    
    static func updateBTdevices(byName: Bool = false, _ device: Device) {
        if byName {
            if let index = self.btDevices.firstIndex(where: { $0.deviceName == device.deviceName }) { self.btDevices[index] = device } else { self.btDevices.append(device) }
        } else {
            if let index = self.btDevices.firstIndex(where: { $0.deviceID == device.deviceID }) { self.btDevices[index] = device } else { self.btDevices.append(device) }
        }
    }
    
    static func updateBLEdevice(byName: Bool = false, _ device: Device) {
        if byName  {
            if let index = self.bleDevices.firstIndex(where: { $0.deviceName == device.deviceName }) { self.bleDevices[index] = device } else { self.bleDevices.append(device) }
        } else {
            if let index = self.bleDevices.firstIndex(where: { $0.deviceID == device.deviceID }) { self.bleDevices[index] = device } else { self.bleDevices.append(device) }
        }
    }
    
    static func getAll() -> [Device] {
        let disappearTime = (UserDefaults.standard.object(forKey: "disappearTime") ?? 20) as! Int
        let now = Double(Date().timeIntervalSince1970)
        //var list:[Device] = []
        //for d in bleDevices + iDevices + btDevices { if Double(now) - d.lastUpdate < 1800 { list.append(d) } }
        var list = bleDevices + iDevices + btDevices
        if disappearTime != 999 { list = list.filter({ now - $0.lastUpdate < Double(disappearTime * 60) }) }
        return list
    }
    
    static func getAllName() -> [String] {
        var list: [String] = []
        for b in getAll() {
            list.append(b.deviceName)
            if let sub = b.subDevices {
                for s in sub {
                    list.append(s.deviceName)
                }
            }
        }
        return list
    }
    
    static func getAllID() -> [String] {
        var list: [String] = []
        for b in getAll() {
            list.append(b.deviceID)
            if let sub = b.subDevices {
                for s in sub {
                    list.append(s.deviceID)
                }
            }
        }
        return list
    }
    
    static func getByName(_ name: String) -> Device? {
        for d in getAll() {
            if d.deviceName == name { return d }
            if let sub = d.subDevices { for s in sub { if s.deviceName == name { return s } } }
        }
        return nil
    }
    
    static func getByID(_ id: String) -> Device? {
        for d in getAll() {
            if d.deviceID == id { return d }
            if let sub = d.subDevices { for s in sub { if s.deviceID == id { return s } } }
        }
        return nil
    }
}
