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
    var isHidden: Bool = false
    var parentName: String = ""
    var lastUpdate: Double
    
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
        hasher.combine(isHidden)
        hasher.combine(lastUpdate)
        hasher.combine(parentName)
    }
}

class AirBatteryModel {
    static var lock = false
    static var Devices: [Device] = []
    static let machineName = UserDefaults.standard.string(forKey: "machineName") ?? "Mac"
    static let key = "com.lihaoyun6.AirBattery.widget"
    
    static func updateDevice(_ device: Device) {
        if lock { return }
        lock = true
        if let index = self.Devices.firstIndex(where: { $0.deviceName == device.deviceName }) { self.Devices[index] = device } else { self.Devices.append(device) }
        lock = false
    }
    
    static func hideDevice(_ name: String) {
        for index in Devices.indices {
            if Devices[index].deviceName == name {
                Devices[index].isHidden = true
            }
        }
    }
    
    static func unhideDevice(_ name: String) {
        for index in Devices.indices {
            if Devices[index].deviceName == name {
                Devices[index].isHidden = false
            }
        }
    }
    
    static func getBlackList() -> [Device] {
        let blackList = (UserDefaults.standard.object(forKey: "blackList") ?? []) as! [String]
        let devices = getAll(noFilter: true)
        return devices.filter({ blackList.contains($0.deviceName) })
    }
    
    static func getAll(reverse: Bool = false, noFilter: Bool = false) -> [Device] {
        let disappearTime = (UserDefaults.standard.object(forKey: "disappearTime") ?? 20) as! Int
        let blackList = (UserDefaults.standard.object(forKey: "blackList") ?? []) as! [String]
        let now = Double(Date().timeIntervalSince1970)
        var list = (reverse ? Array(Devices.reversed()) : Devices).filter { (now - $0.lastUpdate < Double(disappearTime * 60)) }
        if !noFilter { list = list.filter { !blackList.contains($0.deviceName) && !$0.isHidden } }
        var newList: [Device] = []
        for d in list {
            if d.parentName == "" {
                newList.append(d)
                for sd in list.filter({ $0.parentName == d.deviceName }) {
                    newList.append(sd)
                }
            }
        }
        for dd in list.filter({ !newList.contains($0) }) { newList.append(dd) }
        return newList
    }
    
    static func getByName(_ name: String) -> Device? {
        for d in getAll(noFilter: true) { if d.deviceName == name { return d } }
        return nil
    }
    
    static func getByID(_ id: String) -> Device? {
        for d in getAll(noFilter: true) { if d.deviceID == id { return d } }
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
        let showMac = UserDefaults.standard.object(forKey: "showMacOnWidget") as? Bool ?? true
        let revList = UserDefaults.standard.object(forKey: "revListOnWidget") as? Bool ?? false
        
        var devices = getAll(reverse: revList)
        let ibStatus = InternalBattery.status
        if ibStatus.hasBattery && showMac { devices.insert(ibToAb(ibStatus), at: 0) }
        do {
            let jsonData = try JSONEncoder().encode(devices)
            try jsonData.write(to: getJsonURL())
        } catch {
            print("Write JSON error：\(error)")
        }
    }
    
    static func readData() -> [Device]{
        do {
            let jsonData = try Data(contentsOf: getJsonURL())
            let list = try JSONDecoder().decode([Device].self, from: jsonData)
            return list
        } catch {
            print("Read JSON error：\(error)")
        }
        return []
    }
}
