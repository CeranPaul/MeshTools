//
//  LineSegTests.swift
//  SketchCurves
//
//  Created by Paul on 11/3/15.
//  Copyright © 2018 Ceran Digital Media. All rights reserved.  See LICENSE.md
//

import XCTest

class LineSegTests: XCTestCase {

    
    func testFidelity()   {
        
        let alpha = Point3D(x: 2.5, y: 2.5, z: 2.5)
        let beta = Point3D(x: 4.5, y: 4.5, z: 2.5)
        
        let stroke = try! LineSeg(end1: alpha, end2: beta)
        
        XCTAssert(alpha == stroke.getOneEnd())
        XCTAssert(beta == stroke.getOtherEnd())
        
        XCTAssert(stroke.usage == PenTypes.Ordinary)
        
        let gamma = Point3D(x: 2.5, y: 2.5, z: 2.5)
        
        XCTAssertThrowsError(try LineSeg(end1: alpha, end2: gamma))
        
    }
    
    func testSetIntent()   {
        
        let alpha = Point3D(x: 2.5, y: 2.5, z: 2.5)
        let beta = Point3D(x: 4.5, y: 4.5, z: 2.5)
        
        let stroke = try! LineSeg(end1: alpha, end2: beta)
        
        XCTAssert(stroke.usage == PenTypes.Ordinary)
        
        stroke.setIntent(purpose: PenTypes.Boundary)
        XCTAssert(stroke.usage == PenTypes.Boundary)
        
    }
    


    /// Test a point at some proportion along the line segment
    func testPointAt() {
        
        let pt1 = Point3D(x: 1.0, y: 1.0, z: 1.0)
        let pt2 = Point3D(x: 5.0, y: 5.0, z: 5.0)
        
        let slash = try! LineSeg(end1: pt1, end2: pt2)
        
        let ladybug = try! slash.pointAt(t: 0.6)
        
        let home = Point3D(x: 3.4, y: 3.4, z: 3.4)
        
        XCTAssert(ladybug == home)
        
    }
    

    func testTangent()   {
        
        let alpha = Point3D(x: 2.5, y: 2.5, z: 2.5)
        let beta = Point3D(x: 2.5, y: 4.5, z: 2.5)
        
        let stroke = try! LineSeg(end1: alpha, end2: beta)
        
        let target = Vector3D(i: 0.0, j: 1.0, k: 0.0)
        
        var trial = stroke.tangentAt(t: 0.5)
        trial.normalize()
        
        XCTAssert(trial == target)
        
    }
    
    func testLength()   {
        
        let alpha = Point3D(x: 2.5, y: 2.5, z: 2.5)
        let beta = Point3D(x: 4.5, y: 2.5, z: 2.5)
        
        let bar = try! LineSeg(end1: alpha, end2: beta)
        
        let target = 2.0
        
        XCTAssertEqual(bar.getLength(), target)
    }
    

    func testReverse()   {
        
        let alpha = Point3D(x: 2.5, y: 2.5, z: 2.5)
        let beta = Point3D(x: 4.5, y: 4.5, z: 4.5)
        
        let stroke = try! LineSeg(end1: alpha, end2: beta)
        
        stroke.reverse()
        
        XCTAssertEqual(alpha, stroke.getOtherEnd())
        XCTAssertEqual(beta, stroke.getOneEnd())
    }
    
     func testResolveRelative()   {
        
        let alpha = Point3D(x: 2.5, y: 2.5, z: 2.5)
        let beta = Point3D(x: 4.5, y: 2.5, z: 2.5)
        
        let stroke = try! LineSeg(end1: alpha, end2: beta)
        
        let pip = Point3D(x: 3.5, y: 3.0, z: 2.5)
        
        let offset = stroke.resolveRelativeVec(speck: pip)
        
        
        let targetA = Vector3D(i: 1.0, j: 0.0, k: 0.0)
        let targetP = Vector3D(i: 0.0, j: 0.5, k: 0.0)
        
        XCTAssertEqual(offset.along, targetA)
        XCTAssertEqual(offset.perp, targetP)
        
    }
    
    func testTransform()   {
        
        let alpha = Point3D(x: 2.5, y: 2.5, z: 2.5)
        let beta = Point3D(x: 4.5, y: 2.5, z: 2.5)
        
        let stroke = try! LineSeg(end1: alpha, end2: beta)
        
        let swing = Transform(rotationAxis: Axis.z, angleRad: Double.pi / 2.0)
        
        let door = try! stroke.transform(xirtam: swing)
        
        let targetAlpha = Point3D(x: -2.5, y: 2.5, z: 2.5)
        let targetBeta = Point3D(x: -2.5, y: 4.5, z: 2.5)
        
        XCTAssert(door.getOneEnd() == targetAlpha)
        XCTAssert(door.getOtherEnd() == targetBeta)

    }
    
    func testIsCrossing()   {
        
        let alpha = Point3D(x: 2.5, y: 2.5, z: 2.5)
        let beta = Point3D(x: 2.5, y: 4.5, z: 2.5)
        
        let stroke = try! LineSeg(end1: alpha, end2: beta)
        
        let chopA = Point3D(x: 2.4, y: 2.8, z: 2.5)
        let chopB = Point3D(x: 2.6, y: 2.7, z: 2.5)
        
        let chop = try! LineSeg(end1: chopA, end2: chopB)
        
        let flag1 = stroke.isCrossing(chop: chop)
        
        XCTAssert(flag1)
        
    }
    
    func testClipTo()   {
        
        let alpha = Point3D(x: 2.5, y: 2.5, z: 2.5)
        let beta = Point3D(x: 4.5, y: 4.5, z: 2.5)
        
        let stroke = try! LineSeg(end1: alpha, end2: beta)
        
        let cliff = Point3D(x: 4.0, y: 4.0, z: 2.5)
        
        let shorter = stroke.clipTo(stub: cliff, keepNear: true)
        
        let target = 1.5 * sqrt(2.0)
        
        XCTAssertEqual(target, shorter.getLength(), accuracy: Point3D.Epsilon)
        
        let distal = stroke.clipTo(stub: cliff, keepNear: false)
        let target2 = 0.5 * sqrt(2.0)
        
        XCTAssertEqual(target2, distal.getLength(), accuracy: Point3D.Epsilon)
        
    }
    
    func testCrown()   {
        
        let ptA = Point3D(x: 4.0, y: 2.0, z: 5.0)
        let ptB = Point3D(x: 2.0, y: 4.0, z: 5.0)
        
        let plateau = try! LineSeg(end1: ptA, end2: ptB)
        
        XCTAssert(plateau.findCrown(smallerT: 0.0, largerT: 1.0)  == 0.0)
        
    }
    
    func testFindStep()   {
        
        let ptA = Point3D(x: 4.0, y: 2.0, z: 5.0)
        let ptB = Point3D(x: 2.0, y: 4.0, z: 5.0)
        
        let dash = try! LineSeg(end1: ptA, end2: ptB)
        
        let param = 0.6
        
        let inc = dash.findStep(allowableCrown: 0.010, currentT: param, increasing: true)
        XCTAssert(inc == 1.0)
        
        let dec = dash.findStep(allowableCrown: 0.010, currentT: param, increasing: false)
        XCTAssert(dec == 0.0)
        
    }
    
}
