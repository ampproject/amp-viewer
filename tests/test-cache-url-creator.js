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

import {constructViewerCacheUrl, constructCacheDomain_} from '../src/amp-url-creator';

const punycode = require('punycode');

const initParams = {
  origin: 'http://localhost:8000'
};

describe('Tests for CacheUrlCreator', () => {

  it('should compute something.com correctly', () => {
    return constructCacheDomain_('something.com').then(output => {
      expect(output).to.equal('something-com');
    });
  });

  it('should compute SOMETHING.COM correctly', () => {
    return constructCacheDomain_('SOMETHING.COM').then(output => {
      expect(output).to.equal('something-com');
    });
  });

  it('should compute hello-world.com correctly', () => {
    return constructCacheDomain_('hello-world.com').then(output => {
      expect(output).to.equal('hello--world-com');
    });
  });

  it('should compute hello--world.com correctly', () => {
    return constructCacheDomain_('hello--world.com').then(output => {
      expect(output).to.equal('hello----world-com');
    });
  });

  it('should compute toplevelnohyphens correctly', () => {
    // If the origin has no dots or hyphens -- meaning that we wouldn't have
    // an easy way to tell the human-readable form from the base32 form --
    // fall back to base32. This should be rare or impossible in reality.
    return constructCacheDomain_('toplevelnohyphens').then(output => {
      expect(output).to.equal('qsgpfjzulvuaxb66z77vlhb5gu2irvcnyp6t67cz6tqo5ae6fysa');
    });
  });

  it('should compute no-dot-domain correctly', () => {
    return constructCacheDomain_('no-dot-domain').then(output => {
      expect(output).to.equal('4lxc7wqq7b25walg4rdiil62veijrmqui5z3ept2lyfqqwpowryq');
    });
  });

  it('should compute too long domain correctly', () => {
    //  Human-readable form will be too long; we should fall back.
    const tooLongDomain = 'itwasadarkandstormynight.therainfellintorrents.exceptatoccasionalintervalswhenitwascheckedby.aviolentgustofwindwhichsweptupthestreets.com';
    return constructCacheDomain_(tooLongDomain).then(output => {
      expect(output).to.equal('dgz4cnrxufaulnwku4ow5biptyqnenjievjht56hd7wqinbdbteq');
    });
  });

  it('should compute xn--bcher-kva.ch correctly', () => {
    // Wikipedia's example of an IDN: "bücher.ch" -> "bücher-ch".
    return constructCacheDomain_('xn--bcher-kva.ch').then(output => {
      expect(output).to.equal('xn--bcher-ch-65a');
    });
  });

  it('should compute RTL chars correctly', () => {
    // Actual URL of Egyptian Ministry of Communications.
    // Right-to-left (RTL) characters will pass through, so long as the entire
    // domain is wholly RTL as in this case. It even renders nicely in Chrome.
    return constructCacheDomain_('xn--4gbrim.xn----rmckbbajlc6dj7bxne2c.xn--wgbh1c').then(output => {
      expect(output).to.equal('xn-------i5fvcbaopc6fkc0de0d9jybegt6cd');
    });
  });

  it('should compute RTL & LTR chars correctly', () => {
    // A mix of RTL and LTR can't be legally combined into one label.
    // ToASCII() catches this case for us and fails, so we fall back:
    return constructCacheDomain_('hello.xn--4gbrim.xn----rmckbbajlc6dj7bxne2c.xn--wgbh1c').then(output => {
      expect(output).to.equal('a6h5moukddengbsjm77rvbosevwuduec2blkjva4223o4bgafgla');
    });
  });

  it('should compute constructViewerCacheUrl correctly', () => {
    return constructViewerCacheUrl('https://www.ampproject.org', initParams).then(output => {
      expect(output).to.equal('https://www-ampproject-org.cdn.ampproject.org/v/s/www.ampproject.org/?amp_js_v=0.1#origin=http%3A%2F%2Flocalhost%3A8000');
    });
  });

  it('should compute constructViewerCacheUrl correctly', () => {
    return constructViewerCacheUrl('http://www.example.com/article/bla/la', initParams).then(output => {
      expect(output).to.equal('https://www-example-com.cdn.ampproject.org/v/www.example.com/article/bla/la?amp_js_v=0.1#origin=http%3A%2F%2Flocalhost%3A8000');
    });
  });

  it('should compute constructViewerCacheUrl correctly', () => {
    return constructViewerCacheUrl('http://www.example.com/foo?amp=true', initParams).then(output => {
      expect(output).to.equal('https://www-example-com.cdn.ampproject.org/v/www.example.com/foo?amp=true&amp_js_v=0.1#origin=http%3A%2F%2Flocalhost%3A8000');
    });
  });
});