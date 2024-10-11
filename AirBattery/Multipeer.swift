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
            defaults: UserDefaults.standard,
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
                case "":
                    print("No command.")
                default:
                    print("Unknown command: \(message.command)")
                }
                if self.ncGroupID == "" { return }
                if let jsonString = decryptString(message.content, password: self.ncGroupID) {
                    if let jsonData = jsonString.data(using: .utf8) {
                        let url = ncFolder.appendingPathComponent("\(message.sender).json")
                        try? jsonData.write(to: url)
                    } else {
                        print("Failed to convert JSON string to Data.")
                    }
                }
            }
        }
        
        print("⚙️ Nearcast Group ID: \(serviceType)")
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
