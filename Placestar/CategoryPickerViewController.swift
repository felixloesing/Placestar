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
    
    var categories = ["No Category","Museum", "Store", "Bar", "Park", "Bookstore", "Club", "Grocery Store","Beautiful View", "Historic Building", "House","Company", "Icecream Vendor", "Valley", "Landmark", "Park", "Restaurant", "City",]
    
    
    //var selectedIndexPath = NSIndexPath()
    
    var customCat = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        categories = categories.sort()
    }
    
    @IBAction func addCustom(sender: AnyObject) {
        print("custom")
        
        let alert = UIAlertController(title: "Custom Category", message: "enter custom category", preferredStyle: .Alert)
        
        alert.addTextFieldWithConfigurationHandler({ (textField) -> Void in
        })
        
        alert.addAction(UIAlertAction(title: "Okay", style: .Default, handler: { (action) -> Void in
            let textField = alert.textFields![0] as UITextField
            
            self.selectedCategoryName = textField.text!
            self.customCat = true
            
            self.performSegueWithIdentifier("PickedCategory", sender: self)
        }))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    //MARK: - TableView Data Source
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell") as UITableViewCell!
        
        let categoryName = categories[indexPath.row]
        cell.textLabel?.text = categoryName
        
        
        if categoryName == selectedCategoryName {
            cell.accessoryType = .Checkmark
            //selectedIndexPath = indexPath
        } else {
            cell.accessoryType = .None
        }
 
        return cell
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "PickedCategory" {
            if customCat == false {
            
                let cell = sender as! UITableViewCell
                if let indexPath = tableView.indexPathForCell(cell) {
                    selectedCategoryName = categories[indexPath.row]
                }
            } else {
                //selectedCategoryName = selectedCategoryName
            }
        }
    }
    
    //MARK: - UITableViewDelegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        /*
        if indexPath.row != selectedIndexPath.row {
            if let newCell = tableView.cellForRowAtIndexPath(indexPath) {
                newCell.accessoryType = .Checkmark
            }
            
            if let oldCell = tableView.cellForRowAtIndexPath(selectedIndexPath) {
                oldCell.accessoryType = .None
            }
            
            selectedIndexPath = indexPath
            
        }
        */
    }
}
