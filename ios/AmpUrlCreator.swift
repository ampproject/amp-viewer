//
//  ampUrlCreator.swift
//  viewer
//
//  Created by Chen Shay on 7/13/17.
//  Copyright © 2017 Chen Shay. All rights reserved.
//

import Foundation

class AmpUrlCreator {
    /**
     * The default JavaScript version to be used for AMP viewer URLs.
     */
    static let DEFAULT_VIEWER_JS_VERSION_ = "0.1";
    
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
