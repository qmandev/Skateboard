//
//  MenuLayer.swift
//  Skateboard
//
//  Created by ARMSTRONG on 6/1/20.
//  Copyright © 2020 ARMSTRONG. All rights reserved.
//

import SpriteKit

class MenuLayer: SKSpriteNode {
    
    // Display a message and optionally display a score
    func display(message: String, score: Int?) {
        
        // Create a message label using the message
        let messageLabel: SKLabelNode = SKLabelNode(text: message)
        
        // Set the label's starting position to the left of the menu layer
        messageLabel.position = CGPoint(x: -frame.width, y: frame.height / 2.0)
        
        messageLabel.horizontalAlignmentMode = .center
        messageLabel.fontName = "Courier-Bold"
        messageLabel.fontSize = 48.0
        messageLabel.zPosition = 20
        self.addChild(messageLabel)
        
        // Animate the message label to the center of the screen
        let finalX = frame.width / 2.0
        let messageAction = SKAction.moveTo(x: finalX, duration: 0.3)
        messageLabel.run(messageAction)
        
        // If a score was passed in to the method, display it
        if let scoreToDisplay = score {
            // Create a score label
            let scoreLabel: SKLabelNode = SKLabelNode(text: String(format: "Score: %04d", scoreToDisplay))
            
            // Set the label's starting position to the right of the menu layer
            scoreLabel.position = CGPoint(x: frame.width, y: messageLabel.position.y - messageLabel.frame.height)
            
            scoreLabel.horizontalAlignmentMode = .center
            scoreLabel.fontName = "Courier-Bold"
            scoreLabel.fontSize = 32.0
            scoreLabel.zPosition = 20
            self.addChild(scoreLabel)
            
            // Animate the score label to the center of the screen
            let scoreAction =  SKAction.moveTo(x: finalX, duration: 0.3)
            scoreLabel.run(scoreAction)
        }
     }

}
