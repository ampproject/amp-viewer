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

import Foundation

class AmpUrlCreator {
    /**
     * The default JavaScript version to be used for AMP viewer URLs.
     */
    static let DEFAULT_VIEWER_JS_VERSION_ = "0.1";
    

    /**
     * Constructs a Viewer cache url using these rules:
     * https://developers.google.com/amp/cache/overview
     *
     * Example:
     * Input url 'http://ampproject.org' can return
     * 'https://www-ampproject-org.cdn.ampproject.org/v/s/www.ampproject.org/?amp_js_v=0.1#origin=http:%2F%2Flocalhost:8000'
     */
    static func constructViewerCacheUrl(_ urlstring: String,
                                        initParams: Dictionary<String, String>,
                                        opt_viewerJsVersion: String) -> String {
        let urlComponents = NSURLComponents(string: urlstring)
        
        let protocolStr = urlComponents?.scheme == "https" ? "s/" : ""
        let viewerJsVersion = !opt_viewerJsVersion.isEmpty ? opt_viewerJsVersion :
        DEFAULT_VIEWER_JS_VERSION_;
        let search = !((urlComponents!.query?.isEmpty)!) ? "?" + urlComponents!.query! + "&" : "?";
        
        return
            "https://" +
                constructCacheDomainUrl_() +
                "/v/" +
                protocolStr +
                urlComponents!.host! +
                urlComponents!.path! +
                search +
                "amp_js_v=" + viewerJsVersion +
                "#" +
                paramsToString_(params: initParams)
        
        //"http://www.example.com/foo/bla/la?amp=true"
        //"https://www-example-com.cdn.ampproject.org/v/www.example.com/foo/bla/la?amp=true&amp_js_v=0.1#origin=http%3A%2F%2Flocalhost%3A8000"
    }
    
    // todo
    static func constructCacheDomainUrl_() -> String {
        return "www-example-com.cdn.ampproject.org"
    }
    
    
    /**
     * Takes a Dictionary such as:
     * {
     *   origin: "http://localhost:8000",
     *   prerenderSize: "1"
     * }
     * and converts it to: "origin=http:%2F%2Flocalhost:8000&prerenderSize=1"
     */
    static func paramsToString_(params: Dictionary<String, String>) -> String {
        var str = "";
        
        for (key, value) in params {
            if (value.isEmpty) {
                continue
            }
            if (str.characters.count > 0) {
                str += "&";
                
            }
            str += key.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)! + "=" + value.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        }
        
        return str
    }
}
