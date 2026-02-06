import SwiftUI
import Combine

// MARK: BatteryViewModel
class BatteryViewModel: ObservableObject {
	private let batteryManager: BatteryManagerProtocol
	private var cancellables = Set<AnyCancellable>()
	
	@Published private(set) var currentCapacityPercentage: Int = 0
	@Published private(set) var powerSource: String? = nil
	@Published private(set) var isCharging: Bool? = nil
	
	init(batteryManager: BatteryManagerProtocol = BatteryManager.shared) {
		self.batteryManager = batteryManager
		updateBatteryState()
		
		
		NotificationCenter.default.publisher(for: .batteryStateUpdated)
			.receive(on: RunLoop.main)
			.map { $0.userInfo?["state"] as? BatteryState }
			.compactMap { $0 }
			.sink { [weak self] _ in self?.updateBatteryState() }
			.store(in: &cancellables)
		
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
