//
//  Multipeer.swift
//  AirBattery
//
//  Created by apple on 2024/6/10.
//

import SwiftUI
import Foundation
import MultipeerKit

class MultipeerService: ObservableObject {
    @AppStorage("ncGroupID") var ncGroupID = ""
    @AppStorage("deviceName") var deviceName = "Mac"
    let transceiver: MultipeerTransceiver

    init(serviceType: String) {
        let configuration = MultipeerConfiguration(
            serviceType: serviceType,
            peerName: getMacDeviceName(),
            defaults: ud,
            security: .default,
            invitation: .automatic)
        transceiver = MultipeerTransceiver(configuration: configuration)
        
        // Start the transceiver
        //transceiver.resume()
        
        // Handle received data
        transceiver.receive(Data.self) { data, peer in
            DispatchQueue.global().async {
                guard let message = try? JSONDecoder().decode(NCMessage.self, from: data) else {
                    print("Failed to decode message")
                    return
                }
                if message.id != self.ncGroupID.prefix(15) { return }
                switch message.command {
                case "resend":
                    var allDevices = AirBatteryModel.getAll()
                    allDevices.insert(ib2ab(InternalBattery.status), at: 0)
                    do {
                        let jsonData = try JSONEncoder().encode(allDevices)
                        guard let jsonString = String(data: jsonData, encoding: .utf8) else { return }
                        guard let data = encryptString(jsonString, password: self.ncGroupID) else { return }
                        let message = NCMessage(id: String(self.ncGroupID.prefix(15)), sender: systemUUID ?? self.deviceName, command: "", content: data)
                        netcastService.sendMessage(message, peerID: peer.id)
                    } catch {
                        print("Write JSON error：\(error)")
                    }
                    return
                case "trans":
                    print("Device received.")
                    return
                    /*if let jsonString = decryptString(message.content, password: self.ncGroupID) {
                        if let jsonData = jsonString.data(using: .utf8) {
                            if let device = try? JSONDecoder().decode(btdDevice.self, from: jsonData) {
                                let ret = BTTool.connect(mac: device.mac)
                                if ret {
                                    createNotification(title: "Device Connected".local,
                                                       message: String(format: "%@ from %@".local, device.name, peer.name))
                                } else {
                                    if let message = self.createInfo(type: 254, title: "Connection Failed".local, info: String(format: "cannot connect to your device!".local, device.name), atta: device.mac) {
                                        self.sendMessage(message, peerID: peer.id)
                                    }
                                }
                            }
                        } else {
                            print("Failed to convert JSON string to Data.")
                        }
                    }*/
                case "notify":
                    print("Info received.")
                    if let jsonString = decryptString(message.content, password: self.ncGroupID) {
                        if let jsonData = jsonString.data(using: .utf8) {
                            if let info = try? JSONDecoder().decode(NCNotification.self, from: jsonData) {
                                switch info.type {
                                case 1:
                                    createNotification(title: info.title, message: "\(info.info) (\(peer.name))")
                                case 255:
                                    createNotification(title: info.title, message: "\(peer.name) \(info.info)")
                                case 254:
                                    _ = BTTool.connect(mac: info.atta)
                                    createNotification(title: info.title, message: "\(peer.name) \(info.info)")
                                default:
                                    createNotification(title: info.title, message: info.info)
                                }
                            }
                        } else {
                            print("Failed to convert JSON string to Data.")
                        }
                    }
                case "":
                    print("Data received.")
                    if let jsonString = decryptString(message.content, password: self.ncGroupID) {
                        if let jsonData = jsonString.data(using: .utf8) {
                            let url = ncFolder.appendingPathComponent("\(message.sender).json")
                            try? jsonData.write(to: url)
                        } else {
                            print("Failed to convert JSON string to Data.")
                        }
                    }
                default:
                    print("Unknown command: \(message.command)")
                    if let info = self.createInfo(type: 255, title: "Unknown Command".local, info: String(format: "doesn't support command \"%@\"".local, message.command)) {
                        self.sendMessage(info, peerID: peer.id)
                    }
                    return
                }
            }
        }
        
        print("⚙️ Nearcast Group ID: \(ncGroupID)")
    }
    
    func resume() {
        transceiver.resume()
        print("ℹ️ Nearcast is running...")
    }
    
    func stop() {
        transceiver.stop()
        print("ℹ️ Nearcast has stopped")
    }

    func sendMessage(_ message: NCMessage, peerID: String? = nil) {
        guard let data = try? JSONEncoder().encode(message) else {
            print("Failed to encode message")
            return
        }
        let peers = removeDuplicatesPeer(peers: transceiver.availablePeers)
        if let peerID {
            transceiver.send(data, to: peers.filter({ $0.id == peerID }))
        } else {
            for peer in peers { transceiver.send(data, to: [peer]) }
        }
    }
    
    func refeshAll() {
        print("ℹ️ Pulling data...")
        let message = NCMessage(id: String(ncGroupID.prefix(15)), sender: systemUUID ?? self.deviceName, command: "resend", content: "")
        self.sendMessage(message)
    }
    
    func transDevice(device: Device, to name: String) {
        do {
            let btd = btdDevice(time: Date(), vid: "", pid: "", type: device.deviceType, mac: device.deviceID.replacingOccurrences(of: ":", with: "-").lowercased(), name: device.deviceName, level: device.batteryLevel)
            let jsonData = try JSONEncoder().encode(btd)
            guard let jsonString = String(data: jsonData, encoding: .utf8) else { return }
            guard let data = encryptString(jsonString, password: self.ncGroupID) else { return }
            let message = NCMessage(id: String(self.ncGroupID.prefix(15)), sender: systemUUID ?? self.deviceName, command: "trans", content: data)
            for peer in transceiver.availablePeers.filter({ $0.name == name }) {
                self.sendMessage(message, peerID: peer.id)
            }
        } catch {
            print("Write JSON error：\(error)")
        }
    }
    
    func createInfo(type: Int = 0, title: String, info: String, atta: String = "") -> NCMessage? {
        do {
            let error = NCNotification(type: 0, title: title, info: info, atta: atta)
            let jsonData = try JSONEncoder().encode(error)
            guard let jsonString = String(data: jsonData, encoding: .utf8) else { return nil }
            guard let data = encryptString(jsonString, password: self.ncGroupID) else { return nil }
            return NCMessage(id: String(self.ncGroupID.prefix(15)), sender: systemUUID ?? self.deviceName, command: "notify", content: data)
        } catch {
            print("Write JSON error：\(error)")
        }
        return nil
    }
}

func removeDuplicatesPeer(peers: [Peer]) -> [Peer] {
    var seenIDs = Set<String>()
    let filteredPeers = peers.filter { peer in
        if seenIDs.contains(peer.id) {
            return false
        } else {
            seenIDs.insert(peer.id)
            return true
        }
    }
    return filteredPeers
}

struct NCMessage: Codable {
    let id: String
    let sender: String
    let command: String
    let content: String
}

struct NCNotification: Codable {
    /// 0 = normal
    /// 1 = normal error
    /// 254 = bt error
    /// 255 = unknow command
    let type: Int
    let title: String
    let info: String
    let atta: String
}
