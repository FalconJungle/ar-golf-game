//
//  PoseTracker.swift
//  AR Golf Game
//
//  Vision and CoreML-powered pose tracking for golf swing analysis
//

import Foundation
import Vision
import CoreML
import ARKit
import simd

/// Tracks human pose for golf swing analysis using Vision and CoreML
@MainActor
class PoseTracker: ObservableObject {
    // MARK: - Published Properties
    @Published var currentPose: VNHumanBodyPoseObservation?
    @Published var isTracking: Bool = false
    @Published var confidence: Float = 0.0
    @Published var swingPhase: SwingPhase = .address
    @Published var keyPoints: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint] = [:]
    
    // MARK: - Private Properties
    private var poseRequest: VNDetectHumanBodyPoseRequest
    private var sequenceHandler = VNSequenceRequestHandler()
    private var frameBuffer: [CVPixelBuffer] = []
    private let maxFrameHistory = 10
    private var swingAnalyzer: SwingAnalyzer?
    
    // MARK: - Pose Tracking Configuration
    private let minimumConfidence: Float = 0.6
    private let keyJoints: [VNHumanBodyPoseObservation.JointName] = [
        .leftShoulder, .rightShoulder,
        .leftElbow, .rightElbow,
        .leftWrist, .rightWrist,
        .leftHip, .rightHip,
        .leftKnee, .rightKnee,
        .leftAnkle, .rightAnkle,
        .neck, .nose
    ]
    
    // MARK: - Initialization
    init() {
        poseRequest = VNDetectHumanBodyPoseRequest(completionHandler: handlePoseDetection)
        poseRequest.revision = VNDetectHumanBodyPoseRequestRevision1
        swingAnalyzer = SwingAnalyzer()
    }
    
    // MARK: - Public Methods
    
    /// Start pose tracking
    func startTracking() {
        isTracking = true
        frameBuffer.removeAll()
    }
    
    /// Stop pose tracking
    func stopTracking() {
        isTracking = false
        currentPose = nil
        keyPoints.removeAll()
        confidence = 0.0
    }
    
    /// Process frame for pose detection
    func processFrame(_ pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation = .right) {
        guard isTracking else { return }
        
        // Add to frame buffer for temporal analysis
        addToFrameBuffer(pixelBuffer)
        
        // Perform pose detection
        do {
            try sequenceHandler.perform([poseRequest], on: pixelBuffer, orientation: orientation)
        } catch {
            print("Failed to perform pose detection: \(error)")
        }
    }
    
    /// Get specific joint position
    func getJointPosition(_ joint: VNHumanBodyPoseObservation.JointName) -> simd_float2? {
        guard let point = keyPoints[joint],
              point.confidence > minimumConfidence else {
            return nil
        }
        return simd_float2(Float(point.location.x), Float(point.location.y))
    }
    
    /// Get joint positions in 3D space (using ARKit integration)
    func getJoint3DPosition(_ joint: VNHumanBodyPoseObservation.JointName, 
                           in cameraTransform: simd_float4x4) -> simd_float3? {
        guard let point2D = getJointPosition(joint) else { return nil }
        
        // Convert 2D pose to 3D using depth estimation
        // This is a simplified approach - in practice, you'd use more sophisticated depth estimation
        let depth: Float = 2.0 // Estimated depth in meters
        let x = (point2D.x - 0.5) * 2.0 * depth
        let y = (point2D.y - 0.5) * 2.0 * depth
        let z = -depth
        
        return simd_float3(x, y, z)
    }
    
    // MARK: - Private Methods
    
    private func handlePoseDetection(request: VNRequest, error: Error?) {
        if let error = error {
            print("Pose detection error: \(error)")
            return
        }
        
        guard let observations = request.results as? [VNHumanBodyPoseObservation],
              let pose = observations.first else {
            DispatchQueue.main.async {
                self.currentPose = nil
                self.confidence = 0.0
            }
            return
        }
        
        DispatchQueue.main.async {
            self.processPoseObservation(pose)
        }
    }
    
    private func processPoseObservation(_ pose: VNHumanBodyPoseObservation) {
        currentPose = pose
        
        // Extract key points
        var newKeyPoints: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint] = [:]
        var totalConfidence: Float = 0.0
        var validJoints = 0
        
        for joint in keyJoints {
            do {
                let point = try pose.recognizedPoint(joint)
                if point.confidence > minimumConfidence {
                    newKeyPoints[joint] = point
                    totalConfidence += point.confidence
                    validJoints += 1
                }
            } catch {
                continue
            }
        }
        
        keyPoints = newKeyPoints
        confidence = validJoints > 0 ? totalConfidence / Float(validJoints) : 0.0
        
        // Analyze swing phase
        analyzeSwingPhase()
        
        // Perform swing analysis if we have sufficient pose data
        if confidence > minimumConfidence {
            swingAnalyzer?.analyzePose(pose, keyPoints: keyPoints)
        }
    }
    
    private func addToFrameBuffer(_ pixelBuffer: CVPixelBuffer) {
        frameBuffer.append(pixelBuffer)
        if frameBuffer.count > maxFrameHistory {
            frameBuffer.removeFirst()
        }
    }
    
    private func analyzeSwingPhase() {
        guard let leftWrist = keyPoints[.leftWrist],
              let rightWrist = keyPoints[.rightWrist],
              let leftShoulder = keyPoints[.leftShoulder],
              let rightShoulder = keyPoints[.rightShoulder] else {
            return
        }
        
        // Simple swing phase detection based on wrist positions relative to shoulders
        let leftWristY = leftWrist.location.y
        let rightWristY = rightWrist.location.y
        let shoulderY = (leftShoulder.location.y + rightShoulder.location.y) / 2
        let avgWristY = (leftWristY + rightWristY) / 2
        
        // Determine swing phase based on wrist height
        if avgWristY > shoulderY + 0.1 {
            swingPhase = .backswing
        } else if avgWristY > shoulderY - 0.1 {
            swingPhase = .topOfSwing
        } else if avgWristY < shoulderY - 0.2 {
            swingPhase = .impact
        } else {
            swingPhase = .followThrough
        }
    }
}

// MARK: - Supporting Types

enum SwingPhase: String, CaseIterable {
    case address = "Address"
    case backswing = "Backswing"
    case topOfSwing = "Top of Swing"
    case downswing = "Downswing"
    case impact = "Impact"
    case followThrough = "Follow Through"
    case finish = "Finish"
}

// MARK: - Swing Analysis Helper

class SwingAnalyzer {
    private var poseHistory: [VNHumanBodyPoseObservation] = []
    private let maxHistory = 30
    
    func analyzePose(_ pose: VNHumanBodyPoseObservation, 
                    keyPoints: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) {
        poseHistory.append(pose)
        if poseHistory.count > maxHistory {
            poseHistory.removeFirst()
        }
        
        // Perform swing analysis
        analyzeSwingTempo()
        analyzePosture(keyPoints)
        analyzeClubPath(keyPoints)
    }
    
    private func analyzeSwingTempo() {
        // Implement swing tempo analysis using pose history
        // This would analyze the speed and rhythm of the swing
    }
    
    private func analyzePosture(_ keyPoints: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) {
        // Implement posture analysis
        // Check spine angle, shoulder alignment, etc.
    }
    
    private func analyzeClubPath(_ keyPoints: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) {
        // Implement club path analysis based on hand/wrist movement
        // This would track the path of the hands through the swing
    }
}
