//
//  InterstitialController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 7/22/16.
//  Copyright © 2016 Sergei Pekar. All rights reserved.
//

import UIKit
import JavaScriptCore

class InterstitialController: UIViewController, UIWebViewDelegate {
    
    @IBOutlet weak var webView: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
       // webView.loadHTMLString("<!DOCTYPE html><html><head><script type=\"text/javascript\">  (function(B, i, L, l, y) {l = B.createElement(i); y = B.getElementsByTagName(i)[0]; l.src = L + '3942008c0c46c155e9' + '?&' + ((1 * new Date()) + Math.random()) + '&' + 'nw=false&cm=true&fp=true'; y.parentNode.insertBefore(l, y)})(document, 'script', '//c.billypub.com/b/');</script></head><body><h1>Hi</h1></body></html>", baseURL: nil)
        
        webView.delegate = self
        webView.loadRequest(URLRequest(url: URL(string: "http://api-tests.indiefics.com/test.html")!))
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        let context: JSContext =  webView.value(forKeyPath: "documentView.webView.mainFrame.javaScriptContext") as! JSContext
        
        //context["adLoaded"] = { (Void) in
       //     print("loaded")
       // };
        
        let codeClosure: @convention(block) ()->() = { ()->() in
            print("this is my swift code closure")
        }
        
        let casted: AnyObject = unsafeBitCast(codeClosure, to: AnyObject.self) as AnyObject
        context.setObject(casted, forKeyedSubscript: "adLoaded" as (NSCopying & NSObjectProtocol)!)
    }
    
    @IBAction func closeTouched(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
}
