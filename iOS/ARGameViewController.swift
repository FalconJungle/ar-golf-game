//
//  ARGameViewController.swift
//  AR Golf Game
//
//  Main RealityKit/ARKit-based controller for AR Golf Game
//

import SwiftUI
import RealityKit
import ARKit
import Combine

struct ARGameViewController: UIViewRepresentable {
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // Configure AR session
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic
        
        arView.session.run(config)
        arView.addGestureRecognizer(UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:))))
        
        // Store reference for coordinator
        context.coordinator.arView = arView
        
        // Set up initial scene
        setupInitialScene(arView: arView)
        
        return arView
    }
    
    func updateUIView(_ arView: ARView, context: Context) {
        // Update AR view as needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: ARGameViewController
        var arView: ARView?
        var golfBall: Entity?
        var golfHole: Entity?
        var isGameActive = false
        
        private var cancellables: Set<AnyCancellable> = []
        
        init(_ parent: ARGameViewController) {
            self.parent = parent
            super.init()
        }
        
        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let arView = arView else { return }
            
            let tapLocation = recognizer.location(in: arView)
            
            if !isGameActive {
                // First tap: place golf hole and ball
                setupGame(at: tapLocation, in: arView)
            } else {
                // Subsequent taps: hit the ball toward tap location
                hitBall(toward: tapLocation, in: arView)
            }
        }
        
        private func setupGame(at tapLocation: CGPoint, in arView: ARView) {
            guard let raycastResult = arView.raycast(from: tapLocation, allowing: .estimatedPlane, alignment: .horizontal).first else {
                return
            }
            
            let position = raycastResult.worldTransform.translation
            
            // Create golf hole
            createGolfHole(at: position, in: arView)
            
            // Create golf ball slightly in front of the hole
            let ballPosition = SIMD3<Float>(position.x, position.y + 0.02, position.z + 0.5)
            createGolfBall(at: ballPosition, in: arView)
            
            isGameActive = true
        }
        
        private func createGolfHole(at position: SIMD3<Float>, in arView: ARView) {
            // Create hole mesh
            let holeMesh = MeshResource.generateCylinder(height: 0.05, radius: 0.05)
            let holeMaterial = SimpleMaterial(color: .black, roughness: 0.8, isMetallic: false)
            
            golfHole = ModelEntity(mesh: holeMesh, materials: [holeMaterial])
            golfHole?.position = position
            
            // Create anchor and add hole
            let holeAnchor = AnchorEntity(.world(transform: Transform(translation: position)))
            holeAnchor.addChild(golfHole!)
            
            arView.scene.addAnchor(holeAnchor)
        }
        
        private func createGolfBall(at position: SIMD3<Float>, in arView: ARView) {
            // Create ball mesh
            let ballMesh = MeshResource.generateSphere(radius: 0.02)
            let ballMaterial = SimpleMaterial(color: .white, roughness: 0.3, isMetallic: false)
            
            golfBall = ModelEntity(mesh: ballMesh, materials: [ballMaterial])
            golfBall?.position = position
            
            // Add physics
            let ballShape = ShapeResource.generateSphere(radius: 0.02)
            golfBall?.components.set(CollisionComponent(shapes: [ballShape]))
            golfBall?.components.set(PhysicsBodyComponent(massProperties: .default, material: nil, mode: .dynamic))
            
            // Create anchor and add ball
            let ballAnchor = AnchorEntity(.world(transform: Transform(translation: position)))
            ballAnchor.addChild(golfBall!)
            
            arView.scene.addAnchor(ballAnchor)
        }
        
        private func hitBall(toward tapLocation: CGPoint, in arView: ARView) {
            guard let ball = golfBall,
                  let raycastResult = arView.raycast(from: tapLocation, allowing: .estimatedPlane, alignment: .horizontal).first else {
                return
            }
            
            let targetPosition = raycastResult.worldTransform.translation
            let ballPosition = ball.position
            
            // Calculate direction and force
            let direction = normalize(targetPosition - ballPosition)
            let force = direction * 2.0 // Adjust force as needed
            
            // Apply impulse to ball
            if var physicsBody = ball.components[PhysicsBodyComponent.self] {
                physicsBody.mode = .dynamic
                ball.components.set(physicsBody)
                
                // Apply impulse
                let impulse = force
                ball.addForce(impulse, relativeTo: nil)
            }
        }
    }
    
    private func setupInitialScene(arView: ARView) {
        // Add some ambient lighting
        let lightEntity = DirectionalLight()
        lightEntity.light.intensity = 1000
        lightEntity.orientation = simd_quatf(angle: -Float.pi / 4, axis: [1, 0, 0])
        
        let lightAnchor = AnchorEntity(.world(transform: Transform(translation: [0, 2, 0])))
        lightAnchor.addChild(lightEntity)
        arView.scene.addAnchor(lightAnchor)
    }
}

// SIMD3 extension for convenience
extension SIMD3 where Scalar == Float {
    var translation: SIMD3<Float> {
        return self
    }
}

// simd_float4x4 extension for convenience
extension simd_float4x4 {
    var translation: SIMD3<Float> {
        return SIMD3<Float>(columns.3.x, columns.3.y, columns.3.z)
    }
}

#if DEBUG
struct ARGameViewController_Previews: PreviewProvider {
    static var previews: some View {
        ARGameViewController()
    }
}
#endif
