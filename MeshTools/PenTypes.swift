//
//  PenTypes.swift
//  ArcHammer
//
//  Created by Paul Hollingshead on 8/24/19.
//  Copyright © 2019 Paul Hollingshead. All rights reserved.
//

import Foundation

/// Meaning that can be associated with various curves.  Used to set pen characteristics in the drawing routine.
/// - Notes:  Will probably vary for each different app.
/// - Notes:  Needs to be independent from Easel so that various curve entites can be tested.
public enum PenTypes {
    
    case Boundary
    
    case Ordinary
    
    case Interior
        
    case Blanket
       
}

