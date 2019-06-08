//
//  Friend+CoreDataProperties.swift
//  PetPal
//
//  Created by Afonso H Sabino on 07/06/19.
//  Copyright © 2019 Razeware. All rights reserved.
//
//

import Foundation
import CoreData


extension Friend {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Friend> {
        return NSFetchRequest<Friend>(entityName: "Friend")
    }
    
    @NSManaged public var name: String?
}
