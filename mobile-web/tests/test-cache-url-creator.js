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

import { constructViewerCacheUrl } from "../src/amp-url-creator";

const initParams = {
  origin: "http://localhost:8000"
};

describe("Tests for CacheUrlCreator", () => {
  it("should compute constructViewerCacheUrl correctly", () => {
    return constructViewerCacheUrl(
      "https://www.ampproject.org",
      initParams
    ).then(output => {
      expect(output).to.equal(
        "https://www-ampproject-org.cdn.ampproject.org/v/s/www.ampproject.org/?amp_js_v=0.1#origin=http%3A%2F%2Flocalhost%3A8000"
      );
    });
  });

  it("should compute constructViewerCacheUrl correctly", () => {
    return constructViewerCacheUrl(
      "http://www.example.com/article/bla/la",
      initParams
    ).then(output => {
      expect(output).to.equal(
        "https://www-example-com.cdn.ampproject.org/v/www.example.com/article/bla/la?amp_js_v=0.1#origin=http%3A%2F%2Flocalhost%3A8000"
      );
    });
  });

  it("should compute constructViewerCacheUrl correctly", () => {
    return constructViewerCacheUrl(
      "http://www.example.com/foo?amp=true",
      initParams
    ).then(output => {
      expect(output).to.equal(
        "https://www-example-com.cdn.ampproject.org/v/www.example.com/foo?amp=true&amp_js_v=0.1#origin=http%3A%2F%2Flocalhost%3A8000"
      );
    });
  });
});
