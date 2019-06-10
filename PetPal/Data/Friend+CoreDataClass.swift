//
//  Friend+CoreDataClass.swift
//  PetPal
//
//  Created by Afonso H Sabino on 07/06/19.
//  Copyright © 2019 Razeware. All rights reserved.
//
//

import Foundation
import CoreData
import UIKit


public class Friend: NSManagedObject {
    
    //Calc Age
    var age: Int {
        
        if let dob = dob as Date? {
            return Calendar.current.dateComponents([.year], from: dob, to: Date()).year!
        }
        
        return 0
    }
    
    var eyeColorString: String {
        guard let color = eyeColor as? UIColor else {
            return "No Color"
        }
        
        switch color {
        case .black:
            return "Black"
        case .blue:
            return "Blue"
        case .brown:
            return "Brown"
        case .green:
            return "Green"
        case .gray:
            return "Gray"
        default:
            return "Unknown"
        }
    }

}
