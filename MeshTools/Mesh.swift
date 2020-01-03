//
//  Mesh.swift
//  MeshTools
//
//  Created by Paul Hollingshead on 6/30/19.
//  Copyright © 2019 Paul Hollingshead. All rights reserved.
//

import UIKit

/// Main class for Set operations
public class Mesh   {

    /// Simple collection of flakes to define a (partial) boundary of a volume
    var scales = [Facet]()
    
    /// Edges that are used once
    var bachelorSet = Set<CommonEdge>()
    
    /// Edges that are used twice
    var matedSet = Set<CommonEdge>()
    
    /// Definition of "equal" for point coordinates for this mesh.  Used to hash in "Edge".
    /// Should vary with measurement system used, and with model dimensions.
    /// Could become a variable set with the constructor.
    /// Distinct from "allowableCrown", and Point3D.Epsilon.
    public static let Epsilon = 0.010   // Appropriate for millimeters
    
    
    /// Empty initializer
    init()   {
        
    }
    
    /// Copy constructor
    init(source: Mesh)   {
        
        for chip in source.scales   {
            try! self.add(shiny: chip)
        }
    }
    
    
    /// Welcome a new Facet to the club.  Definitely not thread safe!
    /// - Parameters:
    ///   - shiny:  The new Facet
    /// - Throws: EdgeOverflowError if one of these edges represents a third triangle
    /// - SeeAlso:  addPoints()
    func add(shiny: Facet) throws -> Void   {
        
        try recordEdge(ptAlpha: shiny.getVertA(), ptOmega: shiny.getVertB())
        try recordEdge(ptAlpha: shiny.getVertB(), ptOmega: shiny.getVertC())
        try recordEdge(ptAlpha: shiny.getVertC(), ptOmega: shiny.getVertA())
        
        scales.append(shiny)
    }
    
    
    
    ///Add a CommonEdge to one of the Sets for this mesh.
    /// - Parameters:
    ///   - ptAlpha:  One end of the common edge
    ///   - ptOmega:  Other end of the common edge
    /// - Throws: EdgeOverflowError if a third triangle was attempted
    /// Should this become 'private'?
    public func recordEdge(ptAlpha: Point3D, ptOmega: Point3D) throws -> Void   {
        
        /// Shiny new Edge
        let razor = CommonEdge(endA: ptAlpha, endB: ptOmega)
        
        
        /// Puke if this is already in the mated set
        guard !self.matedSet.contains(razor) else  {  throw EdgeOverflowError(dupeEndA: ptAlpha, dupeEndB: ptOmega)  }
        
        
        if self.bachelorSet.contains(razor)   {
            
            self.matedSet.update(with: razor)   // Move this Edge to the 'mated' set
            self.bachelorSet.remove(razor)
//            print("Moved one")
            
        }  else  {
//            print("Status quo")
            self.bachelorSet.update(with: razor)  // Insert the new Edge in the 'bachelor' set
            
        }
        
    }
    
    
    ///Add a CommonEdge to one of the Sets for this mesh.
    /// - Parameters:
    ///   - ptAlpha:  One end of the common edge
    ///   - ptOmega:  Other end of the common edge
    /// - Throws: EdgeOverflowError if a third triangle was attempted
    /// Should this become 'private'?
    public func recordMatedEdge(ptAlpha: Point3D, ptOmega: Point3D) throws -> Void   {
        
        /// Shiny new Edge
        let razor = CommonEdge(endA: ptAlpha, endB: ptOmega)
        
        if self.matedSet.contains(razor)  ||  self.bachelorSet.contains(razor)    { throw EdgeOverflowError(dupeEndA: ptAlpha, dupeEndB: ptOmega)
            
        }   else   {
            self.matedSet.update(with: razor)   // Add this Edge to the 'mated' set

        }

    }
    
    
    
    /// Combine two Meshes.
    /// Should this be done by overloading the '+' operator?
    /// - Throws: EdgeOverflowError if a third triangle was attempted
    public func absorb(noob: Mesh) throws -> Void   {
        
        // These checks mean you can't use "formUnion"
        
        for hinge in noob.matedSet   {
            
            try self.recordMatedEdge(ptAlpha: hinge.endA, ptOmega: hinge.endB)

        }
        
        for hinge in noob.bachelorSet   {
            
            try self.recordEdge(ptAlpha: hinge.endA, ptOmega: hinge.endB)
        }
        
        
        self.scales.append(contentsOf: noob.scales)   // Simple accumulation
        
    }
    
    
    
    /// Pile on a new Facet starting from three points
    /// - Parameters:
    ///   - ptA:  One vertex
    ///   - ptB:  Another vertex
    ///   - ptC:  Final vertex
    /// - Throws: CoincidentPointsError if any of the vertices are duplicates
    /// - Throws: TriangleError if the vertices are linear
    /// - SeeAlso:  add()
    func addPoints(ptA: Point3D, ptB: Point3D, ptC: Point3D) throws   {
        
        // Be certain that they are distinct points
        guard Point3D.isThreeUnique(alpha: ptA, beta: ptB, gamma: ptC) else { throw CoincidentPointsError(dupePt: ptB) }
        
        // Ensure that the points are not linear
        guard !Point3D.isThreeLinear(alpha: ptA, beta: ptB, gamma: ptC) else { throw TriangleError(dupePt: ptB) }
        
        try recordEdge(ptAlpha: ptA, ptOmega: ptB)
        try recordEdge(ptAlpha: ptB, ptOmega: ptC)
        try recordEdge(ptAlpha: ptC, ptOmega: ptA)
        
        let dorito = try Facet(ptA: ptA, ptB: ptB, ptC: ptC)
        
        scales.append(dorito)
        
    }
    
    
    /// Make triangles between two full Arcs.
    /// Perhaps start with the radii so that check cylinders can be used.
    /// - Parameters:
    ///   - inner: Points on a ring.  Smaller count
    ///   - outer: Points on a ring.  Larger count
    /// - Throws: ArcPointsError, RingCountError
    /// - Returns: Small mesh
    public static func fillRingStep(inner: [Point3D], outer: [Point3D]) throws -> Mesh   {
        
        guard inner.count > 2 else {throw ArcPointsError(badPtA: inner[0], badPtB: inner[1], badPtC: inner[0])}
        
        guard outer.count > 2 else {throw ArcPointsError(badPtA: outer[0], badPtB: outer[1], badPtC: outer[0])}
        
        let diff = outer.count - inner.count
        
        guard diff >= 0 else {throw ArcPointsError(badPtA: inner[0], badPtB: inner[1], badPtC: inner[2])}
        
        // How do I check that the rings increase in the same direction?
        
        /// The ring of triangles to be returned
        let hula = Mesh()
        
        /// Index in the outer array of points
        var outerG = 0
        
        /// Stopping point for a section in the outer chain
        var endIndex: Int
        
        for g in 1..<inner.count   {
            
            if g == inner.count - 1   {    // Align indices for final verts
                endIndex = outer.count - 1
            }  else  {   // Find the proportional index in the outer chain
                let endFloat = Double(g) / Double(inner.count) * Double(outer.count)
                endIndex = Int(round(endFloat))
            }
            
            /// Next pair from the inner chain
            let duo = [inner[g - 1], inner[g]]
            
            /// Array slice from the outer chain
            let portion = outer[outerG...endIndex]
            let oppo = [Point3D](portion)   // Coerce into a Point3D array
            
            /// Vertices that are neighbors
            let card = try Mesh.duoLadder(duo: duo, oppo: oppo)
            try hula.absorb(noob: card)
            
            outerG = endIndex
        }
        
        return hula
    }


    /// Fill a ladder with two points on one side, and up to six on the other.
    /// Using copies of the points works out fine when hashed.
    /// - Parameters:
    ///   - duo:  Pair of points for one side
    ///   - oppo: Points on opposite side
    /// - Throws: LadderCountError if oppo contains more than six points
    public static func duoLadder(duo: [Point3D], oppo: [Point3D]) throws -> Mesh   {
        
        guard oppo.count < 7  else  { throw LadderCountError(tallyL: duo.count, tallyR: oppo.count) }   // Needs a better error
        
        // Should I test that the inputs contain no duplicates?
        
        
        /// The return value
        var patch: Mesh
        
        switch oppo.count   {
            
        case 2: patch = try Mesh.meshFromFour(ptA: duo[0], ptB: oppo[0], ptC: oppo[1], ptD: duo[1])
            
        case 3:
            
            patch = Mesh()
            try patch.addPoints(ptA: duo[0], ptB: oppo[0], ptC: oppo[1])
            try patch.addPoints(ptA: duo[0], ptB: oppo[1], ptC: duo[1])
            try patch.addPoints(ptA: oppo[1], ptB: oppo[2], ptC: duo[1])
            
        case 4, 5, 6:
            
            //            print("Large case")
            
            let leap = Mesh.findBigGap(chain: oppo)
            patch = try Mesh.meshFromFour(ptA: duo[0], ptB: oppo[leap], ptC: oppo[leap + 1], ptD: duo[1])
            
            for g in 0..<leap   {
                try patch.addPoints(ptA: duo[0], ptB: oppo[g], ptC: oppo[g + 1])
            }
            
            // Are there unused points past the gap?
            if leap < oppo.count - 2   {
                
                for g in leap + 2..<oppo.count   {
                    try patch.addPoints(ptA: duo[1], ptB: oppo[g - 1], ptC: oppo[g])
                }
            }
            
            
        default: patch = try! Mesh.meshFromFour(ptA: duo[0], ptB: oppo.first!, ptC: oppo.last!, ptD: duo[1])
            
        }
        
        //        print(patch.scales.count)
        
        return patch
    }
    
    
    
    /// Find the lower index of the pair that has the largest gap
    public static func findBigGap(chain: [Point3D]) -> Int   {
        
        var span = Point3D.dist(pt1: chain[0], pt2: chain[1])
        var spanIndex = 0
        
        for g in 2..<chain.count   {
            
            let freshSpan = Point3D.dist(pt1: chain[g - 1], pt2: chain[g])
            
            if freshSpan > span   {
                span = freshSpan
                spanIndex = g - 1
            }
        }
        
        return spanIndex
    }
    
    
    
    /// Build a Mesh of two Facets from four points - using the shorter common edge
    /// Points are assumed to be in CCW order
    /// - Parameters:
    ///   - ptA:  First point
    ///   - ptB:  Second point in CCW order
    ///   - ptC:  Third point
    ///   - ptD:  Fourth point
    /// - Returns: Tiny Mesh
    /// - Throws: CoincidentPointsError if any of the vertices are duplicates
    /// - Throws: TriangleError if the vertices are linear
    /// - Throws: EdgeOverflowError if a third triangle was attempted
    public static func meshFromFour(ptA: Point3D, ptB: Point3D, ptC: Point3D, ptD: Point3D) throws -> Mesh   {
        
        /// Collection of triangle pairs being constructed
        let resultMesh = Mesh()
        
        let distanceAC = Point3D.dist(pt1: ptA, pt2: ptC)
        let distanceBD = Point3D.dist(pt1: ptB, pt2: ptD)
        
        /// Two chips from four points
        var flake1, flake2: Facet
        
        if distanceAC < distanceBD  {
            
            flake1 = try Facet(ptA: ptA, ptB: ptB, ptC: ptC)
            flake2 = try Facet(ptA: ptC, ptB: ptD, ptC: ptA)
            
        }  else  {
            
            flake1 = try Facet(ptA: ptB, ptB: ptC, ptC: ptD)
            flake2 = try Facet(ptA: ptD, ptB: ptA, ptC: ptB)
            
        }
        
        try resultMesh.add(shiny: flake1)
        try resultMesh.add(shiny: flake2)
        
        return resultMesh
    }
    
    /// Fill a strip with triangles.  Port and starboard are important to get triangle normals in the proper direction.
    /// The chain counts may be different by one, in which case a wedge will be added at the finish.
    /// This could certainly benefit from an illustration.
    /// - Parameters:
    ///   - port:  Column of points for one side
    ///   - starboard: Column of points for other side
    /// - Returns: Small Mesh
    public static func fillLadder(port: [Point3D], starboard: [Point3D]) -> Mesh   {
        
        // TODO: It might be good if fillLadder found curves that were reversed.
        
        /// The triangle data that will be returned.
        let strip = Mesh()
        
        let portCount = port.count
        let starCount = starboard.count
        
        /// Default value for iterations
        var lesserCount = portCount
        
        /// Is there one more point in the starboard chain?
        var growing = false
        
        let equalCounts = (portCount == starCount)
        
        if !equalCounts {
            
            // Change some settings when the starboard array is smaller than the port array
            if starCount < portCount   {
                lesserCount = starCount
                growing = false
            }  else  {
                growing = true
            }
        }
        
        for g in 1..<lesserCount   {   // Changed on 7-27 to CCW order
            let pair = try! meshFromFour(ptA: port[g], ptB: port[g - 1], ptC: starboard[g - 1], ptD: starboard[g])
            try! strip.absorb(noob: pair)
        }
        
        // Insert one wedge triangle, if needed
        if !equalCounts  {
            
            let wedgeCount = lesserCount - 1
            
            let finalBarPort = port[wedgeCount]
            let finalBarStbd = starboard[wedgeCount]
            
            if growing   {
                try! strip.addPoints(ptA: finalBarPort, ptB: finalBarStbd, ptC: starboard[wedgeCount + 1])
            }  else  {
                try! strip.addPoints(ptA: finalBarPort, ptB: finalBarStbd, ptC: port[wedgeCount + 1])
            }
        }
        
        return strip
    }
    

    /// See that facet normals are not opposite of the guide direction
    /// - Parameters:
    ///   - knit: Mesh to be checked
    ///   - guide: Unit vector in the direction expected for the normals
    public static func isCoherent(knit: Mesh, guide: Vector3D) -> Bool   {
        
        let spikes = knit.scales.map( { try! Facet.genNormal(tricorner: $0) } )
        let downstream = spikes.map( { Vector3D.dotProduct(lhs: $0, rhs: guide) } )
        let badApples = downstream.filter( { $0 <= 0.0 } )
        
        let flag = badApples.count == 0
        
        return flag
    }
    
    
    /// Transform a Mesh copy including the creation of new topology
    /// Should be thread safe
    /// - Parameters:
    ///   - source:  Mesh to be moved or rotated
    ///   - xirtam:  Combination of translation, rotation, and scaling to be applied
    /// - Returns: A shiny Mesh
    public static func transform(source: Mesh, xirtam: Transform) -> Mesh   {
        
        /// The new Mesh to be returned
        let sparkling = Mesh()
        
        for chip in source.scales   {
            
            /// Transformed vertices
            let transA = xirtam.alter(pip: chip.getVertA())
            let transB = xirtam.alter(pip: chip.getVertB())
            let transC = xirtam.alter(pip: chip.getVertC())
            
            try! sparkling.addPoints(ptA: transA, ptB: transB, ptC: transC)
        }
        
        return sparkling
    }
    
    

    /// Create a duplicate Mesh on the other side of a Plane
    public static func mirror(knit: Mesh, flat: Plane) -> Mesh   {
        
        /// The new set of triangles
        let fairest = Mesh()
        
        for chip in knit.scales   {
            let pancake = Facet.mirror(flake: chip, flat: flat)
            try! fairest.add(shiny: pancake)
        }
        
        return fairest
    }
    
    
    /// Return LineSegs for the edges that are used exactly twice
    /// - Returns: Array of LineSegs
    public static func getMated(screen: Mesh) -> [LineSeg]   {
        
        /// Array to be returned
        var showoff = [LineSeg]()
        
        for razor in screen.matedSet   {
            let bar = try! LineSeg(end1: razor.endA, end2: razor.endB)
            showoff.append(bar)
        }
        
        return showoff
    }
    
    
    /// Return LineSegs for the edges that are used only once
    /// - Returns: Array of LineSegs
    public static func getBach(screen: Mesh) -> [LineSeg]   {
        
        /// Array to be returned
        var showoff = [LineSeg]()
        
        for razor in screen.bachelorSet   {
            let bar = try! LineSeg(end1: razor.endA, end2: razor.endB)
            showoff.append(bar)
        }
        
        return showoff
    }


}   // End of declaration for Mesh



/// A triangle with additional functions
public struct Facet   {
    
    /// The geometry
    private var vertA: Point3D   // To block new values that have skipped the integrity checks
    private var vertB: Point3D
    private var vertC: Point3D
    
    
    
    /// Ordering of vertices defines the normal direction
    /// - Parameters:
    ///   - ptA:  One vertex
    ///   - ptB:  Another vertex
    ///   - ptC:  Final vertex
    /// - Throws: CoincidentPointsError if any of the vertices are duplicates
    /// - Throws: TriangleError if the vertices are linear
    /// - See: 'testFidelity' and 'testCoincidence' under FacetTests
    init(ptA: Point3D, ptB: Point3D, ptC: Point3D) throws   {
        
        // Be certain that they are distinct points
        guard Point3D.isThreeUnique(alpha: ptA, beta: ptB, gamma: ptC) else { throw CoincidentPointsError(dupePt: ptB) }
        
        // Ensure that the points are not linear
        guard !Point3D.isThreeLinear(alpha: ptA, beta: ptB, gamma: ptC) else { throw TriangleError(dupePt: ptB) }
        
        
        self.vertA = ptA
        self.vertB = ptB
        self.vertC = ptC
        
    }
    
    
    
    /// Simple accessor
    public func getVertA() -> Point3D   {
        return self.vertA
    }
    
    /// Simple accessor
    public func getVertB() -> Point3D   {
        return self.vertB
    }
    
    /// Simple accessor
    public func getVertC() -> Point3D   {
        return self.vertC
    }
    
    
    /// These normal checks don't seem necessary
    /// Reversal not needed for triangles perpendicular to the mirror plane
    public static func mirror(flake: Facet, flat: Plane) -> Facet   {
        
        let sourceNorm = try! Facet.genNormal(tricorner: flake)
        
        let freshA = Plane.mirror(flat: flat, pip: flake.getVertA())
        let freshB = Plane.mirror(flat: flat, pip: flake.getVertB())
        let freshC = Plane.mirror(flat: flat, pip: flake.getVertC())
        
        var sparkle = try! Facet(ptA: freshA, ptB: freshC, ptC: freshB)   // Assumes that order needs to be reversed
        
        let destNorm = try! Facet.genNormal(tricorner: sparkle)
        
        let sense = Vector3D.dotProduct(lhs: sourceNorm, rhs: destNorm)
        
        if sense > 0.0   {
            sparkle.reverse()
        }
        
        return sparkle
    }
    

    /// Calculate the cross product of two edge directions
    /// Assumes that the vertices are unique, and not linear
    /// - Parameters:
    ///   - tricorner:  Triangle of interest
    /// - Returns: Normalized vector pointing outwards
    /// - Throws: TriangleError if the vertices somehow got corrupted
    /// - Throws: IdenticalVectorError if the vertices got corrupted
    public static func genNormal(tricorner: Facet) throws -> Vector3D  {
        
        do   {
            
            let firstDir = Vector3D.built(from: tricorner.vertA, towards: tricorner.vertB)
            let secondDir = Vector3D.built(from: tricorner.vertB, towards: tricorner.vertC)
            
            var upwards =  try Vector3D.crossProduct(lhs: firstDir, rhs: secondDir)
            upwards.normalize()
            
            return upwards
            
        }  catch  {
            throw TriangleError(dupePt: tricorner.vertB)   // The constructor checks should keep this from happening
        }
        
    }
    
    
    /// Change the order of vertices to generate the opposite normal
    public mutating func reverse() -> Void   {
        
        let bubble = self.vertB
        self.vertB = self.vertC
        self.vertC = bubble
        
    }
    
}   // End of declaration for Facet


    
/// Document the topology across a triangle edge.
/// Default initializer suffices
public struct CommonEdge: Hashable   {
    
    public var endA: Point3D   // No significance to the ordering
    public var endB: Point3D
    

    
    
    /// Generate the unique value
    /// Will generate the same value even if the commonA and commonB are reversed
    public func hash(into hasher: inout Hasher)   {
        
        let divXA = Int(round(endA.x / Mesh.Epsilon))
        
        let divYA = Int(round(endA.y / Mesh.Epsilon))
        
        let divZA = Int(round(endA.z / Mesh.Epsilon))
        
        let divXB = Int(round(endB.x / Mesh.Epsilon))
        
        let divYB = Int(round(endB.y / Mesh.Epsilon))
        
        let divZB = Int(round(endB.z / Mesh.Epsilon))
        
        
        var myX = divXA
        var myY = divYA
        var myZ = divZA
        var secondX = divXB
        var secondY = divYB
        var secondZ = divZB
        
        if divXA > divXB   {
            
            myX = divXB
            myY = divYB
            myZ = divZB
            secondX = divXA
            secondY = divYA
            secondZ = divZA
            
        }  else if  divXA == divXB && divYA > divYB   {
            
            myX = divXB
            myY = divYB
            myZ = divZB
            secondX = divXA
            secondY = divYA
            secondZ = divZA
            
        }  else if  divXA == divXB && divYA == divYB && divZA > divZB   {
            
            myX = divXB
            myY = divYB
            myZ = divZB
            secondX = divXA
            secondY = divYA
            secondZ = divZA
            
        }
        
        
        hasher.combine(myX)
        hasher.combine(myY)
        hasher.combine(myZ)
        hasher.combine(secondX)
        hasher.combine(secondY)
        hasher.combine(secondZ)
        
    }
    
    
    /// Check to see that both edges use the same points, independent of ordering
    /// These seem like strange functions to have for something Hashable,
    /// but Hashable is a child of Equatable
    public static func == (lhs: CommonEdge, rhs: CommonEdge) -> Bool   {
        
        var separationA = Point3D.dist(pt1: lhs.endA, pt2: rhs.endA)
        var separationB = Point3D.dist(pt1: lhs.endB, pt2: rhs.endB)
        
        let forward = separationA < Point3D.Epsilon  &&  separationB < Point3D.Epsilon
        
        separationA = Point3D.dist(pt1: lhs.endA, pt2: rhs.endB)
        separationB = Point3D.dist(pt1: lhs.endB, pt2: rhs.endA)
        
        let backward = separationA < Point3D.Epsilon  &&  separationB < Point3D.Epsilon
        
        return forward || backward
    }

}
