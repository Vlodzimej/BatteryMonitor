//
//  BatteryManager.swift
//  BatteryMonitor
//
//  Created by Vladimir Amelkin on 05.02.2026.
//

import Foundation
import IOKit.ps
import UserNotifications

// MARK: BatteryState
struct BatteryState: Equatable {
    let capacity: Int?
    let maxCapacity: Int?
    let powerSource: String?
}

// MARK: BatteryManagerProtocol
protocol BatteryManagerProtocol {
    func getBatteryState() -> BatteryState?
}

// MARK: BatteryManager
class BatteryManager: BatteryManagerProtocol {
    
    static let shared: BatteryManagerProtocol = BatteryManager()
    
    // C-compatible callback that does not capture Swift context
    private static let powerSourceChangedCallback: IOPowerSourceCallbackType = { context in
        // Recover the BatteryManager instance from the opaque context pointer
        guard let context = context else { return }
        let unmanaged = Unmanaged<BatteryManager>.fromOpaque(context)
        let manager = unmanaged.takeUnretainedValue()
        manager.handlePowerSourceChanged()
    }
    
    private var lastLowNotificationLevel: Int? = nil
    private var lastHighNotificationLevel: Int? = nil
    
    init() {
        initialize()
        requestNotificationPermissions()
    }
    
    // Ключевые параметры (Ключи)
    // Для детальной информации используйте следующие ключи в словаре description:
    // kIOPSCurrentCapacityKey: Текущий уровень заряда (Int).
    // kIOPSMaxCapacityKey: Максимальная емкость (Int).
    // kIOPSInternalBatteryKey: Проверка, является ли батарея встроенной.
    // kIOPSPowerSourceStateKey: Источник питания (от сети/батареи).

    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Ошибка запроса разрешений на уведомления: \(error)")
            } else {
                print("Разрешения на уведомления: \(granted ? "предоставлены" : "отклонены")")
            }
        }
    }
    
    private func initialize() {
        // Prepare opaque context with a retained reference to self
        let context = Unmanaged.passRetained(self).toOpaque()
        if let runLoopSource = IOPSNotificationCreateRunLoopSource(BatteryManager.powerSourceChangedCallback, context)?.takeRetainedValue() {
            
            // Добавление в текущий RunLoop (обычно Main)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .defaultMode)
            // Balance the retain performed when creating the context; the run loop source holds its own reference now
            Unmanaged<BatteryManager>.fromOpaque(context).release()
            
            print("Подписка на события питания активна.")
        }
    }
    
    // Instance handler invoked from the C callback
    private func handlePowerSourceChanged() {
        guard let state = self.getBatteryState(),
              let capacity = state.capacity,
              let maxCapacity = state.maxCapacity,
              maxCapacity > 0 else { return }
        
        let percentage = Int(Double(capacity) / Double(maxCapacity) * 100)
        
        // Notify about threshold crossings
        checkAndNotifyAboutBatteryLevel(percentage)
        
        print("Батарея: \(percentage)%")
    }
    
    private func checkAndNotifyAboutBatteryLevel(_ capacity: Int) {
        guard capacity <= 20 || capacity >= 80 else { return }
        
        if capacity <= 20 {
            if lastLowNotificationLevel != capacity {
                lastLowNotificationLevel = capacity
                lastHighNotificationLevel = nil
                showNotification(title: "Низкий заряд батареи", body: "Заряд батареи составляет \(capacity)%")
            }
        } else if capacity >= 80 {
            if lastHighNotificationLevel != capacity {
                lastHighNotificationLevel = capacity
                lastLowNotificationLevel = nil
                showNotification(title: "Высокий заряд батареи", body: "Заряд батареи составляет \(capacity)%")
            }
        }
    }
    
    private func showNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    func getBatteryState() -> BatteryState? {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array
        
        for source in sources {
            if let description = IOPSGetPowerSourceDescription(snapshot, source).takeUnretainedValue() as? [String: Any] {
                let batteryState = BatteryState(
                    capacity: description[kIOPSCurrentCapacityKey] as? Int,
                    maxCapacity: description[kIOPSMaxCapacityKey] as? Int,
                    powerSource: description[kIOPSPowerSourceStateKey] as? String
                )
                return batteryState
            }
        }
        return nil
    }
}

