//
//  ModelView.swift
//  AICompanion
//
//  Created by Barry Juans on 06/08/25.
//
import SwiftUI
import RealityKit

struct ModelView: View {
    
    @ObservedObject var agent: ModelAgent
    
    var body: some View {
        RealityView(make: { content in
            do {
                let entity = try await ModelEntity(named: "Ashe")
                initialize(content: content, entity: entity)
            } catch {
                agent.errorMessage = "Failed to load model: \(error)"
            }
        }, placeholder: {
            ZStack {
                Color.clear

                VStack {
                    ProgressView()
                        .padding()
                        .cornerRadius(10)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        })
    }
    
    private func initialize(content: RealityViewCameraContent, entity: ModelEntity) {
        
        let anchor = AnchorEntity(world: .zero)
        
        entity.position = SIMD3<Float>(x: 0, y: -1.2, z: 1.0)
        anchor.addChild(entity)
        
        let light = PointLight()
        light.light.intensity = 100000
        light.position = SIMD3<Float>(x: 0, y: 0, z: 3)
        anchor.addChild(light)

        content.add(anchor)
        agent.setEntity(entity)
    }
}
