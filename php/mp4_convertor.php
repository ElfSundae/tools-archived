<?php
/**
* Convert any video formats to H264 mp4 file (for mobile device) with `faststart` supported. 
*
* by Elf Sundae. http://www.0x123.com
*/

/**
*TODO:   1. Shows remaining time while converting.
*        2. sub_dir 
*        3. show converting file information, filename, etc..
*/

require_once "VideoInfo.php";

$ffmpeg_path = '/usr/local/bin/ffmpeg';
$supported_extentions = array('wmv', 'avi', 'rmvb', 'rm', 'mpg', 'mpeg');

if (count($argv) < 2 ) {
        global $supported_extentions;
        $script_path = $argv[0];
        $script_path_info = pathinfo($argv[0]);
        $script_name = $script_path_info['basename'];
        $exts = implode(', ', $supported_extentions);
        die("Usage:\n\t$script_name \"path/to/mp4/file/OR/dir\"\nSupported Extensions: $exts \n\n");
}

fun_main($argv[1]);

function fun_main($path) {
        if (!file_exists($path)) {
                die ("Error: $path is not exists.\n");
        }      
        echo "############################################################\n";
        echo "### starting to convert, press `q` to stop one operation.\n";
        echo "############################################################\n";  
        if (is_file($path)) {
                convert2mp4($path);
        } else if (is_dir($path)) {
                $files = get_video_files_in_dir($path);
                if (0 == count($files)) {
                        die("Error: no video files found in '{$path}'\n");   
                } 

                foreach ($files as $file) {
                        convert2mp4($file);
                }   
        } else {
                die ("Error: $path is not file nor directory.\n");
        }
}

function get_video_files_in_dir($dir) {
        global $supported_extentions;
        $arr = scandir($dir);
        $result = array();
        foreach ($arr as $file) {
                $pathinfo = pathinfo($file);
                if (isset($pathinfo['extension'])) {
                        $ext = strtolower($pathinfo['extension']);
                        if (in_array($ext, $supported_extentions)) {
                                $file = rtrim($dir, '/') . '/' . $file;
                                array_push($result, $file);   
                        }
                }
        }
        return $result;
}

function get_destination_mp4_filepath($src_file) {
        static $_shared_dir_name = '';
        if (empty($_shared_dir_name) && !empty($src_file)) {
                $pathinfo = pathinfo($src_file);
                $dir_name = 'convert-' . date('His');
                $dir_name = $pathinfo['dirname'] . '/' . $dir_name . '/';
                if (!file_exists($dir_name) || !is_dir($dir_name)) {
                        if (TRUE == @mkdir($dir_name)) {
                                $_shared_dir_name = $dir_name;
                        } 
                }
        }
        if (!empty($_shared_dir_name) && !empty($src_file)) {
                $pathinfo = pathinfo($src_file);
                return $_shared_dir_name . $pathinfo['filename'] . '.mp4';
        } 
        return '';
}

/**
* return like `480x320`
*/
function video_size($file, $default_width = 960, $default_height = 640) {
        $width = $default_width;
        $height = $default_height;
        
        $info = VideoInfo::get_info($file);
        if ($info) {
                $width = $info->video_info['width'];
                $height = $info->video_info['height'];
                if (!$width || !$height) {
                        $width = $default_width;
                        $height = $default_height;
                }
        }

        if ($width > $default_width && $height > $default_height) {
                $min = min($width, $height);
                if ($min == $width) {
                        $height = $default_width * $height * 1.0 / $width;
                        $width = $default_width;
                } else {
                        $width = $default_height * $width * 1.0 / $height;
                        $height = $default_height;
                }
        }

        $width = (int)(ceil($width));
        $height = (int)(ceil($height));
        
        return "{$width}x{$height}";
}

function convert2mp4($file) {
        global $ffmpeg_path;
        if (!file_exists($file) || !is_file($file)) {
                echo "<Error>: $file is not a file OR it isn't exists.\n";
        } else {
                $error = '';
                $size_string = video_size($file);
                static $file_number = 0;
                $file_number++;
                echo "[ {$file_number} ]: {$file}   ...... ($size_string)\n";
                $pathinfo = pathinfo($file);
                $mp4name = get_destination_mp4_filepath($file);
                if (!$mp4name) {
                        $error = "Cannot create destination path.\n";
                }
                if (empty($error)) {
                        /*$cmd = escapeshellcmd("{$ffmpeg_path} -y -s {$size_string} -r 30000/1001 -b 200k -bt 240k 
                        -acodec libfaac -ac 2 -ar 48000 -ab 128k -vcodec libx264 
                        -loglevel error -stats -movflags faststart -level 30
                        '{$mp4name}' -i '{$file}'"); */
                        
                 
                        $cmd = escapeshellcmd("{$ffmpeg_path} -i '{$file}' -y -s {$size_string} -acodec libfaac -vcodec libx264
                                -loglevel error -stats -movflags faststart -level 30 '{$mp4name}'");
                        //echo $cmd . PHP_EOL;
                        exec($cmd);
                } 
                
                if (empty($error)) {
                        echo "\t\t\t\t Done.\n";
                } else {
                        echo "$error \n";
                }
        }
}