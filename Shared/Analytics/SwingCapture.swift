import Foundation
import AVFoundation
import CoreMotion
import simd

/// SwingCapture handles golf swing motion detection and analysis
class SwingCapture: ObservableObject {
    @Published var isRecording = false
    @Published var swingData: SwingData?
    @Published var analysisResults: SwingAnalysis?
    
    private let motionManager = CMMotionManager()
    private var swingStartTime: Date?
    private var motionData: [CMDeviceMotion] = []
    private var impactDetected = false
    
    init() {
        setupMotionManager()
    }
    
    private func setupMotionManager() {
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0 // 60 Hz
        motionManager.showsDeviceMovementDisplay = true
    }
    
    /// Start recording swing motion
    func startRecording() {
        guard motionManager.isDeviceMotionAvailable else { return }
        
        isRecording = true
        swingStartTime = Date()
        motionData.removeAll()
        impactDetected = false
        
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let motion = motion, error == nil else { return }
            self?.processMotionData(motion)
        }
    }
    
    /// Stop recording and analyze swing
    func stopRecording() {
        guard isRecording else { return }
        
        isRecording = false
        motionManager.stopDeviceMotionUpdates()
        
        analyzeSwing()
    }
    
    private func processMotionData(_ motion: CMDeviceMotion) {
        motionData.append(motion)
        
        // Detect impact based on acceleration spike
        let acceleration = motion.userAcceleration
        let totalAcceleration = sqrt(acceleration.x * acceleration.x + 
                                   acceleration.y * acceleration.y + 
                                   acceleration.z * acceleration.z)
        
        if totalAcceleration > 2.5 && !impactDetected {
            impactDetected = true
            // Impact detected - continue recording for follow-through
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.stopRecording()
            }
        }
    }
    
    private func analyzeSwing() {
        guard let startTime = swingStartTime, !motionData.isEmpty else { return }
        
        let backswingData = extractBackswing()
        let downswingData = extractDownswing()
        let impactData = extractImpact()
        let followThroughData = extractFollowThrough()
        
        swingData = SwingData(
            startTime: startTime,
            duration: Date().timeIntervalSince(startTime),
            motionData: motionData,
            impactDetected: impactDetected
        )
        
        analysisResults = SwingAnalysis(
            tempo: calculateTempo(),
            clubheadSpeed: calculateClubheadSpeed(),
            swingPlane: calculateSwingPlane(),
            balance: calculateBalance(),
            backswingLength: backswingData.count,
            downswingLength: downswingData.count
        )
    }
    
    private func extractBackswing() -> [CMDeviceMotion] {
        // Find peak of backswing (highest angular velocity in z-axis)
        guard let peakIndex = motionData.enumerated().max(by: { 
            abs($0.element.rotationRate.z) < abs($1.element.rotationRate.z) 
        })?.offset else { return [] }
        
        return Array(motionData[0..<peakIndex])
    }
    
    private func extractDownswing() -> [CMDeviceMotion] {
        guard let peakIndex = motionData.enumerated().max(by: { 
            abs($0.element.rotationRate.z) < abs($1.element.rotationRate.z) 
        })?.offset else { return [] }
        
        let impactIndex = findImpactIndex()
        return Array(motionData[peakIndex..<impactIndex])
    }
    
    private func extractImpact() -> [CMDeviceMotion] {
        let impactIndex = findImpactIndex()
        let startIndex = max(0, impactIndex - 5)
        let endIndex = min(motionData.count, impactIndex + 5)
        return Array(motionData[startIndex..<endIndex])
    }
    
    private func extractFollowThrough() -> [CMDeviceMotion] {
        let impactIndex = findImpactIndex()
        return Array(motionData[impactIndex..<motionData.count])
    }
    
    private func findImpactIndex() -> Int {
        return motionData.enumerated().max { first, second in
            let firstAccel = sqrt(pow(first.element.userAcceleration.x, 2) + 
                                pow(first.element.userAcceleration.y, 2) + 
                                pow(first.element.userAcceleration.z, 2))
            let secondAccel = sqrt(pow(second.element.userAcceleration.x, 2) + 
                                 pow(second.element.userAcceleration.y, 2) + 
                                 pow(second.element.userAcceleration.z, 2))
            return firstAccel < secondAccel
        }?.offset ?? motionData.count - 1
    }
    
    private func calculateTempo() -> Double {
        let backswing = extractBackswing()
        let downswing = extractDownswing()
        
        guard backswing.count > 0 && downswing.count > 0 else { return 0 }
        
        return Double(backswing.count) / Double(downswing.count)
    }
    
    private func calculateClubheadSpeed() -> Double {
        let impactData = extractImpact()
        guard !impactData.isEmpty else { return 0 }
        
        let maxAcceleration = impactData.map { motion in
            sqrt(pow(motion.userAcceleration.x, 2) + 
                 pow(motion.userAcceleration.y, 2) + 
                 pow(motion.userAcceleration.z, 2))
        }.max() ?? 0
        
        // Rough estimation: convert acceleration to clubhead speed
        return maxAcceleration * 30.0 // mph estimation
    }
    
    private func calculateSwingPlane() -> Double {
        guard motionData.count > 10 else { return 0 }
        
        let attitudes = motionData.map { $0.attitude.pitch }
        let variance = attitudes.reduce(0) { sum, pitch in
            let diff = pitch - attitudes.first!
            return sum + (diff * diff)
        } / Double(attitudes.count)
        
        return sqrt(variance)
    }
    
    private func calculateBalance() -> Double {
        let gravityData = motionData.map { motion in
            sqrt(pow(motion.gravity.x, 2) + 
                 pow(motion.gravity.y, 2) + 
                 pow(motion.gravity.z, 2))
        }
        
        let variance = gravityData.reduce(0) { sum, gravity in
            let diff = gravity - 1.0 // Expected gravity magnitude
            return sum + (diff * diff)
        } / Double(gravityData.count)
        
        return 1.0 - sqrt(variance) // Higher value = better balance
    }
}

/// Data structure for captured swing information
struct SwingData {
    let startTime: Date
    let duration: TimeInterval
    let motionData: [CMDeviceMotion]
    let impactDetected: Bool
}

/// Analysis results from swing capture
struct SwingAnalysis {
    let tempo: Double
    let clubheadSpeed: Double
    let swingPlane: Double
    let balance: Double
    let backswingLength: Int
    let downswingLength: Int
    
    var tempoRating: String {
        switch tempo {
        case 2.5...3.5: return "Excellent"
        case 2.0..<2.5, 3.5..<4.0: return "Good"
        case 1.5..<2.0, 4.0..<4.5: return "Fair"
        default: return "Needs Work"
        }
    }
    
    var speedRating: String {
        switch clubheadSpeed {
        case 90...: return "Fast"
        case 70..<90: return "Moderate"
        case 50..<70: return "Slow"
        default: return "Very Slow"
        }
    }
}
