//
//  WorkBench.swift
//  MeshTools
//
//  Created by Paul Hollingshead on 1/1/20.
//  Copyright © 2020 Paul Hollingshead. All rights reserved.
//

import UIKit

var modelGeo = WorkBench()

public class WorkBench   {
    
    /// The collection of triangles to define the object boundary
    var hull = Mesh()


    /// Various LineSegs to be displayed
    var displayLines = [LineSeg]()
    
    /// Bounding area for play
    var arena = CGRect(x: -15.0, y: -15.0, width: 30.0, height: 30.0)
    
    /// Rotation center
    var rotCenter = Point3D(x: 0.0, y: 0.0, z: 0.0)   // Will get replaced in "init"

    
    init()   {
        
        let ibFwd = Point3D(x: -10.0, y: 8.0, z: 0.0)
        let tipFwd = Point3D(x: 12.0, y: 6.0, z: 0.0)
        let tipAft = Point3D(x: 12.0, y: -2.0, z: 0.0)
        let ibAft = Point3D(x: -10.0, y: -5.0, z: 0.0)
        
        // Generate four boundary lines
        let top = try! LineSeg(end1: ibFwd, end2: tipFwd)
        displayLines.append(top)
        
        let right = try! LineSeg(end1: tipAft, end2: tipFwd)
        displayLines.append(right)
        
        let bottom = try! LineSeg(end1: ibAft, end2: tipAft)
        displayLines.append(bottom)
        
        let left = try! LineSeg(end1: ibAft, end2: ibFwd)
        displayLines.append(left)
        
        
        var topPt = try! top.pointAt(t: 0.25)
        var botPt = try! bottom.pointAt(t: 0.25)
        
        /// A vertical chain near the left edge
        let interior1 = try! LineSeg(end1: botPt, end2: topPt)

        
        topPt = try! top.pointAt(t: 0.50)
        botPt = try! bottom.pointAt(t: 0.50)
        
        /// A vertical  chain in the middle
        let interior2 = try! LineSeg(end1: botPt, end2: topPt)

        
        var params = [0.00, 0.20, 0.40, 0.60, 0.80, 1.00]
        let leftChain = params.map( { try! left.pointAt(t: $0) } )
        
        params = [0.00, 0.25, 0.50, 0.75, 1.00]
        let portChain = params.map( { try! interior1.pointAt(t: $0) } )

        params = [0.00, 0.30, 0.55, 0.75, 1.00]
        let stbdChain = params.map( { try! interior2.pointAt(t: $0) } )

        params = [0.00, 0.35, 0.75, 1.00]
        let rightChain = params.map( { try! right.pointAt(t: $0) } )

        // The old way of building triangles
        var strip = Mesh.fillLadder(port: leftChain, starboard: portChain)
        try! hull.absorb(noob: strip)

        strip = Mesh.fillLadder(port: portChain, starboard: stbdChain)
        try! hull.absorb(noob: strip)
        
        strip = Mesh.fillLadder(port: stbdChain, starboard: rightChain)
        try! hull.absorb(noob: strip)
        

        
        // Display the mesh
        let fringe = Mesh.getBach(screen: hull)
        for wire in fringe   {
            wire.setIntent(purpose: .Boundary)
            self.displayLines.append(wire)
        }


        let middle = Mesh.getMated(screen: hull)
        for wire in middle   {
            wire.setIntent(purpose: .Interior)
            self.displayLines.append(wire)
        }
        
    }
        
}
