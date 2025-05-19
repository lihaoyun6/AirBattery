//
//  main.swift
//  abt
//
//  Created by apple on 2025/5/19.
//

import AppKit
import ArgumentParser

let fd = FileManager.default
let ud = UserDefaults.standard
let key = "com.lihaoyun6.AirBattery.widget"
let ncFolder = fd.urls(for: .libraryDirectory, in: .userDomainMask).first!.appendingPathComponent("Containers/\(AirBatteryModel.key)/Data/Documents/NearcastData")

extension Device {
    func toItem() -> item {
        var status = "?"
        if isCharged || acPowered || (isCharging != 0) {
            status = "+"
        } else if isPaused {
            status = "="
        } else {
            status = "-"
        }
        let stamp = realUpdate != 0.0 ? realUpdate : lastUpdate
        let min = Int((stamp - Double(Date().timeIntervalSince1970)) / 60)
        return item(
            device: deviceName,
            level: batteryLevel,
            status: status,
            update: min
        )
    }
}

struct item: Codable, Equatable {
    let device: String
    let level: Int
    let status: String
    let update: Int
}


struct airbattery: ParsableCommand {
    static var configuration = CommandConfiguration(version: "0.1.0")
    
    @Flag(name: .shortAndLong, help: "Including Nearcast devices")
    var nearcast: Bool = false
    
    @Flag(name: .shortAndLong, help: "Print in JSON format")
    var json: Bool = false
    
    @Flag(name: .shortAndLong, help: "Print in CSV format")
    var csv: Bool = false
    
    mutating func validate() throws {
        let arguments = [json, csv]
        let activeCount = arguments.filter { $0 }.count
        if activeCount > 1 {
            throw ValidationError("These options cannot be used together!")
        }
    }

    mutating func run() throws {
        if let url = URL(string: "airbattery://writedata") {
            let config = NSWorkspace.OpenConfiguration()
            config.activates = false
            NSWorkspace.shared.open(url, configuration: config)
        }
        usleep(500000)
        var devices = AirBatteryModel.readData()
        if nearcast {
            let allNearcast = getFiles(withExtension: "json", in: ncFolder)
            for jsonUrl in allNearcast {
                devices += AirBatteryModel.ncGetAll(url: jsonUrl, fromWidget: true)
            }
        }
        let items: [item] = devices.map { $0.toItem() }
        if json {
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                
                let jsonData = try encoder.encode(items)
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    print(jsonString)
                }
            } catch {
                print("Get JSON error：\(error)")
            }
            return
        }
        
        var rows = items.map { "\($0.device)\t\(String(format: "%3d", $0.level))%\t\($0.status)" }
        rows.insert("Device\tLevel\tStatus",at:0)
        var joined = rows.joined(separator: "\n") + "\n"
        
        if csv {
            print(joined.replacingOccurrences(of: "\t", with: ","))
            return
        }
        
        rows.insert("-------\t------\t-------",at:1)
        joined = rows.joined(separator: "\n") + "\n"
        let process = Process()
        process.launchPath = "/usr/bin/env"
        process.arguments = ["column", "-t", "-s", "\t"]

        let inputPipe = Pipe()
        let outputPipe = Pipe()
        process.standardInput = inputPipe
        process.standardOutput = outputPipe

        process.launch()
        inputPipe.fileHandleForWriting.write(joined.data(using: .utf8)!)
        inputPipe.fileHandleForWriting.closeFile()

        let result = outputPipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: result, encoding: .utf8) {
            print(output.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }
}

airbattery.main()
