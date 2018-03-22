//
//  HighlightsController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 3/22/18.
//  Copyright © 2018 Sergei Pekar. All rights reserved.
//

import UIKit
import CoreData

class HighlightsController: UIViewController {
    
    @IBOutlet weak var tableView:UITableView!
    
    var theme = DefaultsManager.THEME_DAY
    
    var highlights: [DBHighlightItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Highlights"
        
        if let th = DefaultsManager.getInt(DefaultsManager.THEME_APP) {
            theme = th
        } else {
            theme = DefaultsManager.THEME_DAY
        }
        
        if (theme == DefaultsManager.THEME_NIGHT) {
            self.view.backgroundColor = AppDelegate.redDarkColor
        } else {
            self.view.backgroundColor = UIColor.white
        }
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 200
        self.tableView.tableFooterView = UIView()
        
        self.highlights = self.getAllHighlights()
        self.tableView.reloadData()
    }
    
    func getAllHighlights() -> [DBHighlightItem] {
        var res: [DBHighlightItem] = []
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let managedContext = appDelegate.managedObjectContext else {
                return res
        }
        
        let fetchRequest: NSFetchRequest <NSFetchRequestResult> = NSFetchRequest(entityName:"DBHighlightItem")
        
        do {
            if let fetchedResults = try managedContext.fetch(fetchRequest) as? [DBHighlightItem]  {
                res = fetchedResults
            }
        } catch {
            #if DEBUG
                print("cannot fetch favorites.")
            #endif
        }
        
        return res
    }
}

//MARK: Tableview

extension HighlightsController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return highlights.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: HighlightCell = tableView.dequeueReusableCell(withIdentifier: "HighlightCell") as! HighlightCell
        
        let highlightItem = highlights[indexPath.row]

        cell.contentLabel.text = highlightItem.content
        cell.authorLabel.text = "- \(highlightItem.author ?? ""), \"\(highlightItem.workName ?? "")\""
        
        if (theme == DefaultsManager.THEME_DAY) {
            cell.backgroundColor = AppDelegate.greyLightBg
            cell.contentLabel.textColor = AppDelegate.redTextColor
        } else {
            cell.backgroundColor = AppDelegate.greyDarkBg
            cell.contentLabel.textColor = AppDelegate.textLightColor
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
