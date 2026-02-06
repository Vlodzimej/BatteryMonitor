//
//  ContentView.swift
//  BatteryMonitor
//
//  Created by Vladimir Amelkin on 05.02.2026.
//

import SwiftUI
import Combine

struct ContentView: View {
    // ✔️ Безопасная инициализация для macOS 12+
    @StateObject private var batteryViewModel: BatteryViewModel
    
    init() {
        _batteryViewModel = StateObject(wrappedValue: BatteryViewModel())
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Заряд батареи")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(spacing: 15) {
                ProgressView(value: CGFloat(batteryViewModel.currentCapacityPercentage) / 100)
                    .progressViewStyle(CircularProgressViewStyle())
                    .tint(batteryViewModel.progressBarColor)
                
                Text("\(batteryViewModel.currentCapacityPercentage)%")
                    .font(.headline)
                    .foregroundColor(batteryViewModel.progressBarColor)
                
                if let powerSource = batteryViewModel.powerSource {
                    Text(powerSource)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // ⚠️ UI-предупреждение при ≥80% и зарядке
                if let isCharging = batteryViewModel.isCharging,
                   batteryViewModel.currentCapacityPercentage >= 80,
                   isCharging {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Батарея на 80% — рекомендуется отключить зарядку", systemImage: "bolt.circle")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                        Button("Отключить предупреждение") {
                            // Здесь можно переключать состояние в будущем
                            print("Уведомление отключено")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.mini)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .foregroundColor(.secondary.opacity(0.1))
            )
            .frame(width: 200, height: 200)
        }
        .padding()
    }
}

