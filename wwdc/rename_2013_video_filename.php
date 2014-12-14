<?php

/**
 * 下载目录2013里现在的文件名是 101-HD.mov 101-HD.srt 101.pdf 这样的命名, 
 * 全部修改为 101 Platforms State of the Union.mov(srt|pdf) 
 * 方便浏览 查找
 */

// $video_dir = "/data/ios_dev_videos/wwdc/2013";
// $html = file_get_contents('wwdc_2013.html');

$video_dir = "/data/ios_dev_videos/wwdc/2014";
$html = file_get_contents('wwdc_2014.html');


if (!$html) {
	echo "WWDC HTML page not found.\n";
	exit;
}

/* get all filename from Apple webpage */
$titles = array();
$regex = "/<li class=\"session\" id=\"(\\d+)-video\">\\s*<ul>\\s*<li class=\"title\">([^<]+)<\/li>/i"; 
if (preg_match_all($regex, $html, $matches)) {
	foreach ($matches[1] as $index => $no) {
		$titles[] = "$no {$matches[2][$index]}.mov";
	}
} else {
	echo "No matches.\n";
	exit;
}
// print_r($titles);
// exit;

/* loop download directory and rename filenames */
if ($handle = opendir($video_dir)) {
	while (false !== ($entry = readdir($handle))) {
		if (startsWith($entry, '.')) {
			continue;
		}
		$pathinfo = pathinfo($entry);
		$number = strval(intval($pathinfo['filename']));
		
		// 找到改number对应的title
		$matchedTitle = null;
		foreach ($titles as $t) {
			$pathinfo_t = pathinfo($t);
			$tt = $pathinfo_t['filename'];
			if (startsWith($tt, $number)) {
				$matchedTitle = $tt;
				break;
			}
		}
		if (empty($matchedTitle)) {
			continue;	
		}
		
		// 重命名文件
		$src_file = $video_dir . '/' . $entry;
		$dest_file = $video_dir . '/' . $matchedTitle . '.' . $pathinfo['extension'];
		echo "$src_file =>\n$dest_file\n\n";
		rename($src_file, $dest_file);
	}
	closedir($handle);
}


function startsWith($haystack, $needle) {
	// search backwards starting from haystack length characters from the end
	return $needle === "" || strrpos($haystack, $needle, -strlen($haystack)) !== FALSE;
}
function endsWith($haystack, $needle) {
	// search forward starting from end minus needle length characters
	return $needle === "" || strpos($haystack, $needle, strlen($haystack) - strlen($needle)) !== FALSE;
}