//
//  BatteryMonitorApp.swift
//  BatteryMonitor
//
//  Created by Vladimir Amelkin on 05.02.2026.
//

import SwiftUI

@main
struct BatteryMonitorApp: App {
	var body: some Scene {
		WindowGroup {
			ContentView()
				.frame(width: 300, height: 300)
		}
		.windowResizability(.contentSize)
	}
}
