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

var ampURLCreator = require('../src/amp-url-creator');

/**
* Constructs a Viewer cache url for AmpKit using these rules:
* https://developers.google.com/amp/cache/overview
* 
* Example:
* Input url 'http://ampproject.org' can return 
* 'https://www-ampproject-org.cdn.ampproject.org/c/s/www.ampproject.org/'
*
* Responds to the request via the webkit messaging system using the 'ampkit' handler.
* 
* @param {string} url The complete publisher url.
*/
function createCDNURL(url) {
	ampURLCreator.constructNativeViewerCacheUrl(url).then(successValue => {
		if ('webkit' in window && 'messageHandlers' in window.webkit && 'ampkit' in window.webkit.messageHandlers) {
			window.webkit.messageHandlers.ampkit.postMessage({body: successValue});
		}
	});
}

window.ampkit = {};
window.ampkit.createCDNURL = createCDNURL;
