//
//  FavoriteAuthors.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 11/13/18.
//  Copyright © 2018 Sergei Pekar. All rights reserved.
//

import UIKit
import Crashlytics
import Alamofire
import AlamofireImage
import CoreData

class FavoriteAuthorsController : ListViewController, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var tableView:UITableView!
    @IBOutlet weak var messageLabel:UILabel!
    
    var sortBy = "priority"
    
    var favAuthors: [DBFavAuthor] = []
    
    fileprivate lazy var fetchedResultsController: NSFetchedResultsController<DBFavAuthor>? = {
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return nil
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        
        // Create Fetch Request
        let fetchRequest: NSFetchRequest<DBFavAuthor> = DBFavAuthor.fetchRequest()
        
        // Configure Fetch Request
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: sortBy, ascending: true)]
        
        // Create Fetched Results Controller
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: appDelegate.persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        // Configure Fetched Results Controller
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = Localization("FavoriteAuthors")
        
        self.messageLabel.text = Localization("NoFavoriteAuthors")
        
        self.createDrawerButton()
        
        self.view.backgroundColor = UIColor(named: "onlyDarkBlue")
        self.tableView.backgroundColor = UIColor(named: "tableViewBg")
        self.messageLabel.textColor = UIColor(named: "textColorMedium")
        
        self.sortBy = DefaultsManager.getString(DefaultsManager.SORT_AUTHORS)
        if (self.sortBy.isEmpty) {
            self.sortBy = "priority"
        }
        
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 200
        self.tableView.tableFooterView = UIView()
        
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            print("An error occurred")
        }
        
        self.updateView()
        
        Answers.logCustomEvent(withName: "Favorite Authors", customAttributes: ["count" : fetchedResultsController?.fetchedObjects?.count ?? 0])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    private func updateView() {
        let hasAuthors = fetchedResultsController?.fetchedObjects?.count ?? 0 > 0
        
        self.tableView.isHidden = !hasAuthors
        self.messageLabel.isHidden = hasAuthors
        
        self.title = "Favorite Authors (\(fetchedResultsController?.fetchedObjects?.count ?? 0))"
        
        Answers.logCustomEvent(withName: "Fav Authors",
                               customAttributes: [
                                "count": fetchedResultsController?.fetchedObjects?.count ?? 0])
    }
    
    var selectedRow = 0
    
    @IBAction func worksTouched(_ sender:UIButton) {
        selectedRow = sender.tag
        
        self.performSegue(withIdentifier: "listSegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "listSegue") {
            let item = fetchedResultsController?.object(at: IndexPath(row: selectedRow, section: 0))
            let tagUrl = "https://archiveofourown.org/users/\(item?.name ?? "")/works"
             CLSLogv("FavAuthors: works Tapped = %@", getVaList([tagUrl]))
            Answers.logCustomEvent(withName: "Fav Authors: works",
                                   customAttributes: [
                                    "urlStr": tagUrl])
            if let cController: WorkListController = segue.destination as? WorkListController {
                cController.tagUrl = tagUrl
            }
        } else if (segue.identifier == "authorSegue") {
            let item = fetchedResultsController?.object(at: IndexPath(row: selectedRow, section: 0))
            let tagUrl = "https://archiveofourown.org/users/\(item?.name ?? "")"
            CLSLogv("FavAuthors: author Tapped = %@", getVaList([tagUrl]))
            if let cController: AuthorViewController = segue.destination as? AuthorViewController {
                cController.authorName = item?.name ?? ""
            }
        }
        hideBackTitle()
    }
}

//MARK: Tableview

extension FavoriteAuthorsController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = fetchedResultsController?.sections {
            let currentSection = sections[section]
            return currentSection.numberOfObjects
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: AuthorCell = tableView.dequeueReusableCell(withIdentifier: "AuthorCell") as! AuthorCell
        
        let item = fetchedResultsController?.object(at: indexPath)
        configureCell(cell: cell, author: item, indexPath: indexPath)
        
        return cell
    }
    
    func configureCell(cell: AuthorCell, author: DBFavAuthor?, indexPath: IndexPath) {
        cell.authorNameLabel.text = author?.name ?? ""
        cell.worksButton.tag = indexPath.row
        cell.worksButton.setTitle(Localization("ViewWorks"), for: .normal)
        
        cell.worksButton.addTarget(self, action: #selector( FavoriteAuthorsController.worksTouched), for: UIControl.Event.touchUpInside)
        
        cell.backgroundColor = UIColor(named: "tableViewBg")
        cell.authorNameLabel.textColor = UIColor(named: "textMain")
        cell.worksButton.setTitleColor( UIColor(named: "global_tint"), for: .normal)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        selectedRow = indexPath.row
        self.performSegue(withIdentifier: "authorSegue", sender: self)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Localization("FavoriteAuthors")
    }
    
    //MARK: - NSFetchedResultsControllerDelegate
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, sectionIndexTitleForSectionName sectionName: String) -> String? {
        return sectionName
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.endUpdates()
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections(IndexSet([sectionIndex]), with: .fade)
        case .delete:
            tableView.deleteSections(IndexSet([sectionIndex]), with: .fade)
        default:
            return
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
        case .update:
            if let indexPath = indexPath {
                let item = fetchedResultsController?.object(at: indexPath)
                guard let cell = tableView.cellForRow(at: indexPath) as? AuthorCell else { break }
                configureCell(cell: cell, author: item, indexPath: indexPath)
            }
        case .insert:
            if let indexPath = newIndexPath {
                tableView.insertRows(at: [indexPath], with: .automatic)
            }
        case .move:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .automatic)
                tableView.reloadSections([indexPath.section], with: .none)
            }
            if let newIndexPath = newIndexPath {
                tableView.insertRows(at: [newIndexPath], with: .automatic)
                tableView.reloadSections([newIndexPath.section], with: .none)
            }
        case .delete:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .automatic)
                tableView.reloadSections([indexPath.section], with: .none)
            }
        }
    }

}
