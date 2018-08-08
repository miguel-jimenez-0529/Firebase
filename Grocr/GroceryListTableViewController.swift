/*
 * Copyright (c) 2015 Razeware LLC
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
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit
import Firebase

class GroceryListTableViewController: UITableViewController {
  
  // MARK: Constants
  let listToUsers = "ListToUsers"
  
  // MARK: Properties
  var items: [GroceryItem] = []
  var user: User!
  var userCountBarButtonItem: UIBarButtonItem!
  var groceryItemReference = Database.database().reference(withPath: "grocery-items")
  var usersReference = Database.database().reference(withPath: "online")
  
  
  // MARK: UIViewController Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    tableView.allowsMultipleSelectionDuringEditing = false
    
    userCountBarButtonItem = UIBarButtonItem(title: "1",
                                             style: .plain,
                                             target: self,
                                             action: #selector(userCountButtonDidTouch))
    userCountBarButtonItem.tintColor = UIColor.white
    navigationItem.leftBarButtonItem = userCountBarButtonItem
    
    groceryItemReference.queryOrdered(byChild: "completed").observe(.value) { (snapShot) in
      var newItems = [GroceryItem]()
      for child in snapShot.children {
        let newGrocery = GroceryItem(snapshot: child as! DataSnapshot)
        newItems.append(newGrocery)
      }
      self.items = newItems
      self.tableView.reloadData()
    }
    
    usersReference.observe(.value) { (snapshot) in
      if snapshot.exists() {
        self.userCountBarButtonItem.title = "\(snapshot.childrenCount)"
      } else {
        self.userCountBarButtonItem.title = "0"
      }
    }
    
    Auth.auth().addStateDidChangeListener { (auth, user) in
      if let user = user {
        self.user = User.init(uid: user.uid, email: user.email!)
        let currentUserRef = self.usersReference.child(self.user.uid)
        currentUserRef.setValue(["email" : self.user.email])
        currentUserRef.onDisconnectRemoveValue()
      }
    }
  }
  
  // MARK: UITableView Delegate methods
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return items.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath)
    let groceryItem = items[indexPath.row]
    
    cell.textLabel?.text = groceryItem.name
    cell.detailTextLabel?.text = groceryItem.addedByUser
    
    toggleCellCheckbox(cell, isCompleted: groceryItem.completed)
    
    return cell
  }
  
  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }
  
  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      let groceryItem = items[indexPath.row]
//      groceryItem.ref?.removeValue()
      groceryItem.ref?.setValue(nil)
      items.remove(at: indexPath.row)
      tableView.reloadData()
    }
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let cell = tableView.cellForRow(at: indexPath) else { return }
    var groceryItem = items[indexPath.row]
    let toggledCompletion = !groceryItem.completed
    toggleCellCheckbox(cell, isCompleted: toggledCompletion)
    groceryItem.completed = toggledCompletion
    groceryItem.ref?.updateChildValues(["completed" : toggledCompletion])
//    let values : [String : Any] = ["name" : "Beacon"]
//    groceryItem.ref?.updateChildValues(values)
    tableView.reloadData()
  }
  
  func toggleCellCheckbox(_ cell: UITableViewCell, isCompleted: Bool) {
    if !isCompleted {
      cell.accessoryType = .none
      cell.textLabel?.textColor = UIColor.black
      cell.detailTextLabel?.textColor = UIColor.black
    } else {
      cell.accessoryType = .checkmark
      cell.textLabel?.textColor = UIColor.gray
      cell.detailTextLabel?.textColor = UIColor.gray
    }
  }
  
  // MARK: Add Item
  
  @IBAction func addButtonDidTouch(_ sender: AnyObject) {
    let alert = UIAlertController(title: "Grocery Item",
                                  message: "Add an Item",
                                  preferredStyle: .alert)
    
    let saveAction = UIAlertAction(title: "Save",
                                   style: .default) { action in
                                    let textField = alert.textFields![0]
                                    let groceryItem = GroceryItem(name: textField.text!,
                                                                  addedByUser: self.user.email,
                                                                  completed: false)
                                    
                                    self.items.append(groceryItem)
                                    self.tableView.reloadData()
                                    let groceryItemRef = self.groceryItemReference.child(textField.text!.lowercased())
                                    let values : [String : Any] = ["name" : groceryItem.name,            "addedByUser" :groceryItem.addedByUser,
                                                  "completed" : groceryItem.completed]
                                    groceryItemRef.setValue(values)
                                    
                                    
                                    
    }
    
    let cancelAction = UIAlertAction(title: "Cancel",
                                     style: .default)
    
    alert.addTextField()
    
    alert.addAction(saveAction)
    alert.addAction(cancelAction)
    
    present(alert, animated: true, completion: nil)
  }
  
  @objc func userCountButtonDidTouch() {
    performSegue(withIdentifier: listToUsers, sender: nil)
  }
  
}

