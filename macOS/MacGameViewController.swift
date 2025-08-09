//
//  MacGameViewController.swift
//  ARGolfGame
//
//  Created on 8/9/25.
//

import SwiftUI
import SceneKit
import AVFoundation
import RealityKit

struct MacGameViewController: UIViewRepresentable {
    
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        
        // Configure the scene view
        sceneView.allowsCameraControl = true
        sceneView.autoenablesDefaultLighting = true
        sceneView.backgroundColor = UIColor.systemBackground
        
        // Create and set up the scene
        let scene = createGolfScene()
        sceneView.scene = scene
        
        // Set up camera
        setupCamera(in: scene)
        
        return sceneView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        // Update the view when needed
    }
    
    // MARK: - Scene Creation
    
    private func createGolfScene() -> SCNScene {
        let scene = SCNScene()
        
        // Add ground/course
        addGround(to: scene)
        
        // Add golf ball
        addGolfBall(to: scene)
        
        // Add golf hole
        addGolfHole(to: scene)
        
        // Add lighting
        addLighting(to: scene)
        
        return scene
    }
    
    private func addGround(to scene: SCNScene) {
        let groundGeometry = SCNPlane(width: 50, height: 50)
        groundGeometry.firstMaterial?.diffuse.contents = UIColor.systemGreen
        
        let groundNode = SCNNode(geometry: groundGeometry)
        groundNode.rotation = SCNVector4(1, 0, 0, -Float.pi / 2)
        groundNode.position = SCNVector3(0, -0.5, 0)
        
        scene.rootNode.addChildNode(groundNode)
    }
    
    private func addGolfBall(to scene: SCNScene) {
        let ballGeometry = SCNSphere(radius: 0.021) // Standard golf ball radius
        ballGeometry.firstMaterial?.diffuse.contents = UIColor.white
        ballGeometry.firstMaterial?.specular.contents = UIColor.white
        
        let ballNode = SCNNode(geometry: ballGeometry)
        ballNode.position = SCNVector3(0, 0, 0)
        ballNode.name = "golfBall"
        
        // Add physics
        ballNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        ballNode.physicsBody?.restitution = 0.8
        ballNode.physicsBody?.friction = 0.3
        
        scene.rootNode.addChildNode(ballNode)
    }
    
    private func addGolfHole(to scene: SCNScene) {
        let holeGeometry = SCNCylinder(radius: 0.054, height: 0.1) // Standard golf hole
        holeGeometry.firstMaterial?.diffuse.contents = UIColor.black
        
        let holeNode = SCNNode(geometry: holeGeometry)
        holeNode.position = SCNVector3(0, -0.55, -10)
        holeNode.name = "golfHole"
        
        scene.rootNode.addChildNode(holeNode)
        
        // Add hole flag
        addFlag(to: holeNode, scene: scene)
    }
    
    private func addFlag(to holeNode: SCNNode, scene: SCNScene) {
        // Flag pole
        let poleGeometry = SCNCylinder(radius: 0.01, height: 2.0)
        poleGeometry.firstMaterial?.diffuse.contents = UIColor.systemYellow
        
        let poleNode = SCNNode(geometry: poleGeometry)
        poleNode.position = SCNVector3(holeNode.position.x + 0.06, 0.5, holeNode.position.z)
        
        // Flag
        let flagGeometry = SCNPlane(width: 0.3, height: 0.2)
        flagGeometry.firstMaterial?.diffuse.contents = UIColor.systemRed
        
        let flagNode = SCNNode(geometry: flagGeometry)
        flagNode.position = SCNVector3(0.15, 0.8, 0)
        
        poleNode.addChildNode(flagNode)
        scene.rootNode.addChildNode(poleNode)
    }
    
    private func addLighting(to scene: SCNScene) {
        // Ambient light
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.intensity = 300
        let ambientNode = SCNNode()
        ambientNode.light = ambientLight
        scene.rootNode.addChildNode(ambientNode)
        
        // Directional light (sun)
        let directionalLight = SCNLight()
        directionalLight.type = .directional
        directionalLight.intensity = 1000
        directionalLight.castsShadow = true
        let directionalNode = SCNNode()
        directionalNode.light = directionalLight
        directionalNode.position = SCNVector3(0, 10, 10)
        directionalNode.eulerAngles = SCNVector3(-Float.pi / 4, 0, 0)
        scene.rootNode.addChildNode(directionalNode)
    }
    
    private func setupCamera(in scene: SCNScene) {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 2, 5)
        cameraNode.eulerAngles = SCNVector3(-Float.pi / 6, 0, 0)
        scene.rootNode.addChildNode(cameraNode)
    }
}

// MARK: - Game Controls

extension MacGameViewController {
    
    /// Handle golf ball swing/hit
    func hitBall(force: SCNVector3, in sceneView: SCNView) {
        guard let ballNode = sceneView.scene?.rootNode.childNode(withName: "golfBall", recursively: true) else {
            return
        }
        
        ballNode.physicsBody?.applyForce(force, asImpulse: true)
    }
    
    /// Reset ball position
    func resetBall(in sceneView: SCNView) {
        guard let ballNode = sceneView.scene?.rootNode.childNode(withName: "golfBall", recursively: true) else {
            return
        }
        
        ballNode.position = SCNVector3(0, 0, 0)
        ballNode.physicsBody?.velocity = SCNVector3Zero
        ballNode.physicsBody?.angularVelocity = SCNVector4Zero
    }
}

// MARK: - Preview

#Preview {
    MacGameViewController()
        .frame(width: 400, height: 300)
}
