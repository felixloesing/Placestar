//
//  CategoryPickerViewController.swift
//  Placestar
//
//  Created by Felix Lösing on 24.06.15.
//  Copyright (c) 2015 Felix Lösing. All rights reserved.
//

import UIKit

class CategoryPickerViewController: UITableViewController {
    var selectedCategoryName = ""
    
    var categories = [NSLocalizedString("no-category", value: "No Category", comment: ""), NSLocalizedString("museum", value: "Museum", comment: ""), NSLocalizedString("store", value: "Store", comment: ""), NSLocalizedString("bar", value: "Bar", comment: ""), NSLocalizedString("park", value: "Park", comment: ""), NSLocalizedString("bookstore", value: "Bookstore", comment: ""), NSLocalizedString("club", value: "Club", comment: ""), NSLocalizedString("grocery-store", value: "Grocery Store", comment: ""),NSLocalizedString("beautiful-view", value: "Beautiful View", comment: ""), NSLocalizedString("historic-building", value: "Historic Building", comment: ""), NSLocalizedString("house", value: "House", comment: ""),NSLocalizedString("company", value: "Company", comment: ""), NSLocalizedString("icecream-vendor", value: "Icecream Vendor", comment: ""), NSLocalizedString("valley", value: "Valley", comment: ""), NSLocalizedString("landmark", value: "Landmark", comment: ""), NSLocalizedString("restaurant", value: "Restaurant", comment: ""), NSLocalizedString("city", value: "City", comment: ""),]
    
    
    
    var customCat = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        categories = categories.sorted()
    }
    
    @IBAction func addCustom(_ sender: AnyObject) {
        print("custom")
        
        let alert = UIAlertController(title: NSLocalizedString("custom-category", value: "Custom Category", comment: ""), message: NSLocalizedString("enter-custom-category", value: "enter custom Category", comment: ""), preferredStyle: .alert)
        
        alert.addTextField(configurationHandler: { (textField) -> Void in
        })
        
        alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: { (action) -> Void in
            let textField = alert.textFields![0] as UITextField
            
            self.selectedCategoryName = textField.text!
            self.customCat = true
            
            self.performSegue(withIdentifier: "PickedCategory", sender: self)
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    //MARK: - TableView Data Source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as UITableViewCell?
        
        let categoryName = categories[(indexPath as NSIndexPath).row]
        cell?.textLabel?.text = categoryName
        
        
        if categoryName == selectedCategoryName {
            cell?.accessoryType = .checkmark
            //selectedIndexPath = indexPath
        } else {
            cell?.accessoryType = .none
        }
 
        return cell!
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PickedCategory" {
            if customCat == false {
            
                let cell = sender as! UITableViewCell
                if let indexPath = tableView.indexPath(for: cell) {
                    selectedCategoryName = categories[(indexPath as NSIndexPath).row]
                }
            } else {
                //selectedCategoryName = selectedCategoryName
            }
        }
    }
    
    //MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        

    }
}
