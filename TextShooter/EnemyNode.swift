//
//  EnemyNode.swift
//  TextShooter
//
//  Created by Владислав Соколов on 02.09.2020.
//  Copyright © 2020 Владислав Соколов. All rights reserved.
//

import UIKit
import SpriteKit

class EnemyNode: SKNode {
    override init() {
        super.init()
        name = "Enemy \(self)"
        initNodeGraph()
        initPhysicsBody()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func initPhysicsBody() {
        let body = SKPhysicsBody(rectangleOf: CGSize(width: 40, height: 40))
        body.affectedByGravity = false
        body.categoryBitMask = EnemyCategory
        body.contactTestBitMask = PlayerCategory | EnemyCategory
        body.mass = 0.2
        body.angularDamping = 0
        body.linearDamping = 0
        body.fieldBitMask = 0
        physicsBody = body
    }
    
    private func initNodeGraph() {
        let topRow = SKLabelNode(fontNamed: "Courier-Bold")
        topRow.fontColor = .brown
        topRow.fontSize = 20
        topRow.text = "x x"
        topRow.position = CGPoint(x: 0, y: 15)
        addChild(topRow)
        
        let middleRow = SKLabelNode(fontNamed: "Courier-Bold")
        middleRow.fontColor = .brown
        middleRow.fontSize = 20
        middleRow.text = "x"
        addChild(middleRow)
        
        let bottomRow = SKLabelNode(fontNamed: "Courier-Bold")
        bottomRow.fontColor = .brown
        bottomRow.text = "x x"
        bottomRow.fontSize = 20
        bottomRow.position = CGPoint(x: 0, y: -15)
        addChild(bottomRow)
    }
    
    override func friendlyBumpFrom(_ node: SKNode) {
        physicsBody!.affectedByGravity = true
    }
    override func receiveAttacker(_ attacker: SKNode, contact: SKPhysicsContact) throws {
        physicsBody!.affectedByGravity = true
        let force = vectorMultiply(attacker.physicsBody!.velocity, contact.collisionImpulse)
        
        let myContact = scene!.convert(contact.contactPoint, to: self)
        physicsBody!.applyForce(force, at: myContact)
        do {
            let url = Bundle.main.url(forResource: "MissileExplosion", withExtension: "sks")!
            let missileExplosionData = try Data(contentsOf: url)
            let explosion = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(missileExplosionData) as! SKEmitterNode
            explosion.numParticlesToEmit = 20
            explosion.position = contact.contactPoint
            scene!.addChild(explosion)
        } catch {
            print(error.localizedDescription)
        }
        run(SKAction.playSoundFileNamed("enemyHit.wav", waitForCompletion: false))
    }
}
