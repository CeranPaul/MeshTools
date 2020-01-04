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
        
        hull = buildNoseCone()
        
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
    
    
    /// Build a portion of a nosecone
    public func buildNoseCone() -> Mesh   {
        
        ///Permissible deviation from the surface
        let allowableCrown = 0.03
        
        /// The mesh to be returned
        let pointedDome = Mesh()

        
        let hub = Point3D(x: 0.0, y: 0.0, z: 0.0)
        let greenFlag = Point3D(x: 4.0, y: 0.0, z: 0.0)
        let checkered = Point3D(x: 0.0, y: 6.0, z: 0.0)
        let heavenward = Vector3D(i: 0.0, j: 0.0, k: 1.0)
        
        /// An ellipse to be the basic profile
        let humpty = Ellipse(retnec: hub, a: 4.0, b: 6.0, azimuth: Double.pi / 2.0, start: greenFlag, finish: checkered, normal: heavenward)
        
        var lilypad = 0.0
        let rangeTop = 0.95
        
        ///Intervals for creating rings
        var ringLevels: [Double]
        
        /// Simple attempt at finding levels
        var rawLevels = [Double]()
        
        repeat   {
            
            rawLevels.append(lilypad)     // Put this value in the array
            
            let hop = humpty.findStep(allowableCrown: 0.7 * allowableCrown, currentT: lilypad, increasing: true)
            
            lilypad = hop   // Prepare for next iteration
            
        } while lilypad < rangeTop
        
        
        // Make adjustments to avoid a row of teeny triangles
        let tnuoc = rawLevels.count
        let currentInterval = rawLevels[tnuoc - 1] - rawLevels[tnuoc - 2]
        let lastInterval = rangeTop - rawLevels[tnuoc - 1]
        
        if lastInterval < (currentInterval * 0.3)   {
            let desiredLast = rangeTop - currentInterval * 0.6
            let factor = desiredLast / rangeTop   // Assumes that you start at 0.00
            
            ringLevels = rawLevels.map( { $0 * factor } )
            
        }  else  {
            ringLevels = rawLevels
        }
        
        ringLevels.append(rangeTop)
        
        for elev in ringLevels   {
            print(elev)
        }
        
        
        let lower = Arc(height: 0.0, radius: 4.00)
        var lwrNecklace = lower.approximate(allowableCrown: allowableCrown * 0.7)
        ringLevels.remove(at: 0)
        
        for elev in ringLevels   {
            
            let spot = try! humpty.pointAt(t: elev)

            let upper = Arc(height: spot.y, radius: spot.x)
            let uprNecklace = upper.approximate(allowableCrown: allowableCrown * 0.7)
            
            let hoop = try! Mesh.fillRingStep(inner: uprNecklace, outer: lwrNecklace)
            try! pointedDome.absorb(noob: hoop)

            lwrNecklace = uprNecklace   //Prep for next hoop
            
        }
        
        let tippyTop = Point3D(x: 0.0, y: 0.0, z: 6.0)   // Needs to coordinated with ellipse parameters
        let cap = fillCenter(ring: lwrNecklace, apex: tippyTop)
        try! pointedDome.absorb(noob: cap)
        
        return pointedDome
    }
    
    
    
    /// Make a pie around a point.
    /// Eventually belongs in Mesh class, probably.
    /// - Parameters:
    ///   - ring: Points in CCW order
    ///   - apex:  Middle point
    /// - Returns: A small Mesh
    public func fillCenter(ring: [Point3D], apex: Point3D) -> Mesh   {
        
        /// The mesh to be returned
        let yarmulke = Mesh()
        
        for (index, pip) in ring.enumerated()   {
            if index > 0   {
                try! yarmulke.addPoints(ptA: apex, ptB: ring[index - 1], ptC: pip)
            }
        }
        
        return yarmulke
    }
    
    /// A simple example
    public func buildQuarilateral() -> Mesh  {
        
        /// The mesh to be returned
        let flag = Mesh()

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
        try! flag.absorb(noob: strip)

        strip = Mesh.fillLadder(port: portChain, starboard: stbdChain)
        try! flag.absorb(noob: strip)
        
        strip = Mesh.fillLadder(port: stbdChain, starboard: rightChain)
        try! flag.absorb(noob: strip)
        
        return flag
    }
        
}
