//
//  Skater.swift
//  Skateboard
//
//  Created by ARMSTRONG on 5/23/20.
//  Copyright © 2020 ARMSTRONG. All rights reserved.
//

import SpriteKit

class Skater: SKSpriteNode {
    var velocity = CGPoint.zero
    var minimumY: CGFloat = 0.0
    var jumpSpeed: CGFloat = 20.0
    var isOnGround = true
    
    func setupPhysicsBody() {
        if let skaterTexture = texture {
            physicsBody = SKPhysicsBody(texture: skaterTexture, size: size)
            physicsBody?.isDynamic = true
            physicsBody?.density = 6.0
            physicsBody?.allowsRotation = true
            physicsBody?.angularDamping = 1.0
            
            physicsBody?.categoryBitMask = PhysicsCategory.skater
            physicsBody?.collisionBitMask = PhysicsCategory.brick
            physicsBody?.contactTestBitMask = PhysicsCategory.brick | PhysicsCategory.gem
        }
    }
    
    func createSparks() {
        
        // Find the sparks emitter file in the project's bundle
        let bundle = Bundle.main
        
        do {
            let sparkPath = bundle.url(forResource: "Sparks", withExtension: "sks")!
            let sparkData = try Data(contentsOf: sparkPath)
                
            // Create a Sparks emitter node
            let sparksNode = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(sparkData) as! SKEmitterNode
                    
            sparksNode.position = CGPoint(x: 0.0, y: -50.0)
            addChild(sparksNode)
            
            // Run an action to wait half a second and then remove the emitter
            let waitAction = SKAction.wait(forDuration: 0.5)
            let removeAction = SKAction.removeFromParent()
            let waitThenRemove = SKAction.sequence([waitAction, removeAction])
            
            sparksNode.run(waitThenRemove)
            
        } catch {
            print("Didn't find sparks emitter file ")
        }
    }
}
