//
//  ARCourseRenderer.swift
//  ar-golf-game
//
//  Created on 8/9/25.
//

import Foundation
import RealityKit
import ARKit
import SwiftUI

/// RealityKit-based AR course renderer for immersive golf experiences
class ARCourseRenderer: ObservableObject {
    
    // MARK: - Properties
    @Published var arView: ARView?
    @Published var courseEntities: [Entity] = []
    @Published var isSessionRunning = false
    
    private var anchorEntity: AnchorEntity?
    private var courseConfiguration: CourseConfiguration
    
    // MARK: - Initialization
    init(configuration: CourseConfiguration = .default) {
        self.courseConfiguration = configuration
        setupARView()
    }
    
    // MARK: - AR Setup
    private func setupARView() {
        let arView = ARView(frame: .zero)
        
        // Configure AR session
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic
        
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            configuration.sceneReconstruction = .mesh
        }
        
        arView.session.run(configuration)
        arView.automaticallyConfigureSession = false
        
        self.arView = arView
        self.isSessionRunning = true
        
        setupGestures()
    }
    
    // MARK: - Course Rendering
    func renderCourse(at position: SIMD3<Float>) {
        guard let arView = arView else { return }
        
        // Create anchor for course
        let anchor = AnchorEntity(world: position)
        anchorEntity = anchor
        arView.scene.addAnchor(anchor)
        
        // Render course components
        renderTerrain(anchor: anchor)
        renderHoles(anchor: anchor)
        renderObstacles(anchor: anchor)
        renderEnvironment(anchor: anchor)
    }
    
    private func renderTerrain(anchor: AnchorEntity) {
        let terrain = createTerrainEntity()
        anchor.addChild(terrain)
        courseEntities.append(terrain)
    }
    
    private func renderHoles(anchor: AnchorEntity) {
        for (index, holeData) in courseConfiguration.holes.enumerated() {
            let hole = createHoleEntity(data: holeData, index: index)
            anchor.addChild(hole)
            courseEntities.append(hole)
        }
    }
    
    private func renderObstacles(anchor: AnchorEntity) {
        for obstacle in courseConfiguration.obstacles {
            let obstacleEntity = createObstacleEntity(obstacle: obstacle)
            anchor.addChild(obstacleEntity)
            courseEntities.append(obstacleEntity)
        }
    }
    
    private func renderEnvironment(anchor: AnchorEntity) {
        let skybox = createSkyboxEntity()
        anchor.addChild(skybox)
        
        let lighting = createLightingEntity()
        anchor.addChild(lighting)
        
        courseEntities.append(contentsOf: [skybox, lighting])
    }
    
    // MARK: - Entity Creation
    private func createTerrainEntity() -> Entity {
        let entity = Entity()
        entity.name = "terrain"
        
        // Create terrain mesh
        let mesh = MeshResource.generatePlane(width: 50, depth: 50, cornerRadius: 0)
        let material = SimpleMaterial(color: .green, isMetallic: false)
        let modelComponent = ModelComponent(mesh: mesh, materials: [material])
        
        entity.components.set(modelComponent)
        entity.components.set(CollisionComponent(shapes: [.generateBox(width: 50, height: 0.1, depth: 50)]))
        
        return entity
    }
    
    private func createHoleEntity(data: HoleData, index: Int) -> Entity {
        let entity = Entity()
        entity.name = "hole_\(index)"
        entity.position = data.position
        
        // Create hole geometry
        let mesh = MeshResource.generateCylinder(height: 0.2, radius: 0.05)
        let material = SimpleMaterial(color: .black, isMetallic: false)
        let modelComponent = ModelComponent(mesh: mesh, materials: [material])
        
        entity.components.set(modelComponent)
        entity.components.set(CollisionComponent(shapes: [.generateCylinder(height: 0.2, radius: 0.05)]))
        
        // Add flag
        let flag = createFlagEntity()
        flag.position = SIMD3<Float>(0, 1.0, 0)
        entity.addChild(flag)
        
        return entity
    }
    
    private func createObstacleEntity(obstacle: ObstacleData) -> Entity {
        let entity = Entity()
        entity.name = "obstacle_\(obstacle.type.rawValue)"
        entity.position = obstacle.position
        
        let mesh: MeshResource
        let material: Material
        
        switch obstacle.type {
        case .sandTrap:
            mesh = MeshResource.generateBox(size: obstacle.size)
            material = SimpleMaterial(color: .systemYellow, isMetallic: false)
        case .waterHazard:
            mesh = MeshResource.generateBox(size: obstacle.size)
            material = SimpleMaterial(color: .systemBlue, isMetallic: true)
        case .tree:
            mesh = MeshResource.generateCylinder(height: obstacle.size.y, radius: obstacle.size.x * 0.1)
            material = SimpleMaterial(color: .systemBrown, isMetallic: false)
        }
        
        let modelComponent = ModelComponent(mesh: mesh, materials: [material])
        entity.components.set(modelComponent)
        entity.components.set(CollisionComponent(shapes: [.generateBox(size: obstacle.size)]))
        
        return entity
    }
    
    private func createFlagEntity() -> Entity {
        let entity = Entity()
        entity.name = "flag"
        
        // Flag pole
        let poleMesh = MeshResource.generateCylinder(height: 2.0, radius: 0.01)
        let poleMaterial = SimpleMaterial(color: .white, isMetallic: true)
        let poleModel = ModelComponent(mesh: poleMesh, materials: [poleMaterial])
        entity.components.set(poleModel)
        
        // Flag cloth
        let flagMesh = MeshResource.generatePlane(width: 0.3, depth: 0.2)
        let flagMaterial = SimpleMaterial(color: .red, isMetallic: false)
        let flagModel = ModelComponent(mesh: flagMesh, materials: [flagMaterial])
        
        let flagEntity = Entity()
        flagEntity.components.set(flagModel)
        flagEntity.position = SIMD3<Float>(0.15, 1.8, 0)
        entity.addChild(flagEntity)
        
        return entity
    }
    
    private func createSkyboxEntity() -> Entity {
        let entity = Entity()
        entity.name = "skybox"
        
        // Create skybox sphere
        let mesh = MeshResource.generateSphere(radius: 100)
        var material = UnlitMaterial()
        material.color = .init(tint: .systemBlue)
        
        let modelComponent = ModelComponent(mesh: mesh, materials: [material])
        entity.components.set(modelComponent)
        
        return entity
    }
    
    private func createLightingEntity() -> Entity {
        let entity = Entity()
        entity.name = "lighting"
        
        // Directional light for sun
        let lightComponent = DirectionalLightComponent(
            color: .white,
            intensity: 10000,
            isRealWorldProxy: true
        )
        entity.components.set(lightComponent)
        entity.look(at: SIMD3<Float>(0, -1, 0), from: SIMD3<Float>(0, 10, 10), relativeTo: nil)
        
        return entity
    }
    
    // MARK: - Gesture Setup
    private func setupGestures() {
        guard let arView = arView else { return }
        
        // Add tap gesture for interaction
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let arView = arView else { return }
        
        let location = gesture.location(in: arView)
        
        // Perform raycast to find surface
        let results = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .horizontal)
        
        if let firstResult = results.first {
            let position = SIMD3<Float>(
                firstResult.worldTransform.columns.3.x,
                firstResult.worldTransform.columns.3.y,
                firstResult.worldTransform.columns.3.z
            )
            
            // Place course at tapped location
            renderCourse(at: position)
        }
    }
    
    // MARK: - Public Methods
    func updateCourseConfiguration(_ configuration: CourseConfiguration) {
        self.courseConfiguration = configuration
        clearCourse()
    }
    
    func clearCourse() {
        courseEntities.removeAll()
        anchorEntity?.removeFromParent()
        anchorEntity = nil
    }
    
    func pauseSession() {
        arView?.session.pause()
        isSessionRunning = false
    }
    
    func resumeSession() {
        guard let arView = arView else { return }
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        arView.session.run(configuration)
        isSessionRunning = true
    }
}

// MARK: - Supporting Data Types
struct CourseConfiguration {
    let holes: [HoleData]
    let obstacles: [ObstacleData]
    
    static let `default` = CourseConfiguration(
        holes: [
            HoleData(position: SIMD3<Float>(0, 0, -5), par: 3),
            HoleData(position: SIMD3<Float>(10, 0, -15), par: 4),
            HoleData(position: SIMD3<Float>(-5, 0, -25), par: 5)
        ],
        obstacles: [
            ObstacleData(type: .sandTrap, position: SIMD3<Float>(2, 0, -3), size: SIMD3<Float>(3, 0.2, 2)),
            ObstacleData(type: .waterHazard, position: SIMD3<Float>(-3, 0, -10), size: SIMD3<Float>(4, 0.1, 6)),
            ObstacleData(type: .tree, position: SIMD3<Float>(5, 0, -8), size: SIMD3<Float>(1, 8, 1))
        ]
    )
}

struct HoleData {
    let position: SIMD3<Float>
    let par: Int
}

struct ObstacleData {
    let type: ObstacleType
    let position: SIMD3<Float>
    let size: SIMD3<Float>
}

enum ObstacleType: String, CaseIterable {
    case sandTrap = "sand_trap"
    case waterHazard = "water_hazard"
    case tree = "tree"
}
