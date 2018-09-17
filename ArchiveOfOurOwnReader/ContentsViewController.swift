//
//  ContentsViewController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 10/15/15.
//  Copyright © 2015 Sergei Pekar. All rights reserved.
//

import UIKit
import Crashlytics

class ContentsViewController: UIViewController, UIPopoverPresentationControllerDelegate, UITableViewDataSource, UITableViewDelegate {
    
    var downloadedChapters: [DBChapter]! = nil
    var onlineChapters: [Int:ChapterOnline]! = nil
    var modalDelegate: ModalControllerDelegate! = nil
    var theme = DefaultsManager.THEME_DAY

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (theme == DefaultsManager.THEME_DAY) {
            self.tableView.backgroundColor = AppDelegate.greyLightBg
        } else {
            self.tableView.backgroundColor = AppDelegate.greyDarkBg
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (onlineChapters != nil) {
            return onlineChapters.count
        } else if (downloadedChapters != nil) {
            return downloadedChapters.count
        } else {
            Answers.logCustomEvent(withName: "Contents: empty", customAttributes: [:])
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier: String = "contentscCell"
        
        var cell:UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        
        if (cell == nil) {
            cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: cellIdentifier)
        }
        
        var chapterIsRead = false
        
        if (onlineChapters != nil) {
            let chapterNum = onlineChapters[indexPath.row]
            cell?.textLabel?.text = chapterNum?.url
        } else {
            
            let chapter = downloadedChapters[indexPath.row]
            
            chapterIsRead = Bool(truncating: chapter.unread ?? 0)

            let chapterName = chapter.chapterName
            cell?.textLabel?.text = chapterName
        }
        
        cell?.textLabel?.font = UIFont.systemFont(ofSize: 14.0, weight: UIFont.Weight.light)
        
        if (theme == DefaultsManager.THEME_DAY) {
            cell?.textLabel?.textColor = AppDelegate.redColor
            if (chapterIsRead == false) {
                cell?.backgroundColor = AppDelegate.greyLightBg
            } else {
                cell?.backgroundColor = AppDelegate.greyColor
            }
        } else {
            cell?.textLabel?.textColor = AppDelegate.textLightColor
            if (chapterIsRead == false) {
                cell?.backgroundColor = AppDelegate.greyDarkBg
            } else {
                cell?.backgroundColor = AppDelegate.greyColor
            }
        }
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        modalDelegate.controllerDidClosedWithChapter!((indexPath as NSIndexPath).row)
        self.dismiss(animated: true, completion: nil)
    }
    
}
