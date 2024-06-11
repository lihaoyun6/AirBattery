//
//  Multipeer.swift
//  AirBattery
//
//  Created by apple on 2024/6/10.
//

import Foundation
import MultipeerKit

class MultipeerService: ObservableObject {
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
            guard let message = try? JSONDecoder().decode(NCMessage.self, from: data) else {
                print("Failed to decode message")
                return
            }
            guard let id = UserDefaults.standard.string(forKey: "ncGroupID") else { return }
            if let jsonString = decryptString(message.content, password: id) {
                if let jsonData = jsonString.data(using: .utf8) {
                    let url = ncFolder.appendingPathComponent("\(message.sender).json")
                    try? jsonData.write(to: url)
                } else {
                    print("Failed to convert JSON string to Data.")
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

    func sendMessage(_ message: NCMessage) {
        guard let data = try? JSONEncoder().encode(message) else {
            print("Failed to encode message")
            return
        }
        transceiver.send(data, to: transceiver.availablePeers)
    }
}

struct NCMessage: Codable {
    let sender: String
    let content: String
}
