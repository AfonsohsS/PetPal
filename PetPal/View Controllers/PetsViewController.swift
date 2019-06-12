/**
* Copyright (c) 2018 Razeware LLC
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Notwithstanding the foregoing, you may not use, copy, modify, merge, publish, 
* distribute, sublicense, create a derivative work, and/or sell copies of the 
* Software in any work that is designed, intended, or marketed for pedagogical or 
* instructional purposes related to programming, coding, application development, 
* or information technology.  Permission for such use, copying, modification,
* merger, publication, distribution, sublicensing, creation of derivative works, 
* or sale is expressly withheld.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*/

import UIKit
import CoreData

class PetsViewController: UIViewController, UIGestureRecognizerDelegate {
	@IBOutlet private weak var collectionView:UICollectionView!
	
    //MARK: - Properties
    
//	var petAdded:(()->Void)!
//	var pets = [String]()

	private var isFiltered = false
	private var filtered = [String]()
	private var selected:IndexPath!
	private var picker = UIImagePickerController()
    
    //CoreData Properties
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var friend: Friend!
    var fetchedRC: NSFetchedResultsController<Pet>!
    var query = ""
    
    var formatter = DateFormatter()
    
    
    //MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
		picker.delegate = self
        formatter.dateFormat = "d MMM YYYY"
        pressToDelete()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refresh()

    }

    // MARK:- Private Methods
    
    private func refresh() {
        let request: NSFetchRequest<Pet> = Pet.fetchRequest()
        
        ///You have to always filter the data based on the relationship, inn this case... on the owner, the Friend Entity, stored in the friend variable.
        if query.isEmpty {
            //If no query, use Predicate with the relationship Pet -> Friend
            request.predicate = NSPredicate(format: "owner = %@", friend)
        } else {
            //Combine the two conditions using the "AND" operator so that you get only record for a particular owner and for pets with the query string in their name
            request.predicate = NSPredicate(format: "name CONTAINS[cd] %@ AND owner = %@", query, friend)
        }
        let sort = NSSortDescriptor(key: #keyPath(Pet.name), ascending: true, selector: #selector(NSString.caseInsensitiveCompare(_:)))
        request.sortDescriptors = [sort]
        do {
            fetchedRC = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
            fetchedRC.delegate = self
            try fetchedRC.performFetch()
        } catch let error as NSError {
            print("Error Fetching Pet: \(error), \(error.userInfo)")
        }
    }
    
    //Edit Button
    private func showEditButton() {
        
        //If objs can fetch any results and this result is != NIL, go ahead...
        guard let objs = fetchedRC.fetchedObjects else {return}
        
        if objs.count > 0 {
            navigationItem.leftBarButtonItem = editButtonItem
        }
    }
	
	// MARK:- Actions
	@IBAction func addPet() {
        
        //Instance Class Data Model
        let data = PetData()
        
        //Instance Core Data Entity
        let pet = Pet(entity: Pet.entity(), insertInto: context)
        
        //Relationship between Core Data Attribute with Class Data Model Property
        pet.name = data.name
        pet.kind = data.kind
        pet.dob = data.dob as Date
        
        //Don't forget to put this relationship.
        pet.owner = friend
        
        //Save context
        appDelegate.saveContext()
        
        //You don't need this because now you are using the Feteched Results Controller Delegate. But you don’t forget to set the delegate for your fetched results controller in the refresh() method.
//        refresh()
//        collectionView.reloadData()
        
        
//        var pet = PetData()
//        while pets.contains(pet.name) {
//            pet = PetData()
//        }
//        pets.append(pet.name)
//		let index = IndexPath(row:pets.count - 1, section:0)
//		collectionView.insertItems(at: [index])
//		// Call closure
//		petAdded()
        
        
        
	}
    
    //MARK: - Gesture Recognizer
    
    private func pressToDelete() {
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(deleteCell(sender:)))
        collectionView.addGestureRecognizer(gesture)
        gesture.delegate = self
    }
    
    @objc func deleteCell(sender: UILongPressGestureRecognizer) {
        
        if sender.state != .ended {
            return
        }

        let point = sender.location(in: self.collectionView)
        if let indexPath = self.collectionView.indexPathForItem(at: point) {
            let pet = self.fetchedRC.object(at: indexPath)
            self.context.delete(pet)
            self.appDelegate.saveContext()
            self.refresh()
            
            //You don't need this because now you are using the Feteched Results Controller Delegate. But you don’t forget to set the delegate for your fetched results controller in the refresh() method.
//            self.collectionView.deleteItems(at: [indexPath])
        }
    }
}

//MARK: - Collection View Delegates
extension PetsViewController: UICollectionViewDelegate, UICollectionViewDataSource {
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        let count = fetchedRC.fetchedObjects?.count ?? 0
        
//		let count = isFiltered ? filtered.count : pets.count
		return count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PetCell", for: indexPath) as! PetCell
        
        //Take the object in the IndexPath
        let pet = fetchedRC.object(at: indexPath)
        
        cell.nameLabel.text = pet.name
        cell.animalLabel.text = pet.kind
        
        if let dob = pet.dob as Date? {
            cell.dobLabel.text = formatter.string(from: dob)
        } else {
            cell.dobLabel.text = "Unknown"
        }
        
        if let data = pet.picture as Data? {
            cell.pictureImageView.image = UIImage(data: data)
        } else {
            cell.pictureImageView.image = UIImage(named: "pet-placeholder")
        }
        
//		let pet = isFiltered ? filtered[indexPath.row] : pets[indexPath.row]
//		cell.nameLabel.text = pet
		return cell
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		selected = indexPath
		self.navigationController?.present(picker, animated: true, completion: nil)
	}
}

//MARK: - Search Bar Delegate
extension PetsViewController:UISearchBarDelegate {
	func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
		guard let txt = searchBar.text else {
			return
		}
        
        self.query = txt
        
        self.refresh()
        
//		isFiltered = true
//		filtered = pets.filter({(txt) -> Bool in
//			return txt.contains(query)
//		})
		searchBar.resignFirstResponder()
		collectionView.reloadData()
	}
	
	func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        
        self.query = ""
        
//		isFiltered = false
//		filtered.removeAll()
		searchBar.text = nil
		searchBar.resignFirstResponder()
        self.refresh()
		collectionView.reloadData()
	}
}

//MARK: - Image Picker Delegates
extension PetsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        // Local variable inserted by Swift 4.2 migrator.
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        let image = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as! UIImage
        
        let pet = fetchedRC.object(at: selected)
        
        pet.picture = image.pngData() as Data?
        
        appDelegate.saveContext()
        
        
		collectionView?.reloadItems(at: [selected])
		picker.dismiss(animated: true, completion: nil)
	}
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}

//MARK: - Fetched Results Controller Delegate

extension PetsViewController: NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        let index = indexPath ?? (newIndexPath ?? nil)
        guard let cellIndex = index else {
            return
        }
        
        switch type {
        case .insert:
            collectionView.insertItems(at: [cellIndex])
        case .delete:
            collectionView.deleteItems(at: [cellIndex])
        default:
            break
        }
    }
}
