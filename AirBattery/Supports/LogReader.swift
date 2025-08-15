import Foundation
import SwiftUI

class LogReader {
    static let shared = LogReader()

    @AppStorage("readBTHID") var readBTHID = true
    @AppStorage("logReaderLastTS") var lastTS: String = ""   // e.g. "2025-07-01 12:34:56 +0000"

    private var isRunning = false
    private var queued = false
    private let lock = NSLock()
    private let fmt: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZZZ"
        return f
    }()

    enum Trigger { case bootstrap, wake, connect }

    func run(_ trigger: Trigger) {
        guard readBTHID else { return }
        lock.lock()
        if isRunning { queued = true; lock.unlock(); return }
        isRunning = true
        lock.unlock()

        // Build arguments
        let args: [String]
        if let start = computeStart(trigger) {
            setenv("START_TS", start, 1)
            args = ["\(Bundle.main.resourcePath!)/logReader.sh", "mac", "10m"]
        } else {
            unsetenv("START_TS")
            let win = (trigger == .bootstrap) ? "20m" : (trigger == .wake ? "3m" : "2m")
            args = ["\(Bundle.main.resourcePath!)/logReader.sh", "mac", win]
        }

        // Short timeout to bound CPU
        let out = process(path: "/bin/bash", arguments: args, timeout: 5)
        parseAndUpdate(output: out)
        advanceLastTS()

        lock.lock()
        isRunning = false
        let again = queued
        queued = false
        lock.unlock()

        if again {
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.8) { self.run(.wake) }
        }
    }

    private func computeStart(_ trigger: Trigger) -> String? {
        if lastTS.isEmpty {
            let t = Date(timeIntervalSinceNow: -20*60)
            return fmt.string(from: t)
        }
        if let prev = fmt.date(from: lastTS) {
            return fmt.string(from: prev.addingTimeInterval(-2))
        }
        return nil
    }

    private func advanceLastTS() {
        lastTS = fmt.string(from: Date().addingTimeInterval(-2))
    }

    private func parseAndUpdate(output: String?) {
        guard let output = output, !output.isEmpty else { return }
        let parent = ud.string(forKey: "deviceName") ?? "Mac"
        for line in output.split(separator: "\n") {
            if let json = try? JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any] {
                let mac = json["mac"] as? String ?? ""
                var name = json["name"] as? String ?? ""
                let type = json["type"] as? String ?? "hid"
                let time = json["time"] as? String ?? ""
                let level = json["level"] as? Int ?? 0
                let status = (json["status"] as? String == "+") ? 1 : 0
                if name.isEmpty { name = "\(type) (\(mac))" }
                AirBatteryModel.updateDevice(Device(deviceID: mac, deviceType: type, deviceName: name, batteryLevel: min(100, max(0, level)), isCharging: status, parentName: parent, lastUpdate: Date().timeIntervalSince1970, realUpdate: isoFormatter.date(from: time)?.timeIntervalSince1970 ?? 0.0))
            }
        }
    }
}

