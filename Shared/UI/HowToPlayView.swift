//
//  HowToPlayView.swift
//  AR Golf Game
//
//  Created on 8/9/2025.
//

import SwiftUI

struct HowToPlayView: View {
    @State private var currentStep = 0
    @Environment(\.dismiss) var dismiss
    
    private let onboardingSteps = [
        OnboardingStep(
            title: "Welcome to AR Golf",
            description: "Experience realistic golf in augmented reality. Let's get you started!",
            imageName: "arkit",
            tips: ["Make sure you have good lighting", "Clear a space of at least 6x6 feet"]
        ),
        OnboardingStep(
            title: "Device Calibration",
            description: "Hold your device steady and move it slowly around the playing area.",
            imageName: "iphone.radiowaves.left.and.right",
            tips: [
                "Keep the device upright and steady",
                "Move slowly in a circular motion",
                "Point the camera at different surfaces",
                "Wait for the yellow dots to appear"
            ]
        ),
        OnboardingStep(
            title: "Surface Detection",
            description: "Find a flat surface for your golf course. The app will detect horizontal planes.",
            imageName: "viewfinder",
            tips: [
                "Look for well-lit, textured surfaces",
                "Avoid reflective or transparent surfaces",
                "Tables, floors, and desks work best",
                "Wait for the surface grid to appear"
            ]
        ),
        OnboardingStep(
            title: "Placing Your Course",
            description: "Tap on a detected surface to place your golf hole and start playing.",
            imageName: "hand.tap",
            tips: [
                "Tap anywhere on the detected surface",
                "The hole will appear automatically",
                "You can move the course by tapping again",
                "Make sure you have room to swing"
            ]
        ),
        OnboardingStep(
            title: "Golf Controls",
            description: "Swipe to aim, pull back to set power, and release to shoot!",
            imageName: "sportscourt",
            tips: [
                "Swipe left/right to aim your shot",
                "Pull down to increase power",
                "Release to hit the ball",
                "Watch the power meter for accuracy"
            ]
        )
    ]
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Progress Bar
                    ProgressView(value: Double(currentStep + 1), total: Double(onboardingSteps.count))
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    
                    // Content Area
                    ScrollView {
                        VStack(spacing: 24) {
                            // Step Indicator
                            HStack {
                                ForEach(0..<onboardingSteps.count, id: \.self) { index in
                                    Circle()
                                        .fill(index <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                                        .frame(width: 12, height: 12)
                                        .animation(.easeInOut(duration: 0.3), value: currentStep)
                                }
                            }
                            .padding(.top, 20)
                            
                            // Main Content
                            let step = onboardingSteps[currentStep]
                            
                            // Icon
                            Image(systemName: step.imageName)
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                                .padding(.bottom, 16)
                            
                            // Title
                            Text(step.title)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                            
                            // Description
                            Text(step.description)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                                .lineLimit(nil)
                            
                            // Tips Section
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "lightbulb")
                                        .foregroundColor(.yellow)
                                    Text("Tips:")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    Spacer()
                                }
                                
                                ForEach(step.tips, id: \.self) { tip in
                                    HStack(alignment: .top, spacing: 12) {
                                        Circle()
                                            .fill(Color.blue)
                                            .frame(width: 6, height: 6)
                                            .padding(.top, 8)
                                        
                                        Text(tip)
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                            .lineLimit(nil)
                                        
                                        Spacer()
                                    }
                                }
                            }
                            .padding(16)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .padding(.horizontal, 20)
                            .padding(.top, 24)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Navigation Buttons
                    HStack(spacing: 16) {
                        if currentStep > 0 {
                            Button("Previous") {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentStep -= 1
                                }
                            }
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                        } else {
                            Spacer()
                        }
                        
                        Button(currentStep == onboardingSteps.count - 1 ? "Start Playing" : "Next") {
                            if currentStep == onboardingSteps.count - 1 {
                                dismiss()
                            } else {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentStep += 1
                                }
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .padding(.top, 16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Skip") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct OnboardingStep {
    let title: String
    let description: String
    let imageName: String
    let tips: [String]
}

#Preview {
    HowToPlayView()
}
