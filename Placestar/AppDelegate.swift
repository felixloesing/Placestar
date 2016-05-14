//
//  AppDelegate.swift
//  Placestar
//
//  Created by Felix Lösing on 09.06.15.
//  Copyright (c) 2015 Felix Lösing. All rights reserved.
//

import UIKit
import CoreData

let MyManagedObjectContextSaveDidFailNotification = "MyManagedObjectContextSaveDidFailNotification"

func fatalCoreDataError(error: ErrorType) {
    print("*** Fatal Error: \(error) ***")
    NSNotificationCenter.defaultCenter().postNotificationName(MyManagedObjectContextSaveDidFailNotification, object: nil)
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        self.window?.tintColor = UIColor(red:0.998, green:0.057, blue:0, alpha:1)
        
        let navigationController = self.window!.rootViewController as! UINavigationController
        let controller = navigationController.topViewController as! ViewController
        controller.managedObjectContext = self.managedObjectContext
        
        
        
        /*
         let Controller = window!.rootViewController! as UIViewController
         
         if let c = Controller {
         c
         }
         
         if let tabBarViewControllers = Controller {
         let currentLocationViewController = tabBarViewControllers[0] as! CurrentLocationViewController
         
         currentLocationViewController.managedObjectContext = managedObjectContext
         
         /*
         let navigationController = tabBarViewControllers[1] as! UINavigationController
         let locationsViewController = navigationController.viewControllers[0] as! LocationsViewController
         locationsViewController.managedObjectContext = managedObjectContext
         
         let mapViewController = tabBarViewControllers[2] as! MapViewController
         mapViewController.managedObjectContext = managedObjectContext
         
         */
         
         }
         
         */
        listenForFatalCoreDataNotification()
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func listenForFatalCoreDataNotification() {
        NSNotificationCenter.defaultCenter().addObserverForName(MyManagedObjectContextSaveDidFailNotification, object: nil, queue: NSOperationQueue.mainQueue(), usingBlock: { notification in
            
            let alert = UIAlertController(title: "Internal Error", message: "There was a fatal error in the app and cannot continue. \n\n" + "Press Okay to termiante the app.", preferredStyle: .Alert)
            
            let action = UIAlertAction(title: "Okay", style: .Default) { _ in
                let execption = NSException(name: NSInternalInconsistencyException, reason: "Fatal Core Data Error", userInfo: nil)
                execption.raise()
            }
            alert.addAction(action)
            
            self.viewControllerForShowingAlert().presentViewController(alert, animated: true, completion: nil)
        })
        }
    
    // search for visible view controller
    func viewControllerForShowingAlert() -> UIViewController {
        let rootViewController = self.window!.rootViewController!
        
        if let presentedViewController = rootViewController.presentedViewController {
            return presentedViewController
        } else {
            return rootViewController
        }
    }
    


    /* old iOS 8 CoreData stuff
    lazy var managedObjectContext: NSManagedObjectContext = {
        if let modelURL = NSBundle.mainBundle().URLForResource("DataModel", withExtension: "momd") {
        
            if let model = NSManagedObjectModel(contentsOfURL: modelURL) {
                let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
                
                let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
                
                let documentDirectory = urls[0] 
                
                let storeURL = documentDirectory.URLByAppendingPathComponent("DataStore.sqlite")
                
                var error: NSError?
                
                if let store = coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: nil, error: &error) {
                
                    let context = NSManagedObjectContext()
                    context.persistentStoreCoordinator = coordinator
                    return context
                } else {
                    print("Error adding persistent store at \(storeURL): \(error!)")
                }
            } else {
                print("Error initializing model from \(modelURL)")
            }
        } else {
            print("Could not find data model in app bundle")
        }
        abort()
    
    }()
    */
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        guard let modelURL = NSBundle.mainBundle().URLForResource("DataModel", withExtension: "momd") else {
            fatalError("Could not find data model in app bundle")
        }
        
        guard let model = NSManagedObjectModel(contentsOfURL: modelURL) else {
            fatalError("Error initializing model from: \(modelURL)")
        }
        
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        let documentsDirectory = urls[0]
        let storeURL = documentsDirectory.URLByAppendingPathComponent("DataStore.sqlite")
        print(storeURL)
        
        do {
            let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: nil)
            
            let context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
            context.persistentStoreCoordinator = coordinator
            return context
        } catch {
            fatalError("Error adding persistent store at \(storeURL): \(error)")
        }
        }()

}

