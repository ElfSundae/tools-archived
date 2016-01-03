// ==UserScript==
// @name       kFangFix
// @namespace  http://www.0x123.com/
// @description  Fix kFang website for Mac OS X.
// @include 	http://app100646015.qzone.qzoneapp.com/*
// @run-at      document-end
// @copyright  Elf Sundae
// @version    0.1
// ==/UserScript==

(function(){
	document.getElementsByTagName("body")[0].style.marginLeft = '20px';
	
	var dynamic = document.getElementsByClassName('sendgift_new')[0];
	if (dynamic) {
		var main_nav = document.getElementsByClassName('header_w')[0];
		var main_content = document.getElementsByClassName('main2_w')[0];
		var gd_w = document.getElementsByClassName('gd_w')[0];
		
		// change dynamic_div order
		main_content.removeChild(dynamic);
		main_content.insertBefore(dynamic, gd_w);
		
		// margin top
		main_content.style.marginTop = '-12px';
		
		// automate 'close flash'
		var close_flash = document.getElementsByClassName('close_flash')[0];
		close_flash.onclick.apply(close_flash);
		
	}
})();
