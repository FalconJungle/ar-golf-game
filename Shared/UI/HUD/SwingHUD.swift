//
//  SwingHUD.swift
//  AR Golf Game
//
//  Created on 8/9/25.
//

import SwiftUI
import ARKit

struct SwingHUD: View {
    @StateObject private var swingAnalyzer = SwingAnalyzer()
    @StateObject private var weatherManager = WeatherManager()
    
    var body: some View {
        VStack {
            HStack {
                // Power Meter
                PowerMeter(power: swingAnalyzer.currentPower)
                    .frame(width: 80, height: 200)
                
                Spacer()
                
                // Wind Indicator
                WindIndicator(
                    windSpeed: weatherManager.windSpeed,
                    windDirection: weatherManager.windDirection
                )
                .frame(width: 120, height: 120)
                
                Spacer()
                
                // Accuracy Meter
                AccuracyMeter(accuracy: swingAnalyzer.currentAccuracy)
                    .frame(width: 80, height: 200)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false) // Allow touches to pass through to AR scene
    }
}

// MARK: - Power Meter Component
struct PowerMeter: View {
    let power: Double // 0.0 to 1.0
    
    var body: some View {
        VStack {
            Text("POWER")
                .font(.caption)
                .foregroundColor(.white)
                .shadow(color: .black, radius: 1)
            
            ZStack(alignment: .bottom) {
                // Background
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.5), lineWidth: 2)
                    )
                
                // Power fill
                GeometryReader { geometry in
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: powerGradientColors,
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(height: geometry.size.height * power)
                        .animation(.easeInOut(duration: 0.1), value: power)
                }
                .padding(4)
            }
            
            Text("\(Int(power * 100))%")
                .font(.caption2)
                .foregroundColor(.white)
                .shadow(color: .black, radius: 1)
        }
    }
    
    private var powerGradientColors: [Color] {
        switch power {
        case 0.0..<0.3:
            return [.green, .yellow]
        case 0.3..<0.7:
            return [.yellow, .orange]
        default:
            return [.orange, .red]
        }
    }
}

// MARK: - Accuracy Meter Component
struct AccuracyMeter: View {
    let accuracy: Double // 0.0 to 1.0
    
    var body: some View {
        VStack {
            Text("ACCURACY")
                .font(.caption)
                .foregroundColor(.white)
                .shadow(color: .black, radius: 1)
            
            ZStack(alignment: .bottom) {
                // Background
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.5), lineWidth: 2)
                    )
                
                // Accuracy fill
                GeometryReader { geometry in
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: accuracyGradientColors,
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(height: geometry.size.height * accuracy)
                        .animation(.easeInOut(duration: 0.1), value: accuracy)
                }
                .padding(4)
            }
            
            Text("\(Int(accuracy * 100))%")
                .font(.caption2)
                .foregroundColor(.white)
                .shadow(color: .black, radius: 1)
        }
    }
    
    private var accuracyGradientColors: [Color] {
        switch accuracy {
        case 0.0..<0.5:
            return [.red, .orange]
        case 0.5..<0.8:
            return [.orange, .yellow]
        default:
            return [.yellow, .green]
        }
    }
}

// MARK: - Wind Indicator Component
struct WindIndicator: View {
    let windSpeed: Double // mph
    let windDirection: Double // degrees
    
    var body: some View {
        VStack(spacing: 8) {
            Text("WIND")
                .font(.caption)
                .foregroundColor(.white)
                .shadow(color: .black, radius: 1)
            
            ZStack {
                // Background circle
                Circle()
                    .fill(Color.black.opacity(0.3))
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.5), lineWidth: 2)
                    )
                
                // Wind direction arrow
                Image(systemName: "arrow.up")
                    .font(.title2)
                    .foregroundColor(windSpeedColor)
                    .rotationEffect(.degrees(windDirection))
                    .shadow(color: .black, radius: 1)
                
                // Center dot
                Circle()
                    .fill(Color.white)
                    .frame(width: 6, height: 6)
            }
            
            Text("\(Int(windSpeed)) mph")
                .font(.caption2)
                .foregroundColor(.white)
                .shadow(color: .black, radius: 1)
        }
    }
    
    private var windSpeedColor: Color {
        switch windSpeed {
        case 0..<5:
            return .green
        case 5..<10:
            return .yellow
        case 10..<15:
            return .orange
        default:
            return .red
        }
    }
}

// MARK: - Supporting Classes
class SwingAnalyzer: ObservableObject {
    @Published var currentPower: Double = 0.0
    @Published var currentAccuracy: Double = 1.0
    @Published var isSwinging: Bool = false
    
    private var motionManager = CMMotionManager()
    
    init() {
        startMotionTracking()
    }
    
    private func startMotionTracking() {
        guard motionManager.isDeviceMotionAvailable else { return }
        
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let motion = motion, error == nil else { return }
            self?.processMotionData(motion)
        }
    }
    
    private func processMotionData(_ motion: CMDeviceMotion) {
        let acceleration = motion.userAcceleration
        let totalAcceleration = sqrt(pow(acceleration.x, 2) + pow(acceleration.y, 2) + pow(acceleration.z, 2))
        
        // Update power based on motion intensity
        withAnimation(.easeInOut(duration: 0.1)) {
            currentPower = min(1.0, totalAcceleration / 3.0)
        }
        
        // Update accuracy based on motion stability
        let rotationRate = motion.rotationRate
        let totalRotation = sqrt(pow(rotationRate.x, 2) + pow(rotationRate.y, 2) + pow(rotationRate.z, 2))
        
        withAnimation(.easeInOut(duration: 0.1)) {
            currentAccuracy = max(0.0, 1.0 - (totalRotation / 10.0))
        }
    }
    
    deinit {
        motionManager.stopDeviceMotionUpdates()
    }
}

class WeatherManager: ObservableObject {
    @Published var windSpeed: Double = 0.0
    @Published var windDirection: Double = 0.0
    
    init() {
        // Simulate wind conditions
        simulateWind()
    }
    
    private func simulateWind() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            withAnimation(.easeInOut(duration: 1.0)) {
                self?.windSpeed = Double.random(in: 0...15)
                self?.windDirection = Double.random(in: 0...360)
            }
        }
    }
}

// MARK: - Preview
struct SwingHUD_Previews: PreviewProvider {
    static var previews: some View {
        SwingHUD()
            .background(Color.blue.opacity(0.3)) // Simulate AR background
    }
}
