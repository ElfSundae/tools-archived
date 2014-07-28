// ==UserScript==
// @name	Google Optimization
// @namespace	0x123.com
// @author      Elf Sundae
// @description	Google webpage optimization
// @copyright	www.0x123.com
// @icon        http://www.google.com/images/google_favicon_128.png
// @encoding    utf-8
// @run-at      document-end
// @include 	/^https?://www\.google\.com
// @date        28/07/2014
// @modified    28/07/2014
// @version    	1.0.0
// ==/UserScript==


if (document.URL.match(/[\?#&]q=/g)) {
	remove_url_tracker();
	function remove_url_tracker() {
		var timer = setInterval(function(){
			var ires_div = document.getElementById('ires');
			if (null != ires_div) {
				clearInterval(timer);
				var links = ires_div.getElementsByTagName('a');
				Array.prototype.slice.call(links).forEach(function(a) {
					console.log(a);
					a.removeAttribute("onmousedown");
					// var url = a.getAttribute('data-href');
					// if (null != url) {
					// 	a.setAttribute('href', url);
					// }
				})
				var resultStats = document.getElementById('resultStats');
				resultStats.innerHTML += "<nobr>&nbsp;<i>Removed URL tracker.</i>&nbsp;</nobr>"
			}
		}, 100);
	}
}