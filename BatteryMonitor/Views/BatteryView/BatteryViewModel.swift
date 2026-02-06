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
	@Published private(set) var isCharging: Bool? = nil  // ← новое свойство
	
	init(batteryManager: BatteryManagerProtocol = BatteryManager.shared) {
		self.batteryManager = batteryManager
		updateBatteryState()
		
		Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
			self?.updateBatteryState()
		}
	}
	
	func updateBatteryState() {
		guard let state = batteryManager.getBatteryState(),
					let capacity = state.capacity,
					let maxCapacity = state.maxCapacity,
					maxCapacity > 0 else { return }
		
		let percentage = Int(Double(capacity) / Double(maxCapacity) * 100)
		currentCapacityPercentage = percentage
		powerSource = state.powerSource
		isCharging = state.isCharging
	}
	
	var progressBarColor: Color {
		guard currentCapacityPercentage > 0 else { return .gray }
		
		switch currentCapacityPercentage {
			case ..<20: return .red
			case 81...100: return .yellow
			default: return .green
		}
	}
}
