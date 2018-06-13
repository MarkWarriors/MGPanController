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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.panController.delegate = self
    }

    func didPerformSwipeAction(direction: MGPanController.Direction) {
        print("Swipe action \(direction.rawValue)")
    }
    
    func isPanningIn(direction: MGPanController.Direction) {
        print("Panning in \(direction.rawValue)")
    }
    


}

