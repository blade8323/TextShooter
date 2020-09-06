//
//  PlayerNode.swift
//  TextShooter
//
//  Created by Владислав Соколов on 02.09.2020.
//  Copyright © 2020 Владислав Соколов. All rights reserved.
//

import UIKit
import SpriteKit

class PlayerNode: SKNode {
    override init() {
        super.init()
        name = "Player \(self)"
        initNodeGraph()
        initPhysicsBody()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func initPhysicsBody() {
        let body = SKPhysicsBody(rectangleOf: CGSize(width: 20, height: 20))
        body.affectedByGravity = false
        body.categoryBitMask = PlayerCategory
        body.contactTestBitMask = EnemyCategory
        body.collisionBitMask = 0
        body.fieldBitMask = 0
        physicsBody = body
    }
    
    private func initNodeGraph() {
        let label = SKLabelNode(fontNamed: "Courier")
        label.fontColor = .darkGray
        label.fontSize = 40
        label.text = "v"
        label.zRotation = CGFloat(Double.pi)
        label.name = "label"
        addChild(label)
    }
    
    func moveToward(_ location: CGPoint) {
        removeAction(forKey: "movement")
        removeAction(forKey: "wobbling")
        
        let distance = pointDistance(position, location)
        let screenWidth = UIScreen.main.bounds.size.width
        let duration = TimeInterval(2 * distance / screenWidth)
        
        run(SKAction.move(to: location, duration: duration), withKey: "movement")
        
        let wobbleTime = 0.3
        let halfWobbleTime = wobbleTime / 2
        let wobbling = SKAction.sequence([
            SKAction.scaleX(to: 0.2, duration: halfWobbleTime),
            SKAction.scaleX(to: 1, duration: halfWobbleTime)
        ])
        let wobbleCount = Int(duration / wobbleTime)
        run(SKAction.repeat(wobbling, count: wobbleCount), withKey: "wobbling")
    }
    
    override func receiveAttacker(_ attacker: SKNode, contact: SKPhysicsContact) throws {
        do {
            let url = Bundle.main.url(forResource: "EnemyExplosion", withExtension: "sks")!
            let enemyExplosionData = try Data(contentsOf: url)
            let explosion = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(enemyExplosionData) as! SKEmitterNode
            explosion.numParticlesToEmit = 50
            explosion.position = contact.contactPoint
            scene!.addChild(explosion)
        } catch {
            print(error.localizedDescription)
        }
        run(SKAction.playSoundFileNamed("playerHit.wav", waitForCompletion: false))
    }
}
