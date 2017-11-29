//
//  ContentsViewController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 10/15/15.
//  Copyright © 2015 Sergei Pekar. All rights reserved.
//

import UIKit

class ContentsViewController: UIViewController, UIPopoverPresentationControllerDelegate, UITableViewDataSource, UITableViewDelegate {
    
    var downloadedChapters: [DBChapter]! = nil
    var onlineChapters: [Int:ChapterOnline]! = nil
    var modalDelegate: ModalControllerDelegate! = nil

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (onlineChapters != nil) {
            return onlineChapters.count
        } else {
            return downloadedChapters.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier: String = "contentscCell"
        
        var cell:UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        
        if (cell == nil) {
            cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: cellIdentifier)
        }
        
        if (onlineChapters != nil) {
            
            let chapterNum = onlineChapters[indexPath.row]
            cell?.textLabel?.text = chapterNum?.url
        } else {
            
            //let chapterNum = downloadedChapters[indexPath.row].chapterIndex.int32Value + 1
            let chapterName = downloadedChapters[indexPath.row].chapterName
            cell?.textLabel?.text = chapterName
        }
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        modalDelegate.controllerDidClosedWithChapter!((indexPath as NSIndexPath).row)
        self.dismiss(animated: true, completion: nil)
    }
    
}
