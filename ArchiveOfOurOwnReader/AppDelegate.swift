//
//  AppDelegate.swift
//  ArchiveOfOurOwnReader
//
//  Created by Sergei Pekar on 7/9/15.
//  Copyright (c) 2015 Sergei Pekar. All rights reserved.
//

import UIKit
import CoreData
import Fabric
import Crashlytics
import Firebase
import AVFoundation
import Appirater

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var cookies: [HTTPCookie] = [HTTPCookie]()
    var token = ""
    
    static var ao3SiteUrl = "https://archiveofourown.org"
    static var gapString = "…"
    
    static var smallCornerRadius: CGFloat = 10.0
    
    static var redColor = UIColor(red: 81/255, green: 52/255, blue: 99/255, alpha: 1.0)
    static var redLightColor = UIColor(red: 100/255, green: 29/255, blue: 139/255, alpha: 1.0)
    static var redDarkColor = UIColor(red: 49/255, green: 28/255, blue: 59/255, alpha: 1.0)
    static var purpleLightColor = UIColor(red: 146/255, green: 84/255, blue: 180/255, alpha: 1.0)
    static var redTxtColor = UIColor(red: 108/255, green: 93/255, blue: 93/255, alpha: 1.0)
    static var greyColor = UIColor(red: 149/255, green: 155/255, blue: 174/255, alpha: 1.0)
    static var greyBg = UIColor(red: 92/255, green: 73/255, blue: 100/255, alpha: 1.0)
    static var greyLightBg = UIColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1.0)
    static var greyDarkBg = UIColor(red: 54/255, green: 45/255, blue: 62/255, alpha: 1.0)
    static var greenColor = UIColor(red: 110/255, green: 177/255, blue: 157/255, alpha: 1.0)
    static var textLightColor = UIColor(red: 247/255, green: 245/255, blue: 247/255, alpha: 1.0)
    static var greyLightColor = UIColor(red: 198/255, green: 196/255, blue: 198/255, alpha: 1.0)
    static var redTextColor = UIColor(red: 108/255, green: 93/255, blue: 93/255, alpha: 1.0)
    static var redBrightTextColor = UIColor(red: 208/255, green: 93/255, blue: 93/255, alpha: 1.0)
    static var darkerGreyColor = UIColor(red: 170/255, green: 170/255, blue: 170/255, alpha: 1.0)
    static var nightTextColor = UIColor(red: 225/255, green: 225/255, blue: 206/255, alpha: 1.0)
    static var dayTextColor = UIColor(red: 2/255, green: 20/255, blue: 57/255, alpha: 1.0)
    static var nightBgColor = UIColor(red: 39/255, green: 40/255, blue: 43/255, alpha: 1.0)
    static var dayBgColor = UIColor(red: 231/255, green: 234/255, blue: 238/255, alpha: 1.0)
    static var greyTransparentColor = UIColor(red: 115/255, green: 116/255, blue: 118/255, alpha: 0.9)
    static var whiteTransparentColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.9)
    
    static var bigCollCellWidth = 70
    static var smallCollCellWidth = 38
    
    //utf8=%E2%9C%93&authenticity_token=Ew7ritgSHINn3NyzuiPTBYjEBWyddhe%2FYmcAqQJQ8iU%3D&user_session%5Blogin%5D=SSADev&user_session%5Bpassword%5D=IsiT301-1&commit=Log+In

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        Fabric.with([Crashlytics.self])
        
       // TFTTapForTap.initializeWithAPIKey("ecd826723b670f9d750ce1eb02d9558a")
        
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent
        //UINavigationBar.appearance().barStyle = .Black
        
        UITabBarItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName : UIColor.white], for: UIControlState())
        UITabBarItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName : UIColor.white], for: UIControlState.selected)        
        
        //register local notifications
        let notificationSettings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
        UIApplication.shared.registerUserNotificationSettings(notificationSettings)
        
        application.applicationIconBadgeNumber = 0
        
       //  Flurry.startSession("DW87V8SZQC24X83XPSXB")
        FirebaseApp.configure()
        GADMobileAds.configure(withApplicationID: "ca-app-pub-8760316520462117~7329426789");
        
        if (DefaultsManager.getObject(DefaultsManager.PSEUD_IDS) == nil) {
            let s: [String:String] = [:]
            DefaultsManager.putString("", key: DefaultsManager.LOGIN)
            DefaultsManager.putString("", key: DefaultsManager.PSWD)
            DefaultsManager.putString("", key: DefaultsManager.PSEUD_ID)
            DefaultsManager.putObject(s as AnyObject, key: DefaultsManager.PSEUD_IDS)
        }
        
        if let cookiesDate = DefaultsManager.getDate(DefaultsManager.COOKIES_DATE) {
            let calendar = Calendar.current
            if let dateDayAfter = calendar.date(byAdding: .minute, value: 13, to: cookiesDate) { // cookies live 14 days 
            
                if (calendar.startOfDay(for: dateDayAfter) >= calendar.startOfDay(for: Date())) {
                
                    token = DefaultsManager.getString(DefaultsManager.TOKEN)
                    if let ck = DefaultsManager.getObject(DefaultsManager.COOKIES) as? [HTTPCookie] {
                        cookies = ck
                    }
                }
            }
        }
        
       // UIApplication.sharedApplication().cancelAllLocalNotifications()
        
        Appirater.setAppId("1047221122")
        Appirater.setDaysUntilPrompt(1)
        Appirater.setUsesUntilPrompt(3)
        Appirater.setSignificantEventsUntilPrompt(-1)
        Appirater.setTimeBeforeReminding(4)
        Appirater.setDebug(false)
        Appirater.appLaunched(true)
        
        return true
    }
    
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        application.applicationIconBadgeNumber = 0
        //self.navigationController?.popToRootViewControllerAnimated(true)
    }
    
    //MARK: - UIApplicationDelegate

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
        do { try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient) } catch _ {}
        do { try AVAudioSession.sharedInstance().setActive(true) } catch _ {}
        
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: URL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "sergei.pekar.ArchiveOfOurOwnReader" in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1] 
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = Bundle.main.url(forResource: "ArchiveOfOurOwnReader", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let mOptions = [NSMigratePersistentStoresAutomaticallyOption: true,
                        NSInferMappingModelAutomaticallyOption: true]

        
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent("ArchiveOfOurOwnReader.sqlite")
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator!.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: mOptions)
        } catch var error1 as NSError {
            error = error1
            coordinator = nil
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?
            dict[NSUnderlyingErrorKey] = error
            error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(String(describing: error)), \(error!.userInfo)")
            abort()
        } catch {
            fatalError()
        }
        
        return coordinator
    }()

    lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        if let moc = self.managedObjectContext {
            var error: NSError? = nil
            if moc.hasChanges {
                do {
                    try moc.save()
                } catch let error1 as NSError {
                    error = error1
                    // Replace this implementation with code to handle the error appropriately.
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    NSLog("Unresolved error \(String(describing: error)), \(error!.userInfo)")
                    abort()
                }
            }
        }
    }

}

