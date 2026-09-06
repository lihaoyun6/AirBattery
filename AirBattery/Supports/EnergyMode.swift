//
//  EnergyMode.swift
//  AirBattery
//
//  Added: Energy mode switching (Automatic / Low Power / High Power)
//         and "Using Significant Energy" app detection.
//

import AppKit
import SwiftUI

enum EnergyMode: Int, CaseIterable {
    case automatic = 0
    case lowPower = 1
    case highPower = 2

    var titleKey: String {
        switch self {
        case .automatic: return "Automatic Mode"
        case .lowPower: return "Low Power Mode"
        case .highPower: return "High Power Mode"
        }
    }

    var icon: String {
        switch self {
        case .automatic: return "arrow.triangle.2.circlepath"
        case .lowPower: return "battery.25percent"
        case .highPower: return "bolt.fill"
        }
    }
}

struct EnergyAppInfo: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let icon: NSImage
    let cpu: Double
}

class EnergyModeManager {

    /// Raw pmset power related values from `pmset -g`.
    /// Modern macOS (26+) exposes a unified "powermode" key (0=auto, 1=low, 2=high),
    /// older systems expose "lowpowermode" / "highpowermode" (0/1 each).
    /// Note: keys and values are separated by SPACES (not tabs); the keys we care
    /// about are single words, so tokenizing by whitespace is sufficient.
    static func rawPowerSettings() -> [String: Int] {
        guard let out = process(path: "/usr/bin/pmset", arguments: ["-g"]) else { return [:] }
        var result = [String: Int]()
        for line in out.split(separator: "\n") {
            let tokens = line.split(separator: " ", omittingEmptySubsequences: true)
            if tokens.count >= 2, let value = Int(tokens.last!.trimmingCharacters(in: .whitespaces)) {
                result[String(tokens[0])] = value
            }
        }
        return result
    }

    /// True when the system uses the unified "powermode" key (macOS 26+).
    static func isModernPowerMode() -> Bool {
        return rawPowerSettings()["powermode"] != nil
    }

    /// High Power mode is only available on select hardware; the key only shows up when supported.
    static func highPowerSupported() -> Bool {
        let settings = rawPowerSettings()
        return settings["powermode"] != nil || settings["highpowermode"] != nil
    }

    /// Current active energy mode.
    static func currentMode() -> EnergyMode? {
        let settings = rawPowerSettings()
        if let pm = settings["powermode"], let mode = EnergyMode(rawValue: pm) { return mode }
        if settings["highpowermode"] == 1 { return .highPower }
        if settings["lowpowermode"] == 1 { return .lowPower }
        if settings["lowpowermode"] != nil || settings["highpowermode"] != nil { return .automatic }
        return nil
    }

    /// Exact sudoers whitelist: only these pmset power-mode commands are allowed
    /// to run passwordless, nothing else. Validated by visudo before install.
    static let sudoersRule = "%admin ALL=(root) NOPASSWD: /usr/bin/pmset -a powermode 0, /usr/bin/pmset -a powermode 1, /usr/bin/pmset -a powermode 2, /usr/bin/pmset -a lowpowermode 0, /usr/bin/pmset -a lowpowermode 1, /usr/bin/pmset -a highpowermode 0, /usr/bin/pmset -a highpowermode 1"
    static let sudoersFile = "/etc/sudoers.d/airbattery"

    /// True when `sudo -n /usr/bin/pmset ...` can run without a password
    /// (i.e. the one-time whitelist is already installed).
    static func passwordlessSudoReady() -> Bool {
        return process(path: "/usr/bin/sudo", arguments: ["-n", "/usr/bin/pmset", "-g"]) != nil
    }

    /// Installs the sudoers whitelist. Requires ONE administrator authorization;
    /// afterwards every energy-mode switch runs without any password prompt.
    static func installPasswordlessWhitelist(completion: (() -> Void)? = nil) {
        let tmpPath = "/tmp/airbattery.sudoers"
        do {
            try sudoersRule.write(toFile: tmpPath, atomically: true, encoding: .utf8)
        } catch {
            print("⚠️ Failed to write temp sudoers file: \(error)")
            completion?()
            return
        }
        // validate syntax first (visudo), then install with root:wheel 0440
        let command = "/usr/sbin/visudo -cf \(tmpPath) >/dev/null && /usr/bin/install -m 0440 -o root -g wheel \(tmpPath) \(sudoersFile) && /bin/rm -f \(tmpPath)"
        CommandLineTool.runAsRoot(command) {
            completion?()
        }
    }

    /// Switch energy mode.
    /// - Normal path: `sudo -n` (passwordless, no prompt) after one-time trust.
    /// - First time: installs the whitelist with a single admin prompt, then switches.
    /// - Fallback: direct elevated pmset (prompts) if the user declined the trust.
    static func set(_ mode: EnergyMode, completion: (() -> Void)? = nil) {
        let pmset = "/usr/bin/pmset"
        let commandSeq: [[String]]
        if isModernPowerMode() {
            commandSeq = [[pmset, "-a", "powermode", "\(mode.rawValue)"]]
        } else {
            switch mode {
            case .automatic: commandSeq = [[pmset, "-a", "lowpowermode", "0"], [pmset, "-a", "highpowermode", "0"]]
            case .lowPower:  commandSeq = [[pmset, "-a", "lowpowermode", "1"], [pmset, "-a", "highpowermode", "0"]]
            case .highPower: commandSeq = [[pmset, "-a", "lowpowermode", "0"], [pmset, "-a", "highpowermode", "1"]]
            }
        }

        let apply: () -> Void = {
            for cmd in commandSeq {
                _ = process(path: "/usr/bin/sudo", arguments: ["-n"] + cmd)
            }
            completion?()
        }

        if passwordlessSudoReady() {
            apply()
        } else {
            installPasswordlessWhitelist {
                if passwordlessSudoReady() {
                    apply()
                } else {
                    // user declined the one-time trust -> fall back to prompting each time
                    CommandLineTool.runAsRoot(commandSeq.map { $0.joined(separator: " ") }.joined(separator: "; ")) {
                        completion?()
                    }
                }
            }
        }
    }

    /// Top energy-consuming apps.
    /// True per-app "energy impact" requires root (powermetrics), so we use the
    /// per-process CPU usage from `ps` (decayed average, weighted towards recent
    /// activity) as a close proxy, aggregated per application bundle.
    static func topEnergyApps(_ count: Int = 3, minCPU: Double = 0.5) -> [EnergyAppInfo] {
        guard let out = process(path: "/bin/ps", arguments: ["-axo", "%cpu=,comm="]) else { return [] }
        var bundles = [String: Double]() // bundlePath -> summed cpu
        for line in out.split(separator: "\n") {
            let parts = line.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
            guard parts.count == 2, let cpu = Double(parts[0]) else { continue }
            let fullPath = parts[1].trimmingCharacters(in: .whitespaces)
            // Roll helper/XPC executables up into their outermost .app bundle
            // (e.g. "WorkBuddy Helper (Renderer).app" -> "WorkBuddy.app")
            guard let marker = fullPath.range(of: ".app/") else { continue }
            let bundlePath = String(fullPath[fullPath.startIndex..<marker.lowerBound]) + ".app"
            if bundlePath.hasSuffix("AirBattery.app") { continue } // don't list ourselves
            bundles[bundlePath, default: 0] += cpu
        }
        return bundles
            .filter { $0.value >= minCPU }
            .sorted { $0.value > $1.value }
            .prefix(count)
            .compactMap { entry in
                let bundleURL = URL(fileURLWithPath: entry.key)
                let bundle = Bundle(url: bundleURL)
                let name = (bundle?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
                    ?? (bundle?.object(forInfoDictionaryKey: "CFBundleName") as? String)
                    ?? bundleURL.deletingPathExtension().lastPathComponent
                let icon = NSWorkspace.shared.icon(forFile: entry.key)
                icon.size = NSSize(width: 20, height: 20)
                return EnergyAppInfo(name: name, path: entry.key, icon: icon, cpu: entry.value)
            }
    }

    /// Opens the system Battery settings pane (same page as native "Battery Settings...").
    static func openBatterySettings() {
        let links = ["x-apple.systempreferences:com.apple.Battery-Settings.extension",
                     "x-apple.systempreferences:com.apple.preference.battery"]
        for link in links {
            if let url = URL(string: link), NSWorkspace.shared.open(url) { return }
        }
    }
}

// MARK: - Popover Section

struct EnergyModeSection: View {
    @State private var currentMode: EnergyMode? = nil
    @State private var highSupported = true
    @State private var topApps: [EnergyAppInfo] = []
    @State private var isSetting = false
    @State private var overMode = -1
    @State private var overApp = -1
    @State private var overSettingsButton = false

    var body: some View {
        if InternalBattery.status.hasBattery {
            VStack(spacing: 0) {
                // Energy Mode header
                HStack {
                    Text("Energy Mode".local)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                    Spacer()
                    if isSetting {
                        ProgressView()
                            .scaleEffect(0.45)
                            .frame(width: 14, height: 14)
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)

                HStack(spacing: 6) {
                    ForEach(EnergyMode.allCases.filter { $0 != .highPower || highSupported }, id: \.rawValue) { mode in
                        let selected = (currentMode == mode)
                        Button(action: { setMode(mode) }, label: {
                            HStack(spacing: 4) {
                                Image(systemName: modeIcon(mode))
                                    .font(.system(size: 11, weight: .medium))
                                Text(mode.titleKey.local)
                                    .font(.system(size: 11.5, weight: selected ? .semibold : .regular))
                                    .lineLimit(1)
                                if selected {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 9, weight: .bold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 5)
                            .background(
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .fill(selected ? Color.accentColor.opacity(0.18) : Color.blackWhite.opacity(overMode == mode.rawValue ? 0.12 : 0.05))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .strokeBorder(selected ? Color.accentColor.opacity(0.55) : Color.secondary.opacity(0.18), lineWidth: 1)
                            )
                        })
                        .buttonStyle(PlainButtonStyle())
                        .focusable(false)
                        .disabled(isSetting)
                        .onHover { hovering in overMode = hovering ? mode.rawValue : -1 }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 8)

                Divider()

                // Using Significant Energy header
                HStack {
                    Text("Using Significant Energy".local)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)

                if topApps.isEmpty {
                    HStack {
                        Text("No Significant Energy Use".local)
                            .font(.system(size: 11.5))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 8)
                } else {
                    ForEach(topApps.indices, id: \.self) { index in
                        HStack(spacing: 7) {
                            Image(nsImage: topApps[index].icon)
                                .resizable()
                                .frame(width: 17, height: 17)
                            Text(topApps[index].name)
                                .font(.system(size: 12))
                                .lineLimit(1)
                            Spacer()
                            Text(String(format: "%.0f%%", topApps[index].cpu))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 10)
                        .background(overApp == index ? Color.blackWhite.opacity(0.12) : .clear)
                        .onHover { hovering in overApp = hovering ? index : -1 }
                        .help(topApps[index].path)
                    }
                    .padding(.bottom, 4)
                }

                Divider()

                // Battery Settings...
                Button(action: {
                    dockWindow.orderOut(nil)
                    menuPopover.performClose(nil)
                    EnergyModeManager.openBatterySettings()
                }, label: {
                    HStack {
                        Text("Battery Settings...".local)
                            .font(.system(size: 12))
                            .foregroundColor(.blackWhite)
                        Spacer()
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(overSettingsButton ? Color.blackWhite.opacity(0.15) : .clear)
                })
                .buttonStyle(PlainButtonStyle())
                .focusable(false)
                .onHover { hovering in overSettingsButton = hovering }
            }
            .padding(.vertical, 1)
            .padding(.horizontal, 6)
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(Color.secondary, lineWidth: 1)
                    .padding(.vertical, -1)
                    .padding(.horizontal, 5)
                    .opacity(0.23)
            )
            .offset(y: 2.5)
            .onAppear {
                refreshMode()
                topApps = EnergyModeManager.topEnergyApps(3)
            }
            .onReceive(dockTimer) { _ in // refresh every 5s while visible
                refreshMode()
                topApps = EnergyModeManager.topEnergyApps(3)
            }
        }
    }

    private func modeIcon(_ mode: EnergyMode) -> String {
        switch mode {
        case .automatic: return "arrow.triangle.2.circlepath"
        case .lowPower: return "battery.25percent"
        case .highPower: return "bolt.fill"
        }
    }

    private func refreshMode() {
        DispatchQueue.global(qos: .utility).async {
            let mode = EnergyModeManager.currentMode()
            let supported = EnergyModeManager.highPowerSupported()
            DispatchQueue.main.async {
                currentMode = mode
                highSupported = supported
            }
        }
    }

    private func setMode(_ mode: EnergyMode) {
        isSetting = true
        DispatchQueue.global(qos: .utility).async {
            EnergyModeManager.set(mode) {
                let m = EnergyModeManager.currentMode()
                DispatchQueue.main.async {
                    currentMode = m ?? mode
                    isSetting = false
                }
            }
        }
    }
}
