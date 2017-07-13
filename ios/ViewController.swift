//
//  ViewController.swift
//  viewer
//
//  Created by Chen Shay on 7/10/17.
//  Copyright © 2017 Chen Shay. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var webView: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var initParams : [String : String] = [:]
        initParams["origin"] = "http://localhost:8000"
        let cachedUrl = AmpUrlCreator.constructViewerCacheUrl(
            "http://www.example.com/foo/bla/la?amp=true",
            initParams: initParams,
            opt_viewerJsVersion: "")
        print(cachedUrl)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func openViewer(_ sender: Any) {
        let ampUrl = URL(string: "https://www.ampproject.org")
        let ampUrlRequest = URLRequest(url: ampUrl!)
        webView.loadRequest(ampUrlRequest)
    }
    
    @IBAction func goBack(_ sender: Any) {
        webView.goBack()
    }
    
    @IBAction func goForward(_ sender: Any) {
        webView.goForward()
    }
}
