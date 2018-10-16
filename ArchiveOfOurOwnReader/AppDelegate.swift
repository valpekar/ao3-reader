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
import UserNotifications
import Alamofire

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?
    var cookies: [HTTPCookie] = [HTTPCookie]()
    var token = ""
    
    static var ao3SiteUrl = "https://archiveofourown.org"
    static var gapString = "…"
    
    var countryCode = ""
    
    static var smallCornerRadius: CGFloat = 10.0
    static var mediumCornerRadius: CGFloat = 20.0
    
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
    static var greyTransparentColor = UIColor(red: 115/255, green: 116/255, blue: 118/255, alpha: 0.95)
    static var whiteTransparentColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.95)
    static var whiteHalfTransparentColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.85)

    static var bigCollCellWidth = 70
    static var smallCollCellWidth = 38
    
    //utf8=%E2%9C%93&authenticity_token=Ew7ritgSHINn3NyzuiPTBYjEBWyddhe%2FYmcAqQJQ8iU%3D&user_session%5Blogin%5D=SSADev&user_session%5Bpassword%5D=IsiT301-1&commit=Log+In

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Possible fix of #1162
        // see https://forums.developer.apple.com/thread/90411#285457
        setenv("JSC_useJIT", "false", 0)
        
        // Override point for customization after application launch.
        Fabric.with([Crashlytics.self])
        FirebaseApp.configure()
        
       // TFTTapForTap.initializeWithAPIKey("ecd826723b670f9d750ce1eb02d9558a")
        
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent
        //UINavigationBar.appearance().barStyle = .Black
        
        UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor : UIColor.white], for: UIControl.State())
        UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor : UIColor.white], for: UIControl.State.selected)        
        
        //create the notificationCenter
        let center  = UNUserNotificationCenter.current()
        center.delegate = self
        // set the type as sound or badge
        center.requestAuthorization(options: [.sound,.alert,.badge]) { (granted, error) in
            // Enable or disable features based on authorization
            if granted {
                DispatchQueue.main.async(execute: {
                    UIApplication.shared.registerForRemoteNotifications()
                })
            }
        }
        
        //let worksToReload = DefaultsManager.getStringArray(DefaultsManager.NOTIF_IDS_ARR)
       // application.applicationIconBadgeNumber = worksToReload.count
        
       //  Flurry.startSession("DW87V8SZQC24X83XPSXB")
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
        
        let worksToReload = DefaultsManager.getStringArray(DefaultsManager.NOTIF_IDS_ARR)
        
        for workToReload in worksToReload {
            if let downloadedWorkItem: DBWorkItem = getWorkById(workId: workToReload) {
                downloadedWorkItem.needsUpdate = 1
            }
            
            
        }
        
        // Check if launched from notification
//        if let notification = launchOptions?[.remoteNotification] as? [String: AnyObject] {
//            if let workId = notification["workId"] as? String {
//                openWorkDetailController(workId: workId)
//            }
//         //   if (notification.count == 0) {
////            if let currentViewController: ContainerViewController = self.window?.rootViewController as? ContainerViewController {
////                currentViewController.selectedControllerAtIndex(IndexPath(row: 4, section: 0))
////            }
//         //   }
//        }
        
//        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) {
//            self.openWorkDetailController(workId: "1")
//        }
        
        return true
    }
    
    func createLocalNotification(workId: String) {
        //creating the notification content
        let content = UNMutableNotificationContent()
        
        //adding title, subtitle, body and badge
        content.title = "Work Update"
        content.subtitle = "Yay :)"
        content.body = "Open the app to update the work."
        content.userInfo = ["workId":workId]
        content.badge = 1
        
        //getting the notification trigger
        //it will be called after 5 seconds
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        
        //getting the notification request
        let request = UNNotificationRequest(identifier: "WorkUpdate", content: content, trigger: trigger)
        
        //adding the notification to notification center
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    func getWorkById(workId: String) -> DBWorkItem? {
        var res: DBWorkItem?
        
        let managedContext = persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest <NSFetchRequestResult> = NSFetchRequest(entityName:"DBWorkItem")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "dateAdded", ascending: false)]
        fetchRequest.fetchLimit = 1
        let searchPredicate: NSPredicate = NSPredicate(format: "workId = %@", workId)
        
        fetchRequest.predicate = searchPredicate
        
        do {
            let fetchedResults = try managedContext.fetch(fetchRequest) as? [DBWorkItem]
            
            if let results = fetchedResults {
                res = results.first
            }
        } catch {
            #if DEBUG
            print("cannot fetch favorites.")
            #endif
        }
        return res
    }
    
    func openWorkDetailController(workId: String) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc: WorkDetailViewController = storyboard.instantiateViewController(withIdentifier: "WorkDetailViewController") as! WorkDetailViewController
        //let item: WorkItem = WorkItem()
        vc.workUrl = "https://archiveofourown.org/works/\(workId)" //DefaultsManager.getString(DefaultsManager.LASTWRKID)
        vc.fromNotif = true
        //vc.workItem = item
        
        if let currentViewController: ContainerViewController = self.window?.rootViewController as? ContainerViewController, currentViewController.instantiatedControllers.count > 0 {
            currentViewController.instantiatedControllers[0]?.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        print("AppDelegate: willPresent notification")
        
        var worksToReload = DefaultsManager.getStringArray(DefaultsManager.NOTIF_IDS_ARR)
        
        let notification = notification.request.content.userInfo
        if let workId = notification["workId"] as? String {
            if worksToReload.contains(workId) == false {
                worksToReload.append(workId)
                print("willPresent workId \(workId)")
            }
        }
        
        DefaultsManager.putStringArray(worksToReload, key: DefaultsManager.NOTIF_IDS_ARR)
        
        UIApplication.shared.applicationIconBadgeNumber = worksToReload.count
        
        completionHandler([.alert, .sound, .badge])
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("AppDelegate: didReceiveRemoteNotification ")
        
        var wId = ""
        
        if let workId = userInfo["workId"] as? String {
            wId = workId
            print("didReceiveRemoteNotification workId \(workId)")
        }
        
        var worksToReload = DefaultsManager.getStringArray(DefaultsManager.NOTIF_IDS_ARR)
        if worksToReload.contains(wId) == false {
            worksToReload.append(wId)
        }
        DefaultsManager.putStringArray(worksToReload, key: DefaultsManager.NOTIF_IDS_ARR)
        UIApplication.shared.applicationIconBadgeNumber = worksToReload.count
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("AppDelegate: didReceive UNNotificationResponse")
        
        var wId = ""
        
        let notification = response.notification.request.content.userInfo
        if let workId = notification["workId"] as? String {
            wId = workId
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) {
                self.openWorkDetailController(workId: workId)
            }
        }
            //   if (notification.count == 0) {
            //            if let currentViewController: ContainerViewController = self.window?.rootViewController as? ContainerViewController {
            //                currentViewController.selectedControllerAtIndex(IndexPath(row: 4, section: 0))
            //            }
            //   }
        else {
        
            if let currentViewController: ContainerViewController = self.window?.rootViewController as? ContainerViewController {
                currentViewController.selectedControllerAtIndex(IndexPath(row: 7, section: 0))
            }
        }
        
        var worksToReload = DefaultsManager.getStringArray(DefaultsManager.NOTIF_IDS_ARR)
        if worksToReload.contains(wId) == false {
            worksToReload.append(wId)
        }
        DefaultsManager.putStringArray(worksToReload, key: DefaultsManager.NOTIF_IDS_ARR)
        UIApplication.shared.applicationIconBadgeNumber = worksToReload.count
                
        completionHandler()
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data -> String in
            return String(format: "%02.2hhx", data)
        }
        
        let token = tokenParts.joined()
        print("Device Token: \(token)")
        
        DefaultsManager.putString(token, key: DefaultsManager.NOTIF_DEVICE_TOKEN)
        
        let reqToken = DefaultsManager.getString(DefaultsManager.REQ_DEVICE_TOKEN)
        if (reqToken.isEmpty == true) {
            self.sendRequestRegisterForPushes()
        } else {
            self.sendRequestUpdateForPushes()
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register: \(error)")
    }
    
    //MARK: - send register for pushes on our server
    
    func sendRequestRegisterForPushes() {
        let deviceToken = DefaultsManager.getString(DefaultsManager.NOTIF_DEVICE_TOKEN)
        let localTimeZoneName = TimeZone.current.identifier
        
        var params:[String:Any] = [String:Any]()
        params["os"] = "i"
        params["token"] = deviceToken
        params["timezone"] = localTimeZoneName // "America/Atka"//localTimeZoneName
        
        params["app_version"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        params["app_build"] = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
        
        let url = "https://fanfic-pocket-reader.herokuapp.com/api/devices" //"http://192.168.100.49/api/devices"
        
        if (deviceToken.isEmpty == false) {
            Alamofire.request(url, method: HTTPMethod.post, parameters: params).response(completionHandler: { (response) in
                print(response.error ?? "")
                
                if let data = response.data {
                    self.parseReqNotifWorkResponse(data)
                }
            })
        }
    }
    
    func sendRequestUpdateForPushes() {
        let deviceToken = DefaultsManager.getString(DefaultsManager.NOTIF_DEVICE_TOKEN)
        let reqDeviceToken = DefaultsManager.getString(DefaultsManager.REQ_DEVICE_TOKEN)
        let localTimeZoneName = TimeZone.current.identifier
        
        var params:[String:Any] = [String:Any]()
        params["token"] = deviceToken
        params["timezone"] = localTimeZoneName
        
        params["app_version"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        params["app_build"] = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
        
        var headers:[String:String] = [String:String]()
        headers["auth"] = reqDeviceToken
        headers["Content-Type"] = "application/x-www-form-urlencoded"
        
        if (deviceToken.isEmpty == false) {
            let url = "https://fanfic-pocket-reader.herokuapp.com/api/devices" //"http://192.168.100.49/api/devices" 
            Alamofire.request(url, method: HTTPMethod.put, parameters: params, headers: headers).response(completionHandler: { (response) in
                print(response.error ?? "")
                
                if let data = response.data, let responseString = String(data: data, encoding: .utf8) {
                    print(responseString)
                    
                    if (responseString.contains("No device with such token")) {
                        self.sendRequestRegisterForPushes()
                    }
                }
                
                if (response.response?.statusCode == 200) {
                    print("device token ok")
                }
            })
        }
    }
    
    func parseReqNotifWorkResponse(_ data: Data) {
        let jsonWithObjectRoot = try? JSONSerialization.jsonObject(with: data, options: [])
        if let dictionary = jsonWithObjectRoot as? [String: Any] {
            if let result = dictionary["token"] as? String {
                if (result.isEmpty == false) {
                    DefaultsManager.putString(result, key: DefaultsManager.REQ_DEVICE_TOKEN)
                }
            }
        }
    }
    
    //MARK: - UIApplicationDelegate

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
      //  self.saveContext()
    }
    
    
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        let systemVersion = UIDevice.current.systemVersion
        if (systemVersion.contains("10.0") == true || systemVersion.contains("10.1") == true) {
            print("version 10.0.x contains bugs with audio")
            let shown: Bool = DefaultsManager.getBool(DefaultsManager.SHOW_ERR_AVFAUDIO) ?? false
            if (shown == false) {
                showError(message: "Your operating system is not up-to-date and is known to have bugs with Audio. You will have problems with listening music while using other apps like mine. Please consider updating.")
                DefaultsManager.putBool(true, key: DefaultsManager.SHOW_ERR_AVFAUDIO)
            }
        } else  {
            do { try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category(rawValue: convertFromAVAudioSessionCategory(AVAudioSession.Category.ambient)), mode: AVAudioSession.Mode.default) } catch let error as NSError {debugLog(error.description)}
            do { try AVAudioSession.sharedInstance().setActive(true) } catch let error as NSError {debugLog(error.description)}
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
      //  self.saveContext()
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
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        var container = NSPersistentContainer(name: "ArchiveOfOurOwnReader")
        
        let newUrl = self.applicationDocumentsDirectory.appendingPathComponent("ArchiveOfOurOwnReader.sqlite")
        
        let description = NSPersistentStoreDescription()
//
//        description.shouldInferMappingModelAutomatically = true
//        description.shouldMigrateStoreAutomatically = true
        description.url = newUrl
        
        container.persistentStoreDescriptions.append(description)
        
     //   print("default url =\(NSPersistentContainer.defaultDirectoryURL())")
        
        /*let migrated = DefaultsManager.getBool("migrated") ?? false
        
        if (migrated == false) {
        //self.applicationDocumentsDirectory.appendingPathComponent("ArchiveOfOurOwnReader.sqlite")
        if let oldStore = self.persistentStoreCoordinator1?.persistentStores.first {
            do {
                try self.persistentStoreCoordinator1?.migratePersistentStore(oldStore, to:  newUrl, options: [NSPersistentStoreRemoveUbiquitousMetadataOption:true, NSMigratePersistentStoresAutomaticallyOption: true,
                NSInferMappingModelAutomaticallyOption: true], withType: NSSQLiteStoreType)
            } catch {
                print("Could not replace store: \(error)")
            }
            
            let oldUrl = self.persistentStoreCoordinator1?.url(for: oldStore)
            //print("old persistent store url \(oldUrl)")
            
                        do {
                            try persistentStoreCoordinator1?.remove(oldStore)
                        } catch {
                            print("Could not remove store: \(error)")
                        }
            
                        if let old_url = oldUrl {
                        do {
                            try FileManager.default.removeItem(at: old_url)
                        } catch {
                            print("Could not remove at url: \(error)")
                        }
                        }
            
            DefaultsManager.putBool(true, key: "migrated")
        }
        }*/
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                debugLog(message: "Unresolved error \(error), \(error.userInfo)")
                
                if (error.code == 134110 || error.code == 259 ) {
                    debugLog(message: "error to load old db, try to create new: \(error.userInfo)")
                    container = self.createNewContainer()
                    self.showError(message: "Error while trying to load database. More Info: \(error.userInfo)")
                } else {
                    fatalError("Unresolved error \(error), \(error.userInfo)")
                }
            } else {
             //   container.viewContext.automaticallyMergesChangesFromParent = true
             //   container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
            }
        })
        return container
    }()
    
    func showError(message: String) {
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) {
            UIAlertAction in
            NSLog("OK Pressed")
        }
        alertController.addAction(okAction)
        self.window?.rootViewController?.present(alertController, animated: true, completion: nil)
    }
    
    func createNewContainer() -> NSPersistentContainer {
        
        let fileManager = FileManager.default
        if let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).last {
            
            let storeURL = documentsDirectory.appendingPathComponent("ArchiveOfOurOwnReader.sqlite")
        
            if (fileManager.fileExists(atPath: storeURL.path)) {
                debugLog("Core data store (old) exists. Deleting store.")
                do {
                    try fileManager.removeItem(at: storeURL)
                } catch {
                    debugLog("Failed to delete incompatible store, carrying on anyway.")
                }
            }
        }
        let container = NSPersistentContainer(name: "ArchiveOfOurOwnReader")
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                debugLog(message: "Unresolved error \(error), \(error.userInfo)")
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }

//    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
//        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
//        // Create the coordinator and store
//        let mOptions = [NSMigratePersistentStoresAutomaticallyOption: true,
//                        NSInferMappingModelAutomaticallyOption: true
//                        /*NSPersistentStoreUbiquitousContentNameKey: "ArchiveOfOurOwnReaderContainer"*/] as [String : Any]
//
//
//        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
//        let url = self.applicationDocumentsDirectory.appendingPathComponent("ArchiveOfOurOwnReader.sqlite")
//        var error: NSError? = nil
//        var failureReason = "There was an error creating or loading the application's saved data."
//
//        do {
//            try coordinator!.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: mOptions)
//        } catch var error1 as NSError {
//            error = error1
//            coordinator = nil
//            // Report any error we got.
//            var dict = [String: AnyObject]()
//            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
//            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?
//            dict[NSUnderlyingErrorKey] = error
//            error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
//            // Replace this with code to handle the error appropriately.
//            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//            NSLog("Unresolved error \(String(describing: error)), \(error!.userInfo)")
//            abort()
//        } catch {
//            fatalError()
//        }
//
//        return coordinator
//    }()
    
/*    lazy var persistentStoreCoordinator1: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        
        let mOptions = [NSMigratePersistentStoresAutomaticallyOption: true,
                        NSInferMappingModelAutomaticallyOption: true,
                        NSPersistentStoreUbiquitousContentNameKey: "ArchiveOfOurOwnReaderContainer" ] as [String : Any]
        
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
    }()*/

//    lazy var managedObjectContext: NSManagedObjectContext? = {
//        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
//        let coordinator = self.persistentStoreCoordinator
//        if coordinator == nil {
//            return nil
//        }
//        var managedObjectContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType)
//        managedObjectContext.persistentStoreCoordinator = coordinator
//        return managedObjectContext
//    }()
    
    /*lazy var managedObjectContextOld: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator1
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()*/

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                debugLog(message: "Unresolved error \(nserror), \(nserror.userInfo)")
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVAudioSessionCategory(_ input: AVAudioSession.Category) -> String {
	return input.rawValue
}
