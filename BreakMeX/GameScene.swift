//
//  GameScene.swift
//  BreakMeX
//
//  Created by Chethana Arunodh on 5/16/19.
//  Copyright © 2019 Chethana Arunodh. All rights reserved.
//

import SpriteKit
import GameplayKit

let BallCategoryName = "ball"
let PaddleCategoryName = "paddle"
let BlockCategoryName = "block"
let BlockCategoryName2 = "block1"
let BlockCategoryName3 = "block2"
let GameMessageName = "gameMessage"
let ThemeCategoryName = "theme"
//let GameThemeName = "gameTheme"

let BallCategory   : UInt32 = 0x1 << 0
let BottomCategory : UInt32 = 0x1 << 1
let BlockCategory  : UInt32 = 0x1 << 2
let PaddleCategory : UInt32 = 0x1 << 3
let BorderCategory : UInt32 = 0x1 << 4
let BlockCategory2  : UInt32 = 0x1 << 5
let BlockCategory3  : UInt32 = 0x1 << 6

//    let playableRect: CGRect

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var isFingerOnPaddle = false
    // var isFingerOnTheme = false
    var lifeLabel: SKLabelNode!
    var life:Int = 3{
        didSet{
            lifeLabel.text = "Lives: \(life)"
        }
    }
    
    var scoreLabel: SKLabelNode!
    var score:Int = 0{
        didSet{
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    lazy var gameState: GKStateMachine = GKStateMachine(states: [
        WaitingForTap(scene: self),
        Playing(scene: self),
        GameOver(scene: self)])
    
    var gameWon : Bool = false {
        didSet {
            let gameOver = childNode(withName: GameMessageName) as! SKSpriteNode
            let textureName = gameWon ? "YouWon" : "GameOver"
            let texture = SKTexture(imageNamed: textureName)
            let actionSequence = SKAction.sequence([SKAction.setTexture(texture),
                                                    SKAction.scale(to: 1.0, duration: 0.25)])
            
            gameOver.run(actionSequence)
            run(gameWon ? gameWonSound : gameOverSound)
        }
    }
    
    let blipSound = SKAction.playSoundFileNamed("pongblip", waitForCompletion: false)
    let blipPaddleSound = SKAction.playSoundFileNamed("paddleBlip", waitForCompletion: false)
    let bambooBreakSound = SKAction.playSoundFileNamed("BambooBreak", waitForCompletion: false)
    let hit1Sound = SKAction.playSoundFileNamed("hit1", waitForCompletion: false)
    let hit2Sound = SKAction.playSoundFileNamed("hit2", waitForCompletion: false)
    let gameWonSound = SKAction.playSoundFileNamed("game-won", waitForCompletion: false)
    let gameOverSound = SKAction.playSoundFileNamed("game-over", waitForCompletion: false)
    
    
    // MARK: - Setup
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        // 1.
        let borderBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        // 2.
        borderBody.friction = 0
        // 3.
        self.physicsBody = borderBody
        
        physicsWorld.gravity = CGVector(dx: 0.0, dy: 0.0)
        physicsWorld.contactDelegate = self
        
        let ball = childNode(withName: BallCategoryName) as! SKSpriteNode
        
        let bottomRect = CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.size.width, height: 0.1)
        let bottom = SKNode()
        bottom.physicsBody = SKPhysicsBody(edgeLoopFrom: bottomRect)
        addChild(bottom)
        
        let paddle = childNode(withName: PaddleCategoryName) as! SKSpriteNode
        
        bottom.physicsBody!.categoryBitMask = BottomCategory
        ball.physicsBody!.categoryBitMask = BallCategory
        paddle.physicsBody!.categoryBitMask = PaddleCategory
        borderBody.categoryBitMask = BorderCategory
        
        ball.physicsBody!.contactTestBitMask = BottomCategory | BlockCategory | BorderCategory | PaddleCategory | BlockCategory2 | BlockCategory3
        
        lifeLabel = SKLabelNode(text: "Lifes: \(life)")
        lifeLabel.fontColor = UIColor.white
        lifeLabel.fontSize = 18
        lifeLabel.fontName = "Helvetica Neue-Bold"
        lifeLabel.zPosition = 5
        lifeLabel.horizontalAlignmentMode = .left
        lifeLabel.verticalAlignmentMode = .bottom
        lifeLabel.position = CGPoint(
            x: CGFloat(20),
            y: CGFloat(6))
        self.addChild(lifeLabel)
        
        scoreLabel = SKLabelNode(text: "Score: \(score)")
        scoreLabel.fontColor = UIColor.white
        scoreLabel.fontSize = 18
        scoreLabel.fontName = "Helvetica Neue-Bold"
        scoreLabel.zPosition = 5
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.verticalAlignmentMode = .bottom
        scoreLabel.position = CGPoint(
            x: CGFloat(470),
            y: CGFloat(6))
        self.addChild(scoreLabel)
        
       generateBlocks()
        
        let gameMessage = SKSpriteNode(imageNamed: "TapToPlay")
        gameMessage.name = GameMessageName
        gameMessage.position = CGPoint(x: frame.midX, y: frame.midY)
        gameMessage.zPosition = 4
        gameMessage.setScale(0.0)
        addChild(gameMessage)
        
        
        //        let gameTheme = SKSpriteNode(imageNamed: "theme")
        //        gameTheme.name = GameThemeName
        //        gameTheme.position = CGPoint(x: frame.midX, y: frame.midY/2)
        //        gameTheme.zPosition = 5
        //        gameTheme.setScale(0.1)
        //        addChild(gameTheme)
        
        let trailNode = SKNode()
        trailNode.zPosition = 1
        addChild(trailNode)
        let trail = SKEmitterNode(fileNamed: "BallTrail")!
        trail.targetNode = trailNode
        ball.addChild(trail)
        
        
        gameState.enter(WaitingForTap.self)
    }
    
    // MARK: Events
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch gameState.currentState {
        case is WaitingForTap:
            gameState.enter(Playing.self)
            isFingerOnPaddle = true
            
        case is Playing:
            let touch = touches.first
            let touchLocation = touch!.location(in: self)
            
            let touchTheme = touches.first
            let touchLocationTheme = touchTheme!.location(in: self)
            
            if let body = physicsWorld.body(at: touchLocation) {
                if body.node!.name == PaddleCategoryName {
                    print("Began touch on paddle")
                    isFingerOnPaddle = true
                }
            }
            if let bodyTheme = physicsWorld.body(at: touchLocationTheme) {
                if bodyTheme.node!.name == ThemeCategoryName {
                    print("aaaaa ThemeCategoryName")
                    //                isFingerOnPaddle = true
                }
            }
            
        case is GameOver:
            let newScene = GameScene(fileNamed:"GameScene")
            newScene!.scaleMode = .aspectFit
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            self.view?.presentScene(newScene!, transition: reveal)
            
        default:
            break
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // 1.
        if isFingerOnPaddle {
            // 2.
            let touch = touches.first
            let touchLocation = touch!.location(in: self)
            let previousLocation = touch!.previousLocation(in: self)
            // 3.
            let paddle = childNode(withName: PaddleCategoryName) as! SKSpriteNode
            // 4.
            var paddleX = paddle.position.x + (touchLocation.x - previousLocation.x)
            // 5.
            paddleX = max(paddleX, paddle.size.width/2)
            paddleX = min(paddleX, size.width - paddle.size.width/2)
            // 6.
            paddle.position = CGPoint(x: paddleX, y: paddle.position.y)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isFingerOnPaddle = false
    }
    
    override func update(_ currentTime: TimeInterval) {
        gameState.update(deltaTime: currentTime)
    }
    
    
    // MARK: - SKPhysicsContactDelegate
    func didBegin(_ contact: SKPhysicsContact) {
        if gameState.currentState is Playing {
            // 1.
            var firstBody: SKPhysicsBody
            var secondBody: SKPhysicsBody
            // 2.
            if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
                firstBody = contact.bodyA
                secondBody = contact.bodyB
            } else {
                firstBody = contact.bodyB
                secondBody = contact.bodyA
            }
            // React to contact with bottom of screen
            if firstBody.categoryBitMask == BallCategory && secondBody.categoryBitMask == BottomCategory {
                print("Hit bottom. First contact has been made.")
                life = life - 1
                //gameState.enter(GameOver.self)
                //gameWon = false
            }
//            if (life == 0 ){
//                gameState.enter(GameOver.self)
//                gameWon = false
//            }
            
            // React to contact with blocks
            if firstBody.categoryBitMask == BallCategory && secondBody.categoryBitMask == BlockCategory {
                breakBlock(secondBody.node!)
                if isGameWon() && isGameWon2() && isGameWon3()  {
                    gameState.enter(GameOver.self)
                    gameWon = true
                }
            }
            if firstBody.categoryBitMask == BallCategory && secondBody.categoryBitMask == BlockCategory2 {
                breakBlock2(secondBody.node!)
                if isGameWon()  && isGameWon2() && isGameWon3() {
                    gameState.enter(GameOver.self)
                    gameWon = true
                }
            }
            if firstBody.categoryBitMask == BallCategory  && secondBody.categoryBitMask == BlockCategory3 {
                breakBlock3(secondBody.node!)
                if isGameWon()  && isGameWon2() && isGameWon3(){
                    gameState.enter(GameOver.self)
                    gameWon = true
                }
            }
            // 1.
            if firstBody.categoryBitMask == BallCategory && secondBody.categoryBitMask == BorderCategory {
                run(blipSound)
            }
            
            // 2.
            if firstBody.categoryBitMask == BallCategory && secondBody.categoryBitMask == PaddleCategory {
                run(blipPaddleSound)
            }
            
            
            
        }
    }
    
    // MARK: - Helpers
    func breakBlock(_ node: SKNode) {
        run(bambooBreakSound)
        let particles = SKEmitterNode(fileNamed: "BrokenPlatform")!
        particles.position = node.position
        particles.zPosition = 3
        addChild(particles)
        particles.run(SKAction.sequence([SKAction.wait(forDuration: 1.0), SKAction.removeFromParent()]))
        node.removeFromParent()
        score = score + 1
    }
    func breakBlock2(_ node: SKNode) {
        run(hit1Sound)
        let particles = SKEmitterNode(fileNamed: "BrokenPlatform2")!
        particles.position = node.position
        particles.zPosition = 3
        addChild(particles)
        particles.run(SKAction.sequence([SKAction.wait(forDuration: 1.0), SKAction.removeFromParent()]))
        node.removeFromParent()
        score = score + 2
    }
    func breakBlock3(_ node: SKNode) {
        run(hit2Sound)
        let particles = SKEmitterNode(fileNamed: "BrokenPlatform3")!
        particles.position = node.position
        particles.zPosition = 3
        addChild(particles)
        particles.run(SKAction.sequence([SKAction.wait(forDuration: 1.0), SKAction.removeFromParent()]))
        node.removeFromParent()
        score = score + 5
    }
    
    func randomFloat(from:CGFloat, to:CGFloat) -> CGFloat {
        let rand:CGFloat = CGFloat(Float(arc4random()) / 0xFFFFFFFF)
        return (rand) * (to - from) + from
    }
    
    func isGameWon() -> Bool {
        var numberOfBricks = 0
        
     self.enumerateChildNodes(withName: BlockCategoryName) {
            node, stop in
            numberOfBricks = numberOfBricks + 1
        }
        return numberOfBricks == 0
    }
    func isGameWon2() -> Bool {
        var numberOfBricks = 0
        
        self.enumerateChildNodes(withName: BlockCategoryName2) {
            node, stop in
            numberOfBricks = numberOfBricks + 1
        }
        return numberOfBricks == 0
    }
    func isGameWon3() -> Bool {
        var numberOfBricks = 0
        
        self.enumerateChildNodes(withName: BlockCategoryName3) {
            node, stop in
            numberOfBricks = numberOfBricks + 1
        }
        return numberOfBricks == 0
    }
    
    func generateBlocks(){
        // 1.
        let numberOfBlocks = 5
        let blockWidth = SKSpriteNode(imageNamed: "block2").size.width
        let totalBlocksWidth = blockWidth * CGFloat(numberOfBlocks)
        // 2.
        let xOffset = (frame.width - totalBlocksWidth) / 2
        
        // 3.
        for i in 0..<numberOfBlocks {
            let block = SKSpriteNode(imageNamed: "block.png")
            block.position = CGPoint(x: 20 + CGFloat(CGFloat(i) + 0.5) * blockWidth,
                                     y: frame.height * 0.95)
            
            block.physicsBody = SKPhysicsBody(rectangleOf: block.frame.size)
            block.physicsBody!.allowsRotation = false
            block.physicsBody!.friction = 0.0
            block.physicsBody!.affectedByGravity = false
            block.physicsBody!.isDynamic = false
            block.name = BlockCategoryName
            block.physicsBody!.categoryBitMask = BlockCategory
            block.zPosition = 2
            addChild(block)
        }
        
        let block = SKSpriteNode(imageNamed: "block3.png")
        block.position = CGPoint(x: ((blockWidth * 6) - 3),
                                 y: frame.height * 0.95)
        
        block.physicsBody = SKPhysicsBody(rectangleOf: block.frame.size)
        block.physicsBody!.allowsRotation = false
        block.physicsBody!.friction = 0.0
        block.physicsBody!.affectedByGravity = false
        block.physicsBody!.isDynamic = false
        block.name = BlockCategoryName3
        block.physicsBody!.categoryBitMask = BlockCategory3
        block.zPosition = 2
        addChild(block)
        
        let numberOfBlocks1 = 3
        for j in 0..<numberOfBlocks1 {
            let block = SKSpriteNode(imageNamed: "block2.png")
            block.position = CGPoint(x: ((blockWidth * 7) - 25) + CGFloat(CGFloat(j) + 0.5) * blockWidth,
                                     y: frame.height * 0.95)

            block.physicsBody = SKPhysicsBody(rectangleOf: block.frame.size)
            block.physicsBody!.allowsRotation = false
            block.physicsBody!.friction = 0.0
            block.physicsBody!.affectedByGravity = false
            block.physicsBody!.isDynamic = false
            block.name = BlockCategoryName2
            block.physicsBody!.categoryBitMask = BlockCategory2
            block.zPosition = 2
            addChild(block)
        }
        
        let numberOfBlocks2 = 2
        for j in 0..<numberOfBlocks2 {
            let block = SKSpriteNode(imageNamed: "block3.png")
            block.position = CGPoint(x: ((blockWidth * 10) - 25) + CGFloat(CGFloat(j) + 0.5) * blockWidth,
                                     y: frame.height * 0.95)
            
            block.physicsBody = SKPhysicsBody(rectangleOf: block.frame.size)
            block.physicsBody!.allowsRotation = false
            block.physicsBody!.friction = 0.0
            block.physicsBody!.affectedByGravity = false
            block.physicsBody!.isDynamic = false
            block.name = BlockCategoryName3
            block.physicsBody!.categoryBitMask = BlockCategory3
            block.zPosition = 2
            addChild(block)
        }
        
        let numberOfBlocks3 = 11
        for j in 0..<numberOfBlocks3 {
            let block = SKSpriteNode(imageNamed: "block.png")
            block.position = CGPoint(x: (20) + CGFloat(CGFloat(j) + 0.5) * blockWidth,
                                     y: frame.height * 0.9)
            
            block.physicsBody = SKPhysicsBody(rectangleOf: block.frame.size)
            block.physicsBody!.allowsRotation = false
            block.physicsBody!.friction = 0.0
            block.physicsBody!.affectedByGravity = false
            block.physicsBody!.isDynamic = false
            block.name = BlockCategoryName3
            block.physicsBody!.categoryBitMask = BlockCategory3
            block.zPosition = 2
            addChild(block)
        }
        
//        let block2 = SKSpriteNode(imageNamed: "block3.png")
//        block2.position = CGPoint(x: ((blockWidth * 10) - 2.5),
//                                 y: frame.height * 0.95)
//
//        block2.physicsBody = SKPhysicsBody(rectangleOf: block2.frame.size)
//        block2.physicsBody!.allowsRotation = false
//        block2.physicsBody!.friction = 0.0
//        block2.physicsBody!.affectedByGravity = false
//        block2.physicsBody!.isDynamic = false
//        block2.name = BlockCategoryName
//        block2.physicsBody!.categoryBitMask = BlockCategory
//        block2.zPosition = 2
//        addChild(block2)
//
//
//
//        let numberOfBlocks2 = 3
//        let blockWidth2 = SKSpriteNode(imageNamed: "block2").size.width
//        let totalBlocksWidth2 = blockWidth2 * CGFloat(numberOfBlocks2)
//        // 2.
//        let xOffset2 = ((frame.width - totalBlocksWidth2) / 2 ) + totalBlocksWidth
//        // 3.
//        for i in 0..<numberOfBlocks2 {
//            let block2 = SKSpriteNode(imageNamed: "block3.png")
//            block2.position = CGPoint(x: xOffset2 + CGFloat(CGFloat(i) + 0.5) * blockWidth2,
//                                      y: frame.height * 0.95)
//
//            block2.physicsBody = SKPhysicsBody(rectangleOf: block2.frame.size)
//            block2.physicsBody!.allowsRotation = false
//            block2.physicsBody!.friction = 0.0
//            block2.physicsBody!.affectedByGravity = false
//            block2.physicsBody!.isDynamic = false
//            block2.name = BlockCategoryName
//            block2.physicsBody!.categoryBitMask = BlockCategory
//            block2.zPosition = 2
//            addChild(block2)
//        }
//        for j in 0..<numberOfBlocks2 {
//            let block2 = SKSpriteNode(imageNamed: "block4.png")
//            block2.position = CGPoint(x: xOffset2 + CGFloat(CGFloat(j) + 0.5) * blockWidth2,
//                                      y: frame.height * 0.9)
//
//            block2.physicsBody = SKPhysicsBody(rectangleOf: block2.frame.size)
//            block2.physicsBody!.allowsRotation = false
//            block2.physicsBody!.friction = 0.0
//            block2.physicsBody!.affectedByGravity = false
//            block2.physicsBody!.isDynamic = false
//            block2.name = BlockCategoryName
//            block2.physicsBody!.categoryBitMask = BlockCategory
//            block2.zPosition = 2
//            addChild(block2)
//        }
    }
    
    
}
