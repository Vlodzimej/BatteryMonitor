	//
	//  BatteryManager.swift
	//  BatteryMonitor
	//
	//  Created by Vladimir Amelkin on 05.02.2026.
	//

import Foundation
import IOKit.ps
import UserNotifications

// MARK: - BatteryState
struct BatteryState: Equatable {
	let capacity: Int?
	let maxCapacity: Int?
	let powerSource: String?
	let isCharging: Bool?
}

// MARK: - BatteryManagerProtocol
protocol BatteryManagerProtocol {
	func getBatteryState() -> BatteryState?
}

	// MARK: - BatteryManager
class BatteryManager: BatteryManagerProtocol {
	
	static let shared: BatteryManagerProtocol = BatteryManager()
	
	private static let powerSourceChangedCallback: IOPowerSourceCallbackType = { context in
		guard let context = context else { return }
		let unmanaged = Unmanaged<BatteryManager>.fromOpaque(context)
		let manager = unmanaged.takeUnretainedValue()
		manager.handlePowerSourceChanged()
	}
	
	private var notificationSentForBatteryLevel: Bool = false
	
	init() {
		initialize()
		requestNotificationPermission()
	}
	
	private func initialize() {
		let context = Unmanaged.passRetained(self).toOpaque()
		if let runLoopSource = IOPSNotificationCreateRunLoopSource(BatteryManager.powerSourceChangedCallback, context)?.takeRetainedValue() {
			CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .defaultMode)
			Unmanaged<BatteryManager>.fromOpaque(context).release()
			print("Подписка на события питания активна.")
		}
	}
	
	private func handlePowerSourceChanged() {
		guard let state = getBatteryState() else { return }
		print("Батарея: \(state.capacity ?? 0)%, заряжается: \(state.isCharging != false)")
		checkAndSendBatteryNotification(state: state)
	}
	
	func getBatteryState() -> BatteryState? {
		let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
		let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array
		
		for source in sources {
			if let description = IOPSGetPowerSourceDescription(snapshot, source).takeUnretainedValue() as? [String: Any] {
				let batteryState = BatteryState(
					capacity: description[kIOPSCurrentCapacityKey] as? Int,
					maxCapacity: description[kIOPSMaxCapacityKey] as? Int,
					powerSource: description[kIOPSPowerSourceStateKey] as? String,
					isCharging: description[kIOPSIsChargingKey] as? Bool
				)
				return batteryState
			}
		}
		return nil
	}
	
		// MARK: - Notification Support
	
	private func requestNotificationPermission() {
		UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
			if let error = error {
				print("⚠️ Ошибка запроса разрешения на уведомления: \(error)")
			} else {
				print("✅ Уведомления \(granted ? "разрешены" : "запрещены")")
			}
		}
	}
	
	private func checkAndSendBatteryNotification(state: BatteryState) {
		guard let capacity = state.capacity,
					let maxCapacity = state.maxCapacity,
					maxCapacity > 0 else { return }
		
		let percentage = Int(Double(capacity) / Double(maxCapacity) * 100)
		let isCharging = state.isCharging ?? false
		
			// Отправляем оповещение только один раз при достижении ≥80% и зарядке
		if percentage >= 80 && isCharging && !notificationSentForBatteryLevel {
			sendBatteryNotification(percentage: percentage)
			notificationSentForBatteryLevel = true
		} else if percentage < 80 {
				// Сброс флага, когда батарея разряжается ниже 80%
			notificationSentForBatteryLevel = false
		}
	}
	
	private func sendBatteryNotification(percentage: Int) {
		let content = UNMutableNotificationContent()
		content.title = "🔋 Батарея заряжена"
		content.subtitle = "Достигнут уровень \(percentage)% — рекомендуется отключить зарядное устройство"
		content.body = "Это поможет продлить срок службы аккумулятора."
		content.sound = .default
		content.categoryIdentifier = "battery.charge.full"
		
			// Use UNNotificationTimeDateTrigger for latest API\
		let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
		let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
		UNUserNotificationCenter.current().add(request) { error in
			if let error = error {
				print("❌ Ошибка при отправке уведомления: \(error)")
			} else {
				print("✅ Уведомление отправлено: Батарея — \(percentage)%")
			}
		}
	}
}



