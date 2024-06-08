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
        if #available(macOS 14.0, *) {
            return containerBackground(for: .widget) { backgroundView }
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
    
    func supportFamily() -> some WidgetConfiguration {
        if #available(macOS 14, *) {
            return self.supportedFamilies([.systemLarge, .systemMedium])
        } else {
            return self.supportedFamilies([.systemLarge, .systemMedium, .systemSmall])
        }
    }
}

@main
struct widgetBundle: WidgetBundle {
    var body: some Widget {
        widgets()
    }
    
    func widgets() -> some Widget {
        if #available(macOS 14, *) {
            return WidgetBundleBuilder.buildBlock(batteryWidget(), batteryWidget2New(), batteryWidget2(), batteryWidget3())
        } else {
            return WidgetBundleBuilder.buildBlock(batteryWidget(), batteryWidget2(), batteryWidget3())
        }
    }
}
