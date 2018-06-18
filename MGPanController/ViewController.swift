//
//  ViewController.swift
//  MGPanController
//
//  Created by Marco Guerrieri on 13/06/18.
//  Copyright © 2018 Marco Guerrieri. All rights reserved.
//

import UIKit

class ViewController: UIViewController, MGPanControllerDelegate {
    
    @IBOutlet weak var panController: MGPanController!
    @IBOutlet weak var fieldView: UIView!
    @IBOutlet weak var droneView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.panController.delegate = self
        createParticles()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.droneView.center = fieldView.center
    }
    
    func createParticles() {
        let particleEmitter = CAEmitterLayer()
        
        particleEmitter.emitterPosition = CGPoint(x: self.fieldView.center.x, y: 0)
        particleEmitter.emitterShape = kCAEmitterLayerLine
        particleEmitter.emitterSize = CGSize(width: self.fieldView.frame.size.width, height: 1)
        
        let red = makeEmitterCell(color: UIColor.white)
        let green = makeEmitterCell(color: UIColor.gray)
        let blue = makeEmitterCell(color: UIColor.darkGray)
        
        particleEmitter.emitterCells = [red, green, blue]
        
        self.fieldView.layer.addSublayer(particleEmitter)
    }
    
    func makeEmitterCell(color: UIColor) -> CAEmitterCell {
        let cell = CAEmitterCell()
        cell.birthRate = 5
        cell.lifetime = 7.0
        cell.lifetimeRange = 0
        cell.color = color.cgColor
        cell.velocity = 50
        cell.velocityRange = 20
        cell.emissionLongitude = CGFloat.pi
        cell.emissionRange = CGFloat.pi / 4
        cell.spin = 1
        cell.spinRange = 3
        cell.scaleRange = 0.5
        cell.scaleSpeed = -0.05
        
        cell.contents = UIImage(named: "confetti.png")?.cgImage
        return cell
    }

    
    func isPanningIn(direction: MGPanController.Direction, strenght: CGFloat) {
        var newPosition = self.droneView.center
        let move = 10 * strenght
        switch direction {
        case .topDirection:
            newPosition = CGPoint.init(x: self.droneView.center.x, y:  self.droneView.center.y + move)
            break
        case .bottomDirection:
            newPosition = CGPoint.init(x: self.droneView.center.x, y:  self.droneView.center.y - move)
            break
        case .leftDirection:
            newPosition = CGPoint.init(x: self.droneView.center.x - move, y: self.droneView.center.y)
            break
        case .rightDirection:
            newPosition = CGPoint.init(x: self.droneView.center.x + move, y: self.droneView.center.y)
            break
        default:
            break
        }
        if self.fieldView.bounds.contains(newPosition) {
            UIView.animate(withDuration: 0.1) {
                self.droneView.center = newPosition
            }
            
        }
    }
    


}

