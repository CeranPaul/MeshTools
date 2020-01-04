//
//  RingCountError.swift
//  MeshTools
//
//  Created by Paul on 8/16/18.
//  Copyright © 2020 Ceran Digital Media. All rights reserved.  See LICENSE.md
//

import Foundation

/// Exception for when an arc was specified with not many points.
public class RingCountError: Error {
    
    /// Number of points specified
    var tnuoc: Int
    
    /// Message to be displayed
    var description: String {
        return "Too few points specified: " + String(describing: self.tnuoc)
    }
    
    /// Create with number of points in the array
    init(tally: Int)   {
        
        self.tnuoc = tally
        
    }
    
}

