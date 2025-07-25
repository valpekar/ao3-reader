//
//  ContainerViewController.swift
//  TopTags
//
//  Created by ValeriyaPekar on 2/6/15.
//  Copyright (c) 2015 Simple Soft Alliance. All rights reserved.
//

import UIKit
import QuartzCore
import FirebaseCrashlytics
import CoreData
import Firebase

enum SlideOutState {
    case bothCollapsed
    case leftPanelExpanded
}

let centerPanelExpandedOffset: CGFloat = 60

class ContainerViewController: UserMessagesController, CenterViewControllerDelegate, UIGestureRecognizerDelegate, SidePanelViewControllerDelegate {
    
    var centerNavigationController: UINavigationController!
    var centerViewController: CenterViewController!
    
    var currentState: SlideOutState = .bothCollapsed
    var leftViewController: SidePanelViewController?
    
    var viewControllers = ["FeedViewController", "FavoritesSiteController", "MarkedForLaterController", "SubscriptionsViewController", "ViewFoldersController", "MeViewController", "RecommendationsController", "FavoriteAuthorsController", "SupportController"/*, "PublishWorkController"*/]
    
    var instantiatedControllers: [Int: CenterViewController] = [Int: CenterViewController]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // wrap the centerViewController in a navigation controller, so we can push views to it
        // and display bar button items in the navigation bar
        centerNavigationController =  UIStoryboard.mainStoryboard().instantiateViewController(withIdentifier: "NavigationViewController") as? UINavigationController //
        //UINavigationController(rootViewController: centerViewController)
        view.addSubview(centerNavigationController.view)
        addChild(centerNavigationController)
        
        let controller = UIStoryboard.mainStoryboard().instantiateViewController(withIdentifier: self.viewControllers[0]) as! CenterViewController
        self.instantiatedControllers[0] = controller
        controller.delegate = self
        
        self.centerNavigationController.setViewControllers([controller], animated: true)

        self.instantiatedControllers[0]?.didMove(toParent: self)
        /*
        centerViewController = centerNavigationController.viewControllers[0] as? CenterViewController //UIStoryboard.centerViewController()
        centerViewController.delegate = self
        
        centerNavigationController.didMoveToParentViewController(self)
*/
        
   /*     let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(ContainerViewController.handlePanGesture(_:)))
        centerNavigationController.view.addGestureRecognizer(panGestureRecognizer) */
    }
    
    // MARK: CenterViewController delegate methods
    
    func toggleLeftPanel() {
        let notAlreadyExpanded = (currentState != .leftPanelExpanded)
        
        if notAlreadyExpanded {
            addLeftPanelViewController()
        }
        
        animateLeftPanel(shouldExpand: notAlreadyExpanded)
    }
    
    func collapseSidePanels() {
        switch (currentState) {
        case .leftPanelExpanded:
            toggleLeftPanel()
        default:
            break
        }
    }
    
    func addLeftPanelViewController() {
        if (leftViewController == nil) {
            leftViewController = UIStoryboard.leftViewController()
            
            addChildSidePanelController(leftViewController!)
        }
    }
    
    func addChildSidePanelController(_ sidePanelController: SidePanelViewController) {
        sidePanelController.delegate = self
        
        view.insertSubview(sidePanelController.view, at: 0)
        
        addChild(sidePanelController)
        sidePanelController.didMove(toParent: self)
    }
    
    func animateLeftPanel(shouldExpand: Bool) {
        if (shouldExpand) {
            currentState = .leftPanelExpanded
            
            animateCenterPanelXPosition(targetPosition: centerNavigationController.view.frame.width - centerPanelExpandedOffset)
        } else {
            animateCenterPanelXPosition(targetPosition: 0) { finished in
                self.currentState = .bothCollapsed
                
                if let leftVC = self.leftViewController {
                    leftVC.view.removeFromSuperview()
                    self.leftViewController = nil
                }
            }
        }
    }
    
    func animateCenterPanelXPosition(targetPosition: CGFloat, completion: ((Bool) -> Void)! = nil) {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: UIView.AnimationOptions(), animations: {
            self.centerNavigationController.view.frame.origin.x = targetPosition
            }, completion: completion)
    }
    
    func showShadowForCenterViewController(_ shouldShowShadow: Bool) {
        if (shouldShowShadow) {
            centerNavigationController.view.layer.shadowOpacity = 0.8
        } else {
            centerNavigationController.view.layer.shadowOpacity = 0.0
        }
    }
    
    // MARK: Gesture recognizer
    
    func handlePanGesture(_ recognizer: UIPanGestureRecognizer) {
        // we can determine whether the user is revealing the left or right
        // panel by looking at the velocity of the gesture
        let gestureIsDraggingFromLeftToRight = (recognizer.velocity(in: view).x > 0)
        
        switch(recognizer.state) {
        case .began:
            if (currentState == .bothCollapsed) {
                // If the user starts panning, and neither panel is visible
                // then show the correct panel based on the pan direction
                
                if (gestureIsDraggingFromLeftToRight) {
                    addLeftPanelViewController()
                    
                    showShadowForCenterViewController(true)
                }
            }
        case .changed:
            // If the user is already panning, translate the center view controller's
            // view by the amount that the user has panned
            
            let f = recognizer.view!.center.x + recognizer.translation(in: view).x
            
            if (f > self.view.frame.size.width/2) {
                
                recognizer.view!.center.x = recognizer.view!.center.x + recognizer.translation(in: view).x
                recognizer.setTranslation(CGPoint.zero, in: view)
                
                NSLog("%d", recognizer.view!.center.x);
            }
        case .ended:
            // When the pan ends, check whether the left or right view controller is visible
            if (leftViewController != nil) {
                // animate the side panel open or closed based on whether the view has moved more or less than halfway
                let hasMovedGreaterThanHalfway = recognizer.view!.center.x > view.bounds.size.width
                animateLeftPanel(shouldExpand: hasMovedGreaterThanHalfway)
            }
        default:
            break
        }
    }
    
    func getLastWork() -> DBWorkItem? {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                return nil
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "DBWorkItem")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "dateUpdated", ascending: false)]
        fetchRequest.fetchLimit = 1
        if let selectWorks = (try? managedContext.fetch(fetchRequest)) as? [DBWorkItem] {
            
            if (selectWorks.count > 0) {
                let currentWork = selectWorks[0] as DBWorkItem
                return currentWork
            }
        }
        
        return nil
    }
    
    
    
    // MARK: - SidePanelViewControllerDelegate
    func selectedControllerAtIndex(_ indexPath:IndexPath) {
        self.collapseSidePanels()
        
        if (indexPath.row == 9 && self.instantiatedControllers.count > 0) { //READING NOW
            if let work = getLastWork() {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc: WorkDetailViewController = storyboard.instantiateViewController(withIdentifier: "WorkDetailViewController") as! WorkDetailViewController
                vc.downloadedWorkItem = work
                
                Analytics.logEvent("Reading_Now", parameters: ["workId": work.id ?? 0 as NSObject])
                
                
                 if let controller = self.instantiatedControllers[0] {
                    controller.navigationController?.pushViewController(vc, animated: true)
                }
            } else {
                self.showWarning(title: "Nothing found", message: "Please start reading any downloaded fic to open it from Reading Now!")
            }
        } else {
        
        if let controller = self.instantiatedControllers[indexPath.row] {
                self.centerNavigationController.setViewControllers([controller], animated: true)
            } else {
            var idx = indexPath.row
            //test
            if (idx == 10) {
                idx = 9
            }
                let controller = UIStoryboard.mainStoryboard().instantiateViewController(withIdentifier: self.viewControllers[idx]) as! CenterViewController
                self.instantiatedControllers[idx] = controller
                controller.delegate = self
                controller.applyTheme()
            
            if (self.centerNavigationController != nil) { //can happen on notification tap!!
                self.centerNavigationController.setViewControllers([controller], animated: true)
            }
        }
        }
    }
    
    func selectedActionAtIndex(_ indexPath: IndexPath) {
        self.collapseSidePanels()
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ImportWorkController") as! ImportWorkController
        vc.importDelegate = self
        vc.modalTransitionStyle = .crossDissolve
        self.present(vc, animated: true, completion: nil)

    }
}

private extension UIStoryboard {
    class func mainStoryboard() -> UIStoryboard { return UIStoryboard(name: "Main", bundle: Bundle.main) }
    
    class func leftViewController() -> SidePanelViewController? {
        return mainStoryboard().instantiateViewController(withIdentifier: "LeftViewController") as? SidePanelViewController
    }
    
//    class func centerViewController() -> CenterViewController? {
//        return mainStoryboard().instantiateViewControllerWithIdentifier("ViewController") as? CenterViewController
//    }
}

extension ContainerViewController : WorkImportDelegate {
   
    func linkPasted(workUrl: String) {
        selectedControllerAtIndex(IndexPath(row:0,section:0))
        if let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WorkDetailViewController") as? WorkDetailViewController {
            controller.workUrl = workUrl
            
            if let instcontroller = self.instantiatedControllers[0] {
                Analytics.logEvent("Import_Work_Link_Pasted", parameters: ["url": workUrl as NSObject])
                
                instcontroller.navigationController?.pushViewController(controller, animated: true)
                
            }
        }
    }
    
    
    
}
