<?php

$page = file_get_contents('2013_sample_code.html');
if (!$page) {
	echo "No contents.\n";
	exit;
}

$regex = "/download\\.action\\?path=([^'\"]+)/i";
if (preg_match_all($regex, $page, $matches)) {
	$text = '';
	foreach ($matches[1] as $path) {
		$text .= 'http://adcdownload.apple.com/' . $path . "\n";
	}
	file_put_contents('2013_sample_code.txt', $text);
}