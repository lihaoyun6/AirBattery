//
//  AirBatteryModel.swift
//  AirBattery
//
//  Created by apple on 2024/2/9.
//

import Foundation

struct Device: Hashable, Codable {
    var hasBattery: Bool = true
    var deviceID: String
    var deviceType: String
    var deviceName: String
    var deviceModel: String?
    var batteryLevel: Int
    var isCharging: Int
    var isCharged: Bool = false
    var isPaused: Bool = false
    var acPowered: Bool = false
    var lastUpdate: Double
    var subDevices: [Device]?
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(hasBattery)
        hasher.combine(deviceID)
        hasher.combine(deviceType)
        hasher.combine(deviceName)
        hasher.combine(deviceModel)
        hasher.combine(batteryLevel)
        hasher.combine(isCharging)
        hasher.combine(isCharged)
        hasher.combine(isPaused)
        hasher.combine(acPowered)
        hasher.combine(lastUpdate)
        hasher.combine(subDevices)
    }
}

class AirBatteryModel {
    static var lock = false
    static var Devices: [Device] = []
    static let machineName = UserDefaults.standard.string(forKey: "machineName") ?? "Mac"
    static let key = "com.lihaoyun6.AirBattery.widget"
    
    static func updateDevices(byName: Bool = false, _ device: Device) {
        if lock { return }
        lock = true
        if let index = self.Devices.firstIndex(where: { $0.deviceName == device.deviceName }) { self.Devices[index] = device } else { self.Devices.append(device) }
        lock = false
    }
    
    static func getBlackList() -> [Device] {
        let blackList = (UserDefaults.standard.object(forKey: "blackList") ?? []) as! [String]
        let devices = getAll(flat: true, noFilter: true)
        return devices.filter({ blackList.contains($0.deviceName) })
    }
    
    static func getAll(reverse: Bool = true, flat: Bool = false, noFilter: Bool = false) -> [Device] {
        let disappearTime = (UserDefaults.standard.object(forKey: "disappearTime") ?? 20) as! Int
        var blackList = (UserDefaults.standard.object(forKey: "blackList") ?? []) as! [String]
        if noFilter { blackList = [] }
        let now = Double(Date().timeIntervalSince1970)
        let list = reverse ? Array(Devices.reversed()) : Devices
        var devices: [Device] = []
        for d in list {
            if let sub = d.subDevices {
                var subdev: [Device] = []
                for subd in sub { if !blackList.contains(subd.deviceName) && (now - subd.lastUpdate < Double(disappearTime * 60)) { subdev.append(subd) } }
                if !blackList.contains(d.deviceName){
                    if (now - d.lastUpdate < Double(disappearTime * 60)){
                        var newd = d
                        newd.subDevices = subdev
                        devices.append(newd)
                    }
                } else {
                    devices = devices + subdev
                }
            } else {
                if !blackList.contains(d.deviceName) && (now - d.lastUpdate < Double(disappearTime * 60)){ devices.append(d) }
            }
        }
        if flat {
            var flatDevices: [Device] = []
            for d in devices {
                flatDevices.append(d)
                if let sub = d.subDevices { for s in sub { flatDevices.append(s) } }
            }
            return flatDevices
        }
        return devices
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
        for d in getAll(flat: true, noFilter: true) {
            if d.deviceName == name { return d }
            //if let sub = d.subDevices { for s in sub { if s.deviceName == name { return s } } }
        }
        return nil
    }
    
    static func getByID(_ id: String) -> Device? {
        for d in getAll(flat: true, noFilter: true) {
            if d.deviceID == id { return d }
            //if let sub = d.subDevices { for s in sub { if s.deviceID == id { return s } } }
        }
        return nil
    }
    
    static func getJsonURL() -> URL {
        var url: URL
        let bundleIdentifier = Bundle.main.bundleIdentifier
        if bundleIdentifier == key {
            url = FileManager.default.temporaryDirectory.appendingPathComponent("temp.json")
        } else {
            url = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!.appendingPathComponent("Containers/\(key)/Data/tmp/temp.json")
        }
        return url
    }
    
    static func writeData(){
        var devices = getAll(flat: true)
        let ibStatus = InternalBattery.status
        if ibStatus.hasBattery { devices.insert(ibToAb(ibStatus), at: 0) }
        do {
            let jsonData = try JSONEncoder().encode(devices)
            try jsonData.write(to: getJsonURL())
        } catch {
            print("JSON error：\(error)")
        }
    }
    
    static func readData() -> [Device]{
        do {
            let jsonData = try Data(contentsOf: getJsonURL())
            let list = try JSONDecoder().decode([Device].self, from: jsonData)
            return list
        } catch {
            print("JSON error：\(error)")
        }
        return []
    }
}
