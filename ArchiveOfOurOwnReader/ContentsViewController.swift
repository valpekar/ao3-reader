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
    var modalDelegate: ModalControllerDelegate! = nil

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return downloadedChapters.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier: String = "contentscCell"
        
        var cell:UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        
        if (cell == nil) {
            cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: cellIdentifier)
        }
        
        let chapterNum = downloadedChapters[(indexPath as NSIndexPath).row].chapterIndex.int32Value + 1
        cell?.textLabel?.text = "Chapter " + String(chapterNum)
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        modalDelegate.controllerDidClosedWithChapter!((indexPath as NSIndexPath).row)
        self.dismiss(animated: true, completion: nil)
    }
    
}
