/**
 * Copyright 2017 The AMP HTML Authors. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS-IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

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
