//
//  ContentView.swift
//  BatteryMonitor
//
//  Created by Vladimir Amelkin on 05.02.2026.
//

import SwiftUI
import Combine

struct ContentView: View {
	var body: some View {
		VStack(spacing: 20) {
			Text("Заряд батареи")
				.font(.title2)
				.fontWeight(.semibold)
			
			BatteryView()
			
		}
		.padding()
	}
}

