<?php

/**
 * Get WWDC Session Videos/PDFs URL.
 *
 * by Elf Sundae, www.0x123.com
 *
 * $ php url.php 2014 hd > 2014_hd.txt
 * $ php url.php 2014 pdf > 2014_pdf.txt
 */

/* option: 2014,2013,enterprise */
$key = '2014';
/* option: hd,sd,pdf */
$type = 'hd';
$page_url = '';

if (count($argv) > 2) {
	$key = $argv[1];
	$type = $argv[2];
} else if (count($argv) > 1) {
	echo "Usage: php $argv[0] [key] [type] > file.txt\n\n";
	echo "key:\t2014,2013,enterprise,techtalks\n";
	echo "type:\thd,sd,pdf\n";
	echo "\n";
	exit();
}

if ($key == '2014' || $key == '2013') {
	$page_url = "https://developer.apple.com/videos/wwdc/$key";
} else if ($key == 'enterprise') {
	$page_url = "https://developer.apple.com/videos/$key";
} else if ($key == 'techtalks') {
	$page_url = "https://developer.apple.com/tech-talks/videos";
} else {
	die("Wrong key '$key'\n");
}

$page = file_get_contents($page_url);
$regex = '';
if ($type == 'hd' || $type == 'sd') {
	$regex = "/http:\\/\\/devstreaming[^\"]+[_-]{$type}[^\"]+/i";
} else if ($type == 'pdf') {
	$regex = "/http:\\/\\/devstreaming[^\"]+\\.{$type}[^\"]+/i";
}

if (!empty($regex) && preg_match_all($regex, $page, $matches)) {
	if (is_array($matches[0])) {
		foreach ($matches[0] as $url) {
			echo $url . PHP_EOL;
		}		
	}
} else {
	echo "No contents for $page\n";
}

exit;