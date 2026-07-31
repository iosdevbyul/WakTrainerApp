//
//  ContentView.swift
//  WakTrainer
//
//  Created by COMATOKI on 2026-08-01.
//

import SwiftUI
import WakTrainerFeatureWorkout

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                
                Text("Hello, world!")
                

                NavigationLink {
                    WorkoutSessionView()
                } label: {
                    Text("다음 화면으로 이동")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
