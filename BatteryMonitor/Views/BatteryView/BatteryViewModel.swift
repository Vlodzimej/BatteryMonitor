//
//  BatteryViewModel.swift
//  BatteryMonitor
//
//  Created by Vladimir Amelkin on 06.02.2026.
//

import SwiftUI
import Combine

	// MARK: BatteryViewModel
class BatteryViewModel: ObservableObject {
	private let batteryManager: BatteryManagerProtocol
	
	@Published private(set) var currentCapacityPercentage: Int = 0
	@Published private(set) var powerSource: String? = nil
	
	init(batteryManager: BatteryManagerProtocol = BatteryManager.shared) {
		self.batteryManager = batteryManager
			// Update immediately
		updateBatteryState()
		
			// Set up timer for periodic updates (since notifications may be delayed)
		Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
			self?.updateBatteryState()
		}
	}
	
	func updateBatteryState() {
		if let state = batteryManager.getBatteryState(),
			 let capacity = state.capacity,
			 let maxCapacity = state.maxCapacity,
			 maxCapacity > 0 {
			
			let percentage = Int(Double(capacity) / Double(maxCapacity) * 100)
			
			if currentCapacityPercentage != percentage {
				currentCapacityPercentage = percentage
			}
			
			powerSource = state.powerSource
		}
	}
	
	var progressBarColor: Color {
		guard currentCapacityPercentage > 0 else { return .gray }
		
		switch currentCapacityPercentage {
			case ..<20: return .red
			case 20..<50: return .orange
			case 50..<80: return .yellow
			default: return .green
		}
	}
}
