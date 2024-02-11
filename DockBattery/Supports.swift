//
//  Support.swift
//  DockBattery
//
//  Created by apple on 2024/2/9.
//
import SwiftUI

struct dayAndWeek {
    var day: String
    var week: String
    var time: String
    var locale: String
}

extension String {
    var boolValue: Bool { return (self as NSString).boolValue }
    var local: String { return NSLocalizedString(self, comment: "") }
}

extension NSMenuItem {
    func performAction() {
        guard let menu else {
            return
        }
        menu.performActionForItem(at: menu.index(of: self))
    }
}

extension View {
    func renderAsImage() -> NSImage? {
        let view = NoInsetHostingView(rootView: self)
        view.setFrameSize(view.fittingSize)
        return view.bitmapImage()
    }
}

extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }

    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return self.map { String(format: format, $0) }.joined()
    }
    
    func ascii() -> String? {
        var asciiString = ""
        for byte in self {
            asciiString.append(Character(UnicodeScalar(byte)))
        }
        return asciiString.replacingOccurrences(of: "\0", with: "")
    }
}

extension NSView {
    func bitmapImage() -> NSImage? {
        guard let rep = bitmapImageRepForCachingDisplay(in: bounds) else {
            return nil
        }
        cacheDisplay(in: bounds, to: rep)
        guard let cgImage = rep.cgImage else {
            return nil
        }
        return NSImage(cgImage: cgImage, size: bounds.size)
    }
    
}

class NoInsetHostingView<V>: NSHostingView<V> where V: View {
    override var safeAreaInsets: NSEdgeInsets {
        return .init()
    }
}

public func process(path: String, arguments: [String]) -> String? {
    let task = Process()
    task.launchPath = path
    task.arguments = arguments
    task.standardError = Pipe()
    
    let outputPipe = Pipe()
    defer {
        outputPipe.fileHandleForReading.closeFile()
    }
    task.standardOutput = outputPipe
    
    do {
        try task.run()
    } catch let error {
        print("\(error.localizedDescription)")
        return nil
    }
    
    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(decoding: outputData, as: UTF8.self)
    
    if output.isEmpty {
        return nil
    }
    
    return output.trimmingCharacters(in: .newlines)
}

func hexToIPv6Address(hexString: String) -> String? {
    // 将 16 进制字符串转换为整数
    guard let hexValue = UInt64(hexString, radix: 16) else {
        return nil
    }
    
    // 将整数转换为 IPv6 地址字符串
    var ipAddress = ""
    for i in 0..<8 {
        let offset = 16 * (7 - i)
        let value = (hexValue >> offset) & 0xFFFF
        ipAddress += String(format: "%04X", value)
        if i != 7 {
            ipAddress += ":"
        }
    }
    
    return ipAddress
}

func getDayAndWeek(_ long:Bool? = false) -> dayAndWeek {
    let now = Date()
    let dateFormatter = DateFormatter()
    let locale = Locale(identifier: Locale.preferredLanguages.first ?? "en_US")
    dateFormatter.dateFormat = "EE"
    dateFormatter.locale = locale
    let week = dateFormatter.string(from: now)
    dateFormatter.dateFormat = "d"
    dateFormatter.locale = locale
    let day = dateFormatter.string(from: now)
    if DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: Locale.current)?.contains("a") == true {
        dateFormatter.dateFormat = "hh:mm"
    } else {
        dateFormatter.dateFormat = "HH:mm"
    }
    dateFormatter.locale = locale
    let time = dateFormatter.string(from: now)
    /*
    let local = Locale(identifier: Locale.preferredLanguages.first ?? "en_US")
    let week = now.formatted(Date.FormatStyle(locale: local).weekday(.abbreviated))
    let day = now.formatted(Date.FormatStyle(locale: Locale(identifier: "en_US_POSIX")).day(.twoDigits))
    let time = now.formatted(Date.FormatStyle().hour(.defaultDigits(amPM: .omitted)).minute())*/
    return dayAndWeek(day: day, week: week, time: time, locale: locale.languageCode!)
}

func getDarkMode() -> Bool {
    @AppStorage("appearance") var appearance = "auto"
    return (appearance == "auto") ? NSApp.effectiveAppearance == NSAppearance(named: .darkAqua) : appearance.boolValue
}

func fetchData(from url: URL, maxRetryCount: Int, completion: @escaping (Result<String, Error>) -> Void) {
    var retryCount = 0
    
    func fetchData() {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("curl/8.1.2", forHTTPHeaderField: "User-Agent")
        request.setValue("*/*", forHTTPHeaderField: "Accept")
        request.setValue("", forHTTPHeaderField: "Accept-Language")
        request.setValue("", forHTTPHeaderField: "Accept-Encoding")
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                if retryCount < maxRetryCount {
                    print("Try Again \(retryCount + 1)...")
                    retryCount += 1
                    fetchData() // 重新尝试
                } else {
                    completion(.failure(error))
                }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 || httpResponse.statusCode == 404 {
                    if let data = data {
                        if let content = String(data: data, encoding: .utf8) {
                            completion(.success(content))
                        }
                    }
                } else {
                    print("HTTP Code：\(httpResponse.statusCode)")
                    if retryCount < maxRetryCount {
                        print("Try Again \(retryCount + 1)...")
                        retryCount += 1
                        fetchData() // 重新尝试
                    } else {
                        completion(.failure(NSError(domain: "HTTPErrorDomain", code: httpResponse.statusCode, userInfo: nil)))
                    }
                }
            }
        }
        task.resume()
    }
    fetchData()
}

func getMonoNum(_ num: Int, count: Int = 3) -> String {
    let chars = ["𝟢","𝟣","𝟤","𝟥","𝟦","𝟧","𝟨","𝟩","𝟪","𝟫"]
    //let chars = ["𝟬","𝟭","𝟮","𝟯","𝟰","𝟱","𝟲","𝟳","𝟴","𝟵"]
    var output: [String] = []
    for i in String(num) { if let n = Int(String(i)) { output.append(chars[n]) } }
    return String(repeating: "  ", count: (count - output.count)) + output.joined()
}

func getIbByName(name: String = "@MacInternalBattery") -> iBattery {
    if name == "@MacInternalBattery" { return getPowerState() }
    var ib = iBattery(hasBattery: false, isCharging: false, isCharged: false, acPowered: false, timeLeft: "", batteryLevel: 0)
    if let abStatus = AirBatteryModel.getByName(name){
        ib.hasBattery = abStatus.hasBattery
        ib.batteryLevel = abStatus.batteryLevel
        ib.isCharging = (abStatus.isCharging != 0) ? true : false
        ib.acPowered = ib.isCharging
        ib.timeLeft = "…"
    }
    return ib
}

func getIbByID(id: String = "@MacInternalBattery") -> iBattery {
    if id == "@MacInternalBattery" { return getPowerState() }
    var ib = iBattery(hasBattery: false, isCharging: false, isCharged: false, acPowered: false, timeLeft: "", batteryLevel: 0)
    if let abStatus = AirBatteryModel.getByID(id){
        ib.hasBattery = abStatus.hasBattery
        ib.batteryLevel = abStatus.batteryLevel
        ib.isCharging = (abStatus.isCharging != 0) ? true : false
        ib.acPowered = ib.isCharging
        ib.timeLeft = "…"
    }
    return ib
}

func getDeviceIcon(_ d: Device) -> Image {
    switch d.deviceType {
    case "iPhone":
        if let model = d.deviceModel, let m = model.components(separatedBy: ",").first, let id = m.components(separatedBy: "e").last {
            if (Int(id) ?? 0 > 9) && !["iPhone12,8", "iPhone14,6"].contains(model) { return Image(systemName: "iphone") }
            return Image(systemName: "iphone.homebutton") }
        return Image(systemName: "iphone")
    case "iPad":
        if let model = d.deviceModel, let m = model.components(separatedBy: ",").first {
            if ["iPad8", "iPad13", "iPad14"].contains(m) { return Image(systemName: "ipad") }
            return Image(systemName: "ipad.homebutton") }
        return Image(systemName: "ipad")
    case "iWatch":
        return Image(systemName: "applewatch")
    case "hid_tpd":
        return Image("trackpad.fill")
    case "hid_kbd":
        return Image(systemName: "keyboard.fill")
    case "hid_mus":
        return Image(systemName: "magicmouse.fill")
    case "ap_pod_right":
        if let model = d.deviceModel {
            switch model {
            case "Airpods":
                return Image(systemName: "airpod.right")
            case "Airpods Pro":
                return Image(systemName: "airpodpro.right")
            case "Airpods Max":
                return Image("airpodsmax")
            case "Airpods 2":
                return Image(systemName: "airpod.right")
            case "Airpods 3":
                return Image("airpod3.right")
            case "Airpods Pro 2":
                return Image(systemName: "airpodpro.right")
            case "PowerBeats":
                return Image("beats.powerbeats.right")
            case "PowerBeats Pro":
                return Image("beats.powerbeatspro.right")
            case "Beats Solo Pro":
                return Image("beats.headphones")
            case "Beats Studio Buds":
                return Image("beats.studiobud.right")
            case "Beats Flex":
                return Image("beats.earphones")
            case "BeatsX":
                return Image("beats.earphones")
            case "Beats Solo3":
                return Image("beats.headphones")
            case "Beats Studio3":
                return Image("beats.studiobud.right")
            case "Beats Studio Pro":
                return Image("beats.studiobud.right")
            case "Beats Fit Pro":
                return Image("beats.fitpro.right")
            case "Beats Studio Buds+":
                return Image("beats.studiobud.right")
            default:
                return Image(systemName: "airpod.right")
            }
        }
        return Image(systemName: "airpod.right")
    case "ap_pod_left":
        if let model = d.deviceModel {
            switch model {
            case "Airpods":
                return Image(systemName: "airpod.left")
            case "Airpods Pro":
                return Image(systemName: "airpodpro.left")
            case "Airpods Max":
                return Image("airpodsmax")
            case "Airpods 2":
                return Image(systemName: "airpod.left")
            case "Airpods 3":
                return Image("airpod3.right")
            case "Airpods Pro 2":
                return Image(systemName: "airpodpro.left")
            case "PowerBeats":
                return Image("beats.powerbeats.left")
            case "PowerBeats Pro":
                return Image("beats.powerbeatspro.left")
            case "Beats Solo Pro":
                return Image("beats.headphones")
            case "Beats Studio Buds":
                return Image("beats.studiobud.left")
            case "Beats Flex":
                return Image("beats.earphones")
            case "BeatsX":
                return Image("beats.earphones")
            case "Beats Solo3":
                return Image("beats.headphones")
            case "Beats Studio3":
                return Image("beats.studiobud.left")
            case "Beats Studio Pro":
                return Image("beats.studiobud.left")
            case "Beats Fit Pro":
                return Image("beats.fitpro.left")
            case "Beats Studio Buds+":
                return Image("beats.studiobud.left")
            default:
                return Image(systemName: "airpod.left")
            }
        }
        return Image(systemName: "airpod.left")
    case "ap_pod_all":
        return Image(systemName: "airpodspro")
    case "ap_case":
        if let model = d.deviceModel {
            switch model {
            case "Airpods":
                return Image("airpods.case.fill")
            case "Airpods Pro":
                return Image("airpodspro.case.fill")
            case "Airpods Max":
                return Image("airpodsmax")
            case "Airpods 2":
                return Image("airpods.case.fill")
            case "Airpods 3":
                return Image("airpods3.case.fill")
            case "Airpods Pro 2":
                return Image("airpodspro.case.fill")
            case "PowerBeats":
                return Image("beats.powerbeatspro.case.fill")
            case "PowerBeats Pro":
                return Image("beats.powerbeatspro.case.fill")
            case "Beats Solo Pro":
                return Image("beats.headphones")
            case "Beats Studio Buds":
                return Image("beats.studiobuds.case.fill")
            case "Beats Flex":
                return Image("beats.earphones")
            case "BeatsX":
                return Image("beats.earphones")
            case "Beats Solo3":
                return Image("beats.headphones")
            case "Beats Studio3":
                return Image("beats.studiobuds.case.fill")
            case "Beats Studio Pro":
                return Image("beats.studiobuds.case.fill")
            case "Beats Fit Pro":
                return Image("beats.fitpro.case.fill")
            case "Beats Studio Buds+":
                return Image("beats.studiobuds.case.fill")
            default:
                return Image("airpodspro.case.fill")
            }
        }
        return Image("airpodspro.case.fill")
    default:
        return Image(systemName: "dot.radiowaves.left.and.right")
    }
}
