//
//  DetailViewController.swift
//  Placestar
//
//  Created by Felix Lösing on 14.05.16.
//  Copyright © 2016 Felix Lösing. All rights reserved.
//


import UIKit
import MapKit

var tableView2: UITableView!

class DetailViewController: UIViewController, UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: DCtableView!
    @IBOutlet weak var mapView: MKMapView!
    var items: [String] = ["1","2","3","4","5","6","7","8","9"]
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        // Do any additional setup after loading the view, typically from a nib.
        self.tableView.backgroundColor = UIColor.clearColor();
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.tableView.contentInset = UIEdgeInsetsMake(self.mapView.frame.size.height-40, 0, 0, 0);
    }
    
    
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if (scrollView.contentOffset.y < self.mapView.frame.size.height * -1 ) {
            scrollView .setContentOffset(CGPointMake(scrollView.contentOffset.x, self.mapView.frame.size.height * -1), animated: true)
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 9
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:UITableViewCell? = self.tableView.dequeueReusableCellWithIdentifier("cell") as UITableViewCell?
        
        cell?.textLabel?.text = self.items[indexPath.row]
        
        return cell!
        
}
}
