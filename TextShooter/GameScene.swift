//
//  GameScene.swift
//  TextShooter
//
//  Created by Владислав Соколов on 02.09.2020.
//  Copyright © 2020 Владислав Соколов. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    private var levelNumber: Int
    private var playerLives: Int {
        didSet {
            let lives = childNode(withName: "LivesLabel") as! SKLabelNode
            lives.text = "Lives: \(playerLives)"
        }
    }
    private var finished = false
    private let playerNode: PlayerNode = PlayerNode()
    private let enemies = SKNode()
    private let playerBullets = SKNode()
    private let forceFields = SKNode()
    
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
 
    init(size: CGSize, levelNumber: Int) {
        self.levelNumber = levelNumber
        self.playerLives = 5
        super.init(size: size)
        
        backgroundColor = .lightGray
        
        physicsWorld.gravity = CGVector(dx: 0, dy: -1)
        physicsWorld.contactDelegate = self
        
        let lives = SKLabelNode(fontNamed: "Courier")
        lives.fontSize = 16
        lives.fontColor = .black
        lives.name = "LivesLabel"
        lives.text = "Lives: \(playerLives)"
        lives.verticalAlignmentMode = .top
        lives.horizontalAlignmentMode = .right
        lives.position = CGPoint(x: frame.size.width, y: frame.size.height)
        
        addChild(lives)
        
        let level = SKLabelNode(fontNamed: "Courier")
        level.fontSize = 16
        level.fontColor = .black
        level.name = "LavelLabel"
        level.text = "Level \(levelNumber)"
        level.verticalAlignmentMode = .top
        level.horizontalAlignmentMode = .left
        level.position = CGPoint(x: 0, y: frame.size.height)
        
        addChild(level)
        
        playerNode.position = CGPoint(x: frame.midX, y: frame.height * 0.1)
        addChild(playerNode)
        
        addChild(enemies)
        spawnEnemies()
        
        addChild(playerBullets)
        
        addChild(forceFields)
        createForceFields()        
    }
    
    private func createForceFields() {
        let fieldCount = 3
        let size = frame.size
        let sectionWidth = Int(size.width) / fieldCount
        for i in 0..<fieldCount {
            let x = CGFloat(UInt32(i * sectionWidth) + arc4random_uniform(UInt32(sectionWidth)))
            let y = CGFloat(arc4random_uniform(UInt32(size.height * 0.25)) + UInt32(size.height * 0.25))
            let gravityField = SKFieldNode.radialGravityField()
            gravityField.position = CGPoint(x: x, y: y)
            gravityField.categoryBitMask = GravityFieldCategory
            gravityField.strength = 4
            gravityField.falloff = 2
            gravityField.region = SKRegion(size: CGSize(width: size.width * 0.3, height: size.height * 0.1))
            forceFields.addChild(gravityField)
            
            let fieldLocationNode = SKLabelNode(fontNamed: "Courier")
            fieldLocationNode.fontSize = 16
            fieldLocationNode.fontColor = .red
            fieldLocationNode.name = "GravityField"
            fieldLocationNode.text = "*"
            fieldLocationNode.position = CGPoint(x: x, y: y)
            forceFields.addChild(fieldLocationNode)
        }
    }
    
    private func spawnEnemies() {
        let count = Int(log(Float(levelNumber))) + levelNumber
        for _ in 0..<count {
            let enemy = EnemyNode()
            let size = frame.size
            let x = arc4random_uniform(UInt32(size.width * 0.8)) + UInt32(size.width * 0.1)
            let y = arc4random_uniform(UInt32(size.height * 0.5)) + UInt32(size.height * 0.5)
            enemy.position = CGPoint(x: CGFloat(x), y: CGFloat(y))
            enemies.addChild(enemy)
        }
    }
    
    convenience override init(size: CGSize) {
        self.init(size: size, levelNumber: 1)
    }
    
    required init?(coder aDecoder: NSCoder) {
        levelNumber = aDecoder.decodeInteger(forKey: "level")
        playerLives = aDecoder.decodeInteger(forKey: "playerLives")
        super.init(coder: aDecoder)
    }
    
    override func encode(with coder: NSCoder) {
        coder.encode(Int(levelNumber), forKey: "levelNumber")
        coder.encode(playerLives, forKey: "playerLives")
    }
    
//    class func scene(size: CGSize, levelNumber: Int) -> GameScene {
//        return scene(size: size, levelNumber: levelNumber)
//    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        if contact.bodyA.categoryBitMask == contact.bodyB.categoryBitMask {
            //оба физических тела относятся к одной категории
            let nodeA = contact.bodyA.node!
            let nodeB = contact.bodyB.node!
            
            //что сделать с этими узлами?
            nodeA.friendlyBumpFrom(nodeB)
            nodeB.friendlyBumpFrom(nodeA)
        } else {
            var attacker: SKNode
            var attackee: SKNode
            
            if contact.bodyA.categoryBitMask > contact.bodyB.categoryBitMask {
                //тело А атаккует тело В
                attacker = contact.bodyA.node!
                attackee = contact.bodyB.node!
            } else {
                //тело B атаккует тело A
                attacker = contact.bodyB.node!
                attackee = contact.bodyA.node!
            }
            if attackee is PlayerNode {
                playerLives -= 1
            }
            
            //что сделать с атакующим и атакуемым телами?
            do {
                try attackee.receiveAttacker(attacker, contact: contact)
            } catch  {
                print(error.localizedDescription)
            }
            playerBullets.removeChildren(in: [attacker])
            enemies.removeChildren(in: [attacker])
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            if location.y < frame.height * 0.2 {
                let target = CGPoint(x: location.x, y: playerNode.position.y)
                playerNode.moveToward(target)
            } else {
                let bullet = BulletNode.bullet(from: playerNode.position, toward: location)
                playerBullets.addChild(bullet)
            }
        }
    }
    
    private func checkForNextLevel() {
        if enemies.children.isEmpty {
            goToNextLevel()
        }
    }
    
    private func goToNextLevel() {
        finished = true
                
        let label = SKLabelNode(fontNamed: "Courier")
        label.text = "Level Complete!"
        label.fontColor = .blue
        label.fontSize = 32
        label.position = CGPoint(x: frame.size.width * 0.5, y: frame.size.height * 0.5)
        addChild(label)
        
        let nextLevel = GameScene(size: frame.size, levelNumber: levelNumber + 1)
        nextLevel.playerLives = playerLives
        view!.presentScene(nextLevel, transition: SKTransition.flipHorizontal(withDuration: 1.0))
    }
    
    private func checkForGameOver() -> Bool {
        if playerLives == 0 {
            triggerGameOver()
            return true
        }
        return false
    }
    
    private func triggerGameOver() {
        finished = true
        
        do {
            let url = Bundle.main.url(forResource: "EnemyExplosion", withExtension: "sks")!
            let enemyExplosionData = try Data(contentsOf: url)
            let explosion = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(enemyExplosionData) as! SKEmitterNode
            explosion.numParticlesToEmit = 200
            explosion.position = playerNode.position
            scene!.addChild(explosion)
        } catch {
            print(error.localizedDescription)
        }
        playerNode.removeFromParent()
        
        let transition = SKTransition.doorsOpenVertical(withDuration: 1)
        let gameOver = GameOverScene(size: frame.size)
        view!.presentScene(gameOver, transition: transition)
        run(SKAction.playSoundFileNamed("gameOver.wav", waitForCompletion: false))
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        if finished {
            return
        }
        updateBullets()
        updateEnemies()
        if !checkForGameOver() {
            checkForNextLevel()            
        }
    }
    
    private func updateBullets() {
        var bulletsToRemove: [BulletNode] = []
        for bullet in playerBullets.children as! [BulletNode] {
            if !frame.contains(bullet.position) {
                bulletsToRemove.append(bullet)
                continue
            }
            bullet.applyRecurringForce()
        }
        playerBullets.removeChildren(in: bulletsToRemove)
    }
    
    private func updateEnemies() {
        var enemiesToRemove: [EnemyNode] = []
        for node in enemies.children as! [EnemyNode] {
            if !frame.contains(node.position) {
                enemiesToRemove.append(node)
            }
        }
        enemies.removeChildren(in: enemiesToRemove)
    }
}
