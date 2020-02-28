//
//  GameController.swift
//  ARProject
//
//  Created by Guilherme Tavares Shimamoto on 27/02/20.
//  Copyright © 2020 Guilherme Shimamoto. All rights reserved.
//

import Foundation
import ARKit
import RealityKit
import Combine


class GameController {
    
    private weak var viewDelegate: ViewDelegate?
    
    var game: Basketball.Game!
    
    var points: Int = 0
    
    let trigger = TriggerVolume(shape: .generateBox(size: [0.15, 0.15, 0.15]), filter: .sensor)
    
    init(viewDelegate: ViewDelegate) {
        self.viewDelegate = viewDelegate
    }
    
    func startGame() {
        // Load the "Box" scene from the "Experience" Reality File
        self.game = try! Basketball.loadGame()
        
        //Adding target trigger
        trigger.position = [0, 0.63, -0.62]
        game.addChild(trigger)
        
        // Add the box anchor to the scene
        viewDelegate?.addAnchor(for: game)
    }
    
    func treatCollision(entityA: Entity, entityB: Entity) {
        guard let ball = game.ball else { return }
        
        if entityA == ball && entityB == trigger {
            points += 1
            viewDelegate?.updatedPointsLabel(with: points)
            
            game.notifications.pointAnimation.post()
        }
    }
    
    func throwBall(for intensity: Int) {
        switch intensity {
        case 1:
            game.notifications.throw1.post()
        case 2:
            game.notifications.throw2.post()
        case 3:
            game.notifications.throw3.post()
        case 4:
            game.notifications.throw4.post()
        case 5:
            game.notifications.throw5.post()
        default:
            return
        }
    }
}
