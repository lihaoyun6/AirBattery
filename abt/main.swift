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


// MARK: - List (default) subcommand
struct List: ParsableCommand {
    static var configuration = CommandConfiguration(abstract: "List devices AirBattery currently knows about.")
    
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

// MARK: - Supported subcommand
struct Supported: ParsableCommand {
    static var configuration = CommandConfiguration(abstract: "Show supported device families and categories.")

    @Flag(name: .shortAndLong, help: "Output JSON instead of Markdown.")
    var json: Bool = false

    @Flag(name: .shortAndLong, help: "Show categories enabled by current settings.")
    var now: Bool = false

    func run() throws {
        // Read current capability toggles
        let readBTDevice = ud.bool(forKey: "readBTDevice")
        let readBLEDevice = ud.bool(forKey: "readBLEDevice")
        let ideviceOverBLE = ud.bool(forKey: "ideviceOverBLE")
        let readIDevice = ud.bool(forKey: "readIDevice")

        let appleHeadphoneModels: [String: String] = [
            "2002": "AirPods",
            "200e": "AirPods Pro",
            "200a": "AirPods Max", "201f": "AirPods Max",
            "200f": "AirPods 2",
            "2013": "AirPods 3",
            "201B": "AirPods 4 (ANC)", "2019": "AirPods 4",
            "2014": "AirPods Pro 2", "2024": "AirPods Pro 2",
            "2003": "PowerBeats 3",
            "200d": "PowerBeats 4",
            "200b": "PowerBeats Pro",
            "200c": "Beats Solo Pro",
            "2011": "Beats Studio Buds",
            "2010": "Beats Flex",
            "2005": "BeatsX",
            "2006": "Beats Solo 3",
            "2009": "Beats Studio 3",
            "2017": "Beats Studio Pro",
            "2012": "Beats Fit Pro",
            "2016": "Beats Studio Buds+"
        ]

        struct Category: Codable { let id, name, source, reliability: String; let requires: [String] }

        let categories: [Category] = [
            .init(id: "magic", name: "Apple Magic accessories (Trackpad/Keyboard/Mouse)", source: "IOKit", reliability: "stable", requires: []),
            .init(id: "iobt-thirdparty", name: "Non‑Apple Bluetooth with batteryPercentSingle", source: "IOBluetooth", reliability: "stable", requires: ["Discover BT and BLE devices"]),
            .init(id: "apple-headphones", name: "Apple/Beats headphones (model codes)", source: "SPBluetooth/BLE", reliability: "stable", requires: ["Discover BT and BLE devices"]),
            .init(id: "gatt-180F", name: "Generic BLE Battery Service (0x180F)", source: "BLE", reliability: "beta", requires: ["Discover more BLE devices"]),
            .init(id: "idevice", name: "iPhone/iPad/Watch/Vision Pro", source: "Network/BLE", reliability: "stable", requires: ["Discover iOS devices via Network or Bluetooth"]),
            .init(id: "pencil", name: "Apple Pencil via iPad", source: "Logs", reliability: "beta", requires: ["Apple Pencil from your iPad"])
        ]

        // Enabled categories given current toggles
        let enabled: [String: Bool] = [
            "magic": true,
            "iobt-thirdparty": readBTDevice,
            "apple-headphones": readBTDevice,
            "gatt-180F": readBLEDevice,
            "idevice": (readIDevice || ideviceOverBLE),
            "pencil": ud.bool(forKey: "readPencil")
        ]

        if json {
            struct Output: Codable { let categories: [Category]; let enabled: [String: Bool]; let appleHeadphoneModels: [String: String] }
            let out = Output(categories: categories, enabled: enabled, appleHeadphoneModels: appleHeadphoneModels)
            let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(out)
            print(String(data: data, encoding: .utf8)!)
            return
        }

        // Markdown output
        print("# AirBattery Supported Devices\n")
        print("## Categories\n")
        for c in categories {
            let mark = now ? (enabled[c.id] == true ? "[x]" : "[ ]") : "-"
            let req = c.requires.isEmpty ? "" : " (Requires: \(c.requires.joined(separator: ", ")))"
            print("- \(mark) \(c.name) — Source: \(c.source), Reliability: \(c.reliability)\(req)")
        }
        print("\n## Apple/Beats Headphone Models\n")
        let sorted = appleHeadphoneModels.keys.sorted()
        for k in sorted { print("- \(k): \(appleHeadphoneModels[k]!)") }
        if now { print("\nNote: [x] means enabled with current settings on this Mac.") }
    }
}

// MARK: - Root command
struct AirbatteryCLI: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "airbattery",
        abstract: "AirBattery command-line tool",
        version: "0.2.0",
        subcommands: [List.self, Supported.self],
        defaultSubcommand: List.self
    )
}

AirbatteryCLI.main()
