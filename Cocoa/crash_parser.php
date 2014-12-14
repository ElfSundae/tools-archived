<?php
/**
 * Parse iOS/OSX Crash log or symbol
 *
 * by Elf Sundae, www.0x123.com 2014-12-15
 */

if (!file_exists('/usr/bin/dwarfdump')) {
	die("dwarfdump is not found.\n");
} else if (!file_exists('/usr/bin/atos')) {
	die("atos is not found.\n");
}

if (!empty($argv) && $argv[1] == 'list') {
	list_archives();
	exit;
} else if (count($argv) >= 2) {
	$uuid = '';
	$crash_log = '';
	$symbol = array();
	
	if (preg_match('/^[0-9a-z-]{36}$/i', $argv[1], $matches)) {
		$uuid = $matches[0];
		if (count($argv) >= 3) {
			if (file_exists($argv[2]) && is_file($argv[2])) {
				$crash_log = $argv[2];
			} else {
				foreach ($argv as $a) {
					if (preg_match('/^0x[0-9a-f]+$/i', $a)) {
						$symbol[] = $a;
					}
				}
			}
		}
	} else if (file_exists($argv[1]) && is_file($argv[1])) {
		$crash_log = $argv[1];
	}
	
	if (!empty($uuid) && !empty($symbol)) {
		parse_symbol($uuid, $symbol);
		exit;
	} else if (!empty($crash_log)) {
		parse_crash_log($crash_log, $uuid);
		exit;
	}
}

print_usage();

function print_usage() {
	echo "Usage:\n";
	echo "\tlist\t\tGet UUIDs and dSYM paths for all Xcode archives.\n";
	echo "\t<UUID> <symbol | crash log path> [symbol]\n";
	echo "\t\t\te.g.\n";
	echo "\t\t\tA0DB0F52-0D21-3FB6-AA03-59AFB3C2591A 0xbb23f\n";
	echo "\t\t\tA0DB0F52-0D21-3FB6-AA03-59AFB3C2591A 0xbb23f 0xace332 0xffd14a\n";
	echo "\t\t\tA0DB0F52-0D21-3FB6-AA03-59AFB3C2591A /data/crash_log/foo.txt\n";	
	echo "\t<crash log path>\tThe crash log must contain UUID, e.g. from Xcode, Umeng, PLCrashReporter\n";
	echo "\n";
	exit;
}

function list_archives() {
	$cmd = "find ~/Library/Developer/Xcode/Archives -iname '*.dSYM' -print0 | xargs -0 dwarfdump -u";
	$output = shell_exec($cmd);
	if (empty($output)) {
		echo "No Archives.\n";
		exit;
	}
	echo $output;
}

function get_dSYMPaths_for_UUID($uuid, &$outArch = null) {

	$dSYMPath_cmd = "find ~/Library/Developer/Xcode/Archives -iname '*.dSYM' -print0 | xargs -0 dwarfdump -u";
	$dSYMPath_cmd .= " | grep $uuid";
	$output = shell_exec($dSYMPath_cmd);
	if (!empty($output)) {
		$result_path = null;
		$result_arch = null;
		$regex = '/UUID:\\s*([0-9a-z-]{36})\\s*\((armv[^\)]+)\)\\s*([^\\n]+)/i';
		if (preg_match_all($regex, $output, $matches)) {
			for ($i = 0; $i < count($matches[0]); ++$i) {
				$result_arch = $matches[2][$i];
				$result_path = $matches[3][$i];
			}
		}
		if (!empty($result_path)) {
			if ($outArch) {
				$outArch = $result_arch;
			}
			return $result_path;
		}
	}
	return null;
}

function parse_symbol($uuid, $symbol = array()) {
	if (empty($uuid) || empty($symbol)) {
		print_usage();
	}
	$arch = 'armv7';
	$dSYMPath = get_dSYMPaths_for_UUID($uuid, $arch);
	if (empty($dSYMPath)) {
		echo "dSYM file is not found for UUID $uuid.\n";
		return;
	}

	$cmd = "xcrun atos -arch $arch -o \"$dSYMPath\"";
	foreach ($symbol as $addr) {
		$cmd .= " $addr";
	}
	
	echo $cmd;
	$output = shell_exec($cmd);
	echo $output;
}

function parse_crash_log($crash_log, $uuid = '') {
	echo "TODO:";
}