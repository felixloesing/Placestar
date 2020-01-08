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

func fatalCoreDataError(_ error: Error) {
    print("Fatal Error: \(error) ***")
    NotificationCenter.default.post(name: Notification.Name(rawValue: MyManagedObjectContextSaveDidFailNotification), object: nil)
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        self.window?.tintColor = UIColor.systemPink
        
        let navigationController = self.window!.rootViewController as! UINavigationController
        let controller = navigationController.topViewController as! ViewController
        controller.managedObjectContext = self.managedObjectContext
        
        listenForFatalCoreDataNotification()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func listenForFatalCoreDataNotification() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: MyManagedObjectContextSaveDidFailNotification), object: nil, queue: OperationQueue.main, using: { notification in
            
            let alert = UIAlertController(title: "Internal Error", message: "There was a fatal error in the app and it cannot continue. \n\n" + "Press Okay to termiante the app.", preferredStyle: .alert)
            
            let action = UIAlertAction(title: "Okay", style: .default) { _ in
                let execption = NSException(name: NSExceptionName.internalInconsistencyException, reason: "Fatal Core Data Error", userInfo: nil)
                execption.raise()
            }
            alert.addAction(action)
            
            self.viewControllerForShowingAlert().present(alert, animated: true, completion: nil)
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
    
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        guard let modelURL = Bundle.main.url(forResource: "DataModel", withExtension: "momd") else {
            fatalError("Could not find data model in app bundle")
        }
        
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Error initializing model from: \(modelURL)")
        }
        
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = urls[0]
        let storeURL = documentsDirectory.appendingPathComponent("DataStore.sqlite")
        print(storeURL)
        
        do {
            let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)
            
            let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
            context.persistentStoreCoordinator = coordinator
            return context
        } catch {
            fatalError("Error adding persistent store at \(storeURL): \(error)")
        }
        }()
}
