<?php

/**
 * subtitle 
 * 
 * This script renames the subtitles (from https://github.com/qiaoxueshi/WWDC_2014_Video_Subtitle)
 * to the same as videos
 *
 * Elf Sundae, www.0x123.com
 */

$subtitle_dir = "{$_SERVER['HOME']}/Desktop/WWDC_2014_Video_Subtitle";
$video_dir = "/data/ios_dev_videos/wwdc/2014";

$subtitle_dir = rtrim($subtitle_dir, '/');
$video_dir = rtrim($video_dir, '/');

$video_files = array();

/* Get all videos file name */
if ($handle = opendir($video_dir)) {
	while (false !== ($entry = readdir($handle))) {
		if (endsWith($entry, '.mov')) {
			$video_files[] = str_replace('.mov', '', $entry);
		}
	}
	closedir($handle);
}

/* rename */
if ($handle = opendir($subtitle_dir)) {
	while (false !== ($entry = readdir($handle))) {
		if (endsWith($entry, '.srt')) {
			$number = str_replace('.srt', '', $entry);
			$video_filename = '';
			foreach ($video_files as $v) {
				if (startsWith($v, $number)) {
					$video_filename = $v;
				}
			}
			if (!empty($video_filename)) {
				$video_filename .= '.srt';
				
				$old_file = $subtitle_dir . '/' . $entry;
				$new_file = $subtitle_dir . '/' . $video_filename;
				//echo "rename $old_file $new_file\n";
				rename($old_file, $new_file);
			} else {
				echo "Video Not Found: $entry\n";
			}
		}
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