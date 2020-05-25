//
//  GameScene.swift
//  Skateboard
//
//  Created by ARMSTRONG on 5/22/20.
//  Copyright © 2020 ARMSTRONG. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    
    // An array that holds all the current sidewalk bricks
    var bricks = [SKSpriteNode]()
    
    // The size of the sidewalk brick graphics used
    var brickSize = CGSize.zero
    
    // Setting for how fast the game is scrolling to the right
    // This may increase as the user progresses in the game
    var scrollSpeed: CGFloat = 5.0
    
    // A constant for gravity, or how fast objects will fall to Earth
    let gravitySpeed : CGFloat = 1.5
    
    // The timestamp of the last update method call
    var lastUpdateTime: TimeInterval?
    
    // the skater is created here
    let skater = Skater(imageNamed: "skater")
    
    override func didMove(to view: SKView) {
        anchorPoint = CGPoint.zero
        
        // Setup the background sprit
        let background = SKSpriteNode(imageNamed: "background")
        background.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(background)

        // Setup the skater sprit
        resetSkater()
        addChild(skater)
        
        
        // Add a tap gesture recognizer to know when user tapped the screen
        let tapMethod = #selector(GameScene.handleTap(tapGesture:))
        let tapGesture = UITapGestureRecognizer(target: self, action: tapMethod)
        view.addGestureRecognizer(tapGesture)
    }
    
    func resetSkater() {
        // Set the skater's starting postion, zPostion, and minimumY
        skater.position = CGPoint(x: frame.midX / 2.0, y: skater.frame.height / 2.0 + 64.0)
        skater.zPosition = 10
        skater.minimumY = skater.frame.height / 2.0 + 64.0
    }
    
    func spawnBrick(atPosition pos: CGPoint) -> SKSpriteNode {
        // Create a brick sprite and add it to the scene
        let brick = SKSpriteNode(imageNamed: "sidewalk")
        brick.position = pos
        brick.zPosition = 8
        addChild(brick)
        
        // Update brickSize with the real brick size
        brickSize = brick.size
        
        // Add the new brick to the array of bricks
        bricks.append(brick)
        
        // Return this new brick to the caller
        return brick
    }
    
    func updateBricks(withScrollAmount currentScrollAmount: CGFloat) {
        
        // Keep track of the greatest x-position of all the current bricks
        var farthestRightBrickX: CGFloat = 0.0
        
        for brick in bricks {
            
            let newX = brick.position.x - currentScrollAmount
            
            // If a brick has moved too far left (off the screen), remove it
            if newX < -brickSize.width {
                brick.removeFromParent()
                
                if let brickIndex = bricks.firstIndex(of: brick){
                    bricks.remove(at: brickIndex)
                }
            }  else {
                
                // For a brick that is still onscreen, update it's position
                brick.position = CGPoint(x: newX, y: brick.position.y)
                
                if brick.position.x > farthestRightBrickX {
                    farthestRightBrickX = brick.position.x
                }
            }
        }
        
        // A while loop to ensure the phone screen is always full bricks
        while farthestRightBrickX < frame.width {
            
            var brickX = farthestRightBrickX + brickSize.width + 1.0
            let brickY = brickSize.height / 2.0
            
            // Every now and then, leave a gap the player must jump over
            let randomNumber = arc4random_uniform(99)
            
            if randomNumber < 5 {
                
                // There's a 5 percent chance to leave a gap between bricks
                let gap = 20.0 * scrollSpeed
                brickX += gap
            }
            
            // Spawn a new brick and update the rightmost brick
            let newBrick = spawnBrick(atPosition: CGPoint(x: brickX, y: brickY))

            /*
            print("brickX \(brickX)")
            let temp : CGFloat = newBrick.position.x
            print("newBrick.position.x \(temp)")
             */
            
            farthestRightBrickX = newBrick.position.x
        }
        
        
    }
    
    @objc func handleTap(tapGesture: UITapGestureRecognizer) {
        
        // Make the skater jump if player taps while the skater is on the ground
        if skater.isOnGround {
            
            // Set the skater's y-velocity to skater's initial jump speed
            skater.velocity = CGPoint(x: 0.0, y: skater.jumpSpeed)
            
            // Keep track of the fact that skater is no longer on the ground
            skater.isOnGround = false
        }
    }
    
    func updateSkater() {
        if !skater.isOnGround {
            // Set the skater's new velocity as it is affected by 'gravity'
            let velocityY = skater.velocity.y - gravitySpeed
            skater.velocity = CGPoint(x: skater.velocity.x, y: velocityY)
            
            // Set the skater's new y-position based on her velocity
            let newSkaterY: CGFloat = skater.position.y + skater.velocity.y
            skater.position = CGPoint(x: skater.position.x, y: newSkaterY)
            
            // Check if the skater has landed
            if skater.position.y < skater.minimumY {
                skater.position.y = skater.minimumY
                skater.velocity = CGPoint.zero
                skater.isOnGround = true
            }
        }
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        // Determine the elapsed time since the last update call
        var elapsedTime: TimeInterval = 0.0
        
        if let lastTimeStamp = lastUpdateTime {
            elapsedTime = currentTime - lastTimeStamp
        }
        
        lastUpdateTime = currentTime
        
        let expectedElapsedTime : TimeInterval = 1.0 / 60.0
        
        // Here to calculate how far everything should move in this update
        let scrollAdjustment = CGFloat(elapsedTime / expectedElapsedTime)
        let currentScrollAmount =  scrollSpeed * scrollAdjustment
        
        updateBricks(withScrollAmount: currentScrollAmount)
        
        updateSkater()
    }

}
