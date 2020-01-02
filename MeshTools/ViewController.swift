//
//  ViewController.swift
//  MeshTools
//
//  Created by Paul Hollingshead on 1/1/20.
//  Copyright © 2020 Paul Hollingshead. All rights reserved.
//

import UIKit

/// Rotation angles after user input.  Radians.  To feed the UIView
var yawChange = 0.0   // Around the screen Y axis
var pitchChange = 0.0   // Around the screen X axis

class ViewController: UIViewController {

    /// How much rotation happens with a swipe
    /// Set empirically
    let sensitivity = 280.0
    
    /// Reset point to keep rotation non-cumulative
    var touchPrevious = CGPoint(x: 0.0, y: 0.0)
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    /// Always treat a screen swipe as a rotation
    @IBAction func handlePan(recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: self.view)
        if let view = recognizer.view {
            
            yawChange = Double(translation.x) / sensitivity
            pitchChange = Double(translation.y) / -sensitivity    // Due to screen inversion
            
            view.setNeedsDisplay()     // Request a display update
        }
        
        recognizer.setTranslation(touchPrevious, in: self.view)
    }
    

}

