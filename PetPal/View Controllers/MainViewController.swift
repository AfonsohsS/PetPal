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


class MainViewController: UIViewController {
    
	@IBOutlet private weak var collectionView:UICollectionView!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
	
    //MARK: - Properties
    
    //Commented friends Array to replce it to fetchedRC
//	private var friends = [Friend]()
    private var fetchedRC: NSFetchedResultsController<Friend>!
	private var filtered = [Friend]()
	private var isFiltered = false
	private var friendPets = [String:[String]]()
	private var selected:IndexPath!
	private var picker = UIImagePickerController()
//    private var images = [String:UIImage]()
    private var query = ""

    
    //MARK: - Life Cycle
	override func viewDidLoad() {
		super.viewDidLoad()
		picker.delegate = self
	}
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        refresh()
        
//        do {
//            friends = try context.fetch(Friend.fetchRequest())
//        } catch let error as NSError {
//            print("Error Fetching Friends: \(error), \(error.userInfo)")
//        }
        showEditButton()
    }

	// MARK:- Navigation
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "petSegue" {
			if let index = sender as? IndexPath {
				let pvc = segue.destination as! PetsViewController
                let friend = fetchedRC.object(at: index)
                
                //Replace Array for fetchedRC.object(at:)
//				let friend = friends[index.row]
				if let pets = friendPets[friend.name!] {
					pvc.pets = pets
				}
				pvc.petAdded = {
					self.friendPets[friend.name!] = pvc.pets
				}
			}
		}
	}

	// MARK:- Actions
	@IBAction func addFriend() {
        
        //Instance Class Data Model
        let data = FriendData()
        
        //Instance Core Data Entity
        let friend = Friend(entity: Friend.entity(), insertInto: context)
        
        //Relationship between Core Data Attribute with Class Data Model Property
        friend.name = data.name
        friend.address = data.address
        friend.dob = data.dob as NSDate
        friend.eyeColor = data.eyeColor
        
        //Save context
        appDelegate.saveContext()
        
        //Old code
//        var friend = FriendData()
//        while friends.contains(friend.name) {
//            friend = FriendData()
//        }
        
        //Remove to sort data when add it
//      friends.append(friend)
//        let index = IndexPath(row:friends.count - 1, section:0)
//        collectionView?.insertItems(at: [index])
        
        //With this code we sort the data every time we add a new data
        refresh()
        collectionView.reloadData()
        showEditButton()
	}
	
	// MARK:- Private Methods
    
    //Edit Button
	private func showEditButton() {
        
        //If objs can fetch any results and this result is != NIL, go ahead...
        guard let objs = fetchedRC.fetchedObjects else {return}
        
		if objs.count > 0 {
			navigationItem.leftBarButtonItem = editButtonItem
		}
	}
    
    //Refresh
    private func refresh() {
        
        //Sorting the Data by Friend.name
        let request: NSFetchRequest<Friend> = Friend.fetchRequest()
        
        //If query is not empty... Aplly the filter
        if !query.isEmpty {
            request.predicate = NSPredicate(format: "name CONTAINS[cd] %@", query)
        }
        
        //Commented on this line to add a case-sensitive sort data
//        let sort = NSSortDescriptor(keyPath: \Friend.name, ascending: true)
        
        //With this #selector we call NSString's Method not to consider case-sensitive
        let sortName = NSSortDescriptor(key: #keyPath(Friend.name), ascending: true, selector: #selector(NSString.caseInsensitiveCompare(_:)))
        let sortEyeColor = NSSortDescriptor(key: #keyPath(Friend.eyeColor), ascending: true)
        request.sortDescriptors = [sortEyeColor, sortName]
        
        //Call the request
        do {
            
            fetchedRC = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: #keyPath(Friend.eyeColor), cacheName: nil)
            try fetchedRC.performFetch()
            //Commented this line to add code to create NSFetchedResultsController
//            friends = try context.fetch(request)
        } catch let error as NSError {
            print("Error Fetching Data: \(error), \(error.userInfo)")
        }
    }
}

//MARK: - Collection View Delegates
extension MainViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedRC.sections?.count ?? 0
    }
    
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        guard let sections = fetchedRC.sections, let objs =  sections[section].objects else {
            return 0
        }
        
        //2
//      let count = fetchedRC.fetchedObjects?.count ?? 0
        //1
//		let count = isFiltered ? filtered.count : friends.count
		return objs.count
	}
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "headerRow", for: indexPath)
        if let label = view.viewWithTag(1000) as? UILabel {
            if let friends = fetchedRC.sections?[indexPath.section].objects as? [Friend], let friend = friends.first {
                label.text = "Eye Color: " + friend.eyeColorString
            }
        }
        return view
    }
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FriendCell", for: indexPath) as! FriendCell
        
        let friend = fetchedRC.object(at: indexPath)
        
//		let friend = isFiltered ? filtered[indexPath.row] : friends[indexPath.row]
        
        //Fill in the cell fields
		cell.nameLabel.text = friend.name!
        cell.addressLabel.text = friend.address!
        cell.ageLabel.text = "Age: \(friend.age)"
        cell.eyeColorView.backgroundColor = friend.eyeColor as? UIColor
        
//        if let image = images[friend.name!] {
//            cell.pictureImageView.image = image
//        }
        
        if let data = friend.photo as Data? {
            cell.pictureImageView.image = UIImage(data: data)
        } else {
            cell.pictureImageView.image = UIImage(named: "person-placeholder")
        }
        
		return cell
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		if isEditing {
			selected = indexPath
			self.navigationController?.present(picker, animated: true, completion: nil)
		} else {
			performSegue(withIdentifier: "petSegue", sender: indexPath)
		}
	}
}

//MARK: - Search Bar Delegate
extension MainViewController:UISearchBarDelegate {
	func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
		guard let txt = searchBar.text else {
			return
		}
        self.query = txt
        
        self.refresh()
        
//        let request: NSFetchRequest<Friend> = Friend.fetchRequest()
//        request.predicate = NSPredicate(format: "name CONTAINS[cd] %@", query)
//        do {
//            friends = try context.fetch(request)
//        } catch let error as NSError {
//            print("Error Fetch Friends: \(error), \(error.userInfo)")
//        }
        
        //Commented to use FetchRequest
//		isFiltered = true
//		filtered = friends.filter({(friend) -> Bool in
//            return friend.name!.contains(query)
//            //return txt.contains(query)
//		})
		searchBar.resignFirstResponder()
		collectionView.reloadData()
	}
	
	func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.query = ""
        
        //Replaced for refresh()
//		isFiltered = false
//		filtered.removeAll()
		searchBar.text = nil
		searchBar.resignFirstResponder()
        
        self.refresh()
		collectionView.reloadData()
	}
}

//MARK: - Image Picker Delegates
extension MainViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        // Local variable inserted by Swift 4.2 migrator.
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

		let image = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as! UIImage
        
        let friend = fetchedRC.object(at: selected)
        
        //Replaced it by fetched.object(at:)
//		let friend = isFiltered ? filtered[selected.row] : friends[selected.row]
//        images[friend.name!] = image
        
        friend.photo = image.pngData() as NSData?
        
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
