//
//  BatteryView.swift
//  BatteryMonitor
//
//  Created by Vladimir Amelkin on 06.02.2026.
//

import SwiftUI

// MARK: BatteryView
struct BatteryView: View {
	@StateObject private var batteryViewModel = BatteryViewModel()
	
	var body: some View {
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
		}
		.padding()
		.background(
			RoundedRectangle(cornerRadius: 15)
				.foregroundColor(.secondary.opacity(0.1))
		)
		.frame(width: 200, height: 200)
	}
}
