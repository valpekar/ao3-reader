//
//  DefaultsManager.swift
//  ArchiveOfOurOwnReader
//
//  Created by ValeriyaPekar on 9/4/15.
//  Copyright (c) 2015 Sergei Pekar. All rights reserved.
//

import Foundation

class DefaultsManager {
    
    static var SEARCHED : String = "searched"
    static var SEARCH_Q : String = "sq"
    static var SEARCH_Q_RECOMMEND : String = "sqr"
    static var SEARCH_Q_PREF : String = "sqt"
    static var SEARCH_Q_PREF1 : String = "sqt1"
    static var SEARCH_Q_PREF2 : String = "sqt2"
    static var SEARCH_Q_PREF3 = "sqt3"
    static var EXCLUDE_TAG = "exldt"
    static var EXCLUDE_TAG1 = "exldt1"
    static var EXCLUDE_TAG2 = "exldt2"
    static var EXCLUDE_TAG3 = "exldt3"
    static var KUDOS = "kds"
    static var HITS = "hts"
    static var COMMENTS = "cmnts"
    static var BOOKMARKS = "bkmrks"
    static var WORD_COUNT = "wrdcnt"
    static var AUTHOR = "athr"
    static var TITLE = "title"
    static var SHOW_FIRST_FIC = "sff"
    static var LANGUAGE = "lng"
    static var CATEGORY = "ctgr"
    static var WARNINGS = "wrns"
    static var RATING_ID = "rtng"
    static var SORT_BY = "srtby"
    static var SORT_DIRECTION = "srtdir"
    static var SINGLE_CHAPTER = "schpt"
    static var COMPLETE = "cmplt"
    static var REVISED_AT = "rvsdat"
    static var FANDOMS = "fndms"
    static var RELATIONSHIPS = "rltshps"
    static var FONT_SIZE = "fsz"
    static var FONT_FAMILY = "ffam"
    static var THEME = "thm"
    static var THEME_APP = "thm_app"
    static var LOGIN = "login"
    static var PSWD = "pswd"
    static var PSEUD_ID = "pseud"
    static var PSEUD_IDS = "pseuds"
    static var LAST_DATE = "lastdt"
    static var NOTIFY = "notify"
    static var ADULT = "adlt"
    static var SAFE = "safe"
    static var TOKEN = "authtoken"
    static var COOKIES = "cookies"
    static var COOKIES_DATE = "cookies_date"
    static var LASTWRKID = "lwid"
    static var LASTWRKCHAPTER = "lwchp"
    static var LASTWRKSCROLL = "lwscrl"
    static var DONTSHOW_CONTEST = "dntshc"
    static var CONTENT_SHOWSN = "cntshwn"
    static var NEEDS_AUTH = "needsAuth"
    static var NEEDS_PASS = "needsPass"
    static var USER_PASS = "upass"
    static var SORT_DWNLD_BY = "sort_by"
    static var SORT_DWNLD_ASC = "sort_by_asc"
    static var SORT_HIGHLIGHTS = "sort_ghlts"
    static var SORT_FOLDERS = "sort_fldrs"
    static var NOTIF_DEVICE_TOKEN = "notifdtkn"
    static var REQ_DEVICE_TOKEN = "reqdtkn"
    static var NOTIF_IDS_ARR = "nidsarr"
    static var SHOW_ERR_AVFAUDIO = "serravfaud"
    static var THEME_DAY : Int = 0
    static var THEME_NIGHT : Int = 1
    
    class func getDefaults() -> UserDefaults {
        let defaults = UserDefaults.standard
        
        return defaults
    }
    
    class func getString(_ key:String) -> String {
        getDefaults().synchronize()
        if let res : String = getDefaults().object(forKey: key) as? String {
            return res
        } else {
           return ""
        }
    }
    
    class func getInt(_ key:String) -> Int? {
        getDefaults().synchronize()
        let res : Int? = getDefaults().object(forKey: key) as? Int
        return res
    }
    
    class func getBool(_ key:String) -> Bool? {
        getDefaults().synchronize()
        let res : Bool? = getDefaults().object(forKey: key) as? Bool
        return res
    }
    
    class func getDate(_ key:String) -> Date? {
        getDefaults().synchronize()
        let res : Date? = getDefaults().object(forKey: key) as? Date
        return res
    }
    
    class func putString(_ text:String, key:String) {
        let defaults : UserDefaults = getDefaults()
        defaults.set(text, forKey: key)
        defaults.synchronize()
        
    }
    
    class func putDate(_ date:Date, key:String) {
        let defaults : UserDefaults = getDefaults()
        defaults.set(date, forKey: key)
        defaults.synchronize()
        
    }
    
    class func putInt(_ obj:Int, key:String) {
        let defaults : UserDefaults = getDefaults()
        defaults.set(obj, forKey: key)
        defaults.synchronize()
        
    }
    
    class func putBool(_ obj:Bool, key:String) {
        let defaults : UserDefaults = getDefaults()
        defaults.set(obj, forKey: key)
        defaults.synchronize()
        
    }
    
    class func getObject(_ key:String) -> AnyObject? {
        let data = UserDefaults.standard.object(forKey: key) as? Data
        var res : AnyObject?
        
        if data != nil {
            res = NSKeyedUnarchiver.unarchiveObject(with: data!) as AnyObject?
        }
        return res
    }
    
    class func putObject(_ object:AnyObject, key:String) {
        let defaults : UserDefaults = getDefaults()
        
        let data = NSKeyedArchiver.archivedData(withRootObject: object)
        
        defaults.set(data, forKey: key)
        defaults.synchronize()
        
    }
    
    class func putStringArray(_ obj: [String], key: String) {
        let defaults : UserDefaults = getDefaults()
        defaults.set(obj, forKey: key)
        defaults.synchronize()
    }
    
    class func getStringArray(_ key: String) -> [String] {
        var res: [String] = []
        
        if let strArr = getDefaults().object(forKey: key) as? [String] {
          res = strArr
        }
        
        return res
    }
    
}
