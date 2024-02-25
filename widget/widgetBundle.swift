//
//  widgetBundle.swift
//  widget
//
//  Created by apple on 2024/2/18.
//

import WidgetKit
import SwiftUI

extension View {
    func widgetBackground(_ backgroundView: some View) -> some View {
        // 如果是 iOS 17，则使用 containerBackground
        if #available(macOS 14.0, *) {
            return containerBackground(for: .widget) {
                backgroundView
            }
        } else {
            return background(backgroundView)
        }
    }
}

extension WidgetConfiguration {
    func disableContentMarginsIfNeeded() -> some WidgetConfiguration {
        if #available(macOS 12.0, *) {
            return self.contentMarginsDisabled()
        } else {
            return self
        }
    }
}

@main
struct widgetBundle: WidgetBundle {
    var body: some Widget {
        batteryWidget()
        doubleBatteryWidget()
    }
}
