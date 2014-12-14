<?php

/**
 * 遍历目录, 返回某类型的所有文件列表.
 *
 * Elf Sundae,  2011-11-28
 */

// $tree = dir_tree('/data/www/test.0x123.com/public/tmp/mm-wangqiulei', ['html', '*.php', 'index*'], true);
$tree = dir_tree('/data/www/test.0x123.com/public/tmp/mm-wangqiulei', '*', true);
print_r($tree);

/**
 * @param $dir 绝对路径
 * @param $extension 不区分大小写,支持单独字符串,数组,*通配符, 例如 '*', ['jpg', 'test*.png']
 */
function dir_tree($dir, $extension = '*', $recursive = false) {
	$result = array();
	$dir = rtrim($dir, '/');
	
	if (!is_string($extension) && !is_array($extension)) {
		$extension = '';
	}
	
	if (!file_exists($dir) || !is_dir($dir)) {
		return $result;
	}
	
	
	$handle = opendir($dir);
	if (!$handle) {
		return $result;
	}

	while (false !== ($entry = readdir($handle))) {
		if (startsWith($entry, '.')) {
			continue;
		}
		
		$fullpath = $dir . '/' . $entry;
		
		if (is_dir($fullpath)) {
			if ($recursive) {
				$sub = dir_tree($fullpath, $extension, $recursive);
				$result = array_merge($result, $sub);
			} else {
				continue;
			}
		} else {
			$can_add = false;
			$ext = strtolower(pathinfo($entry, PATHINFO_EXTENSION));
			if (is_array($extension)) {
				foreach ($extension as $type) {
					$type = strtolower($type);
					if (strpos($type, '*') !== false) {
						if (fnmatch($type, $entry)) {
							$can_add = true;
						}
					} else {
						if ($type == $ext) {
							$can_add = true;
						}
					}
				}
				
			} else { // string
				$type = strtolower($extension);
				if (strpos($type, '*') !== false) {
					if (fnmatch($type, $entry)) {
						$can_add = true;
					}
				} else {
					if ($type == $ext) {
						$can_add = true;
					}
				}
			}
			if ($can_add) {
				$result[] = $fullpath;
			}
		}
	}
	closedir($handle);
	
	return $result;
}


function startsWith($haystack, $needle) {
	return $needle === "" || strrpos($haystack, $needle, -strlen($haystack)) !== FALSE;
}
