//
//  GameScene.swift
//  Skateboard
//
//  Created by ARMSTRONG on 5/22/20.
//  Copyright © 2020 ARMSTRONG. All rights reserved.
//

import SpriteKit
import GameplayKit

// This struct holds various physics categorie, so we can define
// which object types collide or have contact with each other
struct PhysicsCategory {
    static let skater: UInt32 = 0x1 << 0
    static let brick: UInt32 = 0x1 << 1
    static let gem: UInt32 = 0x1 << 2
}


class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // Enum for y-position spawn points for bricks
    // Ground bricks are low and upper platforms bricks are high
    enum BrickLevel: CGFloat {
        case low = 0.0
        case high = 100.0
    }
    
    enum GameState {
        case notRunning
        case running
    }
        
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    
    // An array that holds all the current sidewalk bricks
    var bricks = [SKSpriteNode]()
    
    // The size of the sidewalk brick graphics used
    var brickSize = CGSize.zero
    
    // The current brick level determine the y-position of new bricks
    var brickLevel = BrickLevel.low
    
    // The current game state is tracked
    var gameState = GameState.notRunning
    
    // Setting for how fast the game is scrolling to the right
    // This may increase as the user progresses in the game
    var scrollSpeed: CGFloat = 5.0
    let startingScrollSpeed: CGFloat = 5.0
    
    // A constant for gravity, or how fast objects will fall to Earth
    let gravitySpeed : CGFloat = 1.5
    
    // Properties for score tracking
    var score: Int = 0
    var highScore: Int = 0
    var lastScoreUpdateTime: TimeInterval = 0.0
    
    // The timestamp of the last update method call
    var lastUpdateTime: TimeInterval?
    
    // An array that holds all the current gems
    var gems = [SKSpriteNode]()
    
    // the skater is created here
    let skater = Skater(imageNamed: "skater")
    
    override func didMove(to view: SKView) {
        
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -6.0)
        
        physicsWorld.contactDelegate = self
        
        anchorPoint = CGPoint.zero
        
        // Setup the background sprit
        let background = SKSpriteNode(imageNamed: "background")
        background.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(background)
        
        setupLabels()

        // Setup the skater sprit and add her to the scene
        skater.setupPhysicsBody()
        // resetSkater()
        addChild(skater)
        
        
        // Add a tap gesture recognizer to know when user tapped the screen
        let tapMethod = #selector(GameScene.handleTap(tapGesture:))
        let tapGesture = UITapGestureRecognizer(target: self, action: tapMethod)
        view.addGestureRecognizer(tapGesture)
        
        // Start a new game
        // startNewGame()  // Remove this line of code
        
        // Add a menu overlay with "Tap to play" text
        let menuBackgroundColor = UIColor.black.withAlphaComponent(0.4)
        let menuLayer = MenuLayer(color: menuBackgroundColor, size: frame.size)
        menuLayer.anchorPoint = CGPoint(x: 0.0, y: 0.0)
        menuLayer.position = CGPoint(x: 0.0, y: 0.0)
        menuLayer.zPosition = 30
        menuLayer.name = "menuLayer"
        menuLayer.display(message: "Tap to play", score: nil)
        addChild(menuLayer)
    }
    
    func resetSkater() {
        // Set the skater's starting postion, zPostion, and minimumY
        skater.position = CGPoint(x: frame.midX / 2.0, y: skater.frame.height / 2.0 + 64.0)
        skater.zPosition = 10
        skater.minimumY = skater.frame.height / 2.0 + 64.0
        
        skater.zRotation = 0.0
        skater.physicsBody?.velocity = CGVector(dx: 0.0, dy: 0.0)
        skater.physicsBody?.angularVelocity = 0.0
    }
    
    func spawnGem(atPosition pos: CGPoint) {
        // Greate a gem sprite and add it to the scene
        let gem = SKSpriteNode(imageNamed: "gem")
        gem.position = pos
        gem.zPosition = 9
        addChild(gem)
        
        gem.physicsBody = SKPhysicsBody(rectangleOf: gem.size, center: gem.centerRect.origin)
        gem.physicsBody?.categoryBitMask = PhysicsCategory.gem
        gem.physicsBody?.affectedByGravity = false
        
        // Add the new gem to the array of gems
        gems.append(gem)
    }
    
    func removeGem(_ gem: SKSpriteNode) {
        gem.removeFromParent()
        
        if let gemIndex = gems.firstIndex(of: gem) {
            gems.remove(at: gemIndex)
        }
    }
    
    func updateGems (withScrollAmount currentScrollAmount: CGFloat) {
        for gem in gems {
            // Update each gem's position
            let thisGemX = gem.position.x - currentScrollAmount
            gem.position = CGPoint(x: thisGemX, y: gem.position.y)
            
            // Remove any gems that have moved offscreen
            if gem.position.x < 0.0 {
                removeGem(gem)
            }
        }
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
        
        // Set up brick's physics body
        let center = brick.centerRect.origin
        brick.physicsBody = SKPhysicsBody(rectangleOf: brick.size, center: center)
        brick.physicsBody?.affectedByGravity = false
        brick.physicsBody?.categoryBitMask = PhysicsCategory.brick
        brick.physicsBody?.collisionBitMask = 0
        
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
            // let brickY = brickSize.height / 2.0
            let brickY = ( brickSize.height / 2.0 ) + brickLevel.rawValue
            
            // Every now and then, leave a gap the player must jump over
            let randomNumber = arc4random_uniform(99)
            
            //if randomNumber < 5 {
            if randomNumber < 2 && score > 10 {
                
                // -- There's a 5 percent chance to leave a gap between bricks
                // There's a 2 percent chance to leave a gap between bricks after score of 10
                let gap = 20.0 * scrollSpeed
                brickX += gap
                
                // At each gap, add a gem
                let randomGemYAmount = CGFloat(arc4random_uniform(150))
                let newGemY = brickY + skater.size.height + randomGemYAmount
                let newGemX = brickX - gap / 2.0
                
                spawnGem(atPosition: CGPoint(x: newGemX, y: newGemY))
                
            //} else if randomNumber < 10 {
            } else if randomNumber < 4 && score > 20 {
                // --There is a 5 percent chance that the brick level will change
                // There's a 2 percent chance that the brick Y level will change after score of 20
                brickLevel = (brickLevel == BrickLevel.low) ? BrickLevel.high : BrickLevel.low
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
        
        if gameState == .running {
            // Make the skater jump if player taps while the skater is on the ground
            if skater.isOnGround {
                
                // Set the skater's y-velocity to skater's initial jump speed
                // skater.velocity = CGPoint(x: 0.0, y: skater.jumpSpeed)
                
                // Keep track of the fact that skater is no longer on the ground
                // skater.isOnGround = false
                
                skater.physicsBody?.applyImpulse(CGVector(dx: 0.0, dy: 260.0))
                
                run(SKAction.playSoundFileNamed("gem.wav", waitForCompletion: false))
            }
        } else {
            
            // If the game is not running, tapping starts a new game
            if let menuLayer: SKSpriteNode = childNode(withName: "menuLayer") as? SKSpriteNode {
                menuLayer.removeFromParent()
            }

            startNewGame()
        }
        
        

    }
    
    func updateSkater() {
        
        /*
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
        }*/
        
        
        // Determine if the skater is currently on the ground
        if let velocitY = skater.physicsBody?.velocity.dy {
            if velocitY < -100.0 || velocitY > 100.0 {
                skater.isOnGround = false
            } else {
                skater.isOnGround = true // bug fix for not jumping while click
            }
        }
        
        // Check if the game should end
        let isOffScreen = skater.position.y < 0.0 || skater.position.x < 0.0
        
        let maxRotation = CGFloat(GLKMathDegreesToRadians(85.0))
        let isTippedOver = skater.zRotation > maxRotation || skater.zRotation < -maxRotation
        
        if isOffScreen || isTippedOver {
            gameOver()
        }
    }
    
    func setupLabels() {
        // Label that shows 'score' in the upper left
        let scoreTextLabel: SKLabelNode = SKLabelNode(text: "score")
        scoreTextLabel.position = CGPoint(x: 14.0, y: frame.size.height - 20.0)
        scoreTextLabel.horizontalAlignmentMode = .left
        scoreTextLabel.fontName = "Courier-Bold"
        scoreTextLabel.fontSize = 14.0
        scoreTextLabel.zPosition = 20
        addChild(scoreTextLabel)
        
        // Label that shows the actual score
        let scoreLabel: SKLabelNode = SKLabelNode(text: "0")
        scoreLabel.position = CGPoint(x: 14.0, y: frame.size.height - 40.0)
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.fontName = "Courier-Bold"
        scoreLabel.fontSize = 18.0
        scoreLabel.zPosition = 20
        scoreLabel.name = "scoreLabel"
        addChild(scoreLabel)
        
        // label that shows 'high score' in the upper right
        let highScoreTextLabel: SKLabelNode = SKLabelNode(text: "high score")
        highScoreTextLabel.position = CGPoint(x: frame.size.width - 14.0, y: frame.size.height - 20.0)
        highScoreTextLabel.horizontalAlignmentMode = .right
        highScoreTextLabel.fontName = "Courier-Bold"
        highScoreTextLabel.fontSize = 14.0
        highScoreTextLabel.zPosition = 20
        addChild(highScoreTextLabel)
        
        // label that shows player's actual highest score
        let highScoreLabel: SKLabelNode = SKLabelNode(text: "0")
        highScoreLabel.position = CGPoint(x: frame.size.width - 14.0, y: frame.size.height - 40.0)
        highScoreLabel.horizontalAlignmentMode = .right
        highScoreLabel.fontName = "Courier-Bold"
        highScoreLabel.fontSize = 18.0
        highScoreLabel.zPosition = 20
        highScoreLabel.name = "highScoreLabel"
        addChild(highScoreLabel)
        
    }
    
    func updateScoreLabelText() {
        if let scoreLabel = childNode(withName: "scoreLabel") as? SKLabelNode {
            scoreLabel.text = String(format: "%04d", score)
        }
    }
    
    func updateHighScoreLabelText() {
        if let highScoreLabel = childNode(withName: "highScoreLabel") as? SKLabelNode {
            highScoreLabel.text = String(format: "%04d", highScore)
        }
    }
    
    func updateScore(withCurrentTime currentTime: TimeInterval) {
        // Player's score increases the longer they survive
        // Only update score every 1 second
        let elapsedTime = currentTime - lastScoreUpdateTime
        
        if elapsedTime > 1.0 {
            
            // Increase the score
            score += Int(scrollSpeed)
            
            // Reset the lastScoreUpdateTime to the current time
            lastScoreUpdateTime = currentTime
            
            updateScoreLabelText()
        }
    }
    
    func startNewGame() {
        // When a new game is started, reset to starting conditions
        gameState = .running
        resetSkater()
        
        score = 0
        
        scrollSpeed = startingScrollSpeed
        brickLevel = BrickLevel.low
        lastUpdateTime = nil
        
        for brick in bricks {
            brick.removeFromParent()
        }
        
        bricks.removeAll(keepingCapacity: true)
        
        for gem in gems {
            removeGem(gem)
        }
    }
    
    func gameOver() {
        // When game ends, see if player got a new high score
        
        gameState = .notRunning
        
        if score > highScore {
            highScore = score
            updateHighScoreLabelText()
        }
        
        // startNewGame()
        
        // Show the "Game Over!" menu overlay
        let menuBackgroundColor = UIColor.black.withAlphaComponent(0.4)
        let menuLayer = MenuLayer(color: menuBackgroundColor, size: frame.size)
        menuLayer.anchorPoint = CGPoint.zero
        menuLayer.position = CGPoint.zero
        menuLayer.zPosition = 30
        menuLayer.name = "menuLayer"
        menuLayer.display(message: "Game Over!", score: score)
        addChild(menuLayer)

    }

    
    // MARK: SKPhysicsContactDelegate Methods
    func didBegin(_ contact: SKPhysicsContact) {
        // Check if the contact is between the skater and a brick
        if contact.bodyA.categoryBitMask == PhysicsCategory.skater
            && contact.bodyB.categoryBitMask == PhysicsCategory.brick {
            skater.isOnGround = true
        } else if contact.bodyA.categoryBitMask == PhysicsCategory.skater
            && contact.bodyB.categoryBitMask == PhysicsCategory.gem {
            // Skater touched a gem, so remove it
            if let gem = contact.bodyB.node as? SKSpriteNode {
                removeGem(gem)
                
                // Give player 50 points for getting a gem
                score += 50
                updateScoreLabelText()
            }
        }
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        if gameState != .running {
            return
        }
        
        // Slowly increase the scrollSpeed as the game progresses
        scrollSpeed += 0.01
        
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
        
        updateGems(withScrollAmount: currentScrollAmount)
        
        updateScore(withCurrentTime: currentTime)
    }

}
