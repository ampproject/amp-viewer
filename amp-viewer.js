class AmpViewer {
 
 /**
  * @param {!Element} hostEl the element to attatch the iframe to.
  * @param {string} ampUrl the AMP page url.
  */
 constructor(hostEl, ampUrl) {
  /** @type {!Element} */
  this.hostEl_ = hostEl;

  /** @type {string} */
  this.ampUrl_ = ampUrl;

  this.attach();
 }
 
 attach() {
   var iframe = document.createElement('iframe');
   this.hostEl_.appendChild(iframe);
   iframe.src = this.ampUrl_;
 }

}