//
//  LadderCountError.swift
//  MeshTools
//
//  Created by Paul Hollingshead on 1/1/20.
//  Copyright © 2020 Paul Hollingshead. All rights reserved.
//

import Foundation

/// Exception for when a ladder was specified with an overly large delta between the two sides
public class LadderCountError: Error {
    
    var tnuocL: Int
    var tnuocR: Int

    
    var description: String {
        return "Too big of a difference in point counts specified: " + String(describing: self.tnuocL) + " and " + String(describing: self.tnuocL)
    }
    
    init(tallyL: Int, tallyR: Int)   {
        
        self.tnuocL = tallyL
        self.tnuocR = tallyR

    }
    
}

