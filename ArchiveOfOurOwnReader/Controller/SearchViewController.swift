//
//  SearchViewController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Sergei Pekar on 7/9/15.
//  Copyright (c) 2015 Sergei Pekar. All rights reserved.
//

import UIKit
import Alamofire
import PopupDialog

class SearchViewController: UIViewController, UIBarPositioningDelegate, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UITextViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    var delegate:SearchControllerDelegate?
    var modalDelegate:ModalControllerDelegate?
    
    var theme: Int = DefaultsManager.THEME_DAY
    
    @IBOutlet weak var langPickerView: UIPickerView!
    @IBOutlet weak var sortbyPickerView: UIPickerView!
    @IBOutlet weak var sortdirectionPickerView: UIPickerView!
    
    @IBOutlet var ratingPickerView: UIPickerView!
    
    @IBOutlet weak var tableView: UITableView!
    
    var selectedLang:String = ""
    var selectedRaiting:String = ""
    var selectedSortBy:String = ""
    var selectedSortDirection:String = ""
    
    var langDict:NSDictionary! = nil
    var ratingDict:NSDictionary! = nil
    var sortByDict:NSDictionary! = nil
    var sortDirectionDict:NSDictionary! = nil
    
    var searchQuery:SearchQuery! = nil
   // var fandoms:[Fandom] = [Fandom]()
    var searchTags:[String] = [String]()
    var excludeTags:[String] = [String]()
    var labelTitlesWithText:[String] = [
        Localization("AnyField"),
        Localization("Title"),
        Localization("Author"),
        Localization("Language"),
        Localization("Rating")]
    var sortlabelTitlesWithText:[String] = [Localization("SortBy"),
                                            Localization("SortDirection")]
    var worktagsTitlesWithText:[String] = [Localization("Fandoms"),
                                           Localization("Relationships"),
                                           Localization("Characters")]
    var labelTitlesFromTo:[String] = [Localization("Kudos"),
                                      Localization("Hits"),
                                      Localization("Comments"),
                                      Localization("Bookmarks"),
                                      Localization("WordCount")]
    var labelTitlesSwitch:[String] = [Localization("ChooseNoWarn"),
                                      Localization("GraphicViolence"),
                                      Localization("MajorCharDeath"),
                                      Localization("NoWarn")]
                                      //Localization("RapeNonCon"),
                                      //Localization("Underage")]
    var imgTitlesFromTo:[String] = ["likes", "hits", "comments", "bookmark", "word"]
    
    var currentTextField: UITextField?
    
    let TAG_NONE = -1
    let TAG_ANYFIELD = 1
    let TAG_TITLE = 2
    let TAG_AUTHOR = 3
    let TAG_KUDOS_FROM = 4
    let TAG_KUDOS_TO = 5
    let TAG_HITS_FROM = 6
    let TAG_HITS_TO = 7
    let TAG_COMMENTS_FROM = 8
    let TAG_COMMENTS_TO = 9
    let TAG_BOOKMARKS_FROM = 10
    let TAG_BOOKMARKS_TO = 11
    let TAG_WORDCOUNT_FROM = 12
    let TAG_WORDCOUNT_TO = 13
    let TAG_FANDOMS = 21
    let TAG_RELATIONSHIPS = 22
    let TAG_CHARACTERS = 23
    let TAG_SINGLE_CHAPTER = 24
    let TAG_COMPLETE = 25
    let TAG_EXCLUDE_TAGS = 26
    let TAG_INCLUDE_TAGS = 27
    let TAG_RATINGS = 28
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.isHidden = false
        
        var path = Bundle.main.path(forResource: "lang_map", ofType: "plist")
        langDict = NSDictionary(contentsOfFile: path!)
        
        path = Bundle.main.path(forResource: "sortby_map", ofType: "plist")
        sortByDict = NSDictionary(contentsOfFile: path!)
        
        path = Bundle.main.path(forResource: "sortdirection_map", ofType: "plist")
        sortDirectionDict = NSDictionary(contentsOfFile: path!)
        
        path = Bundle.main.path(forResource: "rating_map", ofType: "plist")
        ratingDict = NSDictionary(contentsOfFile: path!)
        
        loadDefaults()
        
        if let th = DefaultsManager.getInt(DefaultsManager.THEME_APP) {
            theme = th
        } else {
            theme = DefaultsManager.THEME_DAY
        }
        
        if (theme == DefaultsManager.THEME_DAY) {
            self.tableView.backgroundColor = UIColor.white
        } else {
            self.tableView.backgroundColor = AppDelegate.greyDarkBg
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.title = ""
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        DefaultsManager.putObject(searchQuery, key: DefaultsManager.SEARCH_Q)
    }

    
    // MARK: - Actions
    @IBAction func cloaseButtonTap(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: { () -> Void in
            
            self.modalDelegate?.controllerDidClosed()
            NSLog("Search completed")
        })
    }
    
    // MARK: - UIBarPositioningDelegate
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return UIBarPosition.top
    }
    
    //MARK: - TableView
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell : UITableViewCell?
     
        switch (indexPath.section) {
        case 0:
            cell = (tableView.dequeueReusableCell(withIdentifier: "searchTagCell") as? SearchTagCell)!
            cell?.accessoryType = .none
            
           (cell as? SearchTagCell)?.textView.text = searchQuery.include_tags
            (cell as? SearchTagCell)?.textView.tag = TAG_INCLUDE_TAGS
            
            if (theme == DefaultsManager.THEME_DAY) {
                (cell as? SearchTagCell)?.textView.textColor = UIColor.black
                (cell as? SearchTagCell)?.textView.backgroundColor = UIColor.white
                
            } else {
                (cell as? SearchTagCell)?.textView.textColor = AppDelegate.textLightColor
                (cell as? SearchTagCell)?.textView.backgroundColor = AppDelegate.greyBg
            }
            
        case 1:
            cell = (tableView.dequeueReusableCell(withIdentifier: "searchTagCell") as? SearchTagCell)!
            cell?.accessoryType = .none
            
            //if (excludeTags.count > indexPath.row) {
                (cell as? SearchTagCell)?.textView.text = searchQuery.exclude_tags
           // }
            (cell as? SearchTagCell)?.textView.tag = TAG_EXCLUDE_TAGS
            
            if (theme == DefaultsManager.THEME_DAY) {
                (cell as? SearchTagCell)?.textView.textColor = UIColor.black
                (cell as? SearchTagCell)?.textView.backgroundColor = UIColor.white
                
            } else {
                (cell as? SearchTagCell)?.textView.textColor = AppDelegate.textLightColor
                (cell as? SearchTagCell)?.textView.backgroundColor = AppDelegate.greyBg
            }
            
        case 2:
            cell = (tableView.dequeueReusableCell(withIdentifier: "searchTagTextCell") as? SearchTagWithTextCell)!
            
            cell?.accessoryType = .none
            
            if (indexPath.row < labelTitlesWithText.count) {
                (cell as? SearchTagWithTextCell)?.label.text = labelTitlesWithText[indexPath.row]
            }
            (cell as? SearchTagWithTextCell)?.textField.delegate = self
            (cell as? SearchTagWithTextCell)?.textField.inputView = nil
            
            switch (indexPath.row) {
            case 0:
                (cell as? SearchTagWithTextCell)?.textField.tag = TAG_ANYFIELD
                (cell as? SearchTagWithTextCell)?.textField.text = searchQuery.tag
            case 1:
                (cell as? SearchTagWithTextCell)?.textField.tag = TAG_TITLE
                (cell as? SearchTagWithTextCell)?.textField.text = searchQuery.title
            case 2:
                (cell as? SearchTagWithTextCell)?.textField.tag = TAG_AUTHOR
                (cell as? SearchTagWithTextCell)?.textField.text = searchQuery.creators
            case 3:
                (cell as? SearchTagWithTextCell)?.textField.tag = TAG_NONE
                (cell as? SearchTagWithTextCell)?.textField.inputView = langPickerView
                (cell as? SearchTagWithTextCell)?.textField.text = selectedLang
            case 4:
                (cell as? SearchTagWithTextCell)?.textField.tag = TAG_RATINGS
                (cell as? SearchTagWithTextCell)?.textField.text = selectedRaiting
            case 5:
                cell = (tableView.dequeueReusableCell(withIdentifier: "searchSwitchCell") as? SearchSwitchCell)!
                (cell as? SearchSwitchCell)?.label.text = Localization("SingleChpt")
                (cell as? SearchSwitchCell)?.switchItem.tag = TAG_SINGLE_CHAPTER
                setCategorySwitchState((cell as? SearchSwitchCell)!.switchItem)
            case 6:
                cell = (tableView.dequeueReusableCell(withIdentifier: "searchSwitchCell") as? SearchSwitchCell)!
                (cell as? SearchSwitchCell)?.label.text = Localization("Complete")
                (cell as? SearchSwitchCell)?.switchItem.tag = TAG_COMPLETE
                setCategorySwitchState((cell as? SearchSwitchCell)!.switchItem)
            default:
                (cell as? SearchTagWithTextCell)?.textField.tag = TAG_NONE
                (cell as? SearchTagWithTextCell)?.textField.text = ""
            }
            
            if (theme == DefaultsManager.THEME_DAY) {
                (cell as? SearchTagWithTextCell)?.textField.textColor = UIColor.black
                (cell as? SearchTagWithTextCell)?.label.textColor = UIColor.black
                (cell as? SearchTagWithTextCell)?.textField.backgroundColor = UIColor.white
                
                (cell as? SearchSwitchCell)?.label.textColor = UIColor.black
                
            } else {
                (cell as? SearchTagWithTextCell)?.textField.textColor = AppDelegate.textLightColor
                (cell as? SearchTagWithTextCell)?.label.textColor = AppDelegate.textLightColor
                (cell as? SearchTagWithTextCell)?.textField.backgroundColor = AppDelegate.greyBg
                
                (cell as? SearchSwitchCell)?.label.textColor = AppDelegate.textLightColor
            }
            
        case 3:
            cell = (tableView.dequeueReusableCell(withIdentifier: "serachFromToCell") as? SearchFromToCell)!
            
            cell?.accessoryType = .none
            
            (cell as? SearchFromToCell)?.nameLabel.text = labelTitlesFromTo[indexPath.row]
            (cell as? SearchFromToCell)?.imgView.image = UIImage(named:imgTitlesFromTo[indexPath.row])
            (cell as? SearchFromToCell)?.fromTextView.delegate = self
            (cell as? SearchFromToCell)?.toTextView.delegate = self
            
            (cell as? SearchFromToCell)?.fromTextView.placeholder = Localization("From")
            (cell as? SearchFromToCell)?.toTextView.placeholder = Localization("To")
            
            if (theme == DefaultsManager.THEME_DAY) {
                (cell as? SearchFromToCell)?.fromTextView.textColor = UIColor.black
                (cell as? SearchFromToCell)?.toTextView.textColor = UIColor.black
                (cell as? SearchFromToCell)?.nameLabel.textColor = UIColor.black
                
                (cell as? SearchFromToCell)?.fromTextView.backgroundColor = UIColor.white
                (cell as? SearchFromToCell)?.toTextView.backgroundColor = UIColor.white
            } else {
                (cell as? SearchFromToCell)?.fromTextView.textColor = AppDelegate.textLightColor
                (cell as? SearchFromToCell)?.toTextView.textColor = AppDelegate.textLightColor
                (cell as? SearchFromToCell)?.nameLabel.textColor = AppDelegate.textLightColor
                
                (cell as? SearchFromToCell)?.fromTextView.backgroundColor = AppDelegate.greyBg
                (cell as? SearchFromToCell)?.toTextView.backgroundColor = AppDelegate.greyBg
            }
            
            switch (indexPath.row) {
            case 0:
                (cell as? SearchFromToCell)?.fromTextView.tag = TAG_KUDOS_FROM
                (cell as? SearchFromToCell)?.toTextView.tag = TAG_KUDOS_TO
                
                parseFromToStatement((cell as! SearchFromToCell).fromTextView!,
                    textFieldTo: (cell as! SearchFromToCell).toTextView!, textToParse: searchQuery.kudos_count)
                
            case 1:
                (cell as? SearchFromToCell)?.fromTextView.tag = TAG_HITS_FROM
                (cell as? SearchFromToCell)?.toTextView.tag = TAG_HITS_TO
                
                parseFromToStatement((cell as! SearchFromToCell).fromTextView!,
                    textFieldTo: (cell as! SearchFromToCell).toTextView!, textToParse: searchQuery.hits)
                
            case 2:
                (cell as? SearchFromToCell)?.fromTextView.tag = TAG_COMMENTS_FROM
                (cell as? SearchFromToCell)?.toTextView.tag = TAG_COMMENTS_TO
                
                parseFromToStatement((cell as! SearchFromToCell).fromTextView!,
                    textFieldTo: (cell as! SearchFromToCell).toTextView!, textToParse: searchQuery.comments_count)
                
            case 3:
                (cell as? SearchFromToCell)?.fromTextView.tag = TAG_BOOKMARKS_FROM
                (cell as? SearchFromToCell)?.toTextView.tag = TAG_BOOKMARKS_TO
                
                parseFromToStatement((cell as! SearchFromToCell).fromTextView!,
                    textFieldTo: (cell as! SearchFromToCell).toTextView!, textToParse: searchQuery.bookmarks_count)
                
            case 4:
                (cell as? SearchFromToCell)?.fromTextView.tag = TAG_WORDCOUNT_FROM
                (cell as? SearchFromToCell)?.toTextView.tag = TAG_WORDCOUNT_TO
                
                parseFromToStatement((cell as! SearchFromToCell).fromTextView!,
                    textFieldTo: (cell as! SearchFromToCell).toTextView!, textToParse: searchQuery.word_count)
            default:
                break
            }
            
        case 4:
            cell = (tableView.dequeueReusableCell(withIdentifier: "searchSwitchesCell") as? SearchSwitchesCell)!
            
            cell?.accessoryType = .none
            
            setWarningSwitchState((cell as? SearchSwitchesCell)!.ffSwitch)
            setWarningSwitchState((cell as? SearchSwitchesCell)!.fmSwitch)
            setWarningSwitchState((cell as? SearchSwitchesCell)!.genSwitch)
            setWarningSwitchState((cell as? SearchSwitchesCell)!.mmSwitch)
            setWarningSwitchState((cell as? SearchSwitchesCell)!.multiSwitch)
            setWarningSwitchState((cell as? SearchSwitchesCell)!.otherSwitch)
            
            if (theme == DefaultsManager.THEME_DAY) {
                (cell as? SearchSwitchesCell)?.fflabel.textColor = UIColor.black
                (cell as? SearchSwitchesCell)?.fmlabel.textColor = UIColor.black
                (cell as? SearchSwitchesCell)?.mmlabel.textColor = UIColor.black
                (cell as? SearchSwitchesCell)?.multlabel.textColor = UIColor.black
                (cell as? SearchSwitchesCell)?.genlabel.textColor = UIColor.black
                (cell as? SearchSwitchesCell)?.otherlabel.textColor = UIColor.black
                
            } else {
                (cell as? SearchSwitchesCell)?.fflabel.textColor = AppDelegate.textLightColor
                (cell as? SearchSwitchesCell)?.fmlabel.textColor = AppDelegate.textLightColor
                (cell as? SearchSwitchesCell)?.mmlabel.textColor = AppDelegate.textLightColor
                (cell as? SearchSwitchesCell)?.multlabel.textColor = AppDelegate.textLightColor
                (cell as? SearchSwitchesCell)?.genlabel.textColor = AppDelegate.textLightColor
                (cell as? SearchSwitchesCell)?.otherlabel.textColor = AppDelegate.textLightColor
            }
            
        case 5:
            cell = (tableView.dequeueReusableCell(withIdentifier: "searchSwitchCell") as? SearchSwitchCell)!
            cell?.accessoryType = .none
            
            (cell as? SearchSwitchCell)?.label.text = labelTitlesSwitch[indexPath.row]
            
            if (theme == DefaultsManager.THEME_DAY) {
                (cell as? SearchSwitchCell)?.label.textColor = UIColor.black
                
            } else {
                (cell as? SearchSwitchCell)?.label.textColor = AppDelegate.textLightColor
            }
            
            switch (indexPath.row) {
            case 0:
                (cell as? SearchSwitchCell)?.switchItem.tag = 14
            case 1:
                (cell as? SearchSwitchCell)?.switchItem.tag = 17
            case 2:
                (cell as? SearchSwitchCell)?.switchItem.tag = 18
            case 3:
                (cell as? SearchSwitchCell)?.switchItem.tag = 16
            case 4:
                (cell as? SearchSwitchCell)?.switchItem.tag = 19
            case 5:
                (cell as? SearchSwitchCell)?.switchItem.tag = 20
            default:
                break
            }
        
            setCategorySwitchState((cell as? SearchSwitchCell)!.switchItem)
            
        case 6:
            if (indexPath.row == 0) {
                cell = tableView.dequeueReusableCell(withIdentifier: "SearchTagsListCell") as? SearchTagsListCell
                    if (theme == DefaultsManager.THEME_DAY) {
                        (cell as? SearchTagsListCell)?.nameLabel.textColor = UIColor.black
                        
                    } else {
                        (cell as? SearchTagsListCell)!.nameLabel.textColor = AppDelegate.textLightColor
                    }
                cell?.accessoryType = .disclosureIndicator
            } else {
             cell = (tableView.dequeueReusableCell(withIdentifier: "searchFandomsCell") as? SearchFandomsCell)
            (cell as? SearchFandomsCell)?.nameLabel.text = worktagsTitlesWithText[indexPath.row]
            (cell as? SearchFandomsCell)?.textfield.delegate = self
                
                cell?.accessoryType = .none
            
            if (theme == DefaultsManager.THEME_DAY) {
                (cell as? SearchFandomsCell)?.nameLabel.textColor = AppDelegate.greyColor
                (cell as? SearchFandomsCell)?.textfield.textColor = UIColor.black
                (cell as? SearchFandomsCell)?.textfield.backgroundColor = UIColor.white
                
            } else {
                (cell as! SearchFandomsCell).nameLabel.textColor = AppDelegate.textLightColor
                (cell as? SearchFandomsCell)!.textfield.textColor = UIColor.white
                (cell as? SearchFandomsCell)!.textfield.backgroundColor = AppDelegate.greyBg
            }
            }
            
            switch (indexPath.row) {
            case 0:
                (cell as? SearchTagsListCell)?.nameLabel.tag = TAG_FANDOMS
                
                if (searchQuery.fandom_names.count > 0) {
                    (cell as? SearchTagsListCell)?.nameLabel.text = searchQuery.fandom_names
                } else {
                    (cell as? SearchTagsListCell)?.nameLabel.text = NSLocalizedString("FandomNotSpecified", comment: "")
                }
                
            case 1:
                (cell as? SearchFandomsCell)?.textfield.tag = TAG_RELATIONSHIPS
                (cell as? SearchFandomsCell)?.textfield.text = searchQuery.relationship_names
            case 2:
                (cell as? SearchFandomsCell)?.textfield.tag = TAG_CHARACTERS
                (cell as? SearchFandomsCell)?.textfield.text = searchQuery.character_names
            default:
                break
            }
            
        case 7:
            cell = (tableView.dequeueReusableCell(withIdentifier: "searchTagTextCell") as? SearchTagWithTextCell)!
            (cell as? SearchTagWithTextCell)?.label.text = sortlabelTitlesWithText[indexPath.row]
            (cell as? SearchTagWithTextCell)?.textField.delegate = self
            
            if (theme == DefaultsManager.THEME_DAY) {
                (cell as? SearchTagWithTextCell)?.textField.textColor = UIColor.black
                (cell as? SearchTagWithTextCell)?.label.textColor = UIColor.black
                (cell as? SearchTagWithTextCell)?.textField.backgroundColor = UIColor.white
                
            } else {
                (cell as? SearchTagWithTextCell)?.textField.textColor = AppDelegate.textLightColor
                (cell as? SearchTagWithTextCell)?.label.textColor = AppDelegate.textLightColor
                (cell as? SearchTagWithTextCell)?.textField.backgroundColor = AppDelegate.greyBg
            }
            
            if (indexPath.row == 0) {
                (cell as? SearchTagWithTextCell)?.textField.inputView = sortbyPickerView
                (cell as? SearchTagWithTextCell)?.textField.text = selectedSortBy
            } else if (indexPath.row == 1) {
                (cell as? SearchTagWithTextCell)?.textField.inputView = sortdirectionPickerView
                (cell as? SearchTagWithTextCell)?.textField.text = selectedSortDirection
            }
        case 8:
            cell = (tableView.dequeueReusableCell(withIdentifier: "buttonCell") as? ButtonCell)!
            
            if (theme == DefaultsManager.THEME_DAY) {
                (cell as? ButtonCell)?.btn.setTitleColor(AppDelegate.redColor, for: .normal)
                
            } else {
                (cell as? ButtonCell)?.btn.setTitleColor(UIColor.white, for: .normal)
            }
            
        default:
            break
        }
        
        if (theme == DefaultsManager.THEME_DAY) {
            cell?.backgroundColor = UIColor.white
        } else {
            cell?.backgroundColor = AppDelegate.greyDarkBg
        }
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var heightForRow : CGFloat = 40
        
//        if (indexPath.section == 0 || indexPath.section == 1) {
//            heightForRow = 1
//        } else
        if (indexPath.section == 4 || indexPath.section == 0 || indexPath.section == 1) {
                heightForRow = 80
            } else if (indexPath.section == 6) {
                heightForRow = 80
        }
      //  }
        
        return heightForRow
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // Return the number of sections.
        return 9
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        var res:Int = 1
        
        switch (section) {
        case 0:
            res = 1//searchTags.count
        case 1:
            res = 1//excludeTags.count
        case 2:
            res = 7
        case 3:
            res = 5
        case 4:
            res = 1
        case 5:
            res = labelTitlesSwitch.count
        case 6:
            res = 3
        case 7:
            res = 2
        case 8:
            res = 1
        default:
            break
        }
        
        return res
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        var res: String = ""
        
        switch (section) {
        case 0:
            res = Localization("IncludeTags")
        case 1:
            res = Localization("ExcludeTags")
        case 2:
            res = Localization("WorkInfo")
        case 3:
            res = Localization("Stats")
        case 4:
            res = Localization("Category")
        case 5:
            res = Localization("Warnings")
        case 6:
            res = Localization("WorkTags")
        case 7:
            res = Localization("Search")
        default:
            break
        }
        return res
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch (indexPath.section) {
        case 6:
            if (indexPath.row == 0){
                self.performSegue(withIdentifier: "popoverSegue", sender: self)
            }
        default: break
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //MARK: - loading search query
    func loadDefaults() {
        
            searchTags.append(DefaultsManager.getString(DefaultsManager.SEARCH_Q_PREF))
            searchTags.append(DefaultsManager.getString(DefaultsManager.SEARCH_Q_PREF1))
            searchTags.append(DefaultsManager.getString(DefaultsManager.SEARCH_Q_PREF2))
            searchTags.append(DefaultsManager.getString(DefaultsManager.SEARCH_Q_PREF3))
        
        if let sq = DefaultsManager.getObject(DefaultsManager.SEARCH_Q) as? SearchQuery {
            self.searchQuery = sq
        } else {
            self.searchQuery = SearchQuery()
        }
        
        if (langDict.allKeys(for: searchQuery.language_id).count > 0) {
            selectedLang = langDict.allKeys(for: searchQuery.language_id)[0] as! String
        }
        
        if (ratingDict.allKeys(for: searchQuery.rating_ids).count > 0) {
            selectedRaiting = ratingDict.allKeys(for: searchQuery.rating_ids)[0] as! String
        }
        
        if (sortByDict.allKeys(for: searchQuery.sort_column).count > 0) {
            selectedSortBy = sortByDict.allKeys(for: searchQuery.sort_column)[0] as! String
        }
        
        if (sortDirectionDict.allKeys(for: searchQuery.sort_direction).count > 0) {
            selectedSortDirection = sortDirectionDict.allKeys(for: searchQuery.sort_direction)[0] as! String
        }
    }
    
        
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if(string == "\n") {
            textField.resignFirstResponder()
            return false
        }
        return true
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText string: String) -> Bool {
        if(string == "\n") {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
//    func textFieldShouldReturn(textField: UITextField) -> Bool {
//        textField.resignFirstResponder()
//        return false
//    }

    func scrollTableView(_ textField: UIView) {
        var cell: UITableViewCell
        
        if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
            // Load resources for iOS 6.1 or earlier
            cell = textField.superview as! UITableViewCell
            
        } else {
            // Load resources for iOS 7 or later
            cell = textField.superview!.superview  as! UITableViewCell
            // TextField -> UITableVieCellContentView -> (in iOS 7!)ScrollView -> Cell!
        }
        tableView.scrollToRow(at: tableView.indexPath(for: cell)!, at:UITableView.ScrollPosition.middle, animated:true)
    }
    
    func showChooseRatingPopup(textField: UITextField) {
        let popup = PopupDialog(title: Localization("Rating"), message: "Selected rating (\(selectedRaiting)")
        
        let buttonCancel = CancelButton(title: "CANCEL") {
            print("You canceled the car dialog.")
        }
        
        guard let ratingKeys = ratingDict.keysSortedByValue(comparator: compareKeys ) as? [String] else {
            return
        }
        
        var buttons: [PopupDialogButton] = [PopupDialogButton]()
        buttons.append(buttonCancel)
        
        for key in ratingKeys {
            let buttonOne = DefaultButton(title: key) {
                self.selectedRaiting = key
                self.searchQuery.rating_ids = self.ratingDict[self.selectedRaiting] as? String ?? ""
                textField.text = self.selectedRaiting
            }
            buttons.append(buttonOne)
        }
        
        popup.addButtons(buttons)
        
        self.present(popup, animated: true, completion: nil)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        currentTextField = textField
        
        scrollTableView(textField)
        
        if (textField.tag == TAG_RATINGS) {
            showChooseRatingPopup(textField: textField)
            textField.endEditing(true)
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        scrollTableView(textView)
    }
    
    @IBAction func tFieldDoneEditing(_ sender: UITextField) {
        switch (sender.tag) {
        case TAG_ANYFIELD:
            searchQuery.tag = sender.text ?? ""
        case TAG_TITLE:
            searchQuery.title = sender.text ?? ""
        case TAG_AUTHOR:
            searchQuery.creators = sender.text ?? ""
        case TAG_KUDOS_FROM:
            for subview in sender.superview!.subviews {
                if let textField = subview as? UITextField {
                    if (textField.tag == TAG_KUDOS_TO) {
                         NSLog("TAG_KUDOS_TO")
                        searchQuery.kudos_count =
                            formFromToStatement(sender, textFieldTo: textField)
                    }
                }
            }
        case TAG_KUDOS_TO:
            for subview in sender.superview!.subviews {
                if let textField = subview as? UITextField {
                    if (textField.tag == TAG_KUDOS_FROM) {
                        NSLog("TAG_KUDOS_FROM")
                        searchQuery.kudos_count = formFromToStatement(textField, textFieldTo: sender)
                    }
                }
            }
            
        case TAG_HITS_FROM:
            for subview in sender.superview!.subviews {
                if let textField = subview as? UITextField {
                    if (textField.tag == TAG_HITS_TO) {
                        searchQuery.hits = formFromToStatement(sender, textFieldTo: textField)
                    }
                }
            }
        case TAG_HITS_TO:
            for subview in sender.superview!.subviews {
                if let textField = subview as? UITextField {
                    if (textField.tag == TAG_HITS_FROM) {
                        searchQuery.hits = formFromToStatement(textField, textFieldTo: sender)
                    }
                }
            }
            
        case TAG_COMMENTS_FROM:
            for subview in sender.superview!.subviews {
                if let textField = subview as? UITextField {
                    if (textField.tag == TAG_COMMENTS_TO) {
                        searchQuery.comments_count = formFromToStatement(sender, textFieldTo: textField)
                    }
                }
            }
        case TAG_COMMENTS_TO:
            for subview in sender.superview!.subviews {
                if let textField = subview as? UITextField {
                    if (textField.tag == TAG_COMMENTS_FROM) {
                        searchQuery.comments_count = formFromToStatement(textField, textFieldTo: sender)
                    }
                }
            }
            
        case TAG_BOOKMARKS_FROM:
            for subview in sender.superview!.subviews {
                if let textField = subview as? UITextField {
                    if (textField.tag == TAG_BOOKMARKS_TO) {
                        searchQuery.bookmarks_count = formFromToStatement(sender, textFieldTo: textField)
                    }
                }
            }
        case TAG_BOOKMARKS_TO:
            for subview in sender.superview!.subviews {
                if let textField = subview as? UITextField {
                    if (textField.tag == TAG_BOOKMARKS_FROM) {
                        searchQuery.bookmarks_count = formFromToStatement(textField, textFieldTo: sender)
                    }
                }
            }
            
        case TAG_WORDCOUNT_FROM:
            for subview in sender.superview!.subviews {
                if let textField = subview as? UITextField {
                    if (textField.tag == TAG_WORDCOUNT_TO) {
                        searchQuery.word_count = formFromToStatement(sender, textFieldTo: textField)
                    }
                }
            }
        case TAG_WORDCOUNT_TO:
            for subview in sender.superview!.subviews {
                if let textField = subview as? UITextField {
                    if (textField.tag == TAG_WORDCOUNT_FROM) {
                        searchQuery.word_count = formFromToStatement(textField, textFieldTo: sender)
                    }
                }
            }
            
        default:
            break
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
       
        switch (textView.tag) {
        case TAG_FANDOMS :
            searchQuery.fandom_names = textView.text
        case TAG_RELATIONSHIPS :
            searchQuery.relationship_names = textView.text
        case TAG_CHARACTERS :
            searchQuery.character_names = textView.text
        case TAG_EXCLUDE_TAGS:
            searchQuery.exclude_tags = textView.text
        case TAG_INCLUDE_TAGS:
            searchQuery.include_tags = textView.text
            
        default:
            break
        }
    }
    
    func formFromToStatement(_ textFieldFrom: UITextField, textFieldTo: UITextField) -> String {
        var res: String = ""
        
        if (textFieldFrom.text != nil && textFieldTo.text != nil && textFieldFrom.text!.count > 0 && textFieldTo.text!.count > 0) {
            res = textFieldFrom.text! + "-" + textFieldTo.text!
        } else  if (textFieldFrom.text!.count == 0 && textFieldTo.text!.count > 0) {
            res = "<" + textFieldTo.text!
        } else  if (textFieldFrom.text!.count == 0 && textFieldTo.text!.count == 0) {
            res = ""
        } else {
            res = ">" + textFieldFrom.text!
        }
        return res
    }
    
    func parseFromToStatement(_ textFieldFrom: UITextField, textFieldTo: UITextField, textToParse:String) {
        
        if textToParse.range(of: ">") != nil {
            textFieldFrom.text = textToParse.replacingOccurrences(of: ">", with: "")
        }
        else if (textToParse.range(of: "<")  != nil) {
            textFieldTo.text = textToParse.replacingOccurrences(of: "<", with: "")
        }
        else if(textToParse.range(of: "-")  != nil) {
            let range: Range = textToParse.range(of: "-")!
            let rangeFirst = textToParse.startIndex..<range.lowerBound
            textFieldFrom.text = String(textToParse[rangeFirst])
            
            let rangeSecond = range.upperBound..<textToParse.endIndex
            textFieldTo.text = String(textToParse[rangeSecond]).replacingOccurrences(of: "-", with: "")
        } else {
            textFieldFrom.text = textToParse
        }
    }
    
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int{
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int{
        
        if(pickerView == langPickerView) {
            return langDict.count
        } else
            if(pickerView == ratingPickerView) {
                return ratingDict.count
            }
            else
                if(pickerView == sortbyPickerView) {
                    return sortByDict.count
                } else
                    if(pickerView == sortdirectionPickerView) {
                        return sortDirectionDict.count
        }
        return 0;
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        if(pickerView == langPickerView) {
            let sortedKeys = langDict.keysSortedByValue(comparator: compareKeys )
            return sortedKeys[row] as? String
        } else
            if(pickerView == ratingPickerView) {
                return ratingDict.keysSortedByValue(comparator: compareKeys )[row] as? String
            } else
                if(pickerView == sortbyPickerView) {
                return sortByDict.keysSortedByValue(comparator: compareKeys )[row] as? String
            } else
                if(pickerView == sortdirectionPickerView) {
                    return sortDirectionDict.keysSortedByValue(comparator: compareKeys )[row] as? String
        }
        
        return ""
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int){
        
        if (currentTextField != nil) {
        
        if(pickerView == langPickerView && currentTextField!.text != nil) {
            currentTextField?.text = langDict.keysSortedByValue(comparator: compareKeys )[row] as? String
            selectedLang = currentTextField!.text!
            searchQuery.language_id = langDict[selectedLang] as! String
        } else
            if(pickerView == ratingPickerView) {
                currentTextField?.text = ratingDict.keysSortedByValue(comparator: compareKeys )[row] as? String
                selectedRaiting = currentTextField!.text!
                searchQuery.rating_ids = ratingDict[selectedRaiting] as! String
            } else
            if(pickerView == sortbyPickerView) {
                currentTextField?.text = sortByDict.keysSortedByValue(comparator: compareKeys )[row] as? String
                selectedSortBy = currentTextField!.text!
                searchQuery.sort_column = sortByDict[selectedSortBy] as! String
            } else
                if(pickerView == sortdirectionPickerView) {
                    currentTextField?.text = sortDirectionDict.keysSortedByValue(comparator: compareKeys )[row] as? String
                    selectedSortDirection = currentTextField!.text!
                    searchQuery.sort_direction = sortDirectionDict[selectedSortDirection] as! String
        }
       
        self.view.endEditing(true)
        
        currentTextField = nil
        }
    }
    
    func compareKeys(_ obj1:Any, obj2:Any) -> ComparisonResult {
        let p1 = obj1 as! String
        let p2 = obj2 as! String
        let result = p1.compare(p2)
        return result
    }

    
    @IBAction func ffSwitchChanged(_ sender: UISwitch) {
        if (sender.isOn) {
            if (!searchQuery.warnings.contains(String(sender.tag))) {
                searchQuery.warnings.append(String(sender.tag))
            }
        } else {
            searchQuery.warnings = searchQuery.warnings.filter( {$0 != String(sender.tag)} )
        }
    }
    
    @IBAction func categorySwitchChanged(_ sender: UISwitch) {
        
        let tag: Int = sender.tag
        
        switch (tag) {
        case TAG_SINGLE_CHAPTER:
            if (sender.isOn) {
             searchQuery.single_chapter = "1"
            } else {
                searchQuery.single_chapter = "0"
            }
        case TAG_COMPLETE:
            if (sender.isOn) {
                searchQuery.complete = "1"
            } else {
                searchQuery.complete = "0"
            }
        default:
            if (sender.isOn) {
                if (!searchQuery.categories.contains(String(sender.tag))) {
                    searchQuery.categories.append(String(sender.tag))
                }
            } else {
                searchQuery.categories = searchQuery.categories.filter( {$0 != String(sender.tag)} )
            }
        }
    }
    
//    func setOtherTagSwitchState(sender: UISwitch, otherTag: String) {
//        
//        var tag: Int = sender.tag
//        
//        if (otherTag == "1") {
//            sender.setOn(true, animated: true)
//        } else {
//            sender.setOn(false, animated: true)
//        }
//    }
    
    func setWarningSwitchState(_ sender: UISwitch) {
        
        let tag: Int = sender.tag
        
        if (searchQuery.warnings.contains(String(tag))) {
            sender.setOn(true, animated: true)
        } else {
            sender.setOn(false, animated: true)
        }
    }
    
    func setCategorySwitchState(_ sender: UISwitch) {
        let tag: Int = sender.tag
        
        switch (tag) {
        case TAG_SINGLE_CHAPTER:
            if (searchQuery.single_chapter == "1") {
                sender.setOn(true, animated: true)
            } else {
                sender.setOn(false, animated: true)
            }
        case TAG_COMPLETE:
            if (searchQuery.complete == "1") {
                sender.setOn(true, animated: true)
            } else {
                sender.setOn(false, animated: true)
            }
        default:
            if (searchQuery.categories.contains(String(tag))) {
                sender.setOn(true, animated: true)
            } else {
                sender.setOn(false, animated: true)
            }
        }
        
    }
    
    @IBAction func searchAndSaveBtnTouched(_ sender: AnyObject) {
        
        self.dismiss(animated: true, completion: {
            self.delegate?.searchApplied(self.searchQuery, shouldAddKeyword: false)
            self.modalDelegate?.controllerDidClosed()
        })
    }
}

extension SearchViewController {
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "popoverSegue") {
             if let controller: PopOverViewController = segue.destination as? PopOverViewController {
                
                let arr = self.searchQuery.fandom_names.components(separatedBy: ",")
                var objects: [FandomObject] = []
                for i in 0..<arr.count {
                    if (arr[i].condenseWhitespace().isEmpty == false) { //condenseWhitespace - Remove leading, trailing and repeated whitespace from a string
                        objects.append(FandomObject(sectionName: arr[i], sectionObject: "", isSelected: true))
                    }
                }
                
                controller.fandoms = objects
                controller.selectedFandoms = objects
                
                controller.selectionProtocol = self
            }
        }
    }
    
}

extension SearchViewController: SelectionProtocol {
    func itemsSelected(items: [FandomObject]) {
        self.searchQuery.fandom_names = ""
        
        for i in 0..<items.count {
            self.searchQuery.fandom_names.append(items[i].sectionName)
            if (i != items.count - 1) {
                self.searchQuery.fandom_names.append(", ")
            }
        }
        
        self.tableView.reloadRows(at: [IndexPath(row: 0, section: 6)], with: .none)
    }
}
