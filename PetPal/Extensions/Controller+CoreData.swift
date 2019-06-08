//
//  Controller+CoreData.swift
//  PetPal
//
//  Created by Afonso H Sabino on 07/06/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import Foundation
import UIKit
import CoreData

extension UIViewController {
    
    //Call the Context in all Controllers
    
    var context: NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }
    
}
